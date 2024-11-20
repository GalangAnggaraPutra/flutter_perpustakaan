import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'add_book_screen.dart';
import 'add_member_screen.dart';
import '../models/book_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> books = [];
  int currentPage = 1;
  int totalPages = 1;
  bool isLoading = true;
  final int booksPerPage = 3;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/flutter_perpustakaan/api/get_books.php?page=$currentPage&per_page=$booksPerPage&search=$searchQuery'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          books = (data['books'] as List)
              .map((book) => Book.fromJson(book))
              .toList();
          totalPages = data['total_pages'];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header (tidak berubah)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, G',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Mau Pinjam Buku\nApa Hari ini?',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, color: Colors.grey[600]),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Search Bar dengan fungsi pencarian
              TextField(
                onChanged: (value) {
                  searchQuery = value;
                  currentPage = 1;
                  fetchBooks();
                },
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 20),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Daftar Buku dari Database
              Expanded(
                child: isLoading 
                  ? Center(child: CircularProgressIndicator())
                  : books.isEmpty
                    ? Center(child: Text('Tidak ada buku'))
                    : ListView.builder(
                        itemCount: books.length,
                        itemBuilder: (context, index) {
                          final book = books[index];
                          return _buildBookCard(
                            book.judul,
                            book.pengarang,
                            4.0, // Bisa ditambahkan field rating di database
                            'assets/images/${book.image}',
                            ['Novel'], // Bisa ditambahkan field kategori di database
                          );
                        },
                      ),
              ),
              
              // Pagination yang dinamis
              if (!isLoading && books.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 1; i <= totalPages; i++)
                        if (i == 1 || i == totalPages || 
                            (i >= currentPage - 1 && i <= currentPage + 1))
                          _buildPageNumber('$i', i == currentPage)
                        else if (i == currentPage - 2 || i == currentPage + 2)
                          Text('...'),
                    ],
                  ),
                ),
              
              // Tombol tambah buku dan anggota
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.book_online),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddBookScreen()),
                      );
                      if (result == true) {
                        fetchBooks();
                      }
                    },
                    tooltip: 'Tambah Buku',
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    icon: Icon(Icons.person_add),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddMemberScreen()),
                      );
                    },
                    tooltip: 'Tambah Anggota',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildBookCard tetap sama
  Widget _buildBookCard(String title, String author, double rating, String imageUrl, List<String> tags) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageUrl,
                width: 80,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 120,
                    color: Colors.grey[300],
                    child: Icon(Icons.book),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    author,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < rating.floor() ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                      SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: tags.map((tag) => Container(
                      margin: EdgeInsets.only(right: 8),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(fontSize: 12),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageNumber(String number, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          setState(() {
            currentPage = int.parse(number);
            isLoading = true;
          });
          fetchBooks();
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          number,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}