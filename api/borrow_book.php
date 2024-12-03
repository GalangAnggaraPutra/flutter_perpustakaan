<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        // Debug: Print received data
        error_log("Received POST data: " . print_r($_POST, true));

        // Validasi input
        if (!isset($_POST['buku_id']) || !isset($_POST['tanggal_pinjam']) || 
            !isset($_POST['tanggal_kembali']) || !isset($_POST['anggota_id'])) {
            throw new Exception('Data tidak lengkap');
        }

        $buku_id = $_POST['buku_id'];
        $anggota_id = $_POST['anggota_id'];
        $tanggal_pinjam = $_POST['tanggal_pinjam'];
        $tanggal_kembali = $_POST['tanggal_kembali'];

        // Check if book exists and is available
        $check_book = "SELECT id FROM buku WHERE id = ? AND NOT EXISTS (
            SELECT 1 FROM peminjaman 
            WHERE buku_id = buku.id AND status = 'dipinjam'
        )";
        
        $stmt = $conn->prepare($check_book);
        $stmt->bind_param("i", $buku_id);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows === 0) {
            throw new Exception('Buku tidak tersedia atau sudah dipinjam');
        }

        // Insert peminjaman
        $query = "INSERT INTO peminjaman (buku_id, anggota_id, tanggal_pinjam, tanggal_kembali, status) 
                 VALUES (?, ?, ?, ?, 'dipinjam')";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("iiss", $buku_id, $anggota_id, $tanggal_pinjam, $tanggal_kembali);
        
        if ($stmt->execute()) {
            $response = [
                'status' => 'success',
                'message' => 'Buku berhasil dipinjam',
                'data' => [
                    'id' => $conn->insert_id,
                    'buku_id' => $buku_id,
                    'tanggal_pinjam' => $tanggal_pinjam,
                    'tanggal_kembali' => $tanggal_kembali,
                    'status' => 'dipinjam'
                ]
            ];
        } else {
            throw new Exception($stmt->error);
        }

    } catch (Exception $e) {
        $response = [
            'status' => 'error',
            'message' => $e->getMessage()
        ];
    }

    echo json_encode($response);

    if (isset($stmt)) $stmt->close();
    $conn->close();
}
?>