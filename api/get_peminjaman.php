<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

try {
    // Query untuk mengambil semua peminjaman
    $query = "SELECT p.*, 
              b.judul as judul_buku,
              a.nama as nama_peminjam,
              a.nim as nim_peminjam
              FROM peminjaman p
              JOIN buku b ON p.buku_id = b.id
              JOIN anggota a ON p.anggota_id = a.id
              ORDER BY p.created_at DESC";

    $result = $conn->query($query);

    if (!$result) {
        throw new Exception("Error in query: " . $conn->error);
    }

    $peminjaman = array();
    while ($row = $result->fetch_assoc()) {
        $peminjaman[] = array(
            'id' => (int) $row['id'],
            'buku_id' => (int) $row['buku_id'],
            'anggota_id' => (int) $row['anggota_id'],
            'tanggal_pinjam' => $row['tanggal_pinjam'],
            'tanggal_kembali' => $row['tanggal_kembali'],
            'status' => $row['status'],
            'judul_buku' => $row['judul_buku'],
            'nama_peminjam' => $row['nama_peminjam'],
            'nim_peminjam' => $row['nim_peminjam'],
            'created_at' => $row['created_at']
        );
    }

    echo json_encode([
        'status' => 'success',
        'data' => $peminjaman
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