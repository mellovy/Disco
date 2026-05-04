<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
include 'config.php';

$type = $_GET['type'] ?? '';

if ($type == 'songs') {
    $sql = "SELECT s.song_id, s.title, a.name as artist_name 
            FROM songs s 
            LEFT JOIN artists a ON s.artist_id = a.artist_id 
            ORDER BY s.song_id DESC";
    $res = $conn->query($sql);
    echo json_encode($res->fetch_all(MYSQLI_ASSOC));

} else if ($type == 'playlists') {
    $uId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 0;
    // Fetches all playlists created by the user[cite: 2, 8]
    $res = $conn->query("SELECT * FROM playlists WHERE user_id = $uId ORDER BY created_at DESC");
    echo json_encode($res->fetch_all(MYSQLI_ASSOC));
}
?>