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
import 'package:get/utils.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Homepage extends StatefulWidget {
  final String Pickup;
  final String Drop;
  final String Name;
  final int Number;
  final String Email;
  final String Location;
  final int PassengerId;
  final String CompanyName;
  final String Token;

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
    required this.Token
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

  void initState() {
    super.initState();
    _checkLoginStatus();
    _fetchJobCards();
    _filterJobCards('');
  }

  Future<void> _logout() async {
    try {
      var headers = {'Authorization': 'Bearer ${widget.Token}'};
      const String apiUrl = '${ApiKey.baseUrl}/PassengerLogOut';
      final response = await _dio.delete(
          apiUrl,
          data: widget.Token,
          options: Options(
          headers: headers
      )
      );
      if (response.statusCode == 200) {
        print(response.data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      }
      return ;
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    }
  }

  Future<void> _fetchJobCards() async {
    print("${widget.Token}");
    var headers = {'Authorization': 'Bearer ${widget.Token}'};
    try {
      String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      String apiUrl = '${ApiKey.baseUrl}/CompanyBasedAllowedRoute?companyname=${widget.CompanyName}&date=$currentDate';
       // Format current date
      final response = await _dio.get(
          apiUrl,
        options: Options(
          headers: headers
        )
      );
      if (response.statusCode == 200) {
        setState(() {
          jobCards = List<Map<String, dynamic>>.from(response.data);
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

  Future<void> _showPicker(BuildContext context, String title, Function(String) onSelected, String routeId,String titl32) async {
    var headers = {'Authorization': 'Bearer ${widget.Token}'};
    try {
      String apiUrl = '${ApiKey.baseUrl}/GetStopsBasedRouteId?routeId=$routeId';
      final response = await _dio.get(
          apiUrl,
        options: Options(
          headers: headers
        )
      );

      if (response.statusCode == 200) {
        setState(() {
          options = List<Map<String, dynamic>>.from(response.data);
          // Extract the route_drop value
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
              _navigateToNextPage(routeId);
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

  Future<void> _navigateToNextPage(String routeID) async {
    final formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    var headers = {'Authorization': 'Bearer $token'};

    if(_selectedPickupLocation == null && _selectedDropLocation == null){
      Fluttertoast.showToast(
        msg: 'Please Select any Locations',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
      );
    }else{
      if(_selectedPickupLocation != null){
        print(routeID);

        try{
          String apiUrl = '${ApiKey.baseUrl}/PassengerAttendance';
          final response = await _dio.post(
            apiUrl,
            data: {
              "passenger_id":widget.PassengerId,
              "route_id":routeID,
              "stop_name":_selectedPickupLocation,
              "date":formattedDate,
              "status":"started"
            },
            options: Options(
              headers: headers
            )
          );
          if(response.statusCode==200){
            print(response.data);
            final int attendanceId = response.data['attendanceId'];
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setInt('attendanceId', attendanceId);
            await prefs.setString('stop', _selectedPickupLocation.toString());
            await prefs.setString('routepickup', _routepickup);
            await prefs.setString('routedrop', _routeDrop);
            await prefs.setString("routeid", routeID);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Confirmation
                  (
                  routeDrop: _routeDrop,
                  routePickup: _routepickup,
                  RouteId: routeID,
                  Stop:_selectedPickupLocation,
                  AttendanceId: attendanceId,
                ),
              ),
            );
          }

        }catch (e){
          print(e);
        }
      }
    }


  }

  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? attendanceid = prefs.getInt('attendanceId');
    String routePickup = prefs.getString('routepickup').toString();
    String routeDrop = prefs.getString('routedrop').toString();
    String RouteId = prefs.getString('routeid').toString();
    String Stop = prefs.getString('stop').toString();
    if (attendanceid != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Confirmation(
              routeDrop: routeDrop,
              routePickup: routePickup,
              RouteId: RouteId,
              Stop: Stop,
              AttendanceId: attendanceid
          )
        ),
      );
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
          IconButton(onPressed: (){
            _fetchJobCards();

          }, icon: Icon(Icons.refresh))
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
                  height:50,
                  width: 40,
                  child: ImageIcon(AssetImage('assets/pick_up.png',))),
              title: Text('${widget.Pickup}'),
            ),
            ListTile(
              leading: SizedBox(
                  height:60,
                  width: 40,
                  child: ImageIcon(AssetImage('assets/drop_icon.png',))),
              title: Text('${widget.Drop}'),
            ),
            Padding(
              padding: EdgeInsets.only(left: 10.0),
              child: ListTile(
                leading:Icon(CupertinoIcons.padlock_solid),
                title: Text('Change Password'),
                onTap: () {
                  // Add change password functionality here
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: ListTile(
                leading: Icon(Icons.logout),
                title: Text('Logout'),
                onTap: () {
                  _logout();
                },
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token={accessToken}',
                additionalOptions: {
                  'accessToken': '${ApiKey.Key}',
                  'id': 'mapbox/light-v10',
                },
              ),
            ],
          ),
          Center(
            child: Container(
              width: 320,
              height: 400,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colours.orange,
                    spreadRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
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
                    SizedBox(height: 20),
                    ListView.builder(
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
                        return GestureDetector(
                          onTap: () {
                            _showPicker(context, 'Select Location', (String selectedLocation) {
                              setState(() {
                                // Update the selected location based on the onTap event
                                // You can update _selectedPickupLocation or _selectedDropLocation here
                                _selectedPickupLocation = selectedLocation;
                                _isPickupSelected = true; // Assuming this is the intended behavior
                              });
                            }, jobCard['route_id'],jobCard['route_drop']); // Pass the routeId as parameter to the _showPicker function
                          },
                          child: Card(
                            margin: EdgeInsets.all(8.0),
                            child: ListTile(
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
                          ),
                        );
                      },
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

