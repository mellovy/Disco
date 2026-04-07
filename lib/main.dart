import 'dart:async';
import 'package:flutter/material.dart';
import 'AppShell.dart';

void main() {
  runApp(const MaterialApp(home: DiscoApp()));
}

class DiscoApp extends StatefulWidget {
  const DiscoApp({super.key});

  @override
  State<DiscoApp> createState() => _DiscoAppState();
}

class _DiscoAppState extends State<DiscoApp> {
  // Brand colors (alpha 120 for subtle animated background)
  List<Color> discoColors = [
    const Color(0x78AE65EC), // purple  (#ae65ec) with alpha 0x78 (~120)
    const Color(0x78EB6276), // rosy pink (#eb6276)
    const Color(0x78FFB7E4), // light magenta (#ffb7e4)
    const Color(0x78FF66C4), // pink (#ff66c4)
  ];
  int colorIndex = 0;
  Timer? timer;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        colorIndex = (colorIndex + 1) % discoColors.length;
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              discoColors[colorIndex],
              discoColors[(colorIndex + 1) % discoColors.length],
            ],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 360,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo: single centered image above the title and inputs
                Center(
                  child: SizedBox(
                    width: 300,
                    height: 300,
                    child: Image.asset(
                      'images/disco1.png',
                      fit: BoxFit.contain,
                      semanticLabel: 'Disco logo',
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFAE65EC), Color(0xFFFFB7E4)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Feel the Groove',
                  style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Container(
                    width: 320,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Username (both modes)
                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Username',
                            hintStyle: const TextStyle(color: Colors.black54),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your username';
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        // Email only for Sign Up
                        if (_isSignUp) ...[
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.black),
                            decoration: InputDecoration(
                              hintText: 'Email',
                              hintStyle: const TextStyle(color: Colors.black54),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter your email';
                              if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(value)) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        // Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.black),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(color: Colors.black54),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your password';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                final username = _usernameController.text.trim();
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_isSignUp ? 'Signing up $username' : 'Logging in $username')));
                                // Navigate to HomePage after mock login
                                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => AppShell(username: username)));
                              }
                            },
                            child: Text(_isSignUp ? 'Sign Up' : 'Login', style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _isSignUp = !_isSignUp),
                          child: Text(_isSignUp ? 'Already have an account? Login' : "Don't have an account? Sign Up", style: const TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
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

