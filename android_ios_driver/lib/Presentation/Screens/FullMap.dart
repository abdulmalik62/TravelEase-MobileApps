import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';


class MapView extends StatefulWidget {
  const MapView({super.key});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  MapBoxNavigationViewController? _controller;
  String? _instruction;
  bool _isMultipleStop = false;
  double? _distanceRemaining, _durationRemaining;
  bool _routeBuilt = false;
  bool _isNavigating = false;
  bool _arrived = false;
  late MapBoxOptions _navigationOption;

  final _origin = WayPoint(name: "Origin", latitude: 9.0779, longitude: 77.3452);
  final _destination = WayPoint(name: "Destination", latitude: 9.0351, longitude: 77.3364);

  Future<void> initialize() async {
    if (!mounted) return;
    _navigationOption = MapBoxNavigation.instance.getDefaultOptions();
    _navigationOption.initialLatitude = _origin.latitude;
    _navigationOption.initialLongitude = _origin.longitude;
    _navigationOption.mode = MapBoxNavigationMode.driving;
    MapBoxNavigation.instance.registerRouteEventListener(_onRouteEvent);
  }

  @override
  void initState() {
    initialize();
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 1,
            child: Container(
              color: Colors.grey[100],
              child: MapBoxNavigationView(
                options: _navigationOption,
                onRouteEvent: _onRouteEvent,
                onCreated: (MapBoxNavigationViewController controller) async {
                  _controller = controller;
                  controller.initialize();
                  await _buildRoute();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _buildRoute() async {
    var wayPoints = <WayPoint>[_origin, _destination];
    await MapBoxNavigation.instance.startNavigation(
      wayPoints: wayPoints,
      options: MapBoxOptions(
        initialLatitude: _origin.latitude,
        initialLongitude: _origin.longitude,
        zoom: 15.0,
        tilt: 0.0,
        bearing: 0.0,
        mode: MapBoxNavigationMode.driving,
        isOptimized: true,
        language: "en",
        units: VoiceUnits.metric,
      ),
    );
  }

  Future<void> _onRouteEvent(e) async {
    _distanceRemaining = await MapBoxNavigation.instance.getDistanceRemaining();
    _durationRemaining = await MapBoxNavigation.instance.getDurationRemaining();

    switch (e.eventType) {
      case MapBoxEvent.progress_change:
        var progressEvent = e.data as RouteProgressEvent;
        _arrived = progressEvent.arrived!;
        if (progressEvent.currentStepInstruction != null) {
          _instruction = progressEvent.currentStepInstruction;
        }
        break;
      case MapBoxEvent.route_building:
      case MapBoxEvent.route_built:
        _routeBuilt = true;
        break;
      case MapBoxEvent.route_build_failed:
        _routeBuilt = false;
        break;
      case MapBoxEvent.navigation_running:
        _isNavigating = true;
        break;
      case MapBoxEvent.on_arrival:
        _arrived = true;
        if (!_isMultipleStop) {
          await Future.delayed(const Duration(seconds: 3));
          await _controller?.finishNavigation();
        }
        break;
      case MapBoxEvent.navigation_finished:
      case MapBoxEvent.navigation_cancelled:
        _routeBuilt = false;
        _isNavigating = false;
        break;
      default:
        break;
    }
    // Refresh UI
    setState(() {});
  }
}
