import 'package:android_ios_driver/Colours/Apikey.dart';
import 'package:android_ios_driver/Colours/Colours.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class Passengepage extends StatefulWidget {
  final int StopID;
  final int RouteID;
  final String Token;
  const Passengepage({Key? key, required this.RouteID, required this.StopID, required this.Token}) : super(key: key);

  @override
  State<Passengepage> createState() => _PassengepageState();
}

class _PassengepageState extends State<Passengepage> {
  List<Map<String, dynamic>> passengerData = [];
  List<bool> _switchStates = [];

  @override
  void initState() {
    super.initState();
    _fetchPassengerData();
    print(widget.StopID);
  }

  Future<void> _fetchPassengerData() async {
    final Dio _dio = Dio();
    try {
      var headers = {
        'Authorization': 'Bearer ${widget.Token}'
      };
      String apiUrl = '${ApiKey.baseUrl}/GetPassengersBasedStopId?stopid=${widget.StopID}&routeid=${widget.RouteID}';
      final response = await _dio.get(
          apiUrl,
        options: Options(
          headers: headers
        )
      );

      if (response.statusCode == 200) {
        print(response.data);
        setState(() {
          passengerData = List<Map<String, dynamic>>.from(response.data);
          _switchStates = List<bool>.filled(passengerData.length, false);
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colours.orange,
      body: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).size.height * 0.06,
            child: IconButton(
              // Back button
              onPressed: () {
                Navigator.of(context).pop(); // Navigate back
              },
              icon: Icon(Icons.arrow_circle_left_rounded, size: 40),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.13,
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
              width: MediaQuery.of(context).size.width * 1,
              height: MediaQuery.of(context).size.height * 1,
              child: ListView.separated(
                itemCount: passengerData.length,
                separatorBuilder: (BuildContext context, int index) {
                  return Divider(); // Add a divider between list items
                },
                itemBuilder: (context, index) {
                  final passenger = passengerData[index];
                  return ListTile(
                    leading: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(passenger['passenger_name'] ?? '', style: TextStyle(fontSize: 20)),
                        Text(passenger['passenger_phone']?.toString() ?? '', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    trailing: Transform.scale(
                      scale: 0.9,
                      child: Switch(
                        value: _switchStates[index], // Use the variable to manage the switch state
                        onChanged: (newValue) {
                          // Update the variable when the switch is toggled
                          setState(() {
                            _switchStates[index] = newValue;
                          });
                        },
                        activeColor: Colours.orange,
                        inactiveThumbColor: Colours.grey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
