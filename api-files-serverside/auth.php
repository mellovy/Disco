<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Handle preflight OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    exit;
}

include 'config.php';
$user = $_POST['username'];
$pass = $_POST['password'];
$email = $_POST['email'] ?? null;

if ($email) { // Register mode
    $sql = "INSERT INTO users (username, email, password) VALUES ('$user', '$email', '$pass')";
    echo json_encode(["success" => $conn->query($sql)]);
} else { // Login mode
    $res = $conn->query("SELECT user_id FROM users WHERE username='$user' AND password='$pass'");
    if ($row = $res->fetch_assoc()) echo json_encode(["success" => true, "user_id" => (int)$row['user_id']]);
    else echo json_encode(["success" => false]);
}
?>