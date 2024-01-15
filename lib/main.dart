import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Audio Record'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Record audioRecord;
  late AudioPlayer audioPlayer;
  bool isRecording = false;
  String audioPath = '';
  TextEditingController recordingNameController = TextEditingController();

  @override
  void initState() {
    audioPlayer = AudioPlayer();
    audioRecord = Record();

    super.initState();
  }

  @override
  void dispose() {
    audioRecord.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> startRecording() async {
    try {
      if (await audioRecord.hasPermission()) {
        await audioRecord.start();
        setState(() {
          isRecording = true;
        });
      }
    } catch (e) {
      print('Start Recording Error $e');
    }
  }

  Future<void> stopRecording() async {
    try {
      String? path = await audioRecord.stop();
      setState(() {
        isRecording = false;
        audioPath = path!;
      });

      await showSaveDialog();
    } catch (e) {
      print('Stop Recording Error $e');
    }
  }

  Future<void> showSaveDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Save Recording'),
          content: TextField(
            controller: recordingNameController,
            decoration: const InputDecoration(labelText: 'Enter recording name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                saveRecordingToFile(recordingNameController.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveRecordingToFile(String filename) async {
    if (filename.isNotEmpty) {
      Directory appDocDir = await getApplicationDocumentsDirectory();
      File recordingFile = File('${appDocDir.path}/$filename.mp3');
      await File(audioPath).copy(recordingFile.path);
      setState(() {
        audioPath = '';
      });
    }
  }

  Future<List<String>> loadSavedRecordings() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = appDocDir.listSync();
    List<String> recordings = [];

    for (var file in files) {
      if (file is File && file.path.endsWith('.mp3')) {
        recordings.add(file.path);
      }
    }
    return recordings;
  }

  Future<void> playRecording(String filePath) async {
    try {
      Uri uri = Uri.file(filePath);
      Source sourceUrl = UrlSource(uri.toString());
      await audioPlayer.play(sourceUrl);
    } catch (e) {
      print('Play Recording Error $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (isRecording)
              const Text(
                'Audio Recording........',
                style: TextStyle(fontSize: 20),
              ),
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: isRecording
                  ? const Text('Stop Recording')
                  : const Text('Start Recording'),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            FutureBuilder<List<String>>(
              future: loadSavedRecordings(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('No recordings available.');
                } else {
                  return Column(
                    children: snapshot.data!
                        .map((recording) => ListTile(
                              title: Text(recording),
                              onTap: () => playRecording(recording),
                            ))
                        .toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
