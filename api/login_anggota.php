<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, X-Requested-With');

// Handle preflight request
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        $nim = $_POST['nim'];
        $nama = $_POST['nama'];
        
        $query = "SELECT * FROM anggota WHERE nim=? AND nama=?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ss", $nim, $nama);
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($result->num_rows > 0) {
            $anggota = $result->fetch_assoc();
            echo json_encode([
                'status' => 'success',
                'message' => 'Login berhasil',
                'data' => [
                    'id' => (int)$anggota['id'],
                    'nim' => $anggota['nim'],
                    'nama' => $anggota['nama']
                ]
            ]);
        } else {
            echo json_encode([
                'status' => 'error',
                'message' => 'NIM atau Nama tidak valid'
            ]);
        }
    } catch (Exception $e) {
        echo json_encode([
            'status' => 'error',
            'message' => $e->getMessage()
        ]);
    }
}

$stmt->close();
$conn->close();
?> 