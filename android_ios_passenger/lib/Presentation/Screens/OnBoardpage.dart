import 'dart:async';
import 'dart:convert';

import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:android_ios_passenger/Presentation/Screens/Onboardedpage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class Onboard extends StatefulWidget {
  final String RouteId;
  final String? routeDrop;
  final String? routePickup;
  final String? Stop;
  final double Latitude;
  final double Lonitude;
  const Onboard({Key? key, required this.RouteId, required this.routeDrop, required this.routePickup, required this.Stop, required this.Latitude, required this.Lonitude}) : super(key: key);

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  LatLng? _startLatLng;
  LatLng? _endLatLng;
  LatLng? _stopLatLng;

  List<LatLng> _routePoints = [];
  Timer? _timer;
  final String mapboxApiKey = "${ApiKey.Key}";
  final String mapboxGeocodingUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places/";


  @override
  void initState() {
    super.initState();
    _getCoordinatesFromAddresses();

  }

  @override
  void dispose() {
    super.dispose();


  }
  Future<void> _getCoordinatesFromAddresses() async {
    final pickup = widget.routePickup;
    final drop = widget.routeDrop;
    final stop = widget.Stop;

    try {
      String startAddressUrl = "$mapboxGeocodingUrl${Uri.encodeComponent(pickup!)}.json?access_token=$mapboxApiKey";
      String endAddressUrl = "$mapboxGeocodingUrl${Uri.encodeComponent(drop!)}.json?access_token=$mapboxApiKey";
      String StopAddressUrl = "$mapboxGeocodingUrl${Uri.encodeComponent(stop!)}.json?access_token=$mapboxApiKey";

      var startResponse = await http.get(Uri.parse(startAddressUrl));
      var endResponse = await http.get(Uri.parse(endAddressUrl));
      var StopResponse = await http.get(Uri.parse(StopAddressUrl));

      if (startResponse.statusCode == 200 && endResponse.statusCode == 200 && StopResponse.statusCode == 200) {
        var startData = jsonDecode(startResponse.body);
        var endData = jsonDecode(endResponse.body);
        var StopData = jsonDecode(StopResponse.body);

        if (startData['features'].isNotEmpty && endData['features'].isNotEmpty && StopData['features'].isNotEmpty) {
          double startLatitude = startData['features'][0]['center'][1];
          double startLongitude = startData['features'][0]['center'][0];

          double endLatitude = endData['features'][0]['center'][1];
          double endLongitude = endData['features'][0]['center'][0];

          double stopLatitude = StopData['features'][0]['center'][1];
          double stopLongtitude = StopData['features'][0]['center'][0];

          _startLatLng = LatLng(startLatitude, startLongitude);
          _endLatLng = LatLng(endLatitude, endLongitude);
          _stopLatLng = LatLng(stopLatitude, stopLongtitude);

          await _fetchRoute();

          setState(() {});
        }
      } else {
        print('Error getting coordinates: ${startResponse.statusCode} ${endResponse.statusCode} ${startResponse.statusCode}');
      }
    } catch (e) {
      print(e);
    }
  }
  Future<void> _fetchRoute() async {
    if (_startLatLng == null || _endLatLng == null) return;

    String directionsUrl =
        'https://api.mapbox.com/directions/v5/mapbox/driving/${_startLatLng!.longitude},${_startLatLng!.latitude};${_endLatLng!.longitude},${_endLatLng!.latitude}?geometries=geojson&access_token=$mapboxApiKey';
    try {
      final response = await http.get(Uri.parse(directionsUrl));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        var route = data['routes'][0]['geometry']['coordinates'] as List;
        var polylinePoints = route.map((point) => LatLng(point[1], point[0])).toList();
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
  Widget build(BuildContext context) {
    LatLng? LiveData = LatLng(widget.Latitude, widget.Lonitude);

    return Scaffold(
      body: Stack(
        children: [
          if (_startLatLng != null && _endLatLng != null)
            FlutterMap(
              options: MapOptions(
                initialCenter: LiveData,
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
                      color: Colors.black,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _startLatLng!,
                      child: Container(
                        child: Icon(Icons.location_on, color: Colors.red),
                      ),
                    ),
                    Marker(

                      point: _stopLatLng!,
                      child: Container(
                        child: Icon(Icons.location_on, color: Colors.blue),
                      ),
                    ),
                    Marker(
                      width: 180.0,
                      height: 180.0,
                      point: _endLatLng!,
                      child: Container(
                        height: 100,
                        child: Icon(Icons.location_on, color: Colors.green),
                      ),
                    ),
                    Marker(

                      width: 180.0,
                      height: 180.0,
                      point: LiveData,
                      child: Container(
                        height: 100,
                        child: Icon(Icons.drive_eta, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.055,
            bottom: MediaQuery.of(context).size.height * 0.26,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.89,
              height: MediaQuery.of(context).size.height * 0.10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
                color: Colours.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: 10),
                  Text(
                    "Hit 'OK' Once You Boarded",
                    style: TextStyle(color: Colors.black),
                  ),
                  Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Onboarded(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colours.orange,
                      foregroundColor: Colours.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: Size(MediaQuery.of(context).size.width * 0.02, 0),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      child: Text(
                        "ok",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                ],
              ),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.055,
            bottom: MediaQuery.of(context).size.height * 0.05,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.89,
              height: MediaQuery.of(context).size.height * 0.23,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colours.white,
                border: Border.all(color: Colours.black),
              ),
              child: Column(
                children: [
                  SizedBox(height: 10),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.height * 0.10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
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
                          bottom: MediaQuery.of(context).size.height * 0.05,
                          left: MediaQuery.of(context).size.width * 0.195,
                          child: Column(
                            children: [
                              Text(
                                "SPR123",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: MediaQuery.of(context).size.height * 0.03,
                          left: MediaQuery.of(context).size.width * 0.195,
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
                          bottom: MediaQuery.of(context).size.height * 0.05,
                          left: MediaQuery.of(context).size.width * 0.58,
                          child: Column(
                            children: [
                              Text(
                                "10 min",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: MediaQuery.of(context).size.height * 0.03,
                          left: MediaQuery.of(context).size.width * 0.53,
                          child: Column(
                            children: [
                              Text(
                                "Estimated Time",
                                style: TextStyle(fontSize: 10),
                              )
                            ],
                          ),
                        ),
                        Positioned(
                          left: MediaQuery.of(context).size.width * 0.75,
                          bottom: 40,
                          child: Image.asset(
                            "assets/clock.png",
                            width: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // SizedBox(height: 15),
                  // Center(
                  //   child: ElevatedButton(
                  //     onPressed: () {
                  //       // Implement your logic here
                  //     },
                  //     style: ElevatedButton.styleFrom(
                  //       backgroundColor: Colours.orange,
                  //       foregroundColor: Colours.white,
                  //       shape: RoundedRectangleBorder(
                  //         borderRadius: BorderRadius.circular(5),
                  //       ),
                  //       minimumSize: Size(MediaQuery.of(context).size.width * 0.7, 40),
                  //     ),
                  //     child: Padding(
                  //       padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  //       child: Text(
                  //         "Cancel",
                  //         style: TextStyle(fontSize: 16),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
