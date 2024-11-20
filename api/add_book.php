<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');

include 'connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $response = array();
    
    // Data buku
    $judul = $_POST['judul'];
    $pengarang = $_POST['pengarang'];
    $penerbit = $_POST['penerbit'];
    $tahun_terbit = $_POST['tahun_terbit'];
    $stok = $_POST['stok'];
    $image = 'default_book.jpg'; // Default image
    
    // Handle image upload
    if(isset($_FILES['image'])) {
        $file = $_FILES['image'];
        $fileName = $file['name'];
        $fileTmp = $file['tmp_name'];
        $fileSize = $file['size'];
        $fileError = $file['error'];
        
        // Get file extension
        $fileExt = strtolower(pathinfo($fileName, PATHINFO_EXTENSION));
        $allowed = array('jpg', 'jpeg', 'png');
        
        if(in_array($fileExt, $allowed)) {
            if($fileError === 0) {
                if($fileSize < 5000000) { // Max 5MB
                    // Generate unique filename
                    $fileNameNew = uniqid('book_', true) . '.' . $fileExt;
                    $fileDestination = '../assets/images/' . $fileNameNew;
                    
                    // Move file
                    if(move_uploaded_file($fileTmp, $fileDestination)) {
                        $image = $fileNameNew;
                    } else {
                        $response = array(
                            'status' => 'error',
                            'message' => 'Gagal memindahkan file'
                        );
                        echo json_encode($response);
                        exit;
                    }
                } else {
                    $response = array(
                        'status' => 'error',
                        'message' => 'Ukuran file terlalu besar (max 5MB)'
                    );
                    echo json_encode($response);
                    exit;
                }
            } else {
                $response = array(
                    'status' => 'error',
                    'message' => 'Error saat upload file'
                );
                echo json_encode($response);
                exit;
            }
        } else {
            $response = array(
                'status' => 'error',
                'message' => 'Tipe file tidak diizinkan (jpg, jpeg, png)'
            );
            echo json_encode($response);
            exit;
        }
    }
    
    // Insert book data to database
    $query = "INSERT INTO buku (judul, pengarang, penerbit, tahun_terbit, image, stok) 
              VALUES (?, ?, ?, ?, ?, ?)";
              
    $stmt = $conn->prepare($query);
    $stmt->bind_param("sssssi", $judul, $pengarang, $penerbit, $tahun_terbit, $image, $stok);
    
    if($stmt->execute()) {
        $response = array(
            'status' => 'success',
            'message' => 'Buku berhasil ditambahkan',
            'data' => array(
                'judul' => $judul,
                'pengarang' => $pengarang,
                'penerbit' => $penerbit,
                'tahun_terbit' => $tahun_terbit,
                'image' => $image,
                'stok' => $stok
            )
        );
    } else {
        $response = array(
            'status' => 'error',
            'message' => 'Gagal menambahkan buku: ' . $conn->error
        );
    }
    
    echo json_encode($response);
}
?>