<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

try {
    if (!isset($_POST['buku_id']) || !isset($_POST['anggota_id']) || 
        !isset($_POST['tanggal_pinjam']) || !isset($_POST['tanggal_kembali'])) {
        throw new Exception('Semua field harus diisi');
    }

    $buku_id = $_POST['buku_id'];
    $anggota_id = $_POST['anggota_id'];
    $tanggal_pinjam = $_POST['tanggal_pinjam'];
    $tanggal_kembali = $_POST['tanggal_kembali'];

    $conn->begin_transaction();

    // Cek apakah buku sedang dipinjam
    $check_query = "SELECT id FROM peminjaman 
                   WHERE buku_id = ? AND status = 'dipinjam'";
    $stmt = $conn->prepare($check_query);
    $stmt->bind_param("i", $buku_id);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows > 0) {
        throw new Exception('Buku sedang dipinjam');
    }

    // Insert ke tabel peminjaman
    $insert_query = "INSERT INTO peminjaman (
        buku_id, 
        anggota_id, 
        tanggal_pinjam, 
        tanggal_kembali,
        status,
        created_at
    ) VALUES (?, ?, ?, ?, 'dipinjam', NOW())";

    $stmt = $conn->prepare($insert_query);
    $stmt->bind_param("iiss", $buku_id, $anggota_id, $tanggal_pinjam, $tanggal_kembali);
    
    if (!$stmt->execute()) {
        throw new Exception('Gagal menyimpan data peminjaman');
    }

    $conn->commit();

    echo json_encode([
        'status' => 'success',
        'message' => 'Buku berhasil dipinjam'
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