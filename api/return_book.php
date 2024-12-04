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
        error_log("Received POST data: " . print_r($_POST, true));
        
        if (!isset($_POST['buku_id'])) {
            throw new Exception('ID buku tidak ditemukan');
        }

        // Nonaktifkan autocommit untuk transaksi
        $conn->autocommit(FALSE);

        $buku_id = $_POST['buku_id'];
        
        // Cek peminjaman aktif
        $query = "SELECT p.id, p.tanggal_kembali 
                 FROM peminjaman p 
                 WHERE p.buku_id = ? AND p.status = 'dipinjam'";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $buku_id);
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
        $query = "INSERT INTO pengembalian (peminjaman_id, tanggal_dikembalikan, terlambat, denda) 
                 VALUES (?, CURRENT_DATE, ?, ?)";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("iid", $peminjaman_id, $terlambat, $denda);
        
        if (!$stmt->execute()) {
            throw new Exception('Gagal mencatat pengembalian');
        }
        
        // Update status peminjaman
        $query = "UPDATE peminjaman SET status = 'dikembalikan' WHERE id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $peminjaman_id);
        
        if (!$stmt->execute()) {
            throw new Exception('Gagal mengupdate status peminjaman');
        }
        
        // Commit transaksi
        $conn->commit();
        
        // Response sukses
        $response = [
            'status' => 'success',
            'message' => 'Buku berhasil dikembalikan',
            'data' => [
                'peminjaman_id' => $peminjaman_id,
                'tanggal_dikembalikan' => date('Y-m-d'),
                'terlambat' => $terlambat,
                'denda' => $denda
            ]
        ];

    } catch (Exception $e) {
        // Rollback jika terjadi error
        $conn->rollback();
        $response = [
            'status' => 'error',
            'message' => $e->getMessage()
        ];
    } finally {
        // Aktifkan kembali autocommit
        $conn->autocommit(TRUE);
    }

    error_log("Response: " . json_encode($response));
    echo json_encode($response);
    
    if (isset($stmt)) {
        $stmt->close();
    }
    $conn->close();
}
?>