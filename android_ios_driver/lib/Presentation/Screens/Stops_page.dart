import 'dart:async';
import 'dart:ffi';
import 'package:android_ios_driver/Colours/Apikey.dart';
import 'package:android_ios_driver/Colours/Colours.dart';
import 'package:android_ios_driver/Presentation/Screens/Passenger.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:location/location.dart' as loc;

class Stopspage extends StatefulWidget {
  final String Destination;
  final String RouteID;
  final String Token;
  final String startAddress;
  final String endAddress;
  final int ScheduleID;
  final String Vehicle;
  final int TripID;
  const Stopspage({Key? key, required this.RouteID, required this.Destination, required this.Token, required this.startAddress, required this.endAddress, required this.ScheduleID, required this.Vehicle, required this.TripID}) : super(key: key);

  @override
  State<Stopspage> createState() => _StopspageState();
}

class _StopspageState extends State<Stopspage> {
  List<Map<String, dynamic>> stopData = [];
  List<Marker> markers = [];
  LatLng? initialCenter;
  late MapBoxOptions _navigationOption;
  late int StopId;
  late LatLng _startLatLng;
  late LatLng _endLatLng;
  List<LatLng> _routePoints = [];
  late int RouteID;
  loc.LocationData? _currentLocation;
  StreamSubscription<loc.LocationData>? _locationSubscription;
  final String mapboxApiKey = "${ApiKey.Key}";
  final String mapboxGeocodingUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places/";

  @override
  void initState() {
    _fetchStopData();
    super.initState();
    _initializeLocationAndMap();
  }



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
          "trip_status": "ended",
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
        print(response.data);
        Navigator.of(context).pop();

      } else {
        print('Failed to update vehicle');
      }
    } catch (error) {
      print('Error updating vehicle: $error');
    }
  }

  Future<void> _fetchStopData() async {
    final Dio _dio = Dio();
    try {
      var headers = {
        'Authorization': 'Bearer ${widget.Token}'
      };
      String apiUrl = '${ApiKey.baseUrl}/GetStopsBasedRouteId?routeId=${widget.RouteID}';
      final response = await _dio.get(
          apiUrl,
        options: Options(
          headers: headers
        )
      );

      if (response.statusCode == 200) {
        print(response.data);
        setState(() {
          stopData = List<Map<String, dynamic>>.from(response.data);
        });

        for (var stop in stopData) {
          String stopAddress = stop['stop_address'] ?? '';
          StopId = stop['stop_id']??'';
          RouteID = stop['route_id']['id']??'';

          print("StopID : $StopId");
          print("RouteID : $RouteID");

          LatLng? coordinates = await _getCoordinatesFromAddress(stopAddress);
          if (coordinates != null) {
            if (initialCenter == null) {
              initialCenter = coordinates;
            }
            setState(() {
              markers.add(
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: coordinates,
                  child:  Icon(Icons.location_on, color: Colors.orange),
                ),
              );
            });
          }
        }

        if (initialCenter == null) {
          initialCenter = LatLng(9.0779, 77.3452);
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    final String mapboxApiKey = ApiKey.Key;
    final String mapboxGeocodingUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places/";
    try {
      String url = mapboxGeocodingUrl + Uri.encodeComponent(address) + ".json?access_token=" + mapboxApiKey;
      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['features'].isNotEmpty) {
          double latitude = data['features'][0]['center'][1];
          double longitude = data['features'][0]['center'][0];
          return LatLng(latitude, longitude);
        }
      } else {
        print('Error getting coordinates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting coordinates: $e');
    }
    return null;
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
          if (initialCenter != null)
            FlutterMap(
              options: MapOptions(
                center: initialCenter,
                zoom: 10.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}?access_token=${ApiKey.Key}',
                  additionalOptions: {
                    'accessToken': ApiKey.Key,
                    'id': 'mapbox.streets',
                  },
                ),
                MarkerLayer(
                  markers: markers,
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
              height: MediaQuery.of(context).size.height * 0.50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: ListView.separated(
                        itemCount: stopData.length,
                        separatorBuilder: (BuildContext context, int index) {
                          return Divider();
                        },
                        itemBuilder: (context, index) {
                          final stop = stopData[index];
                          return ListTile(
                            title: Text(stop['stop_name'] ?? ''),
                            trailing: TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => Passengepage(
                                      StopID: stop['stop_id'],
                                    RouteID: RouteID, Token: widget.Token,
                                  )),
                                );
                              },
                              child: Text('Passengers', style: TextStyle(color: Colours.orange)),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40.0, left: 20, right: 20),
                    child: Container(
                      child: Row(
                        children: [
                          _buildLocationIcon(),
                          SizedBox(width: 10),
                          Text("${widget.Destination}", style: TextStyle(fontSize: 20)),
                          Spacer(),
                          TextButton(
                            onPressed: () {
                             _tripstatus();
                            },
                            child: Text("End Trip", style: TextStyle(color: Colours.orange)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Icon(Icons.location_on, color: Colors.black, size: 30),
    );
  }
}
