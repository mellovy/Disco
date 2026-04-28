import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'app_shell.dart';
import 'services/db_service.dart';
import 'pixel_colors.dart';

// Global theme notifier so any widget can toggle dark/light mode
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Disco',
          themeMode: mode,

          // ── Light theme: soft pixel / pastel vaporwave ──────────────────
          theme: ThemeData(
            useMaterial3: false,
            brightness: Brightness.light,
            scaffoldBackgroundColor: PixelColors.lightBg,
            primaryColor: PixelColors.accentPink,
            fontFamily: 'monospace',
            colorScheme: ColorScheme.fromSeed(
              seedColor: PixelColors.accentPink,
              brightness: Brightness.light,
              primary: PixelColors.accentPink,
              secondary: PixelColors.accentMint,
              tertiary: PixelColors.accentLavender,
              surface: PixelColors.lightSurface,
              background: PixelColors.lightBg,
            ),
            cardColor: PixelColors.lightCard,
            dividerColor: PixelColors.lightBorder,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: PixelColors.accentPink,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: PixelColors.accentRose, width: 2),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: PixelColors.accentPink,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                side: const BorderSide(color: PixelColors.accentPink, width: 2),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: PixelColors.lightCard,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: PixelColors.lightBorder, width: 2),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: PixelColors.lightBorder, width: 2),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: PixelColors.accentPink, width: 2),
              ),
              labelStyle: const TextStyle(color: PixelColors.accentLavender),
              hintStyle:
                  TextStyle(color: PixelColors.accentPink.withOpacity(0.5)),
            ),
            sliderTheme: const SliderThemeData(
              activeTrackColor: PixelColors.accentPink,
              thumbColor: PixelColors.accentPink,
              inactiveTrackColor: PixelColors.lightBorder,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.resolveWith(
                (s) => s.contains(MaterialState.selected)
                    ? PixelColors.accentPink
                    : PixelColors.lightBorder,
              ),
              trackColor: MaterialStateProperty.resolveWith(
                (s) => s.contains(MaterialState.selected)
                    ? PixelColors.accentPink.withOpacity(0.4)
                    : PixelColors.lightBorder.withOpacity(0.3),
              ),
            ),
            iconTheme: const IconThemeData(color: PixelColors.accentPink),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: PixelColors.accentPink,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: PixelColors.lightSurface,
              selectedItemColor: PixelColors.accentPink,
              unselectedItemColor: PixelColors.lightBorder,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: PixelColors.lightSurface,
              foregroundColor: PixelColors.accentPink,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: PixelColors.accentPink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: PixelColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: PixelColors.accentPink, width: 2),
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: PixelColors.accentPink,
              contentTextStyle: TextStyle(color: Colors.white),
            ),
          ),

          // ── Dark theme: deep periwinkle with pastel neon pops ────────────
          darkTheme: ThemeData(
            useMaterial3: false,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: PixelColors.darkBg,
            primaryColor: PixelColors.neonPink,
            fontFamily: 'monospace',
            colorScheme: ColorScheme.fromSeed(
              seedColor: PixelColors.neonPink,
              brightness: Brightness.dark,
              primary: PixelColors.neonPink,
              secondary: PixelColors.neonCyan,
              tertiary: PixelColors.neonPurple,
              surface: PixelColors.darkSurface,
              background: PixelColors.darkBg,
            ),
            cardColor: PixelColors.darkCard,
            dividerColor: PixelColors.darkBorder,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: PixelColors.neonPink,
                foregroundColor: PixelColors.darkBg,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                  side: BorderSide(color: PixelColors.neonPurple, width: 2),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                foregroundColor: PixelColors.neonPink,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
                side: const BorderSide(color: PixelColors.neonPink, width: 2),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: PixelColors.darkSurface,
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: PixelColors.darkBorder, width: 2),
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: PixelColors.darkBorder, width: 2),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: PixelColors.neonPink, width: 2),
              ),
              labelStyle: const TextStyle(color: PixelColors.neonPurple),
              hintStyle:
                  TextStyle(color: PixelColors.neonCyan.withOpacity(0.5)),
            ),
            sliderTheme: const SliderThemeData(
              activeTrackColor: PixelColors.neonPink,
              thumbColor: PixelColors.neonPink,
              inactiveTrackColor: PixelColors.darkBorder,
            ),
            switchTheme: SwitchThemeData(
              thumbColor: MaterialStateProperty.resolveWith(
                (s) => s.contains(MaterialState.selected)
                    ? PixelColors.neonPink
                    : PixelColors.darkBorder,
              ),
              trackColor: MaterialStateProperty.resolveWith(
                (s) => s.contains(MaterialState.selected)
                    ? PixelColors.neonPink.withOpacity(0.4)
                    : PixelColors.darkBorder.withOpacity(0.3),
              ),
            ),
            iconTheme: const IconThemeData(color: PixelColors.neonPink),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: PixelColors.neonCyan,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: PixelColors.darkSurface,
              selectedItemColor: PixelColors.neonPink,
              unselectedItemColor: PixelColors.darkBorder,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: PixelColors.darkSurface,
              foregroundColor: PixelColors.neonPink,
              elevation: 0,
              titleTextStyle: TextStyle(
                color: PixelColors.neonPink,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                letterSpacing: 2,
                fontFamily: 'monospace',
              ),
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: PixelColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: PixelColors.neonPink, width: 2),
              ),
            ),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: PixelColors.neonPink,
              contentTextStyle:
                  TextStyle(color: PixelColors.darkBg, fontWeight: FontWeight.bold),
            ),
          ),

          initialRoute: '/',
          routes: {
            '/': (_) => const DiscoApp(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/home') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (_) => AppShell(
                  username: args['username'],
                  userId: args['userId'],
                ),
              );
            }
            return null;
          },
        );
      },
    );
  }
}

// ── Login / Splash screen ───────────────────────────────────────────────────

class DiscoApp extends StatefulWidget {
  const DiscoApp({super.key});
  @override
  State<DiscoApp> createState() => _DiscoAppState();
}

class _DiscoAppState extends State<DiscoApp>
    with SingleTickerProviderStateMixin {
  // Slow, smooth animation controller — replaces the jarring 500ms timer
  late final AnimationController _anim;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignUp = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    // 6-second loop — slow enough to look ambient, not flashy
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Build a smoothly interpolated gradient color from the animation value.
  /// We cycle through 3 fixed pastel stops so it never looks jarring.
  Color _lerpGradientAccent(double t) {
    // Three fixed pastel stops: pink → cyan → lavender → pink
    const stops = [
      Color(0xFFFF7EB9), // bubblegum pink
      Color(0xFF7FECFF), // pastel cyan
      Color(0xFFD4AAFF), // lavender
      Color(0xFFFF7EB9), // back to pink (seamless loop)
    ];
    final scaled = t * (stops.length - 1);
    final idx = scaled.floor().clamp(0, stops.length - 2);
    final frac = scaled - idx;
    return Color.lerp(stops[idx], stops[idx + 1], frac)!;
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isConnecting = true);
    try {
      final res = await DBService.authenticate(
        _usernameController.text,
        _passwordController.text,
        email: _isSignUp ? _emailController.text : null,
      );
      if (res['success'] == true) {
        if (_isSignUp) {
          setState(() => _isSignUp = false);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account created! Please log in.')));
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (_) => false,
            arguments: {
              'username': _usernameController.text,
              'userId': res['user_id'],
            },
          );
        }
      } else {
        throw 'Authentication failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) {
          final accent = _lerpGradientAccent(_anim.value);
          final accent2 = _lerpGradientAccent((_anim.value + 0.33) % 1.0);

          return Container(
            decoration: BoxDecoration(
              // Static sky-blue base with a slow-drifting pastel shimmer overlay
              gradient: LinearGradient(
                colors: [
                  PixelColors.lightBg,
                  Color.lerp(PixelColors.lightBg, accent, 0.28)!,
                  Color.lerp(PixelColors.lightBg, accent2, 0.18)!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            // Only the gradient repaints — the form subtree is stable
            child: child,
          );
        },
        // child is hoisted out of the AnimatedBuilder so the form never
        // rebuilds during animation, preventing the flashing / focus loss.
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                // ── Logo ──────────────────────────────────────────────────
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: PixelColors.lightCard,
                    border: Border.all(
                        color: PixelColors.accentPink, width: 4),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x55FF7EB9),
                          blurRadius: 0,
                          offset: Offset(5, 5)),
                    ],
                  ),
                  child: Image.asset(
                    'images/disco1.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.music_note,
                      size: 60,
                      color: PixelColors.accentPink,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── App title ─────────────────────────────────────────────
                const Text(
                  'DISCO',
                  style: TextStyle(
                    fontSize: 36,
                    color: PixelColors.accentPink,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10,
                    fontFamily: 'monospace',
                    shadows: [
                      Shadow(
                        color: Color(0x88AA80FF), // fixed lavender shadow
                        blurRadius: 0,
                        offset: Offset(4, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '>> FEEL THE GROOVE <<',
                  style: TextStyle(
                    fontSize: 10,
                    color: PixelColors.accentLavender,
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 28),

                // ── Login card ────────────────────────────────────────────
                // Fully static — no AnimatedContainer wrapping the form.
                Container(
                  width: 320,
                  decoration: const BoxDecoration(
                    color: PixelColors.lightSurface,
                    border: Border.fromBorderSide(
                      BorderSide(color: PixelColors.accentPink, width: 3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x55E86DB0),
                        blurRadius: 0,
                        offset: Offset(6, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Title bar — retro pixel window chrome
                        _LoginTitleBar(isSignUp: _isSignUp),

                        // Form body
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _PixelField(
                                controller: _usernameController,
                                hint: 'USERNAME',
                                icon: Icons.person_outline,
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Required' : null,
                              ),
                              if (_isSignUp) ...[
                                const SizedBox(height: 10),
                                _PixelField(
                                  controller: _emailController,
                                  hint: 'EMAIL',
                                  icon: Icons.alternate_email,
                                ),
                              ],
                              const SizedBox(height: 10),
                              _PixelField(
                                controller: _passwordController,
                                hint: 'PASSWORD',
                                icon: Icons.lock_outline,
                                obscure: _obscurePassword,
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Required' : null,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: PixelColors.accentPink,
                                    size: 18,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Submit button ──────────────────────────
                              if (_isConnecting)
                                const Center(
                                  child: CircularProgressIndicator(
                                    color: PixelColors.accentPink,
                                  ),
                                )
                              else
                                _PixelButton(
                                  label: _isSignUp ? 'SIGN UP' : 'LOGIN',
                                  onTap: _handleAuth,
                                ),

                              // ── Toggle sign-up / login ─────────────────
                              Center(
                                child: TextButton(
                                  onPressed: () =>
                                      setState(() => _isSignUp = !_isSignUp),
                                  child: Text(
                                    _isSignUp
                                        ? '< BACK TO LOGIN'
                                        : 'CREATE ACCOUNT >',
                                    style: const TextStyle(
                                      color: PixelColors.accentLavender,
                                      fontSize: 10,
                                      letterSpacing: 1,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Bottom pixel deco row ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      color: [
                        PixelColors.accentPink,
                        PixelColors.accentMint,
                        PixelColors.accentLavender,
                        PixelColors.accentMint,
                        PixelColors.accentPink,
                      ][i],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'v1.0 // DISCO',
                  style: TextStyle(
                    fontSize: 9,
                    color: PixelColors.lightBorder,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pixel window title bar ──────────────────────────────────────────────────

class _LoginTitleBar extends StatelessWidget {
  final bool isSignUp;
  const _LoginTitleBar({required this.isSignUp});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PixelColors.accentPink,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          // Three pixel "traffic light" squares — purely decorative
          _PixelDot(color: PixelColors.neonYellow),
          const SizedBox(width: 5),
          _PixelDot(color: PixelColors.neonGreen),
          const SizedBox(width: 5),
          _PixelDot(color: Colors.white.withOpacity(0.6)),
          const SizedBox(width: 10),
          Text(
            isSignUp ? '[ SIGN UP ]' : '[ LOGIN ]',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 2,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          // Pixel close button decoration
          Container(
            width: 14,
            height: 14,
            color: Colors.white,
            child: const Center(
              child: Text(
                '×',
                style: TextStyle(
                  color: PixelColors.accentPink,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PixelDot extends StatelessWidget {
  final Color color;
  const _PixelDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 10, height: 10, color: color);
  }
}

// ── Pixel text field — consistent with upload_song.dart style ──────────────

class _PixelField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final String? Function(String?)? validator;
  final Widget? suffix;

  const _PixelField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.validator,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(
        color: PixelColors.darkBg,
        fontSize: 13,
        letterSpacing: 1,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: PixelColors.accentPink.withOpacity(0.55),
          fontSize: 11,
          letterSpacing: 2,
          fontFamily: 'monospace',
        ),
        prefixIcon: Icon(icon, color: PixelColors.accentPink, size: 18),
        filled: true,
        fillColor: PixelColors.lightCard,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: PixelColors.accentPink, width: 2),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide:
              BorderSide(color: PixelColors.lightBorder, width: 1.5),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: PixelColors.accentPink, width: 2),
        ),
        errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: PixelColors.accentRose, width: 2),
        ),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      ),
    );
  }
}

// ── Pixel action button — matches library/upload button style ───────────────

class _PixelButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PixelButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          color: PixelColors.accentPink,
          boxShadow: [
            BoxShadow(
              color: Color(0x88AA80FF), // lavender pixel shadow
              blurRadius: 0,
              offset: Offset(4, 4),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: 4,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}