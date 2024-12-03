<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
require_once 'connection.php';

if (!isset($_GET['id'])) {
    echo json_encode([
        'status' => 'error',
        'message' => 'ID buku diperlukan'
    ]);
    exit;
}

$id = $_GET['id'];

try {
    $query = "SELECT b.*, 
              p.tanggal_pinjam,
              p.tanggal_kembali,
              CASE WHEN p.status = 'dipinjam' THEN 1 ELSE 0 END as is_dipinjam
              FROM buku b
              LEFT JOIN peminjaman p ON b.id = p.buku_id AND p.status = 'dipinjam'
              WHERE b.id = ?";

    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $book = $result->fetch_assoc();
        echo json_encode([
            'status' => 'success',
            'data' => $book
        ]);
    } else {
        echo json_encode([
            'status' => 'error',
            'message' => 'Buku tidak ditemukan'
        ]);
    }
} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?>