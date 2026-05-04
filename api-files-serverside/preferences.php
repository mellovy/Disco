<?php
/**
 * preferences.php
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { exit; }

// Include your global config instead of hardcoding credentials
include 'config.php';

try {
    // Parse DB_HOST from config.php (handles "localhost:3306")
    $host_parts = explode(':', DB_HOST);
    $host = $host_parts[0];
    $port = isset($host_parts[1]) ? $host_parts[1] : 3306;

    $pdo = new PDO(
        "mysql:host=$host;port=$port;dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    // Auto-create the table if it doesn't exist in your database
    $pdo->exec("CREATE TABLE IF NOT EXISTS user_preferences (
        user_id INT(11) PRIMARY KEY,
        dark_mode TINYINT(1) DEFAULT 0
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;");

} catch (PDOException $e) {
    echo json_encode(['success' => false, 'error' => 'DB connection failed: ' . $e->getMessage()]);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    // ── Load preferences ──────────────────────────────────────────────────────
    $userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

    if ($userId <= 0) {
        echo json_encode(['success' => false, 'error' => 'Invalid user_id']);
        exit;
    }

    $stmt = $pdo->prepare("SELECT dark_mode FROM user_preferences WHERE user_id = ?");
    $stmt->execute([$userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row) {
        echo json_encode([
            'dark_mode' => (int) $row['dark_mode'],
        ]);
    } else {
        echo json_encode([
            'dark_mode' => 0,
        ]);
    }

} elseif ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // ── Save preferences ──────────────────────────────────────────────────────
    $userId   = isset($_POST['user_id'])   ? intval($_POST['user_id'])   : 0;
    $darkMode = isset($_POST['dark_mode']) ? intval($_POST['dark_mode']) : 0;

    if ($userId <= 0) {
        echo json_encode(['success' => false, 'error' => 'Invalid user_id']);
        exit;
    }

    $stmt = $pdo->prepare("
        INSERT INTO user_preferences (user_id, dark_mode)
        VALUES (?, ?)
        ON DUPLICATE KEY UPDATE dark_mode = VALUES(dark_mode)
    ");
    $stmt->execute([$userId, $darkMode]);

    echo json_encode(['success' => true]);

} else {
    http_response_code(405);
    echo json_encode(['error' => 'Method not allowed']);
}
exit;