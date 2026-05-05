# Disco

A pixel-art themed music streaming app built with Flutter.

## Description

Disco is a retro-styled music streaming application featuring a distinctive pixel-art UI. It allows users to stream music, manage playback queues, create playlists, favorite songs, and search their library — all wrapped in a nostalgic vaporwave aesthetic.

## Features

- **Music Player** — Full-featured audio player with play, pause, skip, seek, volume control, and loop modes
- **Queue Management** — Add songs to queue, reorder via drag-and-drop, remove individual tracks, and clear the queue
- **Playlists** — Create custom playlists, add/remove songs, and delete playlists
- **Favorites** — Permanent "Favorites" playlist synced with the backend; toggle favorites from the player and song menus
- **Shuffle** — Queue-level shuffle that keeps the current song in place while randomizing upcoming tracks
- **Search** — Search songs by title or artist name
- **User Profiles** — Customizable avatar, display name, bio, and color themes
- **Dark / Light Mode** — Toggle between dark and light pixel themes
- **Upload Songs** — Upload new tracks with audio and cover art

## Tech Stack

- **Frontend**: Flutter (Dart)
- **Audio Engine**: [just_audio](https://pub.dev/packages/just_audio)
- **Backend**: PHP (REST API)
- **Database**: MySQL

## Project Structure

```
Disco/
├── lib/
│   ├── main.dart              # App entry point, login screen, themes
│   ├── app_shell.dart         # Main navigation shell with bottom tabs
│   ├── Homepage.dart          # Home feed with top tracks and recommendations
│   ├── Search.dart            # Song search page
│   ├── Library.dart           # Playlists and favorites library
│   ├── music_player.dart      # Full-screen player and queue bottom sheet
│   ├── upload_song.dart       # Song upload flow
│   ├── pixel_colors.dart      # App color palette
│   ├── models/
│   │   └── song.dart          # Song data model
│   ├── services/
│   │   ├── audio_manager.dart # Audio playback & queue management
│   │   └── db_service.dart    # API client for backend communication
│   └── widgets/
│       └── shared_sheets.dart # Reusable playlist bottom sheet
├── DiscoAPI/                  # PHP backend
│   ├── data.php               # Main API endpoint (songs, playlists, favorites)
│   ├── auth.php               # Authentication
│   ├── upload_song.php        # File upload handler
│   ├── preferences.php        # User preferences
│   └── config.php             # Database configuration
└── pubspec.yaml               # Flutter dependencies
```

## Setup Instructions

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- A running MySQL database with the Disco schema
- A web server (Apache/Nginx) to host the PHP backend

### Frontend

1. Clone the repository and navigate to the `Disco` folder.
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Backend

1. Copy the `DiscoAPI` folder to your web server document root.
2. Update `DiscoAPI/config.php` with your database credentials.
3. Ensure the database schema includes tables for:
   - `users`
   - `songs`
   - `artists`
   - `playlists`
   - `playlist_songs`
   - `favorites` (legacy) or use the playlist-based favorites system

## API Endpoints

The backend exposes the following endpoints via `data.php`:

| Type | Method | Description |
|------|--------|-------------|
| `songs` | GET | Fetch all songs |
| `playlists` | GET | Fetch user playlists (auto-creates Favorites) |
| `toggle_favorite` | POST | Add/remove song from Favorites playlist |
| `get_favorites` | GET | Get favorited songs |
| `create_playlist` | POST | Create a new playlist |
| `add_to_playlist` | POST | Add a song to a playlist |
| `get_playlist_songs` | GET | Get songs in a playlist |
| `remove_from_playlist` | POST | Remove a song from a playlist |
| `delete_playlist` | POST | Delete a playlist |

## Key Dependencies

- `just_audio` — Audio playback engine
- `http` — HTTP client for API requests
- `image_picker` — Image selection for uploads and avatars
- `shared_preferences` — Local storage for user preferences

## License

This project is for educational purposes.
