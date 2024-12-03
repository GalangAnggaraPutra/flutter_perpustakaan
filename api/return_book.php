<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    $buku_id = $_POST['buku_id'];
    
    // Update status peminjaman
    $query = "UPDATE peminjaman 
              SET status = 'dikembalikan' 
              WHERE buku_id = ? AND status = 'dipinjam'";
              
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $buku_id);
    
    if ($stmt->execute()) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Buku berhasil dikembalikan'
        ]);
    } else {
        throw new Exception($stmt->error);
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