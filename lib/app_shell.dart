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
    await p.setString(key, jsonEncode({
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

  final List<Color> _avatarColors = [
    Colors.purple, Colors.deepPurple, Colors.indigo, Colors.blue,
    Colors.teal, Colors.green, Colors.orange, Colors.pink, Colors.red,
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

    _songSub = AudioManager.instance.currentSongStream.listen((song) {
      if (mounted && _currentSong?.id != song?.id) {
        setState(() => _currentSong = song);
      }
    });
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
  void _openPlayer(Song song) {
    setState(() {
      _currentSong = song;
      _playerMaximized = true;
    });

    // Always set the song (which clears the queue and plays this one)
    if (AudioManager.instance.currentPlayingId != song.id) {
      AudioManager.instance.setSong(song);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Log Out"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text("Log Out", style: TextStyle(color: Colors.white)),
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
    final navBg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF1E6FF);

    final pages = [
      HomePage(
          username: widget.username,
          userId: widget.userId,
          onOpenPlayer: _openPlayer),
      SearchPage(
        onOpenPlayer: _openPlayer,
        onProfileTap: _showProfile,
        username: _displayName,
        avatarColor: _avatarColors[_avatarColorIndex],
        avatarImageBytes: _avatarImageBytes,
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
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: GestureDetector(
                onTap: _showProfile,
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: _avatarColors[_avatarColorIndex],
                  backgroundImage: _avatarImageBytes != null
                      ? MemoryImage(_avatarImageBytes!)
                      : null,
                  child: _avatarImageBytes == null
                      ? Text(
                          _displayName.isNotEmpty
                              ? _displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
              ),
            ),

          if (_currentSong != null) ...[
            if (_playerMaximized)
              MusicPlayerPage(
                  song: _currentSong!,
                  userId: widget.userId,
                  player: AudioManager.instance.player,
                  onClose: () => setState(() => _playerMaximized = false))
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
        selectedItemColor: Colors.purple,
        unselectedItemColor: Colors.grey,
        backgroundColor: navBg,
        onTap: (i) => setState(() {
          _selectedIndex = i;
          _playerMaximized = false;
        }),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
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
        borderRadius: BorderRadius.circular(15),
        color: isDark ? const Color(0xFF2A2A3E) : Colors.white,
        child: Container(
          height: 75,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  _currentSong!.imageUrl!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: Colors.purple[50],
                    child: const Icon(Icons.music_note, color: Colors.purple),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_currentSong!.title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(_currentSong!.artist ?? '',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.skip_previous, color: textColor),
                onPressed: () {
                  if (AudioManager.instance.player.hasPrevious) {
                    AudioManager.instance.player.seekToPrevious();
                  } else {
                    AudioManager.instance.player.seek(Duration.zero);
                  }
                },
              ),
              StreamBuilder<PlayerState>(
                stream: AudioManager.instance.player.playerStateStream, 
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return SizedBox(
                    width: 44,
                    height: 44,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                          playing
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 35,
                          color: Colors.purple),
                      onPressed: () =>
                          playing ? AudioManager.instance.pause() : AudioManager.instance.play(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.skip_next, color: textColor),
                onPressed: () {
                  if (AudioManager.instance.player.hasNext) {
                    AudioManager.instance.player.seekToNext();
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: textColor),
                onPressed: () {
                  AudioManager.instance.stop();
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
// Profile & Settings sheets remain exactly the same below...
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
              leading: const Icon(Icons.photo_library, color: Colors.purple),
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
    final sheetBg = isDark ? const Color(0xFF2A2A3E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.grey[400]! : Colors.grey;
    final fillColor = isDark ? const Color(0xFF3A3A4E) : Colors.grey[100]!;
    final color = widget.avatarColors[_selectedColorIndex];

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Profile',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary)),
                TextButton.icon(
                  onPressed: () => _isEditing
                      ? _saveChanges()
                      : setState(() => _isEditing = true),
                  icon: Icon(_isEditing ? Icons.check : Icons.edit, size: 16),
                  label: Text(_isEditing ? 'Save' : 'Edit'),
                  style: TextButton.styleFrom(foregroundColor: Colors.purple),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 52,
                  backgroundColor: color,
                  backgroundImage: _avatarImageBytes != null
                      ? MemoryImage(_avatarImageBytes!)
                      : null,
                  child: _avatarImageBytes == null
                      ? Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              fontSize: 40,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                if (_isEditing)
                  GestureDetector(
                    onTap: () => _showImageOptions(isDark),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        shape: BoxShape.circle,
                        border: Border.all(color: sheetBg, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            if (_isEditing && _avatarImageBytes == null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.avatarColors.length, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: widget.avatarColors[i],
                        shape: BoxShape.circle,
                        border: _selectedColorIndex == i
                            ? Border.all(
                                color: isDark ? Colors.white : Colors.black87,
                                width: 2.5)
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 16),
            _isEditing
                ? TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Display name',
                      filled: true,
                      fillColor: fillColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                  )
                : Text(_nameController.text,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary)),
            const SizedBox(height: 8),
            _isEditing
                ? TextField(
                    controller: _bioController,
                    textAlign: TextAlign.center,
                    maxLength: 60,
                    style: TextStyle(color: textSecondary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Short bio...',
                      filled: true,
                      fillColor: fillColor,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      counterText: '',
                    ),
                  )
                : Text(_bioController.text,
                    style: TextStyle(color: textSecondary, fontSize: 13)),
            const SizedBox(height: 24),
            Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
            const SizedBox(height: 8),
            _SheetTile(
              icon: Icons.settings,
              label: "Settings",
              isDark: isDark,
              onTap: widget.onSettings,
            ),
            _SheetTile(
              icon: Icons.logout,
              label: "Log Out",
              color: Colors.red,
              isDark: isDark,
              onTap: widget.onLogout,
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isDark;
  final VoidCallback onTap;

  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? (isDark ? Colors.white : Colors.black87);
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c, fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.chevron_right,
          color: isDark ? Colors.grey[600] : Colors.grey[400]),
      onTap: onTap,
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setDlg(() => obscureNew = !obscureNew),
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
                style:
                    ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: isLoading
                    ? null
                    : () async {
                        if (currentCtrl.text.isEmpty ||
                            newCtrl.text.isEmpty ||
                            confirmCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Please fill in all fields.")));
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(success
                                ? "Password changed successfully!"
                                : "Current password is incorrect."),
                          ));
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
    final sheetBg = isDark ? const Color(0xFF2A2A3E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: isDark ? Colors.grey[600] : Colors.grey[400],
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 20),
            Text("Settings",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: textPrimary)),
            const SizedBox(height: 20),

            _SectionHeader("Appearance", isDark: isDark),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (_, mode, __) {
                final darkOn = mode == ThemeMode.dark;
                return ListTile(
                  leading: Icon(
                    darkOn ? Icons.dark_mode : Icons.light_mode,
                    color: Colors.purple,
                  ),
                  title: Text(
                    darkOn ? "Dark Mode" : "Light Mode",
                    style: TextStyle(
                        fontWeight: FontWeight.w500, color: textPrimary),
                  ),
                  subtitle: Text(
                    darkOn ? "Switch to light mode" : "Switch to dark mode",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Switch(
                    value: darkOn,
                    activeColor: Colors.purple,
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

            _SectionHeader("Account", isDark: isDark),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.purple),
              title: Text("Change Password",
                  style: TextStyle(
                      fontWeight: FontWeight.w500, color: textPrimary)),
              trailing:
                  Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400]),
              onTap: _showChangePassword,
            ),

            _SectionHeader("Playback", isDark: isDark),
            SwitchListTile(
              secondary:
                  const Icon(Icons.play_circle_outline, color: Colors.purple),
              title: Text("Auto-play",
                  style: TextStyle(color: textPrimary)),
              subtitle: const Text("Continue playing similar songs",
                  style: TextStyle(color: Colors.grey)),
              value: _autoPlay,
              activeColor: Colors.purple,
              onChanged: (v) => setState(() => _autoPlay = v),
            ),
            SwitchListTile(
              secondary:
                  const Icon(Icons.high_quality, color: Colors.purple),
              title: Text("High Quality Streaming",
                  style: TextStyle(color: textPrimary)),
              subtitle: const Text("Uses more data",
                  style: TextStyle(color: Colors.grey)),
              value: _highQuality,
              activeColor: Colors.purple,
              onChanged: (v) => setState(() => _highQuality = v),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.blur_on, color: Colors.purple),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Crossfade",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                  color: textPrimary)),
                          Text("${_crossfade.toStringAsFixed(1)}s",
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  Slider(
                    value: _crossfade,
                    max: 12.0,
                    divisions: 24,
                    activeColor: Colors.purple,
                    label: "${_crossfade.toStringAsFixed(1)}s",
                    onChanged: (v) => setState(() => _crossfade = v),
                  ),
                ],
              ),
            ),

            _SectionHeader("Notifications", isDark: isDark),
            SwitchListTile(
              secondary:
                  const Icon(Icons.notifications, color: Colors.purple),
              title: Text("Push Notifications",
                  style: TextStyle(color: textPrimary)),
              subtitle: const Text("New uploads and activity",
                  style: TextStyle(color: Colors.grey)),
              value: _notifications,
              activeColor: Colors.purple,
              onChanged: (v) => setState(() => _notifications = v),
            ),

            _SectionHeader("About", isDark: isDark),
            ListTile(
              leading:
                  const Icon(Icons.info_outline, color: Colors.purple),
              title: Text("Version",
                  style: TextStyle(color: textPrimary)),
              trailing:
                  const Text("1.0.0", style: TextStyle(color: Colors.grey)),
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: () => Navigator.pop(context),
                child: const Text("Done",
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader(this.title, {this.isDark = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
              letterSpacing: 0.8)),
    );
  }
}