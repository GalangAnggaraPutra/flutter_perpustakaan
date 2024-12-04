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
        // Debug: Log received data
        error_log("Received POST data: " . print_r($_POST, true));

        // Validasi input
        if (!isset($_POST['buku_id']) || !isset($_POST['anggota_id']) || 
            !isset($_POST['tanggal_pinjam']) || !isset($_POST['tanggal_kembali'])) {
            throw new Exception('Data tidak lengkap');
        }

        // Sanitasi input
        $buku_id = (int)$_POST['buku_id'];
        $anggota_id = (int)$_POST['anggota_id'];
        $tanggal_pinjam = htmlspecialchars(trim($_POST['tanggal_pinjam']));
        $tanggal_kembali = htmlspecialchars(trim($_POST['tanggal_kembali']));

        // Debug: Log processed data
        error_log("Processing borrow request with data:");
        error_log("Book ID: $buku_id");
        error_log("Member ID: $anggota_id");
        error_log("Borrow Date: $tanggal_pinjam");
        error_log("Return Date: $tanggal_kembali");

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
            error_log("Peminjaman berhasil disimpan. ID: " . $conn->insert_id);
            
            // Update status buku (opsional, jika Anda menyimpan status di tabel buku)
            $update_book = "UPDATE buku SET status = 'dipinjam' WHERE id = ?";
            $stmt_update = $conn->prepare($update_book);
            $stmt_update->bind_param("i", $buku_id);
            $stmt_update->execute();
            
            $response = [
                'status' => 'success',
                'message' => 'Buku berhasil dipinjam',
                'data' => [
                    'id' => $conn->insert_id,
                    'buku_id' => $buku_id,
                    'anggota_id' => $anggota_id,
                    'tanggal_pinjam' => $tanggal_pinjam,
                    'tanggal_kembali' => $tanggal_kembali
                ]
            ];
            error_log("Response: " . json_encode($response));
        } else {
            error_log("Error executing query: " . $stmt->error);
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