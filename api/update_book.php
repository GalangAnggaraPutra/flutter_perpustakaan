<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        throw new Exception('Method not allowed');
    }

    $id = isset($_POST['id']) ? (int)$_POST['id'] : 0;
    $judul = isset($_POST['judul']) ? $_POST['judul'] : '';
    $pengarang = isset($_POST['pengarang']) ? $_POST['pengarang'] : '';
    $penerbit = isset($_POST['penerbit']) ? $_POST['penerbit'] : '';
    $tahun_terbit = isset($_POST['tahun_terbit']) ? (int)$_POST['tahun_terbit'] : 0;

    if ($id <= 0 || empty($judul) || empty($pengarang) || empty($penerbit) || $tahun_terbit <= 0) {
        throw new Exception('Invalid parameters');
    }

    $query = "UPDATE buku SET judul = ?, pengarang = ?, penerbit = ?, tahun_terbit = ? WHERE id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("sssii", $judul, $pengarang, $penerbit, $tahun_terbit, $id);
    
    if ($stmt->execute()) {
        echo json_encode([
            'status' => 'success',
            'message' => 'Book updated successfully'
        ]);
    } else {
        throw new Exception('Failed to update book');
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