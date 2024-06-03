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
  const Jobspage({Key? key, required this.Token, required this.DriverId, required this.phone, required this.profilename, required this.email}) : super(key: key);

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
        data: widget.Token,
      );
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      }
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
      var headers = {
        'Authorization': 'Bearer ${widget.Token}'
      };
      String apiUrl = '${ApiKey.baseUrl}/GetScheduledRouteByDate?date=$formattedDate&driverId=${widget.DriverId}';
      final response = await _dio.get(
        apiUrl,
        options: Options(
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          jobDataList = List<Map<String, dynamic>>.from(response.data);
        });
        jobController.setLoading(false);
      }
    } catch (e) {
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
          title: Text("Jobs", style: TextStyle(color: Colours.white)),
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
                  items: dateList.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(color: Colours.white),
                      ),
                    );
                  }).toList(),
                  style: TextStyle(color: Colours.white),
                  dropdownColor: Colors.black12,
                  icon: Icon(Icons.arrow_drop_down_circle_outlined, color: Colours.white),
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
                padding: EdgeInsets.only(top: 10.0, left: 10.0),
                child: ListTile(
                  leading: Icon(CupertinoIcons.padlock_solid),
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
              child: GetBuilder<JobController>(
                builder: (controller) => controller.isLoading.value
                    ? ShimmerJobsList()
                    : Padding(
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
            ),
          ],
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Pickup Location: $pickupLocation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colours.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Drop Location: $dropLocation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colours.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Start Time: $startTime',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colours.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'End Time: $endTime',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colours.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Route ID: $routeid',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colours.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Vehicle: $vehicle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colours.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Center(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      isCurrentDate && isAccessible ? Colours.orange : Colours.grey,
                    ),
                  ),
                  onPressed: isCurrentDate && isAccessible
                      ? () {
                  }
                      : null,
                  child: Text('View Route'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
