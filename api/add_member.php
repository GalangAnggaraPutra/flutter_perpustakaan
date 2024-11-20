<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

include 'connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
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
    
    echo json_encode($response);
}
?>