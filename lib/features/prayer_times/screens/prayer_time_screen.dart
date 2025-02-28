import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:geolocator/geolocator.dart';

class PrayerTimesScreen extends StatefulWidget {
  @override
  _PrayerTimesScreenState createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  PrayerTimes? prayerTimes;
  CalculationMethod _selectedMethod = CalculationMethod.muslim_world_league;

  @override
  void initState() {
    super.initState();
    _getLocationAndCalculatePrayerTimes();
  }

  Future<void> _getLocationAndCalculatePrayerTimes() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    Coordinates coordinates = Coordinates(position.latitude, position.longitude);

    final params = _selectedMethod.getParameters(); // Use selected method
    params.madhab = Madhab.shafi; // Default to Shafi, can be changed if needed

    setState(() {
      prayerTimes = PrayerTimes.today(coordinates, params);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Prayer Times")),
      body: prayerTimes == null
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          _buildPrayerTimeTile("Fajr", prayerTimes!.fajr),
          _buildPrayerTimeTile("Dhuhr", prayerTimes!.dhuhr),
          _buildPrayerTimeTile("Asr", prayerTimes!.asr),
          _buildPrayerTimeTile("Maghrib", prayerTimes!.maghrib),
          _buildPrayerTimeTile("Isha", prayerTimes!.isha),
          SizedBox(height: 20),
          Text("Select Calculation Method:", style: TextStyle(fontSize: 16)),
          DropdownButton<CalculationMethod>(
            value: _selectedMethod,
            items: CalculationMethod.values.map((method) {
              return DropdownMenuItem(
                value: method,
                child: Text(method.toString().split('.').last),
              );
            }).toList(),
            onChanged: (newMethod) {
              if (newMethod != null) {
                setState(() {
                  prayerTimes=null;
                  _selectedMethod = newMethod;
                });
                _getLocationAndCalculatePrayerTimes(); // Recalculate with new method
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeTile(String name, DateTime time) {
    return ListTile(
      title: Text(name),
      trailing: Text("${time.hour}:${time.minute}"),
    );
  }
}
