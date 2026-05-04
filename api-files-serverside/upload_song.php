<?php
/**
 * upload_song.php
 */

// Safely increase memory limit for handling large audio blob data
ini_set('memory_limit', '256M'); 
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Include your global config instead of hardcoding credentials
include 'config.php';

try {
    $host_parts = explode(':', DB_HOST);
    $host = $host_parts[0];
    $port = isset($host_parts[1]) ? $host_parts[1] : 3306;

    $pdo = new PDO(
        "mysql:host=$host;port=$port;dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'error' => 'DB connection failed: ' . $e->getMessage()]);
    exit;
}

// ── Validate inputs ───────────────────────────────────────────────────────────
$title      = trim($_POST['title']       ?? '');
$artistName = trim($_POST['artist_name'] ?? '');

if ($title === '' || $artistName === '') {
    echo json_encode(['success' => false, 'error' => 'title and artist_name are required']);
    exit;
}

if (!isset($_FILES['audio']) || $_FILES['audio']['error'] !== UPLOAD_ERR_OK) {
    echo json_encode(['success' => false, 'error' => 'Audio file is missing or failed to upload']);
    exit;
}

if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    echo json_encode(['success' => false, 'error' => 'Image file is missing or failed to upload']);
    exit;
}

// ── Find or Create artist ─────────────────────────────────────────────────────
$stmt = $pdo->prepare("SELECT artist_id FROM artists WHERE LOWER(name) = LOWER(?) LIMIT 1");
$stmt->execute([$artistName]);
$artist = $stmt->fetch(PDO::FETCH_ASSOC);

if ($artist) {
    $artistId = (int) $artist['artist_id'];
} else {
    $stmt = $pdo->prepare("INSERT INTO artists (name) VALUES (?)");
    $stmt->execute([$artistName]);
    $artistId = (int) $pdo->lastInsertId();
}

// ── Read file bytes ───────────────────────────────────────────────────────────
$audioData = file_get_contents($_FILES['audio']['tmp_name']);
$imageData = file_get_contents($_FILES['image']['tmp_name']);

if ($audioData === false || $imageData === false) {
    echo json_encode(['success' => false, 'error' => 'Failed to read uploaded files']);
    exit;
}

// ── Insert song ───────────────────────────────────────────────────────────────
try {
    $stmt = $pdo->prepare(
        "INSERT INTO songs (title, artist_id, duration, audio_url, cover_image)
         VALUES (?, ?, 0, ?, ?)"
    );
    $stmt->execute([$title, $artistId, $audioData, $imageData]);
    $songId = (int) $pdo->lastInsertId();

    echo json_encode([
        'success'     => true,
        'song_id'     => $songId,
        'artist_id'   => $artistId,
        'artist_name' => $artistName,
    ]);
} catch (PDOException $e) {
    echo json_encode(['success' => false, 'error' => 'Failed to insert song: ' . $e->getMessage()]);
}
exit;