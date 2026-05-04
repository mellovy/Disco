<?php
/**
 * get_file.php
 */

// Temporarily increase memory limit to prevent crashing when loading large MP3 blobs
ini_set('memory_limit', '256M');
// Turn off error output so HTML error strings don't corrupt the binary audio/image data
ini_set('display_errors', 0); 

header('Access-Control-Allow-Origin: *');
header('Access-Control-Expose-Headers: Content-Length, Content-Range, Accept-Ranges');

// 1. Use your existing config file instead of hardcoded credentials
require_once 'config.php'; 

$id    = isset($_GET['id'])    ? intval($_GET['id'])    : 0;
$field = isset($_GET['field']) ? $_GET['field']         : '';

if (!in_array($field, ['audio_url', 'cover_image'], true)) {
    http_response_code(400);
    exit('Invalid field');
}

if ($id <= 0) {
    http_response_code(400);
    exit('Invalid id');
}

// 2. Fetch the blob using your $conn from config.php
$stmt = $conn->prepare("SELECT `$field` FROM songs WHERE song_id = ?");
if (!$stmt) {
    http_response_code(500);
    exit('Database prepare error');
}

$stmt->bind_param("i", $id);
$stmt->execute();
$stmt->store_result();

if ($stmt->num_rows === 0) {
    http_response_code(404);
    exit('Not found');
}

$stmt->bind_result($data);
$stmt->fetch();

if (empty($data)) {
    http_response_code(404);
    exit('File data is empty');
}

$size = strlen($data);

if ($field === 'audio_url') {
    $mime = 'audio/mpeg';
} else {
    $info = @getimagesizefromstring($data);
    $mime = ($info && isset($info['mime'])) ? $info['mime'] : 'image/jpeg';
}

header('Content-Type: ' . $mime);
header('Accept-Ranges: bytes');
header('Cache-Control: public, max-age=3600');

// 3. Handle Range Requests for Seeking
if (isset($_SERVER['HTTP_RANGE'])) {
    $rangeHeader = $_SERVER['HTTP_RANGE'];

    if (!preg_match('/^bytes=(\d+)-(\d*)$/', trim($rangeHeader), $m)) {
        http_response_code(416);
        header("Content-Range: bytes */$size");
        exit;
    }

    $start = intval($m[1]);
    $end   = ($m[2] !== '') ? intval($m[2]) : $size - 1;
    $end = min($end, $size - 1);

    if ($start > $end || $start >= $size) {
        http_response_code(416);
        header("Content-Range: bytes */$size");
        exit;
    }

    $length = $end - $start + 1;

    http_response_code(206);
    header("Content-Range: bytes $start-$end/$size");
    header("Content-Length: $length");
    echo substr($data, $start, $length);

} else {
    header("Content-Length: $size");
    echo $data;
}

$stmt->close();
$conn->close();
exit;