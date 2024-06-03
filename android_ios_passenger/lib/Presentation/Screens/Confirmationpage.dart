import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/utils.dart';
import 'package:http/http.dart' as http;
import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:android_ios_passenger/Presentation/Screens/OnBoardpage.dart';
import 'package:android_ios_passenger/Presentation/Screens/Routepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class Confirmation extends StatefulWidget {
  final String? routeDrop;
  final String? routePickup;
  final String RouteId;
  final String? Stop;
  final int AttendanceId;

  const Confirmation({Key? key, required this.routeDrop, required this.routePickup, required this.RouteId,required this.Stop, required this.AttendanceId}) : super(key: key);

  @override
  State<Confirmation> createState() => _ConfirmationState();
}

class _ConfirmationState extends State<Confirmation> {
  LatLng? _startLatLng;
  LatLng? _endLatLng;
  LatLng? _stopLatLng;
  List<LatLng> _routePoints = [];
  late Timer _timer;
  final String mapboxApiKey = "${ApiKey.Key}";
  final String mapboxGeocodingUrl = "https://api.mapbox.com/geocoding/v5/mapbox.places/";

  @override
  void initState() {
    super.initState();
    _getCoordinatesFromAddresses();
    _fetchJobCards();
    FetchTrip();
    _timer = Timer.periodic(Duration(seconds: 60), (timer) {
      _fetchJobCards();
      FetchTrip();
    });
    print(widget.routePickup);
    print(widget.routeDrop);
    print(widget.Stop);
    print(widget.AttendanceId);
  }



  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
  }

  Future<void> _fetchJobCards() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    final Dio _dio = Dio();
    try {
      String apiUrl = '${ApiKey.baseUrl}/EmergencyMessage?attendanceId=${widget.AttendanceId}'; // Format current date
      final response = await _dio.get(
          apiUrl,
        options: Options(
          headers: headers
        )
      );

      if (response.statusCode == 200) {
        _timer.cancel();
        toastification.show(
          context: context,
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          description: Text("${response.data}"),
          alignment: Alignment.topRight,
          autoCloseDuration: const Duration(
            seconds: 4,
            milliseconds: 500,
          ),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: highModeShadow,
          showProgressBar: true,
          dragToClose: true,
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _cancelTrip() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Are you going to cancel the Trip?'),
          actions: <Widget>[
            ElevatedButton(
              child: Text(
                'No',
                style: TextStyle(color: Colors.orange,fontWeight: FontWeight.bold), // Highlighting the 'No' button
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
            ),
            ElevatedButton(
              child: Text('Yes',style: TextStyle(color:Colours.black ),),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                String? token = prefs.getString('token');
                var headers = {'Authorization': 'Bearer $token'};
                final Dio _dio = Dio();
                try {
                  String apiUrl = '${ApiKey.baseUrl}/PassengerCancelTrip?id=${widget.AttendanceId}';
                  final response = await _dio.delete(
                    apiUrl,
                    options: Options(
                      headers: headers,
                    ),
                  );

                  if (response.statusCode == 200) {

                    Navigator.pop(context);
                    Navigator.of(context).pop();
                    SharedPreferences prefs = await SharedPreferences.getInstance();
                    await prefs.remove('attendanceId');
                  }
                } catch (e) {
                  print(e);
                }
              },
            ),
          ],
        );
      },
    );
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

  Future<void> FetchTrip() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};
    final Dio _dio = Dio();
    print(widget.RouteId);
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      String apiUrl = '${ApiKey.baseUrl}/GetTripDetailsBasedRouteId?routeId=${widget.RouteId}&date=$formattedDate';
      final response = await _dio.get(
          apiUrl,
        options: Options(
          headers: headers
        )
      );

      if (response.statusCode == 200) {
        _timer.cancel();
        print(response.data['latitude']);
        print(response.data['longitude']);
        final double LiveLat = response.data['latitude'];
        final double LiveLong = response.data['longitude'];
        print(LiveLat);
        print(LiveLong);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('lat', LiveLat);
        await prefs.setDouble("long", LiveLong);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Onboard(
              RouteId: widget.RouteId,
              routeDrop: widget.routeDrop,
              routePickup: widget.routePickup,
              Stop: widget.Stop,
              Latitude: LiveLat,
              Lonitude: LiveLong,
            ),
          ),
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<bool> _onWillPop() async {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            if (_startLatLng != null && _endLatLng != null)
              FlutterMap(
                options: MapOptions(
                  center: _stopLatLng,
                  zoom: 10.0,
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
                    ],
                  ),
                ],
              ),
            Positioned(
              left: MediaQuery.of(context).size.width * 0.055,
              bottom: MediaQuery.of(context).size.height * 0.05,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.89,
                height: MediaQuery.of(context).size.height * 0.25,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colours.white,
                  border: Border.all(color: Colours.black),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Center(
                      child: SvgPicture.asset("assets/tick.svg"),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          FetchTrip();
                        },
                        child: Text(
                          "Your Coach is being allocated.",
                          style: TextStyle(color: Colours.orange, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Center(
                      child: Text("Thanks for waiting."),
                    ),
                    SizedBox(height: 10,),
                    Center(
                      child: TextButton(onPressed: (){
                        _cancelTrip();
                      },
                        child: Text("Cancel Trip",style: TextStyle(color: Colours.orange,fontWeight: FontWeight.bold),),)
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
