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
    if (!isset($_POST['id'])) {
        throw new Exception('ID anggota tidak ditemukan');
    }

    $member_id = $_POST['id'];

    // Cek apakah anggota masih memiliki peminjaman aktif
    $check_query = "SELECT id FROM peminjaman WHERE anggota_id = ? AND status = 'dipinjam'";
    $stmt = $conn->prepare($check_query);
    $stmt->bind_param("i", $member_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        throw new Exception('Anggota masih memiliki peminjaman aktif');
    }

    // Hapus anggota
    $query = "DELETE FROM anggota WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $member_id);

    if ($stmt->execute()) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Anggota berhasil dihapus'
        ]);
    } else {
        throw new Exception('Gagal menghapus anggota');
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