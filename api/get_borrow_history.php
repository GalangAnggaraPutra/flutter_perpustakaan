<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    $anggota_id = isset($_GET['anggota_id']) ? (int)$_GET['anggota_id'] : 0;
    
    // Base query untuk mendapatkan semua peminjaman (aktif dan selesai)
    $query = "SELECT 
                p.id,
                p.tanggal_pinjam,
                p.tanggal_kembali,
                p.status,
                b.judul as judul_buku,
                b.image,
                a.nama as nama_peminjam,
                a.nim,
                CASE 
                    WHEN p.status = 'dipinjam' THEN 'Sedang Dipinjam'
                    WHEN p.status = 'dikembalikan' THEN 'Sudah Dikembalikan'
                    ELSE p.status
                END as status_peminjaman,
                r.tanggal_dikembalikan,
                r.terlambat,
                r.denda,
                CASE 
                    WHEN r.terlambat > 0 THEN CONCAT(r.terlambat, ' hari')
                    WHEN r.tanggal_dikembalikan IS NOT NULL THEN 'Tepat waktu'
                    WHEN p.status = 'dipinjam' AND CURRENT_DATE > p.tanggal_kembali 
                        THEN CONCAT(DATEDIFF(CURRENT_DATE, p.tanggal_kembali), ' hari terlambat')
                    WHEN p.status = 'dipinjam' THEN 'Masih dalam masa peminjaman'
                    ELSE '-'
                END as status_keterlambatan,
                CASE 
                    WHEN r.denda > 0 THEN CONCAT('Rp ', FORMAT(r.denda, 0))
                    WHEN p.status = 'dipinjam' AND CURRENT_DATE > p.tanggal_kembali 
                        THEN CONCAT('Rp ', FORMAT(DATEDIFF(CURRENT_DATE, p.tanggal_kembali) * 2000, 0))
                    ELSE 'Tidak ada denda'
                END as status_denda
              FROM peminjaman p
              JOIN buku b ON p.buku_id = b.id
              JOIN anggota a ON p.anggota_id = a.id
              LEFT JOIN pengembalian r ON p.id = r.peminjaman_id";

    // Filter berdasarkan anggota jika bukan admin
    if ($anggota_id > 0) {
        $query .= " WHERE p.anggota_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $anggota_id);
    } else {
        $stmt = $conn->prepare($query);
    }

    $query .= " ORDER BY p.tanggal_pinjam DESC";
    
    $stmt->execute();
    $result = $stmt->get_result();
    
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
            'status' => $row['status'],
            'status_peminjaman' => $row['status_peminjaman'],
            'terlambat' => (int)$row['terlambat'],
            'denda' => (float)($row['denda'] ?? 0),
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