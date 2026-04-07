import 'dart:async';
import 'package:flutter/material.dart';
import 'AppShell.dart';
import 'services/db_service.dart';

void main() {
  runApp(const MaterialApp(home: DiscoApp()));
}

class DiscoApp extends StatefulWidget {
  const DiscoApp({super.key});
  @override
  State<DiscoApp> createState() => _DiscoAppState();
}

class _DiscoAppState extends State<DiscoApp> {
  List<Color> discoColors = [
    const Color(0x78AE65EC), const Color(0x78EB6276),
    const Color(0x78FFB7E4), const Color(0x78FF66C4),
  ];
  int colorIndex = 0;
  Timer? timer;
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
    timer = Timer.periodic(const Duration(milliseconds: 500), (t) {
      if (mounted) setState(() => colorIndex = (colorIndex + 1) % discoColors.length);
    });
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account Created! Please Login.')));
        } else {
          Navigator.of(context).pushReplacement(MaterialPageRoute(
            builder: (_) => AppShell(username: _usernameController.text, userId: res['user_id'])
          ));
        }
      } else {
        throw 'Authentication failed';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [discoColors[colorIndex], discoColors[(colorIndex + 1) % discoColors.length]]),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset('images/disco1.png', width: 200, height: 200, errorBuilder: (c, e, s) => const Icon(Icons.music_note, size: 100)),
                const Text('Feel the Groove', style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Form(
                  key: _formKey,
                  child: Container(
                    width: 320, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        TextFormField(controller: _usernameController, decoration: const InputDecoration(hintText: 'Username', filled: true, fillColor: Colors.white)),
                        if (_isSignUp) ...[
                          const SizedBox(height: 10),
                          TextFormField(controller: _emailController, decoration: const InputDecoration(hintText: 'Email', filled: true, fillColor: Colors.white)),
                        ],
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _passwordController, obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: 'Password', filled: true, fillColor: Colors.white,
                            suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                          )
                        ),
                        const SizedBox(height: 14),
                        _isConnecting ? const CircularProgressIndicator() : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                            onPressed: _handleAuth,
                            child: Text(_isSignUp ? 'Sign Up' : 'Login', style: const TextStyle(color: Colors.white)),
                          ),
                        ),
                        TextButton(onPressed: () => setState(() => _isSignUp = !_isSignUp), child: Text(_isSignUp ? 'Already have an account? Login' : "Sign Up", style: const TextStyle(color: Colors.white70))),
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