import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'services/db_service.dart';

class UploadSongPage extends StatefulWidget {
  const UploadSongPage({super.key});
  @override
  State<UploadSongPage> createState() => _UploadSongPageState();
}

class _UploadSongPageState extends State<UploadSongPage> {
  final _titleController = TextEditingController();
  final _artistIdController = TextEditingController();
  
  Uint8List? _audioBytes;
  String? _audioName;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  Future<void> _pickFile(bool isAudio) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: isAudio ? FileType.audio : FileType.image,
      withData: true, 
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        if (isAudio) {
          _audioBytes = result.files.single.bytes;
          _audioName = result.files.single.name;
        } else {
          _imageBytes = result.files.single.bytes;
          _imageName = result.files.single.name;
        }
      });
    }
  }

  void _handleUpload() async {
    if (_audioBytes == null || _imageBytes == null || _isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select files first!")));
      return;
    }

    setState(() => _isUploading = true);

    bool success = await DBService.uploadSong(
      title: _titleController.text,
      artistId: _artistIdController.text,
      audioBytes: _audioBytes!,
      audioName: _audioName!,
      imageBytes: _imageBytes!,
      imageName: _imageName!,
    );

    if (mounted) {
      setState(() => _isUploading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload Successful! Swipe down on Home to see it.")));
        _titleController.clear();
        _artistIdController.clear();
        setState(() { _audioBytes = null; _audioName = null; _imageBytes = null; _imageName = null; });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Upload Failed. Check file sizes.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1E6FF),
      appBar: AppBar(title: const Text("Music Upload"), backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Song Title", filled: true, fillColor: Colors.white)),
            const SizedBox(height: 10),
            TextField(controller: _artistIdController, decoration: const InputDecoration(labelText: "Artist ID (Number)", filled: true, fillColor: Colors.white)),
            const SizedBox(height: 25),
            ListTile(
              tileColor: Colors.white,
              title: Text(_audioName ?? "Pick Audio File"),
              leading: const Icon(Icons.audiotrack),
              onTap: () => _pickFile(true),
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.white,
              title: Text(_imageName ?? "Pick Song Art"),
              leading: const Icon(Icons.image),
              onTap: () => _pickFile(false),
            ),
            const SizedBox(height: 40),
            if (_isUploading) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 15),
              const Text("Uploading song please wait...")
            ] else 
              ElevatedButton(
                onPressed: _handleUpload,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.purple),
                child: const Text("Upload song", style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}