import 'dart:async';

import 'package:android_ios_driver/Colours/Apikey.dart';
import 'package:android_ios_driver/Colours/Colours.dart';
import 'package:android_ios_driver/Presentation/Screens/FullMap.dart';
import 'package:android_ios_driver/Presentation/Screens/Stops_page.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:http/http.dart' as http;
import 'dart:convert';

class Routepage extends StatefulWidget {
  final String RouteID;
  final String Vehicle;
  final int ScheduleID;
  final String Token;
  final String startAddress;
  final String endAddress;

  const Routepage({
    Key? key,
    required this.RouteID,
    required this.Vehicle,
    required this.ScheduleID,
    required this.Token,
    required this.startAddress,
    required this.endAddress,
  }) : super(key: key);

  @override
  State<Routepage> createState() => _RoutepageState();
}

class _RoutepageState extends State<Routepage> {
  loc.LocationData? _currentLocation;
  MapBoxNavigationViewController? _controller;
  late MapBoxOptions _navigationOption;
  bool _isNavigating = false;
  WayPoint? _startWayPoint;
  WayPoint? _endWayPoint;
  late LatLng _startLatLng;
  late LatLng _endLatLng;
  List<LatLng> _routePoints = [];
  StreamSubscription<loc.LocationData>? _locationSubscription;
  @override
  void initState() {
    super.initState();
    _initializeLocationAndMap();
  }

  Future<void> _initializeLocationAndMap() async {
    await _getCoordinatesFromAddresses();
    loc.Location location = loc.Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }

    _currentLocation = await location.getLocation();
    _navigationOption = MapBoxOptions(
      initialLatitude: _currentLocation?.latitude ?? 0.0,
      initialLongitude: _currentLocation?.longitude ?? 0.0,
      zoom: 15.0,
      mode: MapBoxNavigationMode.driving,
    );

    _locationSubscription = location!.onLocationChanged.listen((loc.LocationData currentLocation) {
      setState(() {
        _currentLocation = currentLocation;
      });
    });


    setState(() {});
  }

  final String mapboxApiKey = "${ApiKey.Key}";
  final String mapboxGeocodingUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places/";

  Future<void> _getCoordinatesFromAddresses() async {
    try {
      String startAddressUrl = mapboxGeocodingUrl + Uri.encodeComponent(widget.startAddress) + ".json?access_token=" + mapboxApiKey;
      String endAddressUrl = mapboxGeocodingUrl + Uri.encodeComponent(widget.endAddress) + ".json?access_token=" + mapboxApiKey;

      var startResponse = await http.get(Uri.parse(startAddressUrl));
      var endResponse = await http.get(Uri.parse(endAddressUrl));

      if (startResponse.statusCode == 200 && endResponse.statusCode == 200) {
        var startData = jsonDecode(startResponse.body);
        var endData = jsonDecode(endResponse.body);

        if (startData['features'].isNotEmpty && endData['features'].isNotEmpty) {
          double startLatitude = startData['features'][0]['center'][1];
          double startLongitude = startData['features'][0]['center'][0];

          double endLatitude = endData['features'][0]['center'][1];
          double endLongitude = endData['features'][0]['center'][0];

          _startLatLng = LatLng(startLatitude, startLongitude);
          _endLatLng = LatLng(endLatitude, endLongitude);

          await _fetchRoute();

          setState(() {});
        }
      } else {
        print('Error getting coordinates: ${startResponse.statusCode} ${endResponse.statusCode}');
      }
    } catch (e) {
      print('Error getting coordinates: $e');
    }
  }


  Future<void> _tripstatus() async {
    if (_currentLocation == null) return;

    double latitude = _currentLocation!.latitude ?? 0.0;
    double longitude = _currentLocation!.longitude ?? 0.0;

    String formattedTime = DateFormat('HH:mm:ss').format(DateTime.now());
    String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      var headers = {
        'Authorization': 'Bearer ${widget.Token}'
      };
      final response = await Dio().post(
        '${ApiKey.baseUrl}/PostTrip?token=${widget.Token}',
        data: {
          "schedule_id": widget.ScheduleID,
          "trip_status": "started",
          "trip_start_time": formattedTime,
          "trip_date": formattedDate,
          "longitude": longitude,
          "latitude": latitude,
          "vehicle_number": widget.Vehicle
        },
        options: Options(
          headers: headers
        )
      );
      if (response.statusCode == 200) {
        print("response from post Trip :${response.data}");
        print("trip ID : ${response.data['trip_id']}");
        final int StopID = response.data['trip_id'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Stopspage(RouteID: widget.RouteID, Destination: widget.endAddress, Token: widget.Token, startAddress: widget.startAddress,endAddress: widget.endAddress, ScheduleID: widget.ScheduleID,Vehicle: widget.Vehicle, TripID: StopID,),
          ),
        );
      } else {
        print('Failed to update vehicle');
      }
    } catch (error) {
      print('Error updating vehicle: $error');
    }
  }

  Future<void> _fetchRoute() async {
    if (_startLatLng == "null" || _endLatLng ==" null") return;

    String directionsUrl =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${_startLatLng.longitude},${_startLatLng.latitude};${_endLatLng!.longitude},${_endLatLng!.latitude}?geometries=geojson&access_token=$mapboxApiKey';

    try {
      final response = await http.get(Uri.parse(directionsUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var route = data['routes'][0]['geometry']['coordinates'] as List;
        var polylinePoints = route
            .map((point) => LatLng(point[1], point[0]))
            .toList();

        setState(() {
          _routePoints = polylinePoints;
        });
      } else {
        print('Error fetching route: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
  }


  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_currentLocation != null && _startLatLng != "null" && _endLatLng != "null")
            FlutterMap(
              options: MapOptions(
                initialCenter: _startLatLng,
                initialZoom: 10.0,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=$mapboxApiKey',
                  additionalOptions: {
                    'accessToken': mapboxApiKey,
                    'id': 'mapbox.streets',
                  },
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.0,
                      color: Colors.blue,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _startLatLng,
                      child:Container(
                        child: Icon(Icons.location_on, color: Colors.red),
                      ),
                    ),
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _endLatLng,
                      child:Container(
                        child: Icon(Icons.location_on, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.06,
            child: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(Icons.arrow_circle_left_rounded, size: 40),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.7,
            left: MediaQuery.of(context).size.width * 0.03,
            bottom: MediaQuery.of(context).size.height * 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colours.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colours.black.withOpacity(0.5),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.35,
              child: Stack(
                children: [
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0,
                    bottom: MediaQuery.of(context).size.height * 0.15,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colours.black.withOpacity(0.1),
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20)),
                      ),
                      width: MediaQuery.of(context).size.width * 0.95,
                      height: MediaQuery.of(context).size.height * 0.15,
                      child: Stack(
                        children: [
                          Positioned(
                            child: Image.asset(
                              "assets/bus.png",
                              height: MediaQuery.of(context).size.height * 0.4,
                              width: MediaQuery.of(context).size.width * 0.2,
                            ),
                          ),
                          Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.07,
                            left: MediaQuery.of(context).size.width * 0.185,
                            child: Column(
                              children: [
                                Text(
                                  widget.Vehicle,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.057,
                            left: MediaQuery.of(context).size.width * 0.185,
                            child: Column(
                              children: [
                                Text(
                                  "Vehicle Number",
                                  style: TextStyle(fontSize: 10),
                                )
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.07,
                            left: MediaQuery.of(context).size.width * 0.69,
                            child: Column(
                              children: [
                                Text(
                                  widget.RouteID,
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: MediaQuery.of(context).size.height * 0.057,
                            left: MediaQuery.of(context).size.width * 0.69,
                            child: Column(
                              children: [
                                Text(
                                  "Route ID",
                                  style: TextStyle(fontSize: 10),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.025,
                    bottom: MediaQuery.of(context).size.height * 0.067,
                    child: Center(
                      child: ElevatedButton(
                        onPressed: _tripstatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colours.orange,
                          foregroundColor: Colours.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          minimumSize: Size(
                              MediaQuery.of(context).size.width * 0.9, 50),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            "GO Online",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
