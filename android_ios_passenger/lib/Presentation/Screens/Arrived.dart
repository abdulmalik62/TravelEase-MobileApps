import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:android_ios_passenger/Presentation/Screens/Homepage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class Arrived extends StatefulWidget {
  const Arrived({super.key});

  @override
  State<Arrived> createState() => _ArrivedState();
}

class _ArrivedState extends State<Arrived> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                additionalOptions: {
                  'accessToken': '${ApiKey.Key}',
                  'id': 'mapbox/light-v10',
                },
              ),
            ],
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
                  border: Border.all(
                      color: Colours.black
                  )
              ),
              child: Column(
                children: [
                  SizedBox(height: 10,),
                  Positioned(
                    // insidesquare
                    left: MediaQuery.of(context).size.width * 0,
                    bottom: MediaQuery.of(context).size.height * 0.15,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20)),
                      ),
                      width: MediaQuery.of(context).size.width * 0.95,
                      height: MediaQuery.of(context).size.height * 0.10,
                      child: Stack(
                        children: [
                          Positioned(
                            child: Image.asset(
                              "assets/bus.png",
                              height:
                              MediaQuery.of(context).size.height * 0.4,
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
                                  "0 min",
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
                            child: Row(
                              children: [
                                Text(
                                  "Estimated Time",
                                  style: TextStyle(fontSize: 10),
                                )
                              ],
                            ),
                          ),
                          Positioned(
                            left: MediaQuery.of(context).size.width * 0.78,
                            bottom: MediaQuery.of(context).size.height * 0.020,
                            child: Image.asset(
                              "assets/clock.png",
                              height: MediaQuery.of(context).size.height * 0.4,
                              width: MediaQuery.of(context).size.width * 0.12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.055,
                    bottom: MediaQuery.of(context).size.height * 0.05,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.89,
                      height: MediaQuery.of(context).size.height * 0.10,
                      child: Column(
                        children: [
                          Center(
                              child:Text("Hope you enjoyed the journey.",style: TextStyle(color: Colours.orange,fontWeight: FontWeight.bold),)
                          ),
                          Center(
                            child: Text("Have a great day!!!"),
                          ),
                          SizedBox(height: 5,),
                          Center(
                            child: ElevatedButton(
                              onPressed: () {

                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colours.orange,
                                foregroundColor:
                                Colours.white, // Change the button's background color
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5), // Adjust border radius to make it square
                                ),
                                minimumSize: Size(
                                    MediaQuery.of(context).size.width * 0.7,40),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                child: Text(
                                  "Back to Home",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
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
}
