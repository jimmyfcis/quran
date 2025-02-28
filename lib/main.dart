import 'package:flutter/material.dart';
import 'features/prayer_times/screens/prayer_time_screen.dart';

void main() {
  runApp(QuranApp());
}

class QuranApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quran App',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: PrayerTimesScreen(),
    );
  }
}