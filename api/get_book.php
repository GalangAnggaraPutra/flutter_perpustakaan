<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

include 'connection.php';

$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$per_page = isset($_GET['per_page']) ? (int)$_GET['per_page'] : 3;
$offset = ($page - 1) * $per_page;

// Get total books
$total_query = "SELECT COUNT(*) as total FROM buku";
$total_result = mysqli_query($conn, $total_query);
$total_row = mysqli_fetch_assoc($total_result);
$total_books = $total_row['total'];
$total_pages = ceil($total_books / $per_page);

// Get books for current page
$query = "SELECT * FROM buku ORDER BY id DESC LIMIT ? OFFSET ?";
$stmt = $conn->prepare($query);
$stmt->bind_param("ii", $per_page, $offset);
$stmt->execute();
$result = $stmt->get_result();

$books = [];
while ($row = $result->fetch_assoc()) {
    $books[] = $row;
}

$response = [
    'books' => $books,
    'current_page' => $page,
    'total_pages' => $total_pages,
    'per_page' => $per_page,
    'total_books' => $total_books
];

echo json_encode($response);
?>