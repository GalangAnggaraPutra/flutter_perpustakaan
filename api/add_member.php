<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    // Debug: Log request data
    error_log("Received POST request");
    error_log("POST data: " . print_r($_POST, true));

    $nim = $_POST['nim'];
    $nama = $_POST['nama'];
    $alamat = $_POST['alamat'];
    $jenis_kelamin = $_POST['jenis_kelamin'];
    
    $query = "INSERT INTO anggota (nim, nama, alamat, jenis_kelamin) 
              VALUES (?, ?, ?, ?)";
              
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ssss", $nim, $nama, $alamat, $jenis_kelamin);
    
    if($stmt->execute()) {
        $response = array(
            'status' => 'success',
            'message' => 'Anggota berhasil ditambahkan'
        );
    } else {
        $response = array(
            'status' => 'error',
            'message' => 'Gagal menambahkan anggota: ' . $conn->error
        );
    }
    
    // Debug: Log response
    error_log("Sending response: " . json_encode($response));
    echo json_encode($response);
}
?>