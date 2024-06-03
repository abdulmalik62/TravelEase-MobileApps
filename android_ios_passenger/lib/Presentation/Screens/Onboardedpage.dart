import 'dart:async';

import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:android_ios_passenger/Presentation/Screens/Arrived.dart';
import 'package:android_ios_passenger/Presentation/Screens/OnBoardpage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Onboarded extends StatefulWidget {
  const Onboarded({Key? key,}) : super(key: key);

  @override
  State<Onboarded> createState() => _OnboardedState();
}

class _OnboardedState extends State<Onboarded> {

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
                  ),
                  Positioned(
                    left: MediaQuery.of(context).size.width * 0.055,
                    bottom: MediaQuery.of(context).size.height * 0.4,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.89,
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: Column(
                        children: [
                          Center(
                            child:TextButton
                              (onPressed: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Arrived(),
                                ),
                              );
                            },
                                child:  Text("Good day!!!",
                                  style: TextStyle(color: Colours.orange,
                                      fontWeight: FontWeight.bold),))
                          ),
                          SizedBox(height: 5,),
                          Center(
                            child: Text("Your ride is here.Safe Journey"),
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
