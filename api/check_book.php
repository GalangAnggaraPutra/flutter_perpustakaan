<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    if (!isset($_GET['book_id'])) {
        throw new Exception("Book ID is required");
    }

    $book_id = $_GET['book_id'];
    
    // Perbaiki query untuk mengecek status buku
    $query = "SELECT 
                CASE 
                    WHEN EXISTS (
                        SELECT 1 
                        FROM peminjaman 
                        WHERE buku_id = ? 
                        AND status = 'dipinjam'
                        AND deleted_at IS NULL
                    ) THEN 'dipinjam'
                    ELSE 'tersedia'
                END as status,
                (SELECT tanggal_pinjam FROM peminjaman 
                 WHERE buku_id = ? AND status = 'dipinjam' 
                 ORDER BY id DESC LIMIT 1) as tanggal_pinjam,
                (SELECT tanggal_kembali FROM peminjaman 
                 WHERE buku_id = ? AND status = 'dipinjam' 
                 ORDER BY id DESC LIMIT 1) as tanggal_kembali";
              
    $stmt = $conn->prepare($query);
    $stmt->bind_param("iii", $book_id, $book_id, $book_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        echo json_encode([
            'status' => $row['status'],
            'tanggal_pinjam' => $row['tanggal_pinjam'],
            'tanggal_kembali' => $row['tanggal_kembali']
        ]);
    } else {
        throw new Exception("Book not found");
    }

} catch (Exception $e) {
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?>