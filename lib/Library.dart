import 'package:flutter/material.dart';

/// A lightweight content widget for embedding inside parent shells (no Scaffold).
class LibraryContent extends StatelessWidget {
  const LibraryContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final playlists = [
      'Chill Vibes',
      'Workout Mix',
      'Roadtrip',
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.8),
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 8),

                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search',
                        hintStyle: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.mic, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Your Library',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Liked Songs card
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF9C7BFF), Color(0xFFD8C7FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.favorite, color: Colors.white, size: 36),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Liked Songs',
                        style: TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

            // Playlists list
            Expanded(
              child: ListView.separated(
                itemCount: playlists.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final title = playlists[index];
                  return Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(Icons.photo, color: Colors.grey, size: 34),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.more_vert),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LibraryPage extends StatelessWidget {
  const LibraryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1E6FF),
      body: const LibraryContent(),
      bottomNavigationBar: Container(
        color: Colors.white.withOpacity(0.9),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavItem(icon: Icons.home, label: 'Home', active: false),
            _BottomNavItem(icon: Icons.search, label: 'Search', active: false),
            _BottomNavItem(icon: Icons.library_music, label: 'Library', active: true),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomNavItem({required this.icon, required this.label, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEDE0FF) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: active ? Colors.purple : Colors.grey),
        ),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(color: active ? Colors.purple : Colors.grey, fontSize: 12)),
      ],
    );
  }
}