import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'pixel_colors.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $errorMessage")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary = isDark ? Colors.white : PixelColors.darkBg;
    final accent = isDark ? PixelColors.neonPink : PixelColors.accentPink;
    final fillColor = isDark ? PixelColors.darkSurface : PixelColors.lightCard;
    final borderColor = isDark ? PixelColors.darkBorder : PixelColors.lightBorder;

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // ── Homepage-style sticky pink banner ──────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 100,
            automaticallyImplyLeading: false,
            backgroundColor:
                isDark ? PixelColors.darkSurface : PixelColors.accentPink,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Container(
                height: 3,
                color: isDark
                    ? PixelColors.neonPurple
                    : PixelColors.accentLavender,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? PixelColors.darkSurface
                      : PixelColors.accentPink,
                ),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 20,
                  right: 20,
                  bottom: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pixel badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.5), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.cloud_upload,
                              color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text(
                            'DISCO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'UPLOAD SONG',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(
                            color: Color(0x55000000),
                            blurRadius: 0,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      '>> SHARE YOUR MUSIC',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white70,
                        letterSpacing: 2,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Page body ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section label — pixel style
                  _PixelSectionLabel("SONG DETAILS", accent: accent),
                  const SizedBox(height: 14),

                  _SoftPixelInput(
                    controller: _titleController,
                    label: "SONG TITLE",
                    icon: Icons.music_note,
                    accentColor: accent,
                    fillColor: fillColor,
                    borderColor: borderColor,
                    textColor: textPrimary,
                  ),
                  const SizedBox(height: 10),

                  _SoftPixelInput(
                    controller: _artistNameController,
                    label: "ARTIST NAME",
                    icon: Icons.person,
                    accentColor: accent,
                    fillColor: fillColor,
                    borderColor: borderColor,
                    textColor: textPrimary,
                  ),
                  const SizedBox(height: 26),

                  _PixelSectionLabel("FILES", accent: accent),
                  const SizedBox(height: 14),

                  _SoftFilePicker(
                    icon: Icons.audiotrack,
                    label: _audioName ?? "PICK AUDIO FILE",
                    isSelected: _audioBytes != null,
                    isDark: isDark,
                    accent: accent,
                    borderColor: borderColor,
                    onTap: () => _pickFile(true),
                  ),
                  const SizedBox(height: 10),

                  _SoftFilePicker(
                    icon: Icons.image,
                    label: _imageName ?? "PICK COVER ART",
                    isSelected: _imageBytes != null,
                    isDark: isDark,
                    accent: accent,
                    borderColor: borderColor,
                    onTap: () => _pickFile(false),
                  ),

                  if (_imageBytes != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: accent, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: accent.withOpacity(0.3),
                              blurRadius: 0,
                              offset: const Offset(4, 4)),
                        ],
                      ),
                      child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                    ),
                  ],

                  const SizedBox(height: 36),

                  if (_isUploading)
                    Center(child: CircularProgressIndicator(color: accent))
                  else
                    GestureDetector(
                      onTap: _handleUpload,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: accent,
                          boxShadow: [
                            BoxShadow(
                                color: (isDark
                                        ? PixelColors.neonPurple
                                        : PixelColors.accentLavender)
                                    .withOpacity(0.8),
                                blurRadius: 0,
                                offset: const Offset(4, 4)),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.cloud_upload,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'UPLOAD SONG',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 3,
                                fontFamily: 'monospace',
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared pixel-style sub-widgets ─────────────────────────────────────────

class _PixelSectionLabel extends StatelessWidget {
  final String text;
  final Color accent;
  const _PixelSectionLabel(this.text, {required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 18, color: accent),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: accent,
            letterSpacing: 2,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

class _SoftPixelInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color accentColor;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;

  const _SoftPixelInput({
    required this.controller,
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
          color: textColor, fontFamily: 'monospace', fontSize: 13, letterSpacing: 1),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            color: accentColor.withOpacity(0.7),
            fontSize: 11,
            letterSpacing: 2,
            fontFamily: 'monospace'),
        prefixIcon: Icon(icon, color: accentColor, size: 20),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: borderColor, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
      ),
    );
  }
}

class _SoftFilePicker extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final Color accent;
  final Color borderColor;
  final VoidCallback onTap;

  const _SoftFilePicker({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.accent,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? PixelColors.darkCard : PixelColors.lightCard;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: isSelected ? accent : borderColor,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: accent.withOpacity(0.3),
                      blurRadius: 0,
                      offset: const Offset(3, 3))
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(icon,
                color: isSelected ? accent : borderColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.white : PixelColors.darkBg)
                      : borderColor,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: accent, size: 18),
          ],
        ),
      ),
    );
  }
}