import 'package:android_ios_driver/Presentation/Screens/Driver.dart';
import 'package:android_ios_driver/Presentation/Screens/LoginPage.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart' as loc;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  checkPermissionStatus();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tec Driver',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      home:LoginScreen()
    );
  }
}

Future<void> checkPermissionStatus() async {
  loc.Location location = loc.Location();
  late loc.PermissionStatus _permissionStatus;
  _permissionStatus = await location.hasPermission();
  if (_permissionStatus == loc.PermissionStatus.denied) {
    _permissionStatus = await location.requestPermission();
    if (_permissionStatus != loc.PermissionStatus.granted) {
      location.onLocationChanged.listen((loc.LocationData currentLocation) {

        print('Location update 1: ${currentLocation.latitude}, ${currentLocation.longitude}');
      });
    }
  }
  startLocationTracking();
}

void startLocationTracking() {
  loc.Location location = loc.Location();
  location.onLocationChanged.listen((loc.LocationData currentLocation) {
    print('Location update: ${currentLocation.latitude}, ${currentLocation.longitude}');
  });
}