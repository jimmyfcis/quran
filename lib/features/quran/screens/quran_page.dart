import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:new_quran/features/quran/screens/surah_screen.dart';
class QuranHomePage extends StatefulWidget {
  @override
  _QuranHomePageState createState() => _QuranHomePageState();
}

class _QuranHomePageState extends State<QuranHomePage> {
  List<dynamic> surahs = [];
  TextEditingController searchController = TextEditingController();
  List<dynamic> filteredSurahs = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchQuranSurahs();
  }

  Future<void> fetchQuranSurahs() async {
    try {
      final response = await http.get(Uri.parse('https://api.alquran.cloud/v1/surah'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          surahs = data['data'];
          filteredSurahs = List.from(surahs);
          isLoading = false;
          hasError = false;
        });
      } else {
        throw Exception('Failed to load surahs');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  String removeTajweedMarks(String text) {
    final RegExp tajweedRegex = RegExp(r'[\u0617-\u061A\u064B-\u0652]');
    return text.replaceAll(tajweedRegex, '');
  }

  void filterSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredSurahs = List.from(surahs);
      } else {
        filteredSurahs = surahs.where((surah) {
          return surah['englishName'].toLowerCase().contains(query.toLowerCase()) ||
              removeTajweedMarks(surah['name']).contains(removeTajweedMarks(query));
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quran App'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search Surah',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: filterSearch,
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : hasError
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Failed to load Surahs. Please try again.'),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: fetchQuranSurahs,
                    child: Text('Retry'),
                  )
                ],
              ),
            )
                : filteredSurahs.isEmpty
                ? Center(child: Text('No Surah found'))
                : ListView.builder(
              itemCount: filteredSurahs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredSurahs[index]['englishName']),
                  subtitle: Text(filteredSurahs[index]['name']),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SurahScreen(
                          surahNumber: filteredSurahs[index]['number'],
                          surahName: filteredSurahs[index]['name'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}