<?php
include 'connection.php';

if ($conn) {
    echo "Koneksi database berhasil!";
    
    // Test query
    $query = "SELECT * FROM users";
    $result = mysqli_query($conn, $query);
    
    if ($result) {
        echo "<br>Jumlah user: " . mysqli_num_rows($result);
        while ($row = mysqli_fetch_assoc($result)) {
            echo "<br>User: " . $row['email'];
        }
    } else {
        echo "<br>Error query: " . mysqli_error($conn);
    }
} else {
    echo "Koneksi database gagal!";
}
?>

