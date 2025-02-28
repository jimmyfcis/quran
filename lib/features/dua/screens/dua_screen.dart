import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:audioplayers/audioplayers.dart';

class DuaScreen extends StatefulWidget {
  @override
  _DuaScreenState createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> {
  final Dio _dio = Dio();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Map<String, String>> _duas = [];
  bool _isLoading = true;
  String _error = '';
  String? _currentlyPlayingUrl;

  @override
  void initState() {
    super.initState();
    _fetchDuas();
  }

  /// Fetch Duas from Hisn Al-Muslim API
  Future<void> _fetchDuas() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await _dio.get('https://hisnmuslim.com/api/ar/1.json');

      if (response.statusCode == 200 && response.data != null) {
        List<Map<String, String>> allDuas = [];

        response.data.forEach((category, duasList) {
          if (duasList is List) {
            for (var dua in duasList) {
              allDuas.add({
                'title': category,
                'content': dua['ARABIC_TEXT'] ?? 'No Content',
                'audio': dua['AUDIO']?.replaceFirst('http://', 'https://') ?? '',
              });
            }
          }
        });

        setState(() {
          _duas = allDuas;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error fetching Duas: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Play or pause audio
  void _toggleAudio(String audioUrl) async {
    try {
      if (_currentlyPlayingUrl == audioUrl) {
        await _audioPlayer.pause();
        setState(() {
          _currentlyPlayingUrl = null;
        });
      } else {
        await _audioPlayer.stop();
        await _audioPlayer.setSourceUrl(audioUrl); // Set the audio source
        await _audioPlayer.resume(); // Start playing
        setState(() {
          _currentlyPlayingUrl = audioUrl;
        });
      }
    } catch (e) {
      print("Audio Error: $e");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Hisn Al-Muslim Duas')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error, style: TextStyle(color: Colors.red)))
          : ListView.builder(
        itemCount: _duas.length,
        itemBuilder: (context, index) {
          final dua = _duas[index];
          return Card(
            margin: EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(dua['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(dua['content'] ?? ''),
              trailing: dua['audio']!.isNotEmpty
                  ? IconButton(
                icon: Icon(
                  _currentlyPlayingUrl == dua['audio'] ? Icons.pause : Icons.play_arrow,
                  color: Colors.green,
                ),
                onPressed: () => _toggleAudio(dua['audio']!),
              )
                  : null,
            ),
          );
        },
      ),
    );
  }
}