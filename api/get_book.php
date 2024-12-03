<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    $page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
    $per_page = isset($_GET['per_page']) ? (int)$_GET['per_page'] : 10;
    $search = isset($_GET['search']) ? $_GET['search'] : '';
    
    $offset = ($page - 1) * $per_page;
    
    // Join dengan tabel peminjaman untuk cek status
    $query = "SELECT b.*, 
              CASE 
                WHEN p.status = 'dipinjam' THEN 'dipinjam'
                ELSE 'tersedia'
              END as peminjaman_status
              FROM buku b
              LEFT JOIN (
                SELECT buku_id, status 
                FROM peminjaman 
                WHERE status = 'dipinjam'
              ) p ON b.id = p.buku_id
              WHERE b.judul LIKE ?
              GROUP BY b.id
              ORDER BY b.id DESC
              LIMIT ? OFFSET ?";
              
    $stmt = $conn->prepare($query);
    $search_param = "%$search%";
    $stmt->bind_param("sii", $search_param, $per_page, $offset);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $books = array();
    while ($row = $result->fetch_assoc()) {
        $books[] = $row;
    }
    
    // Get total books for pagination
    $total_query = "SELECT COUNT(DISTINCT b.id) as total FROM buku b 
                   WHERE b.judul LIKE ?";
    $stmt = $conn->prepare($total_query);
    $stmt->bind_param("s", $search_param);
    $stmt->execute();
    $total_result = $stmt->get_result();
    $total_row = $total_result->fetch_assoc();
    $total_books = $total_row['total'];
    $total_pages = ceil($total_books / $per_page);
    
    echo json_encode([
        'status' => 'success',
        'books' => $books,
        'total_pages' => $total_pages,
        'total_books' => $total_books,
        'current_page' => $page
    ]);

} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?>