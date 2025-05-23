import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';

class JotItDownPage extends StatefulWidget {
  @override
  _JotItDownPageState createState() => _JotItDownPageState();
}

class _JotItDownPageState extends State<JotItDownPage> {
  final Record _recorder = Record();
  bool _isRecording = false;
  String _status = '';
  List<Note> _notes = [];
  String? _currentRecordingPath;
  int _currentTimestamp = DateTime.now().millisecondsSinceEpoch;

  // for animated transcript
  String _animatedText = '';
  Timer? _timer;
  int _wordIndex = 0;
  List<String> _words = [];

  // for saved-summary display
  String _summary = '';
  String _group = '';

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  Future<void> _fetchNotes() async {
    try {
      final res = await http.get(Uri.parse('http://localhost:5001/notes'));
      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _notes = data.map((e) => Note.fromJson(e)).toList();
        });
      } else {
        print('Failed fetching notes: ${res.statusCode}');
      }
    } catch (e) {
      print('Error fetching notes: $e');
    }
  }

  Future<void> _toggleRecording() async {
  // Create a unique filename with timestamp
  final cacheDir = await getTemporaryDirectory();
   _currentRecordingPath = '${cacheDir.path}/recording_$_currentTimestamp.wav';
  final fileUri = Uri.file(_currentRecordingPath!).toString();
  
    if (!_isRecording) {
      // START RECORDING
      if (await _recorder.hasPermission()) {
        await _recorder.start(
          path: fileUri,
          encoder: AudioEncoder.wav,
          bitRate: 128000,
          samplingRate: 16000,
        );
        setState(() {
          _isRecording = true;
          _status = 'Recording...';
          _animatedText = '';
          _summary = '';
          _group = '';
        });
      }
    } else {
      // STOP RECORDING
      await _recorder.stop();
      setState(() {
        _isRecording = false;
        _status = 'Processing…';
      });

      // Add a small delay to ensure file is written completely
      await Future.delayed(Duration(milliseconds: 300));
      
      final rawPath = _currentRecordingPath!;
      final file = File(rawPath);

      // Debug file info
      print('Reading audio from path: $rawPath');
      print('File exists: ${await file.exists()}');
      if (await file.exists()) {
        print('File last modified: ${await file.lastModified()}');
        print('File size: ${await file.length()}');
      } else {
        setState(() => _status = 'Error: Recording file not found');
        return;
      }

      try {
        final bytes = await file.readAsBytes();
        
        // 1. Send to /transcribe_audio
        final trReq = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost:5001/transcribe_audio'),
        );
        trReq.files.add(http.MultipartFile.fromBytes(
          'audio',
          bytes,
          filename: 'recording_$_currentTimestamp.wav',
          contentType: MediaType('audio', 'wav'),
        ));
        
        final trStreamed = await trReq.send();
        final trResp = await http.Response.fromStream(trStreamed);
        
        // Check response code
        if (trResp.statusCode != 200) {
          print('Transcription API error: ${trResp.statusCode} - ${trResp.body}');
          setState(() => _status = 'API Error: ${trResp.statusCode}');
          return;
        }
        
        final trJson = json.decode(trResp.body);
        final text = trJson['transcript'] as String? ?? 'No text detected.';

        // Animate it word-by-word
        _animateText(text);

        // 2. Save the note
        final saveRes = await http.post(
          Uri.parse('http://localhost:5001/add_note'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'text': text}),
        );
        
        // Check response code
        if (saveRes.statusCode != 200) {
          print('Save note API error: ${saveRes.statusCode} - ${saveRes.body}');
          setState(() => _status = 'API Error: ${saveRes.statusCode}');
          return;
        }
        
        final saveJson = json.decode(saveRes.body);
        setState(() {
          _summary = saveJson['summary'] as String? ?? '';
          _group = saveJson['group'] as String? ?? '';
          _status = '';
        });

        // 3. Refresh the notes list - await to ensure it completes
        await _fetchNotes();
        
        // Delete the temporary file after we're done
        await file.delete();
        _currentRecordingPath = null;
        
        
      } catch (e) {
        setState(() => _status = 'Error: $e');
        print('Transcription/upload error: $e');
        if (e is http.ClientException) {
          print('HTTP Client Error details: ${e.message}');
        }
      }
    }
  }


  void _animateText(String text) {
    _timer?.cancel();
    _words    = text.split(' ');
    _wordIndex = 0;
    setState(() => _animatedText = '');

    _timer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (_wordIndex >= _words.length) {
        timer.cancel();
      } else {
        setState(() {
          _animatedText = _words.sublist(0, _wordIndex + 1).join(' ');
        });
        _wordIndex++;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: Text('Jot It Down')),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // RECORD BUTTON + STATUS
            ElevatedButton(
              onPressed: _toggleRecording,
              child: Text(_isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            SizedBox(height: 8),
            Text(_status, style: TextStyle(color: Colors.grey)),
            SizedBox(height: 24),
            // ANIMATED TRANSCRIPT
            if (_animatedText.isNotEmpty) ...[
              Text(_animatedText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              SizedBox(height: 16),
            ],
            // SAVED SUMMARY
            if (_summary.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(left: BorderSide(color: Colors.blue, width: 4)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Summary:', style: TextStyle(color: Colors.grey[700])),
                    Text(_summary, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Group: $_group', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
            // EXISTING NOTES
            ..._notes.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(left: BorderSide(color: Colors.blue, width: 4)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(n.summary, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    SizedBox(height: 4),
                    Text(n.timestamp, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    Text(n.group, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class Note {
  final String summary, timestamp, group;
  Note({required this.summary, required this.timestamp, required this.group});

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        summary: json['summary'],
        timestamp: json['timestamp'],
        group: json['group'],
      );
}
