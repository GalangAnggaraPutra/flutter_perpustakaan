<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    if (!isset($_POST['buku_id']) || !isset($_POST['anggota_id'])) {
        throw new Exception('ID buku dan ID anggota diperlukan');
    }

    $buku_id = $_POST['buku_id'];
    $anggota_id = $_POST['anggota_id'];
    
    $conn->begin_transaction();
    
    // Cek peminjaman aktif
    $check_query = "SELECT p.id, p.tanggal_kembali 
                   FROM peminjaman p 
                   WHERE p.buku_id = ? 
                   AND p.anggota_id = ?
                   AND p.status = 'dipinjam'";
    
    $stmt = $conn->prepare($check_query);
    $stmt->bind_param("ii", $buku_id, $anggota_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        throw new Exception('Tidak ada peminjaman aktif untuk buku ini');
    }
    
    $peminjaman = $result->fetch_assoc();
    $peminjaman_id = $peminjaman['id'];
    
    // Hitung keterlambatan dan denda
    $tanggal_kembali = new DateTime($peminjaman['tanggal_kembali']);
    $tanggal_sekarang = new DateTime(date('Y-m-d'));
    
    $terlambat = 0;
    $denda = 0;
    if ($tanggal_sekarang > $tanggal_kembali) {
        $terlambat = $tanggal_sekarang->diff($tanggal_kembali)->days;
        $denda = $terlambat * 2000; // Denda Rp 2.000 per hari
    }
    
    // Insert ke tabel pengembalian
    $insert_query = "INSERT INTO pengembalian (
        peminjaman_id,
        tanggal_dikembalikan,
        terlambat,
        denda
    ) VALUES (?, CURRENT_DATE, ?, ?)";
    
    $stmt = $conn->prepare($insert_query);
    $stmt->bind_param("iid", $peminjaman_id, $terlambat, $denda);
    
    if (!$stmt->execute()) {
        throw new Exception('Gagal mencatat pengembalian');
    }
    
    // Update status peminjaman
    $update_query = "UPDATE peminjaman 
                    SET status = 'dikembalikan' 
                    WHERE id = ?";
    $stmt = $conn->prepare($update_query);
    $stmt->bind_param("i", $peminjaman_id);
    
    if (!$stmt->execute()) {
        throw new Exception('Gagal mengupdate status peminjaman');
    }
    
    $conn->commit();
    
    echo json_encode([
        'status' => 'success',
        'message' => 'Buku berhasil dikembalikan',
        'data' => [
            'peminjaman_id' => $peminjaman_id,
            'tanggal_dikembalikan' => date('Y-m-d'),
            'terlambat' => $terlambat,
            'denda' => $denda
        ]
    ]);

} catch (Exception $e) {
    if ($conn->connect_errno == 0) {
        $conn->rollback();
    }
    
    http_response_code(500);
    echo json_encode([
        'status' => 'error',
        'message' => $e->getMessage()
    ]);
}

$conn->close();
?>