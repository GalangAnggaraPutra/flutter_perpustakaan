class Constants {
  static const String baseUrl = 'http://localhost/flutter_perpustakaan/api';
  
  // API Endpoints
  static const String getBooksUrl = '$baseUrl/get_book.php';
  static const String getMembers = '$baseUrl/get_members.php';
  static const String addMember = '$baseUrl/add_member.php';
  static const String updateMember = '$baseUrl/update_member.php';
  static const String deleteMember = '$baseUrl/delete_member.php';
  static const String searchMembers = '$baseUrl/get_members.php?search=';
}