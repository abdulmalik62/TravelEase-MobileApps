import 'package:android_ios_passenger/Constants/Apikey.dart';
import 'package:android_ios_passenger/Constants/Colours.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Homepage.dart'; // Ensure this import matches the correct path in your project

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Dio _dio = Dio();
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  late String Token;
  late String PickupID;
  late String DropID;
  late String Name;
  late int Phone;
  late String Email;
  late String Location;
  late int Passid;
  late String Company;

  void initState() {
    super.initState();
    _checkLoginStatus();
  }


  Future<void> _login() async {
    final String email = _phoneController.text;
    final String password = _passwordController.text;

    try {
      String apiUrl = '${ApiKey.baseUrl}/PassengerLogin';
      final response = await _dio.post(
        apiUrl,
        data: {
          "username": _phoneController.text,
          "password": _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        Token = response.data["token"];
        PickupID = response.data["pickup_route_id"];
        DropID = response.data["drop_route_id"];
        Name = response.data["passenger_name"];
        Phone = response.data["passenger_phone"];
        Email = response.data["passenger_email"];
        Location = response.data["passenger_location"];
        Passid = response.data["passenger_id"];
        Company = response.data["companyname"];

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', Token);
        await prefs.setInt('passenger_id', Passid);
        await prefs.setString("pickup", PickupID);
        await prefs.setString("drop", DropID);
        await prefs.setString("name", Name);
        await prefs.setString("email", Email);
        await prefs.setInt("phone", Phone);
        await prefs.setString("location", Location);
        await prefs.setString("company", Company);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Homepage(
              Pickup: PickupID,
              Drop: DropID,
              Name: Name,
              Number: Phone,
              Email: Email,
              Location: Location,
              PassengerId: Passid,
              CompanyName: Company,
              Token: Token,
            ),
          ),
        );
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

  void _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    int? Passid = prefs.getInt('passenger_id');
    String Pickup = prefs.getString('pickup').toString();
    String Drop = prefs.getString('drop').toString();
    String Name = prefs.getString('name').toString();
    int Phone = int.parse(prefs.getInt('phone').toString());
    String Email = prefs.getString('email').toString();
    String Location = prefs.getString('location').toString();
    String Company = prefs.getString('company').toString();

    if (token != null && Passid != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Homepage(
            Pickup: Pickup,
            Drop: Drop,
            Name: Name,
            Number: Phone,
            Email: Email,
            Location: Location,
            PassengerId: Passid,
            CompanyName: Company,
            Token: token,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.orange.shade200,
              Colours.orange,
              Colours.orange
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 80),
            Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: FadeInUp(
                  duration: Duration(milliseconds: 1000),
                  child: Image.asset(
                    'assets/logo.png', // Ensure this matches the path to your logo
                    width: 100,
                    height: 100,
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(60),
                    topRight: Radius.circular(60),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: <Widget>[
                          SizedBox(height: 60),
                          FadeInUp(
                            duration: Duration(milliseconds: 1400),
                            child: Container(
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
                                          controller: _phoneController,
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
                                          controller: _passwordController,
                                          obscureText: _obscureText,
                                          decoration: InputDecoration(
                                            hintText: "Password",
                                            hintStyle: TextStyle(color: Colors.grey),
                                            border: InputBorder.none,
                                            suffixIcon: IconButton(
                                              icon: Icon(_obscureText
                                                  ? Icons.visibility
                                                  : Icons.visibility_off),
                                              onPressed: () {
                                                setState(() {
                                                  _obscureText = !_obscureText;
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
                          ),
                          SizedBox(height: 40),
                          FadeInUp(
                            duration: Duration(milliseconds: 1500),
                            child: TextButton(
                              child: Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.grey),
                              ),
                              onPressed: () {
                                // Handle forgot password logic here
                              },
                            ),
                          ),
                          SizedBox(height: 40),
                          FadeInUp(
                            duration: Duration(milliseconds: 1600),
                            child: MaterialButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _login();
                                }
                              },
                              height: 50,
                              color: Colours.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Center(
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
