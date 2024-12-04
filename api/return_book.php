<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        if (!isset($_POST['buku_id']) || !isset($_POST['anggota_id'])) {
            throw new Exception('ID buku dan ID anggota diperlukan');
        }

        $buku_id = $_POST['buku_id'];
        $anggota_id = $_POST['anggota_id'];
        
        // Cek peminjaman aktif untuk anggota tersebut
        $query = "SELECT p.id, p.tanggal_kembali 
                 FROM peminjaman p 
                 WHERE p.buku_id = ? 
                 AND p.anggota_id = ?
                 AND p.status = 'dipinjam'";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ii", $buku_id, $anggota_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            throw new Exception('Buku tidak dalam status dipinjam');
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
        $query = "INSERT INTO pengembalian (
                    peminjaman_id, 
                    tanggal_dikembalikan, 
                    terlambat, 
                    denda,
                    anggota_id,
                    buku_id
                 ) VALUES (?, CURRENT_DATE, ?, ?, ?, ?)";
                 
        $stmt = $conn->prepare($query);
        $stmt->bind_param("iidii", 
            $peminjaman_id, 
            $terlambat, 
            $denda,
            $anggota_id,
            $buku_id
        );
        
        if (!$stmt->execute()) {
            throw new Exception('Gagal mencatat pengembalian');
        }
        
        // Update status peminjaman
        $query = "UPDATE peminjaman 
                 SET status = 'dikembalikan', 
                     updated_at = CURRENT_TIMESTAMP 
                 WHERE buku_id = ? AND anggota_id = ? AND status = 'dipinjam'";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ii", $buku_id, $anggota_id);
        
        if (!$stmt->execute()) {
            throw new Exception('Gagal mengupdate status peminjaman');
        }
        
        // Pastikan status buku diupdate
        $update_book = "UPDATE buku 
                       SET status = 'tersedia', 
                           updated_at = CURRENT_TIMESTAMP 
                       WHERE id = ?";
        $stmt = $conn->prepare($update_book);
        $stmt->bind_param("i", $buku_id);
        $stmt->execute();
        
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
        $conn->rollback();
        echo json_encode([
            'status' => 'error',
            'message' => $e->getMessage()
        ]);
    }
}

$conn->close();
?>