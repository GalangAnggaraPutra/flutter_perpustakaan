<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    $book_id = isset($_GET['book_id']) ? (int)$_GET['book_id'] : 0;

    if ($book_id <= 0) {
        throw new Exception('Invalid book ID');
    }

    // Ambil data peminjaman aktif
    $query = "SELECT tanggal_pinjam, tanggal_kembali 
              FROM peminjaman 
              WHERE buku_id = ? AND status = 'dipinjam'
              ORDER BY id DESC LIMIT 1";
              
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $book_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        $data = $result->fetch_assoc();
        echo json_encode([
            'status' => 'success',
            'data' => [
                'tanggal_pinjam' => $data['tanggal_pinjam'],
                'tanggal_kembali' => $data['tanggal_kembali']
            ]
        ]);
    } else {
        echo json_encode([
            'status' => 'success',
            'data' => null
        ]);
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