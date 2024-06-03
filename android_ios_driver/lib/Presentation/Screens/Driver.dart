import 'package:android_ios_driver/Colours/Apikey.dart';
import 'package:android_ios_driver/Colours/Colours.dart';
import 'package:android_ios_driver/Presentation/Screens/Homepage.dart';
import 'package:android_ios_driver/Presentation/Screens/Routepage.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Dio _dio = Dio();
  final _formKeySevilai = GlobalKey<FormState>();
  final _formKeyContract = GlobalKey<FormState>();
  final _phoneControllerSevilai = TextEditingController();
  final _passwordControllerSevilai = TextEditingController();
  final _phoneControllerContract = TextEditingController();
  final _passwordControllerContract = TextEditingController();
  bool _obscureTextSevilai = true;
  bool _obscureTextContract = true;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneControllerSevilai.dispose();
    _passwordControllerSevilai.dispose();
    _phoneControllerContract.dispose();
    _passwordControllerContract.dispose();
    super.dispose();
  }

  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('token');
    int? driverId = prefs.getInt('driverId');
    int Driverphone = int.parse(prefs.getInt("driverphone").toString());
    String Drivername =prefs.getString("drivername").toString();
    String DriverEmail =prefs.getString("driveremail").toString();

    if (token != null && driverId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Jobspage(Token: token, DriverId: driverId, phone: Driverphone, profilename: Drivername,email: DriverEmail,),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colours.grey, Colours.orange],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset('assets/logo.png', height: 150),
                  SizedBox(height: 60,),
                  Container(
                    width: 300,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      controller: _tabController,
                      unselectedLabelColor: Colors.white,
                      labelPadding: EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                      indicatorPadding: EdgeInsets.symmetric(vertical: 0.0),
                      labelStyle: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                      unselectedLabelStyle: TextStyle(fontSize: 12.0),
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            spreadRadius: 3,
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      labelColor: Colors.black,
                      tabs: [
                        Tab(text: 'Sevilai'),
                        Tab(text: 'Contract'),
                      ],
                    ),
                  ),
                  Container(
                    height: 500,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        buildLoginSevilaiTab(),
                        buildLoginContractTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
      ),
    );
  }

  Widget buildLoginSevilaiTab() {
    print("funtion call");
    Future<void> _login() async {
      final String email = _phoneControllerSevilai.text;
      final String password = _passwordControllerSevilai.text;

      try {
        print("funtion call in try");
        const String apiUrl = '${ApiKey.baseUrl}/DriverLogin?drivertype=Sevilai';
        final response = await _dio.post(
          apiUrl,
          data: {
            "username": _phoneControllerSevilai.text,
            "password": _passwordControllerSevilai.text,
          },
        );

        if (response.statusCode == 200) {
          print(response.statusCode);
          print(response.data);
          final String Token = response.data["token"];
          final int DriverId = response.data["driverid"];
          final String DriverEmail = response.data["driveremail"];
          final String Drivername = response.data["drivername"];
          final int Driverphone = response.data["driverphone"];
          final String Drivertype = response.data["drivertype"];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', Token);
          await prefs.setInt('driverId', DriverId);
          await prefs.setInt("driverphone", Driverphone);
          await prefs.setString("drivername", Drivername);
          await prefs.setString("driveremail", DriverEmail);

          print("Sent Token $Token");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Jobspage(
                  Token: Token,
                  DriverId: DriverId,
                phone: Driverphone, profilename: Drivername, email: DriverEmail,


              ),
            ),
          );
        } else {
          print('Error: ${response.statusCode}');
          print('Error Body: ${response.data}');
        }
        return;
      } catch (e) {
        print(e);
        if (e is DioError && e.response != null) {
          if (email.isNotEmpty || password.isNotEmpty) {
            Fluttertoast.showToast(
              msg: '${e.response!.data["message"]}',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
            );
          }
        }
      }
    }

    return Padding(
      padding: EdgeInsets.only(top: 40, left: 20, right: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKeySevilai,
          child: Column(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(225, 95, 27, .3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                          child: TextFormField(
                            controller: _phoneControllerSevilai,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: "Phone number",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              if (!RegExp(r'^\d{8}$').hasMatch(value)) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                          child: TextFormField(
                            controller: _passwordControllerSevilai,
                            obscureText: _obscureTextSevilai,
                            decoration: InputDecoration(
                              hintText: "Password",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureTextSevilai ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscureTextSevilai = !_obscureTextSevilai;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length > 12) {
                                return 'Password cannot be more than 12 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              TextButton(
                child: Text(
                  "Forgot Password?",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                },
              ),
              SizedBox(height: 10),
              MaterialButton(
                onPressed: () {
                  if (_formKeySevilai.currentState!.validate()) {
                    _login();
                  }
                },
                height: 50,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildLoginContractTab() {
    Future<void> _login() async {
      final String email = _phoneControllerSevilai.text;
      final String password = _passwordControllerSevilai.text;

      try {
        const String apiUrl = '${ApiKey.baseUrl}/DriverLogin?drivertype=Contract';
        final response = await _dio.post(
          apiUrl,
          data: {
            "username": _phoneControllerSevilai.text,
            "password": _passwordControllerSevilai.text,
          },
        );

        if (response.statusCode == 200) {
          final String Token = response.data["token"];
          final int DriverId = response.data["driverid"];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', Token);
          await prefs.setInt('driverId', DriverId);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Routepage(
                  Token: Token,
                  RouteID: _phoneControllerContract.text,
                ScheduleID: 15,
                startAddress: '',
                endAddress: '',
                Vehicle: '',
              ),
            ),
          );
        } else {
          print('Error: ${response.statusCode}');
          print('Error Body: ${response.data}');
        }
        return;
      } catch (e) {
        if (e is DioError && e.response != null) {
          if (email.isNotEmpty || password.isNotEmpty) {
            Fluttertoast.showToast(
              msg: '${e.response!.data["message"]}',
              toastLength: Toast.LENGTH_SHORT,
              gravity: ToastGravity.CENTER,
            );
          }
        }
      }
    }
    return Padding(
      padding: EdgeInsets.only(top: 40, left: 20, right: 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKeyContract,
          child: Column(
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(225, 95, 27, .3),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: <Widget>[
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                          child: TextFormField(
                            controller: _phoneControllerContract,
                            decoration: InputDecoration(
                              hintText: "Route ID",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Route Id';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    Stack(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                              ),
                            ),
                          ),
                          child: TextFormField(
                            controller: _passwordControllerContract,
                            obscureText: _obscureTextContract,
                            decoration: InputDecoration(
                              hintText: "RouteID",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              suffixIcon: IconButton(
                                icon: Icon(_obscureTextContract ? Icons.visibility : Icons.visibility_off),
                                onPressed: () {
                                  setState(() {
                                    _obscureTextContract = !_obscureTextContract;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your Route Id';
                              }

                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              MaterialButton(
                onPressed: () {
                  if (_formKeyContract.currentState!.validate()) {
                    // Perform login action
                  }
                },
                height: 50,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
