<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

try {
    if (!isset($_GET['book_id'])) {
        throw new Exception("Book ID is required");
    }

    $book_id = $_GET['book_id'];
    
    $query = "SELECT 
                CASE 
                    WHEN p.id IS NOT NULL AND p.status = 'dipinjam' 
                    THEN 'dipinjam' 
                    ELSE 'tersedia' 
                END as status
              FROM buku b
              LEFT JOIN peminjaman p ON b.id = p.buku_id AND p.status = 'dipinjam'
              WHERE b.id = ?";
              
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $book_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        echo json_encode([
            'status' => $row['status']
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