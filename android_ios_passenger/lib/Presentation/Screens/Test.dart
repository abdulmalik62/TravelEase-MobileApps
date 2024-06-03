import 'dart:ffi';

import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:android_ios_passenger/Presentation/Screens/Confirmationpage.dart';
import 'package:android_ios_passenger/Presentation/Screens/Login.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class Homepage extends StatefulWidget {
  final String Pickup;
  final String Drop;
  final String Name;
  final int Number;
  final String Email;
  final String Location;
  final int PassengerId;
  final String CompanyName;

  const Homepage({
    Key? key,
    required this.Pickup,
    required this.Drop,
    required this.Name,
    required this.Number,
    required this.Email,
    required this.Location,
    required this.PassengerId,
    required this.CompanyName,
  }) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final Dio _dio = Dio();
  final TextEditingController _searchController = TextEditingController();
  String? _searchQuery;
  bool _isSearching = false;
  String? _selectedPickupLocation;
  String? _selectedDropLocation;
  bool _isPickupSelected = false;
  bool _isDropSelected = false;
  List<Map<String, dynamic>> options = [];
  late String _routeDrop;
  late String _routepickup;

  List<Map<String, dynamic>> jobCards = [];
  List<Map<String, dynamic>> filteredJobCards = [];

  @override
  void initState() {
    super.initState();
    _fetchJobCards();
  }

  Future<void> _fetchJobCards() async {
    try {
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String apiUrl = '${ApiKey.baseUrl}/CompanyBasedAllowedRoute?companyname=${widget.CompanyName}&date=$currentDate';
      final response = await _dio.get(apiUrl);
      if (response.statusCode == 200) {
        setState(() {
          jobCards = List<Map<String, dynamic>>.from(response.data);
          filteredJobCards = jobCards;
        });
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to load job cards',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.TOP,
        );
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
        msg: 'Error fetching job cards',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
      );
    }
  }

  void _filterJobCards(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredJobCards = jobCards;
      });
      return;
    }

    List<Map<String, dynamic>> filtered = jobCards.where((job) {
      final routeId = job['route_id'].toString().toLowerCase();
      final pickup = job['route_pickup'].toString().toLowerCase();
      final drop = job['route_drop'].toString().toLowerCase();
      final startTime = job['route_start_time'].toString().toLowerCase();

      final searchQuery = query.toLowerCase();
      return routeId.contains(searchQuery) ||
          pickup.contains(searchQuery) ||
          drop.contains(searchQuery) ||
          startTime.contains(searchQuery);
    }).toList();

    setState(() {
      filteredJobCards = filtered;
    });
  }

  Future<void> _showPicker(BuildContext context, String title, Function(String) onSelected, String routeId, String titl32) async {
    try {
      String apiUrl = '${ApiKey.baseUrl}/GetStopsBasedRouteId?routeId=$routeId';
      final response = await _dio.get(apiUrl);

      if (response.statusCode == 200) {
        setState(() {
          options = List<Map<String, dynamic>>.from(response.data);
          if (options.isNotEmpty) {
            _routeDrop = options[0]['route_id']['route_drop'];
            _routepickup = options[0]['route_id']['route_pickup'];
          }
        });
      }
    } catch (e) {
      print(e);
    }
    Map<String, dynamic> tempSelectedLocation = options[0];

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title: Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          actions: [
            Container(
              height: 250,
              child: CupertinoPicker(
                itemExtent: 32.0,
                onSelectedItemChanged: (int index) {
                  tempSelectedLocation = options[index];
                },
                children: options.map((option) => Center(child: Text(option['stop_name'] as String))).toList(),
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () {
              onSelected(tempSelectedLocation['stop_name'] as String);
              _navigateToNextPage();
              Navigator.pop(context);
            },
            child: Text('Done', style: TextStyle(color: Colors.blue)),
          ),
        );
      },
    );
  }

  void _cancelPickupSelection() {
    setState(() {
      _selectedPickupLocation = null;
      _isPickupSelected = false;
    });
  }

  void _cancelDropSelection() {
    setState(() {
      _selectedDropLocation = null;
      _isDropSelected = false;
    });
  }

  Future<void> _navigateToNextPage() async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    if(_selectedPickupLocation == null && _selectedDropLocation == null) {
      Fluttertoast.showToast(
        msg: 'Please Select any Locations',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
      );
    }
    else {
      if (_selectedPickupLocation != null) {
        try {
          String apiUrl = '${ApiKey.baseUrl}/PassengerAttendance';
          final response = await _dio.post(
            apiUrl,
            data: {
              "passenger_id": widget.PassengerId,
              "route_id": widget.Pickup,
              "stop_name": _selectedPickupLocation,
              "date": formattedDate,
              "status": "started"
            },
          );
          if (response.statusCode == 200) {
            print(response.data);
            final int attendanceId = response.data['attendanceId'];
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Confirmation(
                  routeDrop: _routeDrop,
                  routePickup: _routepickup,
                  RouteId: widget.Pickup,
                  Stop: _selectedPickupLocation,
                  AttendanceId: attendanceId,
                ),
              ),
            );
          }
        } catch (e) {
          print(e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String profileName = '${widget.Name}';
    String profileEmail = '${widget.Email}';
    String profileInitials = profileName.length >= 1 ? profileName.substring(0, 1).toUpperCase() : '';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colours.orange,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: ImageIcon(
                AssetImage("assets/menu.jpg"),
                size: 60,
                color: Colors.black,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(onPressed: _fetchJobCards, icon: Icon(Icons.refresh)),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(profileName),
              accountEmail: Text(profileEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colours.orange,
                child: Text(
                  profileInitials,
                  style: TextStyle(fontSize: 24.0, color: Colours.white),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 9.0),
              child: ListTile(
                leading: Icon(Icons.phone),
                title: Text('${widget.Number}'),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 9.0),
              child: ListTile(
                leading: Icon(CupertinoIcons.home),
                title: Text('${widget.Location}'),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 9.0),
              child: ListTile(
                leading: Icon(CupertinoIcons.building_2_fill),
                title: Text('${widget.CompanyName}'),
              ),
            ),
            ListTile(
              leading: SizedBox(
                  height: 50,
                  width: 50,
                  child: ImageIcon(AssetImage('assets/logout.png'), size: 40, color: Colors.red)),
              title: Text(
                'Log Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 8),
                  child: Text(
                    "Good Morning! ${profileName}",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 10, top: 8),
                  child: SizedBox(
                    height: 50,
                    width: 300,
                    child: TextFormField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _filterJobCards('');
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        hintText: 'Search',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _filterJobCards(value);
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (filteredJobCards.isEmpty)
              Center(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text(
                      'No data found.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: filteredJobCards.length,
                  itemBuilder: (context, index) {
                    final jobCard = filteredJobCards[index];
                    final routeDrop = jobCard['route_drop'] as String;
                    final routePickup = jobCard['route_pickup'] as String;
                    final routeStartTime = jobCard['route_start_time'] as String;
                    final routeEndTime = jobCard['route_end_time'] as String;
                    final routeId = jobCard['route_id'].toString();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey),
                        ),
                        child: Column(
                          children: [
                            ListTile(
                              title: Text('Route ID: $routeId'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pickup Location: $routePickup'),
                                  Text('Drop Location: $routeDrop'),
                                  Text('Start Time: $routeStartTime'),
                                  Text('End Time: $routeEndTime'),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Confirmation(
                                          routeDrop: routeDrop,
                                          routePickup: routePickup,
                                          RouteId: routeId,
                                          Stop: _selectedPickupLocation,
                                          AttendanceId: 1, // Adjust according to your needs
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('View Route'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
