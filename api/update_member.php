<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

try {
    if (!isset($_POST['id']) || !isset($_POST['nim']) || 
        !isset($_POST['nama']) || !isset($_POST['alamat']) || 
        !isset($_POST['jenis_kelamin'])) {
        throw new Exception('Data tidak lengkap');
    }

    $id = $_POST['id'];
    $nim = $_POST['nim'];
    $nama = $_POST['nama'];
    $alamat = $_POST['alamat'];
    $jenis_kelamin = $_POST['jenis_kelamin'];

    // Cek apakah NIM sudah digunakan (kecuali oleh anggota yang sedang diupdate)
    $check_query = "SELECT id FROM anggota WHERE nim = ? AND id != ?";
    $stmt = $conn->prepare($check_query);
    $stmt->bind_param("si", $nim, $id);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        throw new Exception('NIM sudah digunakan');
    }

    // Update data anggota
    $query = "UPDATE anggota SET 
              nim = ?, 
              nama = ?, 
              alamat = ?, 
              jenis_kelamin = ? 
              WHERE id = ?";
              
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ssssi", $nim, $nama, $alamat, $jenis_kelamin, $id);

    if ($stmt->execute()) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Data anggota berhasil diupdate'
        ]);
    } else {
        throw new Exception('Gagal mengupdate data anggota');
    }

} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?> 