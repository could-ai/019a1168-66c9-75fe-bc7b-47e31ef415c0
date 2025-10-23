import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

// IMPORTANT: Replace with your own N2YO API key.
// You can get a free key from https://www.n2yo.com/
const String n2yoApiKey = "YOUR_API_KEY"; 
const String issNoradId = "25544"; // NORAD ID for the International Space Station (ISS)

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Satellite Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const SatelliteMap(),
    );
  }
}

class SatelliteMap extends StatefulWidget {
  const SatelliteMap({super.key});

  @override
  State<SatelliteMap> createState() => _SatelliteMapState();
}

class _SatelliteMapState extends State<SatelliteMap> {
  LatLng? _satellitePosition;
  Timer? _timer;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchSatelliteData();
    // Fetch data every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchSatelliteData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchSatelliteData() async {
    if (n2yoApiKey == "YOUR_API_KEY") {
      setState(() {
        _errorMessage = "Please add your N2YO API key to fetch satellite data.";
        _isLoading = false;
      });
      return;
    }

    // Observer's location (latitude, longitude, altitude). 
    // Using 0,0,0 for a general world view.
    const observerLat = "0";
    const observerLng = "0";
    const observerAlt = "0";

    final url = Uri.parse(
        'https://api.n2yo.com/v1/satellite/positions/$issNoradId/$observerLat/$observerLng/$observerAlt/1?apiKey=$n2yoApiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['positions'] != null && data['positions'].isNotEmpty) {
          final position = data['positions'][0];
          setState(() {
            _satellitePosition = LatLng(
              position['satlatitude'].toDouble(),
              position['satlongitude'].toDouble(),
            );
            _isLoading = false;
            _errorMessage = '';
          });
        }
      } else {
        setState(() {
          _errorMessage = "Failed to load satellite data. Status code: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "An error occurred: $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ISS Satellite Tracker'),
        centerTitle: true,
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _errorMessage.isNotEmpty
                ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                )
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: _satellitePosition ?? const LatLng(0, 0),
                      initialZoom: 2.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: const ['a', 'b', 'c'],
                      ),
                      if (_satellitePosition != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 80.0,
                              height: 80.0,
                              point: _satellitePosition!,
                              child: const Column(
                                children: [
                                  Icon(Icons.satellite_alt, color: Colors.white, size: 30),
                                  Text("ISS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
      ),
    );
  }
}
