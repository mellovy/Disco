<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') exit;

include 'config.php';

$action = $_GET['action'] ?? '';
$user_id = (int)($_POST['user_id'] ?? $_GET['user_id'] ?? 0);

if ($user_id <= 0) {
    echo json_encode(["success" => false, "message" => "Invalid User ID"]);
    exit;
}

switch ($action) {
    case 'create_playlist':
        $name = $conn->real_escape_string($_POST['name']);
        $sql = "INSERT INTO playlists (user_id, name, created_at) VALUES ($user_id, '$name', NOW())";
        if ($conn->query($sql)) {
            echo json_encode(["success" => true, "playlist_id" => $conn->insert_id]);
        } else {
            echo json_encode(["success" => false, "error" => $conn->error]);
        }
        break;

    case 'toggle_favorite':
        $song_id = (int)$_POST['song_id'];
        $check = $conn->query("SELECT * FROM favorites WHERE user_id = $user_id AND song_id = $song_id");
        if ($check->num_rows > 0) {
            $sql = "DELETE FROM favorites WHERE user_id = $user_id AND song_id = $song_id";
            $status = "removed";
        } else {
            $sql = "INSERT INTO favorites (user_id, song_id) VALUES ($user_id, $song_id)";
            $status = "added";
        }
        if ($conn->query($sql)) {
            echo json_encode(["success" => true, "status" => $status]);
        } else {
            echo json_encode(["success" => false, "error" => $conn->error]);
        }
        break;

    case 'get_favorites':
        $sql = "SELECT s.song_id, s.title, a.name as artist_name 
                FROM songs s 
                JOIN favorites f ON s.song_id = f.song_id 
                LEFT JOIN artists a ON s.artist_id = a.artist_id 
                WHERE f.user_id = $user_id";
        $res = $conn->query($sql);
        echo json_encode($res->fetch_all(MYSQLI_ASSOC));
        break;

    case 'add_to_playlist':
        $playlist_id = (int)$_POST['playlist_id'];
        $song_id = (int)$_POST['song_id'];
        $sql = "INSERT INTO playlist_songs (playlist_id, song_id, added_at) VALUES ($playlist_id, $song_id, NOW())";
        echo json_encode(["success" => $conn->query($sql)]);
        break;
        
    case 'get_playlist_songs':
        $playlist_id = (int)$_GET['playlist_id'];
        $sql = "SELECT s.song_id, s.title, a.name as artist_name 
                FROM songs s 
                JOIN playlist_songs ps ON s.song_id = ps.song_id 
                LEFT JOIN artists a ON s.artist_id = a.artist_id 
                WHERE ps.playlist_id = $playlist_id";
        $res = $conn->query($sql);
        echo json_encode($res->fetch_all(MYSQLI_ASSOC));
        break;
}
$conn->close();
?>