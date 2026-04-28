import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'homepage.dart';
import 'search.dart';
import 'library.dart';
import 'upload_song.dart';
import 'models/song.dart';
import 'music_player.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'main.dart' show themeModeNotifier;
import 'pixel_colors.dart';
import 'services/db_service.dart';
import 'services/audio_manager.dart';

class _Prefs {
  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  static Future<void> saveProfile({
    required int userId,
    required String displayName,
    required String bio,
    required int colorIndex,
    Uint8List? avatarBytes,
  }) async {
    final p = await _p;
    final key = 'profile_$userId';
    await p.setString(
        key,
        jsonEncode({
          'displayName': displayName,
          'bio': bio,
          'colorIndex': colorIndex,
          'avatar': avatarBytes != null ? base64Encode(avatarBytes) : null,
        }));
  }

  static Future<Map<String, dynamic>?> loadProfile(int userId) async {
    final p = await _p;
    final raw = p.getString('profile_$userId');
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }
}

class AppShell extends StatefulWidget {
  final String username;
  final int userId;
  const AppShell({super.key, required this.username, required this.userId});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  String _displayName = '';
  String _bio = 'Music lover 🎵';
  int _avatarColorIndex = 0;
  Uint8List? _avatarImageBytes;
  bool _profileLoaded = false;

  // Cached song list for queue building
  List<Song> _cachedSongs = [];

  final List<Color> _avatarColors = [
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.teal,
    Colors.green,
    Colors.orange,
    Colors.pink,
    Colors.red,
  ];

  int _selectedIndex = 0;
  Song? _currentSong;
  bool _playerMaximized = false;

  late StreamSubscription<Song?> _songSub;

  @override
  void initState() {
    super.initState();
    _displayName = widget.username;
    _loadProfile();
    _prefetchSongs();

    _songSub = AudioManager.instance.currentSongStream.listen((song) {
      if (mounted && _currentSong?.id != song?.id) {
        setState(() => _currentSong = song);
      }
    });
  }

  Future<void> _prefetchSongs() async {
    final songs = await DBService.fetchAllSongs(widget.userId);
    if (mounted) setState(() => _cachedSongs = songs);
  }

  Future<void> _loadProfile() async {
    final isDark = await DBService.getDarkMode(widget.userId);
    themeModeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

    final data = await _Prefs.loadProfile(widget.userId);
    if (data != null && mounted) {
      setState(() {
        _displayName = (data['displayName'] as String?)?.isNotEmpty == true
            ? data['displayName'] as String
            : widget.username;
        _bio = (data['bio'] as String?) ?? 'Music lover 🎵';
        _avatarColorIndex = (data['colorIndex'] as int?) ?? 0;
        final avatarB64 = data['avatar'] as String?;
        _avatarImageBytes = avatarB64 != null ? base64Decode(avatarB64) : null;
      });
    }
    if (mounted) setState(() => _profileLoaded = true);
  }

  Future<void> _saveProfile() async {
    await _Prefs.saveProfile(
      userId: widget.userId,
      displayName: _displayName,
      bio: _bio,
      colorIndex: _avatarColorIndex,
      avatarBytes: _avatarImageBytes,
    );
  }

  // ── Player logic ──────────────────────────────────────────────────────────

  /// Opens the player for [song]. If we have a cached song list, load the
  /// full list as the queue starting at this song so next/prev/shuffle works.
  void _openPlayer(Song song) {
    setState(() {
      _currentSong = song;
      _playerMaximized = true;
    });

    final songs = _cachedSongs;
    if (songs.isNotEmpty) {
      // Find the index of the tapped song; fall back to 0 if not found.
      final idx = songs.indexWhere((s) => s.id == song.id);
      final startIndex = idx >= 0 ? idx : 0;

      // Only reload the queue if the song changed or there's no active queue.
      if (AudioManager.instance.currentPlayingId != song.id ||
          AudioManager.instance.currentQueue.length <= 1) {
        AudioManager.instance.setQueue(songs, startIndex: startIndex);
      }
    } else {
      // Fallback: just play this one song if list hasn't loaded yet.
      if (AudioManager.instance.currentPlayingId != song.id) {
        AudioManager.instance.setSong(song);
      }
    }
  }

  @override
  void dispose() {
    _songSub.cancel();
    super.dispose();
  }

  void _logout() {
    AudioManager.instance.pause();
    themeModeNotifier.value = ThemeMode.light;
    Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text("Log Out",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showProfile() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfileSheet(
        username: _displayName,
        bio: _bio,
        avatarColorIndex: _avatarColorIndex,
        avatarColors: _avatarColors,
        avatarImageBytes: _avatarImageBytes,
        onLogout: () {
          Navigator.pop(context);
          _confirmLogout();
        },
        onSettings: () {
          Navigator.pop(context);
          _showSettings();
        },
        onSave: (name, bio, colorIndex, imageBytes) {
          setState(() {
            _displayName = name;
            _bio = bio;
            _avatarColorIndex = colorIndex;
            _avatarImageBytes = imageBytes;
          });
          _saveProfile();
        },
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SettingsSheet(
        userId: widget.userId,
        username: widget.username,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = theme.scaffoldBackgroundColor;
    final navBg =
        isDark ? PixelColors.darkSurface : PixelColors.accentPink;

    final pages = [
      HomePage(
        username: widget.username,
        userId: widget.userId,
        onOpenPlayer: _openPlayer,
        onSongsLoaded: (songs) {
          // Keep the cache updated when homepage loads songs
          if (mounted) setState(() => _cachedSongs = songs);
        },
      ),
      SearchPage(
        onOpenPlayer: _openPlayer,
        onProfileTap: _showProfile,
        username: _displayName,
        avatarColor: _avatarColors[_avatarColorIndex],
        avatarImageBytes: _avatarImageBytes,
        userId: widget.userId,
      ),
      LibraryPage(userId: widget.userId),
      const UploadSongPage(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: pages),

          if (_selectedIndex != 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 12,
              child: GestureDetector(
                onTap: _showProfile,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _avatarColors[_avatarColorIndex],
                    border: Border.all(
                      color: isDark ? PixelColors.neonPink : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark
                                ? PixelColors.neonPink
                                : PixelColors.accentPink)
                            .withOpacity(0.4),
                        blurRadius: 0,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _avatarImageBytes != null
                      ? Image.memory(_avatarImageBytes!, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            _displayName.isNotEmpty
                                ? _displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                fontSize: 16),
                          ),
                        ),
                ),
              ),
            ),

          if (_currentSong != null) ...[
            if (_playerMaximized)
              MusicPlayerPage(
                song: _currentSong!,
                userId: widget.userId,
                player: AudioManager.instance.player,
                onClose: () => setState(() => _playerMaximized = false),
              )
            else
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: _buildMiniPlayer(isDark),
              ),
          ],
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: isDark ? PixelColors.neonPink : Colors.white,
        unselectedItemColor: isDark ? const Color(0xFF555577) : Colors.white.withOpacity(0.6),
        backgroundColor: navBg,
        onTap: (i) => setState(() {
          _selectedIndex = i;
          _playerMaximized = false;
        }),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.upload), label: 'Upload'),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer(bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;
    return GestureDetector(
      onTap: () => setState(() => _playerMaximized = true),
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.zero,
        color: isDark ? PixelColors.darkCard : PixelColors.lightCard,
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? PixelColors.neonPink : PixelColors.accentOrange,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Album art
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: _currentSong?.imageUrl != null
                    ? Image.network(
                        _currentSong!.imageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 48,
                          height: 48,
                          color: isDark
                              ? PixelColors.neonPink.withOpacity(0.15)
                              : PixelColors.accentOrange.withOpacity(0.15),
                          child: Icon(Icons.music_note,
                              color: isDark
                                  ? PixelColors.neonPink
                                  : PixelColors.accentOrange,
                              size: 24),
                        ),
                      )
                    : Container(
                        width: 48,
                        height: 48,
                        color: isDark
                            ? PixelColors.neonPink.withOpacity(0.15)
                            : PixelColors.accentOrange.withOpacity(0.15),
                        child: Icon(Icons.music_note,
                            color: isDark
                                ? PixelColors.neonPink
                                : PixelColors.accentOrange,
                            size: 24),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentSong!.title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: textColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      _currentSong!.artist ?? '',
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StreamBuilder<PlayerState>(
                stream: AudioManager.instance.player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.skip_previous,
                            color: textColor, size: 22),
                        onPressed: () {
                          if (AudioManager.instance.player.hasPrevious) {
                            AudioManager.instance.player.seekToPrevious();
                          } else {
                            AudioManager.instance.player
                                .seek(Duration.zero);
                          }
                        },
                      ),
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            playing
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 36,
                            color: Colors.purple,
                          ),
                          onPressed: () => playing
                              ? AudioManager.instance.pause()
                              : AudioManager.instance.play(),
                        ),
                      ),
                      IconButton(
                        icon:
                            Icon(Icons.skip_next, color: textColor, size: 22),
                        onPressed: () {
                          if (AudioManager.instance.player.hasNext) {
                            AudioManager.instance.player.seekToNext();
                          }
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: textColor),
                        onPressed: () {
                          AudioManager.instance.stop();
                          setState(() => _currentSong = null);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Profile & Settings sheets
// ═══════════════════════════════════════════════════════════════
class _ProfileSheet extends StatefulWidget {
  final String username;
  final String bio;
  final int avatarColorIndex;
  final List<Color> avatarColors;
  final Uint8List? avatarImageBytes;
  final VoidCallback onLogout;
  final VoidCallback onSettings;
  final Function(String name, String bio, int colorIndex, Uint8List? imageBytes)
      onSave;

  const _ProfileSheet({
    required this.username,
    required this.bio,
    required this.avatarColorIndex,
    required this.avatarColors,
    required this.avatarImageBytes,
    required this.onLogout,
    required this.onSettings,
    required this.onSave,
  });

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late int _selectedColorIndex;
  Uint8List? _avatarImageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.username);
    _bioController = TextEditingController(text: widget.bio);
    _selectedColorIndex = widget.avatarColorIndex;
    _avatarImageBytes = widget.avatarImageBytes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _avatarImageBytes = bytes);
    }
  }

  void _showImageOptions(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF2A2A3E) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text('Profile Photo',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const Divider(),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: Colors.purple),
              title: Text('Choose from Gallery',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.purple),
              title: Text('Take a Photo',
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_avatarImageBytes != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _avatarImageBytes = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    widget.onSave(
      _nameController.text.trim().isEmpty
          ? widget.username
          : _nameController.text.trim(),
      _bioController.text.trim(),
      _selectedColorIndex,
      _avatarImageBytes,
    );
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? PixelColors.neonPink : PixelColors.accentPink;
    final accentCyan = isDark ? PixelColors.neonCyan : PixelColors.accentMint;
    final sheetBg = isDark ? PixelColors.darkSurface : PixelColors.lightBg;
    final cardColor = isDark ? PixelColors.darkCard : PixelColors.lightCard;
    final borderColor = isDark ? PixelColors.darkBorder : PixelColors.lightBorder;
    final textPrimary = isDark ? Colors.white : PixelColors.darkBg;
    final textSecondary = isDark ? PixelColors.neonPurple : PixelColors.accentLavender;
    final fillColor = isDark ? PixelColors.darkCard : Colors.white;
    final color = widget.avatarColors[_selectedColorIndex];

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        border: Border(top: BorderSide(color: accent, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pixel drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                color: accent.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),

            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 5, height: 22, color: accent),
                    const SizedBox(width: 10),
                    Text(
                      'PROFILE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: accent,
                        letterSpacing: 3,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _isEditing
                      ? _saveChanges()
                      : setState(() => _isEditing = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isEditing ? accent : Colors.transparent,
                      border: Border.all(color: accent, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.3),
                          blurRadius: 0,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isEditing ? Icons.check : Icons.edit,
                          size: 13,
                          color: _isEditing ? Colors.white : accent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isEditing ? 'SAVE' : 'EDIT',
                          style: TextStyle(
                            color: _isEditing ? Colors.white : accent,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Avatar + name row
            Row(
              children: [
                // Square pixel avatar
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(color: accent, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.4),
                            blurRadius: 0,
                            offset: const Offset(4, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: _avatarImageBytes != null
                          ? Image.memory(_avatarImageBytes!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 36,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showImageOptions(isDark),
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            color: accent,
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _isEditing
                          ? TextField(
                              controller: _nameController,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                              ),
                              decoration: InputDecoration(
                                hintText: 'DISPLAY NAME',
                                hintStyle: TextStyle(
                                  color: accent.withOpacity(0.5),
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
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
                                  borderSide: BorderSide(color: accent, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                              ),
                            )
                          : Text(
                              _nameController.text,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                              ),
                            ),
                      const SizedBox(height: 8),
                      _isEditing
                          ? TextField(
                              controller: _bioController,
                              maxLength: 60,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                hintText: 'SHORT BIO...',
                                hintStyle: TextStyle(
                                  color: accentCyan.withOpacity(0.5),
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                ),
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
                                  borderSide: BorderSide(color: accent, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                counterText: '',
                              ),
                            )
                          : Text(
                              _bioController.text,
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),

            // Color picker (editing only)
            if (_isEditing && _avatarImageBytes == null) ...[
              const SizedBox(height: 16),
              Text(
                'AVATAR COLOR',
                style: TextStyle(
                  color: borderColor,
                  fontSize: 10,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(widget.avatarColors.length, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: widget.avatarColors[i],
                        border: _selectedColorIndex == i
                            ? Border.all(color: accent, width: 2)
                            : Border.all(color: borderColor, width: 1),
                        boxShadow: _selectedColorIndex == i
                            ? [
                                BoxShadow(
                                  color: accent.withOpacity(0.5),
                                  blurRadius: 0,
                                  offset: const Offset(2, 2),
                                )
                              ]
                            : [],
                      ),
                    ),
                  );
                }),
              ),
            ],

            const SizedBox(height: 24),

            // Divider
            Container(height: 2, color: borderColor.withOpacity(0.4)),
            const SizedBox(height: 8),

            // Action tiles — pixel style
            _PixelSheetTile(
              icon: Icons.settings,
              label: 'SETTINGS',
              accent: accentCyan,
              textColor: textPrimary,
              borderColor: borderColor,
              cardColor: cardColor,
              onTap: widget.onSettings,
            ),
            const SizedBox(height: 6),
            _PixelSheetTile(
              icon: Icons.logout,
              label: 'LOG OUT',
              accent: const Color(0xFFFF6B6B),
              textColor: const Color(0xFFFF6B6B),
              borderColor: const Color(0xFFFF6B6B),
              cardColor: cardColor,
              onTap: widget.onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _PixelSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final Color textColor;
  final Color borderColor;
  final Color cardColor;
  final VoidCallback onTap;

  const _PixelSheetTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.textColor,
    required this.borderColor,
    required this.cardColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.2),
              blurRadius: 0,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: borderColor, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatefulWidget {
  final int userId;
  final String username;
  const _SettingsSheet({required this.userId, required this.username});

  @override
  State<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<_SettingsSheet> {
  bool _notifications = true;
  bool _autoPlay = false;
  bool _highQuality = true;
  double _crossfade = 0.0;

  void _showChangePassword() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setDlg) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text("Change Password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentCtrl,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: "Current password",
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setDlg(() => obscureCurrent = !obscureCurrent),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: "New password",
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setDlg(() => obscureNew = !obscureNew),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: "Confirm new password",
                    filled: true,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setDlg(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (currentCtrl.text.isEmpty ||
                            newCtrl.text.isEmpty ||
                            confirmCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Please fill in all fields.")));
                          return;
                        }
                        if (newCtrl.text != confirmCtrl.text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("New passwords don't match.")));
                          return;
                        }
                        if (newCtrl.text.length < 6) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      "Password must be at least 6 characters.")));
                          return;
                        }
                        setDlg(() => isLoading = true);
                        try {
                          final success = await DBService.changePassword(
                            userId: widget.userId,
                            username: widget.username,
                            currentPassword: currentCtrl.text,
                            newPassword: newCtrl.text,
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(success
                                      ? "Password changed successfully!"
                                      : "Current password is incorrect.")));
                        } catch (e) {
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")));
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("Save",
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? PixelColors.neonPink : PixelColors.accentPink;
    final accentCyan = isDark ? PixelColors.neonCyan : PixelColors.accentMint;
    final sheetBg = isDark ? PixelColors.darkSurface : PixelColors.lightBg;
    final cardColor = isDark ? PixelColors.darkCard : PixelColors.lightCard;
    final borderColor = isDark ? PixelColors.darkBorder : PixelColors.lightBorder;
    final textPrimary = isDark ? Colors.white : PixelColors.darkBg;
    final textSecondary = isDark ? PixelColors.neonPurple : PixelColors.accentLavender;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        border: Border(top: BorderSide(color: accent, width: 3)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pixel drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                color: accent.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(width: 5, height: 22, color: accent),
                const SizedBox(width: 10),
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: accent,
                    letterSpacing: 3,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── APPEARANCE ──────────────────────────────────────────────
            _PixelSectionLabel('APPEARANCE', accent: accentCyan),
            const SizedBox(height: 10),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (_, mode, __) {
                final darkOn = mode == ThemeMode.dark;
                return _PixelSettingsTile(
                  icon: darkOn ? Icons.dark_mode : Icons.light_mode,
                  title: darkOn ? 'DARK MODE' : 'LIGHT MODE',
                  subtitle: darkOn ? 'Switch to light mode' : 'Switch to dark mode',
                  accent: accent,
                  cardColor: cardColor,
                  borderColor: borderColor,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  trailing: Switch(
                    value: darkOn,
                    activeColor: accent,
                    activeTrackColor: accent.withOpacity(0.4),
                    inactiveThumbColor: borderColor,
                    inactiveTrackColor: borderColor.withOpacity(0.3),
                    onChanged: (v) {
                      themeModeNotifier.value =
                          v ? ThemeMode.dark : ThemeMode.light;
                      DBService.saveDarkMode(widget.userId, v);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 18),

            // ── ACCOUNT ─────────────────────────────────────────────────
            _PixelSectionLabel('ACCOUNT', accent: accentCyan),
            const SizedBox(height: 10),
            _PixelSettingsTile(
              icon: Icons.lock_outline,
              title: 'CHANGE PASSWORD',
              subtitle: 'Update your login credentials',
              accent: accent,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              trailing: Icon(Icons.chevron_right, color: borderColor, size: 18),
              onTap: _showChangePassword,
            ),
            const SizedBox(height: 18),

            // ── PLAYBACK ─────────────────────────────────────────────────
            _PixelSectionLabel('PLAYBACK', accent: accentCyan),
            const SizedBox(height: 10),
            _PixelSettingsTile(
              icon: Icons.play_circle_outline,
              title: 'AUTO-PLAY',
              subtitle: 'Continue playing similar songs',
              accent: accent,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              trailing: Switch(
                value: _autoPlay,
                activeColor: accent,
                activeTrackColor: accent.withOpacity(0.4),
                inactiveThumbColor: borderColor,
                inactiveTrackColor: borderColor.withOpacity(0.3),
                onChanged: (v) => setState(() => _autoPlay = v),
              ),
            ),
            const SizedBox(height: 8),
            _PixelSettingsTile(
              icon: Icons.high_quality,
              title: 'HIGH QUALITY STREAMING',
              subtitle: 'Uses more data',
              accent: accent,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              trailing: Switch(
                value: _highQuality,
                activeColor: accent,
                activeTrackColor: accent.withOpacity(0.4),
                inactiveThumbColor: borderColor,
                inactiveTrackColor: borderColor.withOpacity(0.3),
                onChanged: (v) => setState(() => _highQuality = v),
              ),
            ),
            const SizedBox(height: 8),
            // Crossfade row
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardColor,
                border: Border.all(color: borderColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.15),
                    blurRadius: 0,
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.blur_on, color: accent, size: 18),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CROSSFADE',
                            style: TextStyle(
                              color: textPrimary,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            '${_crossfade.toStringAsFixed(1)}s',
                            style: TextStyle(
                              color: textSecondary,
                              fontFamily: 'monospace',
                              fontSize: 10,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: accent,
                      inactiveTrackColor: borderColor.withOpacity(0.3),
                      thumbColor: accent,
                      overlayColor: accent.withOpacity(0.2),
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: _crossfade,
                      max: 12.0,
                      divisions: 24,
                      label: '${_crossfade.toStringAsFixed(1)}s',
                      onChanged: (v) => setState(() => _crossfade = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── NOTIFICATIONS ────────────────────────────────────────────
            _PixelSectionLabel('NOTIFICATIONS', accent: accentCyan),
            const SizedBox(height: 10),
            _PixelSettingsTile(
              icon: Icons.notifications,
              title: 'PUSH NOTIFICATIONS',
              subtitle: 'New uploads and activity',
              accent: accent,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              trailing: Switch(
                value: _notifications,
                activeColor: accent,
                activeTrackColor: accent.withOpacity(0.4),
                inactiveThumbColor: borderColor,
                inactiveTrackColor: borderColor.withOpacity(0.3),
                onChanged: (v) => setState(() => _notifications = v),
              ),
            ),
            const SizedBox(height: 18),

            // ── ABOUT ───────────────────────────────────────────────────
            _PixelSectionLabel('ABOUT', accent: accentCyan),
            const SizedBox(height: 10),
            _PixelSettingsTile(
              icon: Icons.info_outline,
              title: 'VERSION',
              subtitle: '1.0.0',
              accent: accent,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              trailing: null,
            ),
            const SizedBox(height: 24),

            // Done button — pixel style
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? PixelColors.neonPurple : PixelColors.accentLavender)
                          .withOpacity(0.8),
                      blurRadius: 0,
                      offset: const Offset(4, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'DONE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pixel section label (used in settings) ───────────────────────────────
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

// ── Pixel settings tile ───────────────────────────────────────────────────
class _PixelSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _PixelSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.15),
              blurRadius: 0,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimary,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondary,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

// _PixelSectionLabel is defined inline in _SettingsSheetState build via _PixelSettingsTile above.