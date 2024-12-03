<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json; charset=utf-8');

include 'connection.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    try {
        // Validasi input
        if (!isset($_POST['judul']) || !isset($_POST['pengarang']) || 
            !isset($_POST['penerbit']) || !isset($_POST['tahun_terbit'])) {
            throw new Exception('Data tidak lengkap');
        }

        // Sanitasi input
        $judul = htmlspecialchars(trim($_POST['judul']));
        $pengarang = htmlspecialchars(trim($_POST['pengarang']));
        $penerbit = htmlspecialchars(trim($_POST['penerbit']));
        $tahun_terbit = htmlspecialchars(trim($_POST['tahun_terbit']));
        $image = isset($_POST['image']) ? htmlspecialchars(trim($_POST['image'])) : 'default_book.jpg';

        // Query untuk insert data
        $query = "INSERT INTO buku (judul, pengarang, penerbit, tahun_terbit, image) 
                 VALUES (?, ?, ?, ?, ?)";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("sssss", $judul, $pengarang, $penerbit, $tahun_terbit, $image);
        
        if ($stmt->execute()) {
            $response = [
                'status' => 'success',
                'message' => 'Buku berhasil ditambahkan',
                'data' => [
                    'id' => $conn->insert_id,
                    'judul' => $judul,
                    'pengarang' => $pengarang,
                    'penerbit' => $penerbit,
                    'tahun_terbit' => $tahun_terbit,
                    'image' => $image
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

    if (isset($stmt)) {
        $stmt->close();
    }
    $conn->close();
}
?>