import 'package:android_ios_driver/Colours/Apikey.dart';
import 'package:android_ios_driver/Colours/Colours.dart';
import 'package:android_ios_driver/Presentation/Screens/Driver.dart';
import 'package:android_ios_driver/Presentation/Screens/Routepage.dart';
import 'package:android_ios_driver/Utils/GetX_Controller.dart';
import 'package:android_ios_driver/Utils/Shimmer_list.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';



class Jobspage extends StatefulWidget {
  final String Token;
  final int DriverId;
  final int phone;
  final String profilename;
  final String email;
  const Jobspage({Key? key, required this.Token,required this.DriverId, required this.phone, required this.profilename, required this.email}) : super(key: key);

  @override
  State<Jobspage> createState() => _JobspageState();
}

class _JobspageState extends State<Jobspage> {
  late List<String> dateList;
  late String selectedDate;
  final Dio _dio = Dio();
  List<Map<String, dynamic>> jobDataList = [];
  final JobController jobController = Get.put(JobController());
  late String formattedDate;



  @override
  void initState() {
    super.initState();
    dateList = generateDateList();
    selectedDate = dateList.first;
    _login();
  }

  List<String> generateDateList() {
    List<String> dates = [];
    DateTime now = DateTime.now();
    for (int i = 0; i < 10; i++) {
      DateTime date = now.add(Duration(days: i));
      formattedDate = "${date.year}-${_padZero(date.month)}-${_padZero(date.day)}";
      dates.add(formattedDate);
    }
    print(now);
    return dates;
  }

  String _padZero(int value) {
    return value.toString().padLeft(2, '0');
  }

  Future<void> _logout() async {
    try {
      const String apiUrl = '${ApiKey.baseUrl}/DriverLogOut';
      final response = await _dio.delete(
        apiUrl,
        data: widget.Token
      );
      if (response.statusCode == 200) {
        print(response.data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
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
          builder: (context) => LoginScreen(),
        ),
      );
    }
  }

  Future<void> _login() async {
    try {
      jobController.setLoading(true);
      final String token = "${widget.Token}";

      DateTime selectedDateTime = DateTime.parse(selectedDate);
      String formattedDate = "${selectedDateTime.year}-${_padZero(selectedDateTime.month)}-${_padZero(selectedDateTime.day)}";
      print(formattedDate);
      print("Received token : $token");
      var headers = {
        'Authorization': 'Bearer ${widget.Token}'
      };
      String apiUrl = '${ApiKey.baseUrl}/GetScheduledRouteByDate?date=$formattedDate&driverId=${widget.DriverId}';
      final response = await _dio.get(
        apiUrl,
        options: Options(
          headers: headers
        )

      );

      if (response.statusCode == 200) {
        setState(() {
          jobDataList = List<Map<String, dynamic>>.from(response.data);
        });
        jobController.setLoading(false);
      }
    } catch (e) {
      print(e);
      jobController.setLoading(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    String profileName = widget.profilename;
    String profileEmail = widget.email;
    String profileInitials = profileName.length >= 1 ? profileName.substring(0, 1).toUpperCase() : '';
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        backgroundColor: Colours.white,
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: Colours.orange,
          title: Text("Jobs",style: TextStyle(color: Colours.white),),
          leading: Builder(
            builder: (BuildContext context) {
              return IconButton(
                icon: ImageIcon(
                  AssetImage("assets/menu.jpg"),
                  size: 60,
                  color: Colors.white,
                ),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Container(
                width: 150,
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButton<String>(
                  value: selectedDate,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDate = newValue!;
                    });
                    _login();
                  },
                  items: dateList.map<DropdownMenuItem<String>>(
                        (String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(color: Colours.white),
                        ),
                      );
                    },
                  ).toList(),
                  style: TextStyle(color: Colours.white),
                  dropdownColor: Colors.black12,
                  icon: Icon(Icons.arrow_drop_down_circle_outlined,
                      color: Colours.white),
                  borderRadius: BorderRadius.circular(20),
                  isExpanded: true,
                  underline: SizedBox(), // Remove underline
                ),
              ),
            ),
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
                  title: Text("${widget.phone}"),
                ),
              ),
              Divider(),

              Padding(
                padding: EdgeInsets.only(top:10.0,left: 10.0),
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
            Positioned(
              child: Container(
                height: MediaQuery.of(context).size.height * 0.15,
                color: Colours.orange,
                child: Row(
                  children: [
                    Spacer(),

                  ],
                ),
              ),
            ),
            Positioned(
              child:GetBuilder<JobController>(
            builder: (controller) => controller.isLoading.value
                  ?ShimmerJobsList()
                  :Padding(
                padding: EdgeInsets.only(left: 20.0, right: 20, top: MediaQuery.of(context).size.width * 0.15),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: jobDataList.isNotEmpty
                        ? List.generate(
                      jobDataList.length,
                          (index) => _buildJobCard(jobDataList[index]),
                    )
                        : [
                      Text(
                        'No jobs available for the selected date.',
                        style: TextStyle(
                          color: Colours.black,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            )],
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> jobData) {
    String pickupLocation = jobData['pickup'];
    String dropLocation = jobData['drop'];
    String startTime = jobData['start_time'];
    String endTime = jobData['end_time'];
    String routeid = jobData['route_id'];
    String vehicle = jobData['vehicle_number'];
    int scheduleid = jobData['schedule_id'];
    // DateTime now = DateTime.now();
    // DateTime jobStartTime = DateTime.parse(startTime);
    //
    // bool isCurrentDate = DateTime.parse(selectedDate).day == now.day &&
    //     DateTime.parse(selectedDate).month == now.month &&
    //     DateTime.parse(selectedDate).year == now.year;
    // bool isAccessible = jobStartTime.isAfter(now) && jobStartTime.difference(now).inMinutes <= 30;

    return Card(
      color: Colours.white,
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVerticalLocations(pickupLocation, dropLocation,routeid),
            SizedBox(height: 5),
            _buildHorizontalLine(),
            SizedBox(height: 5),
            Row(
              children: [
                Text("$startTime - $endTime"),
                Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Routepage(RouteID: routeid,Vehicle: vehicle,ScheduleID: scheduleid, Token: widget.Token, startAddress: pickupLocation,endAddress: dropLocation,)),
                    );
                  },
                  child: Text("View Route", style: TextStyle(color: Colours.green)),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalLocations(String pickupLocation, String dropLocation,String RouteId) {
    return Column(
      children: [
        Row(
          children: [
            _buildLocationIcon(),
            SizedBox(width: 8),
            Text(pickupLocation),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _buildDottedLine(),
              ),
            ],
          ),
        ),
        Row(
          children: [
            _buildLocationIcon(),
            SizedBox(width: 8),
            Text(dropLocation),
            Spacer(),
            Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: Text(RouteId),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildLocationIcon() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Icon(Icons.location_on, color: Colours.black),
    );
  }

  Widget _buildDottedLine() {
    return Container(
      height: 40,
      child: Column(
        children: List.generate(
          5,
              (index) => Padding(
            padding: const EdgeInsets.all(2.0),
            child: Container(
              width: 2,
              height: 4,
              color: Colours.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalLine() {
    return Container(
      height: 2,
      color: Colours.grey.withOpacity(0.15),
    );
  }


}
