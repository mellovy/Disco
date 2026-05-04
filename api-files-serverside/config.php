<?php
define("DB_HOST", "localhost:3306"); // Database is on the same server, port 3306
define("DB_USER", "s24103884_mobdev"); // database username
define("DB_PASS", "Disco1025");        // database password
define("DB_NAME", "s24103884_mobdev"); // database name

// Create connection
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>