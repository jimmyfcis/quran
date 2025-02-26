import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';

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
      home: QuranHomePage(),
    );
  }
}

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
                        builder: (context) => SurahPage(surahNumber: filteredSurahs[index]['number'],surahName: filteredSurahs[index]['name'],),
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

class SurahPage extends StatefulWidget {
  final int surahNumber;
  final String surahName;
  SurahPage({required this.surahNumber, required this.surahName});

  @override
  _SurahPageState createState() => _SurahPageState();
}

class _SurahPageState extends State<SurahPage> {
  List<dynamic> verses = [];
  AudioPlayer audioPlayer = AudioPlayer();
  int? playingIndex;
  bool isTajweedEnabled = true;

  @override
  void initState() {
    super.initState();
    fetchSurahVerses();
    audioPlayer.onPlayerComplete.listen((_) {
      playNextAyah();
    });
  }

  @override
  void dispose() {
    audioPlayer.stop();
    super.dispose();
  }

  Future<void> fetchSurahVerses() async {
    final response = await http.get(Uri.parse(
        'https://api.alquran.cloud/v1/surah/${widget.surahNumber}/${isTajweedEnabled ? "ar.tajweed" : "ar.alafasy"}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        verses = data['data']['ayahs'];
      });
    }
  }
  void toggleTajweed() {
    setState(() {
      isTajweedEnabled = !isTajweedEnabled;
      fetchSurahVerses();
    });
  }

  void playAudio(int index) {
    if (index < verses.length) {
      String? url = verses[index]['audio'];
      if (url != null && url.isNotEmpty) {
        setState(() {
          playingIndex = index;
        });
        audioPlayer.setSourceUrl(url).then((_) {
          audioPlayer.resume();
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to play audio.')),
          );
        });
      }
    }
  }

  void pauseAudio() {
    audioPlayer.pause();
    setState(() {
      playingIndex = null;
    });
  }

  void playNextAyah() {
    if (playingIndex != null && playingIndex! + 1 < verses.length) {
      playAudio(playingIndex! + 1);
    } else {
      setState(() {
        playingIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surahName),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            audioPlayer.stop();
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isTajweedEnabled ? Icons.visibility : Icons.visibility_off),
            onPressed: toggleTajweed,
          ),
        ],
      ),
      body: verses.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: verses.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(verses[index]['text']),
            trailing: IconButton(
              icon: Icon(playingIndex == index ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                if (playingIndex == index) {
                  pauseAudio();
                } else {
                  playAudio(index);
                }
              },
            ),
          );
        },
      ),
    );
  }
}