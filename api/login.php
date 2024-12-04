<?php
header('Access-Control-Allow-Origin: http://localhost:XXXX');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Access-Control-Allow-Credentials: true');
header('Access-Control-Allow-Headers: Origin, Content-Type, X-Auth-Token');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

include 'connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $email = mysqli_real_escape_string($conn, $_POST['email']);
    $password = $_POST['password']; // Jangan gunakan md5 dulu
    
    // Debug: Cetak nilai yang diterima
    error_log("Email: " . $email);
    error_log("Password: " . $password);

    // Tambahkan validasi input
    if (empty($_POST['email']) || empty($_POST['password'])) {
        echo json_encode([
            'status' => 'error',
            'message' => 'Email dan password harus diisi'
        ]);
        exit;
    }

    // Gunakan prepared statement
    $stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);

    // Query tanpa password untuk mengecek email
    $query = "SELECT * FROM users WHERE email='$email'";
    $result = mysqli_query($conn, $query);
    
    if (mysqli_num_rows($result) > 0) {
        $user = mysqli_fetch_assoc($result);
        // Debug: Cetak password dari database
        error_log("Password dari DB: " . $user['password']);
        
        // Bandingkan password
        if (md5($password) === $user['password']) {
            $response = array(
                'status' => 'success',
                'message' => 'Login berhasil',
                'data' => array(
                    'id' => $user['id'],
                    'email' => $user['email'],
                    'nama' => $user['nama']
                )
            );
        } else {
            $response = array(
                'status' => 'error',
                'message' => 'Password salah'
            );
        }
    } else {
        $response = array(
            'status' => 'error',
            'message' => 'Email tidak ditemukan'
        );
    }
    
    echo json_encode($response);
}

mysqli_close($conn);
?>