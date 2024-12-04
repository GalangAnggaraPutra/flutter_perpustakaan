<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    $query = "SELECT 
                r.id,
                r.tanggal_dikembalikan,
                r.terlambat,
                r.denda,
                b.judul as judul_buku,
                b.image,
                a.nama as nama_peminjam,
                a.nim,
                p.tanggal_pinjam,
                p.tanggal_kembali,
                CASE 
                    WHEN r.terlambat > 0 THEN CONCAT(r.terlambat, ' hari')
                    ELSE 'Tepat waktu'
                END as status_keterlambatan,
                CASE 
                    WHEN r.denda > 0 THEN CONCAT('Rp ', FORMAT(r.denda, 0))
                    ELSE 'Tidak ada denda'
                END as status_denda
              FROM pengembalian r
              JOIN peminjaman p ON r.peminjaman_id = p.id
              JOIN buku b ON r.buku_id = b.id
              JOIN anggota a ON r.anggota_id = a.id
              ORDER BY r.tanggal_dikembalikan DESC";
              
    $result = $conn->query($query);
    
    if ($result === false) {
        throw new Exception("Query error: " . $conn->error);
    }
    
    $data = array();
    while ($row = $result->fetch_assoc()) {
        $data[] = array(
            'id' => (int)$row['id'],
            'judul_buku' => $row['judul_buku'],
            'image' => $row['image'],
            'nama_peminjam' => $row['nama_peminjam'],
            'nim' => $row['nim'],
            'tanggal_pinjam' => $row['tanggal_pinjam'],
            'tanggal_kembali' => $row['tanggal_kembali'],
            'tanggal_dikembalikan' => $row['tanggal_dikembalikan'],
            'terlambat' => (int)$row['terlambat'],
            'denda' => (float)$row['denda'],
            'status_keterlambatan' => $row['status_keterlambatan'],
            'status_denda' => $row['status_denda']
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