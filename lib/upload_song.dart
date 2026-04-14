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
  final _artistNameController = TextEditingController();

  Uint8List? _audioBytes;
  String? _audioName;
  Uint8List? _imageBytes;
  String? _imageName;
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _artistNameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(bool isAudio) async {
    final result = await FilePicker.platform.pickFiles(
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

  Future<void> _handleUpload() async {
    if (_isUploading) return;

    final title = _titleController.text.trim();
    final artist = _artistNameController.text.trim();

    if (title.isEmpty || artist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fill in all fields")),
      );
      return;
    }

    if (_audioBytes == null || _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select audio and image")),
      );
      return;
    }

    setState(() => _isUploading = true);

    // Call returns an error message string or null if successful
    final errorMessage = await DBService.uploadSong(
      title: title,
      artistName: artist,
      audioBytes: _audioBytes!,
      audioName: _audioName ?? "audio.mp3",
      imageBytes: _imageBytes!,
      imageName: _imageName ?? "image.jpg",
    );

    if (!mounted) return;

    setState(() => _isUploading = false);

    if (errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Upload successful")),
      );
      _titleController.clear();
      _artistNameController.clear();
      setState(() {
        _audioBytes = null;
        _audioName = null;
        _imageBytes = null;
        _imageName = null;
      });
    } else {
      // Display exact API error on failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $errorMessage")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final fillColor = isDark ? const Color(0xFF2A2A3E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Upload Song", style: TextStyle(color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Song Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: "Song Title",
                prefixIcon: const Icon(Icons.music_note, color: Colors.purple),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _artistNameController,
              style: TextStyle(color: textPrimary),
              decoration: InputDecoration(
                labelText: "Artist Name",
                prefixIcon: const Icon(Icons.person, color: Colors.purple),
                filled: true,
                fillColor: fillColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              "Files",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            _FilePicker(
              icon: Icons.audiotrack,
              label: _audioName ?? "Pick Audio File",
              isSelected: _audioBytes != null,
              isDark: isDark,
              onTap: () => _pickFile(true),
            ),
            const SizedBox(height: 12),

            _FilePicker(
              icon: Icons.image,
              label: _imageName ?? "Pick Cover Art",
              isSelected: _imageBytes != null,
              isDark: isDark,
              onTap: () => _pickFile(false),
            ),

            if (_imageBytes != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _imageBytes!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],

            const SizedBox(height: 40),

            if (_isUploading)
              const Center(
                child: CircularProgressIndicator(color: Colors.purple),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _handleUpload,
                  icon: const Icon(Icons.cloud_upload, color: Colors.white),
                  label: const Text("Upload Song"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _FilePicker extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _FilePicker({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF2A2A3E) : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purple : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.purple : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Colors.purple, size: 20),
          ],
        ),
      ),
    );
  }
}