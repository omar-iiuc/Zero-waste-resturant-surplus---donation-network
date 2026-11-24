<?php
$host = "127.0.0.1";
$username = "root";
$password = "";
$dbname = "zero waste resturant surplus & donation network";

$conn = new mysqli($host, $username, $password, $dbname);

if ($conn->connect_error) {
    die("Database Connection Failed: " . $conn->connect_error);
}
$conn->set_charset("utf8mb4");
?>