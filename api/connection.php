<?php
$host = "localhost";
$username = "root";
$password = "";
$database = "flutter_perpustakaan_1";

$conn = new mysqli($host, $username, $password, $database);

if ($conn->connect_error) {
    die("Koneksi gagal: " . $conn->connect_error);
}
?>