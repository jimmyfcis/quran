import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class QiblaScreen extends StatefulWidget {
  @override
  _QiblaScreenState createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> {
  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return false;
      }
    }
    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Qibla Finder", style: TextStyle(fontWeight: FontWeight.bold))),
      body: FutureBuilder(
        future: _checkLocationPermission(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !(snapshot.data ?? false)) {
            return Center(child: Text("Location permission is required to determine Qibla direction."));
          }
          return QiblaCompassWidget();
        },
      ),
    );
  }
}

class QiblaCompassWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QiblahDirection>(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return Center(child: Text("Error fetching Qibla direction."));

        final qiblahDirection = snapshot.data?.qiblah ?? 0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Align the arrow with the Qibla", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                Image.network("https://example.com/compass_bg.png", width: 250, height: 250),
                Transform.rotate(
                  angle: (qiblahDirection * (math.pi / 180)),
                  child: Icon(Icons.navigation, size: 100, color: Colors.red),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text("Qibla Direction: ${qiblahDirection.toStringAsFixed(2)}°", style: TextStyle(fontSize: 16)),
          ],
        );
      },
    );
  }
}
