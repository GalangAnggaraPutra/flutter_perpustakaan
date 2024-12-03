import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book_model.dart';
import 'book_detail_screen.dart';
import 'borrow_history_screen.dart';
import '../utils/constants.dart';

class HomeScreenAnggota extends StatefulWidget {
  final int anggotaId;
  final String nama;

  HomeScreenAnggota({required this.anggotaId, required this.nama});

  @override
  _HomeScreenAnggotaState createState() => _HomeScreenAnggotaState();
}

class _HomeScreenAnggotaState extends State<HomeScreenAnggota> {
  List<Book> books = [];
  bool isLoading = true;
  String searchQuery = '';
  int currentPage = 1;
  int totalPages = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchBooks();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      if (currentPage < totalPages) {
        currentPage++;
        fetchBooks(isLoadMore: true);
      }
    }
  }

  Future<void> fetchBooks({bool isLoadMore = false}) async {
    try {
      final response = await http.get(
        Uri.parse(
          '${Constants.getBooksUrl}?page=$currentPage&search=$searchQuery'
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final newBooks = (data['books'] as List)
              .map((book) => Book.fromJson(book))
              .toList();

          setState(() {
            if (isLoadMore) {
              books.addAll(newBooks);
            } else {
              books = newBooks;
            }
            totalPages = data['total_pages'];
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _refreshBooks() async {
    setState(() {
      currentPage = 1;
      searchQuery = '';
    });
    await fetchBooks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perpustakaan'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BorrowHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBooks,
        child: Column(
          children: [
            // Header dengan nama anggota
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat datang,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        widget.nama,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Search bar
            Padding(
              padding: EdgeInsets.all(16),
              child: TextField(
                onChanged: (value) {
                  searchQuery = value;
                  currentPage = 1;
                  fetchBooks();
                },
                decoration: InputDecoration(
                  hintText: 'Cari buku...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

            // Daftar buku
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : books.isEmpty
                      ? Center(child: Text('Tidak ada buku'))
                      : ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.all(16),
                          itemCount: books.length + (currentPage < totalPages ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == books.length) {
                              return Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            final book = books[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 16),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    book.image,
                                    width: 50,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 50,
                                        height: 70,
                                        color: Colors.grey[300],
                                        child: Icon(Icons.book),
                                      );
                                    },
                                  ),
                                ),
                                title: Text(
                                  book.judul,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(book.pengarang),
                                trailing: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: book.isDipinjam
                                        ? Colors.red[50]
                                        : Colors.green[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: book.isDipinjam
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                  child: Text(
                                    book.isDipinjam ? 'Dipinjam' : 'Tersedia',
                                    style: TextStyle(
                                      color: book.isDipinjam
                                          ? Colors.red
                                          : Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BookDetailScreen(book: book),
                                    ),
                                  ).then((value) {
                                    if (value == true) {
                                      _refreshBooks();
                                    }
                                  });
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
} 