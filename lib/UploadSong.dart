import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'services/db_service.dart';

class UploadSongPage extends StatefulWidget {
  @override
  State<UploadSongPage> createState() => _UploadSongPageState();
}

class _UploadSongPageState extends State<UploadSongPage> {
  final _titleController = TextEditingController();
  final _artistIdController = TextEditingController();
  File? _selectedAudio;
  File? _selectedImage;
  double _uploadProgress = 0;
  bool _isUploading = false;

  Future<void> _pickFile(bool isAudio) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: isAudio ? FileType.audio : FileType.image,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        if (isAudio)
          _selectedAudio = File(result.files.single.path!);
        else
          _selectedImage = File(result.files.single.path!);
      });
    }
  }

  void _handleUpload() async {
    if (_selectedAudio == null || _selectedImage == null || _isUploading) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select both files")));
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
    });

    try {
      await DBService.uploadSong(
        title: _titleController.text,
        artistId: _artistIdController.text,
        audioFile: _selectedAudio!,
        imageFile: _selectedImage!,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Upload Complete!")));
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _clearForm() {
    _titleController.clear();
    _artistIdController.clear();
    setState(() {
      _selectedAudio = null;
      _selectedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1E6FF),
      appBar: AppBar(
        title: const Text("Upload Song"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Song Title",
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _artistIdController,
              decoration: const InputDecoration(
                labelText: "Artist ID",
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 25),

            _buildFileSelector(
              "Audio File",
              _selectedAudio,
              () => _pickFile(true),
            ),
            const SizedBox(height: 15),
            _buildFileSelector(
              "Cover Image",
              _selectedImage,
              () => _pickFile(false),
            ),

            const SizedBox(height: 40),
            if (_isUploading) ...[
              LinearProgressIndicator(
                value: _uploadProgress,
                color: Colors.purple,
                backgroundColor: Colors.purple[100],
              ),
              const SizedBox(height: 10),
              Text("${(_uploadProgress * 100).toStringAsFixed(0)}% Uploaded"),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleUpload,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    "Upload to Server",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelector(String label, File? file, VoidCallback onTap) {
    return ListTile(
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: Icon(
        file == null ? Icons.file_upload : Icons.check_circle,
        color: file == null ? Colors.grey : Colors.green,
      ),
      title: Text(file == null ? "Select $label" : "$label Selected"),
      subtitle: Text(file?.path.split('/').last ?? "No file chosen"),
      onTap: onTap,
    );
  }
}
