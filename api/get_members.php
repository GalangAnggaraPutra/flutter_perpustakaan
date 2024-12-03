<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

try {
    // Tambahkan error reporting
    error_reporting(E_ALL);
    ini_set('display_errors', 1);

    $search = isset($_GET['search']) ? $_GET['search'] : '';
    
    // Gunakan query sederhana dulu untuk debugging
    $query = "SELECT * FROM anggota";
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query error: " . $conn->error);
    }
    
    $members = array();
    while ($row = $result->fetch_assoc()) {
        $members[] = array(
            'id' => (int)$row['id'],
            'nim' => $row['nim'],
            'nama' => $row['nama'],
            'alamat' => $row['alamat'],
            'jenis_kelamin' => $row['jenis_kelamin']
        );
    }
    
    echo json_encode([
        'status' => 'success',
        'data' => $members
    ]);

} catch (Exception $e) {
    error_log("Error in get_members.php: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?> 