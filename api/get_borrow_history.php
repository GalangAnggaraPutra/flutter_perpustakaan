<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    // Query untuk mengambil data peminjaman beserta data pengembalian
    $query = "SELECT 
                p.id,
                p.tanggal_pinjam,
                p.tanggal_kembali,
                p.status,
                b.judul,
                b.image,
                a.nama as nama_peminjam,
                a.nim,
                r.tanggal_dikembalikan,
                r.terlambat,
                r.denda
              FROM peminjaman p 
              JOIN buku b ON p.buku_id = b.id
              JOIN anggota a ON p.anggota_id = a.id
              LEFT JOIN pengembalian r ON p.id = r.peminjaman_id
              ORDER BY p.tanggal_pinjam DESC";
              
    $result = $conn->query($query);
    
    if ($result === false) {
        throw new Exception("Query error: " . $conn->error);
    }
    
    $data = array();
    while ($row = $result->fetch_assoc()) {
        $data[] = array(
            'id' => (int)$row['id'],
            'judul' => $row['judul'],
            'image' => $row['image'],
            'nama_peminjam' => $row['nama_peminjam'],
            'nim' => $row['nim'],
            'tanggal_pinjam' => $row['tanggal_pinjam'],
            'tanggal_kembali' => $row['tanggal_kembali'],
            'status' => $row['status'],
            // Data pengembalian
            'tanggal_dikembalikan' => $row['tanggal_dikembalikan'],
            'terlambat' => (int)$row['terlambat'],
            'denda' => (float)$row['denda']
        );
    }
    
    echo json_encode([
        'status' => 'success',
        'data' => $data
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