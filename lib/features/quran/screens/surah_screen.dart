import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
class SurahScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  SurahScreen({required this.surahNumber, required this.surahName});

  @override
  _SurahScreenState createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  List<dynamic> verses = [];
  List<dynamic> afasyVerses = [];
  AudioPlayer audioPlayer = AudioPlayer();
  int? playingIndex;
  bool isTajweedEnabled = false;

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
    afasyVerses.clear();
    verses.clear();
    final response = await http.get(Uri.parse(
        'https://api.alquran.cloud/v1/surah/${widget.surahNumber}/${isTajweedEnabled ? "ar.tajweed" : "ar.alafasy"}'));
    final afasyResponse =
    await http.get(Uri.parse('https://api.alquran.cloud/v1/surah/${widget.surahNumber}/${"ar.alafasy"}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        verses = data['data']['ayahs'];
      });
    }
    if (response.statusCode == 200) {
      final data = json.decode(afasyResponse.body);
      setState(() {
        afasyVerses = data['data']['ayahs'];
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
    if (index < afasyVerses.length) {
      String? url = afasyVerses[index]['audio'];
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
    if (playingIndex != null && playingIndex! + 1 < afasyVerses.length) {
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
          InkWell(
            onTap: toggleTajweed,
            child: Row(
              children: [
                Text("Tajweed"),
                Text(
                  isTajweedEnabled ? "On" : "Off",
                  style: TextStyle(
                    color: isTajweedEnabled ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
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