<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    // Cek apakah ada ID buku yang dikirim
    if (!isset($_POST['id'])) {
        throw new Exception('ID buku tidak ditemukan');
    }

    $book_id = $_POST['id'];

    // Cek apakah buku sedang dipinjam
    $check_query = "SELECT id FROM peminjaman WHERE buku_id = ? AND status = 'dipinjam'";
    $stmt = $conn->prepare($check_query);
    $stmt->bind_param("i", $book_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        throw new Exception('Buku sedang dipinjam, tidak bisa dihapus');
    }

    // Hapus buku
    $query = "DELETE FROM buku WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $book_id);

    if ($stmt->execute()) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Buku berhasil dihapus'
        ]);
    } else {
        throw new Exception('Gagal menghapus buku');
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