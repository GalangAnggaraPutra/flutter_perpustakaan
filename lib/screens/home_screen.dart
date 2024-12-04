import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'add_book_screen.dart';
import 'add_member_screen.dart';
import 'borrow_history_screen.dart';
import '../models/book_model.dart';
import 'book_detail_screen.dart';
import 'edit_book_screen.dart';
import '../utils/date_formatter.dart';
import '../utils/constants.dart';
import 'member_list_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Book> books = [];
  int totalMembers = 0;
  int currentPage = 1;
  int totalPages = 1;
  int totalBooks = 0;
  bool isLoading = true;
  final int booksPerPage = 3;
  String searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final _tanggalPinjamController = TextEditingController();
  final _tanggalKembaliController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchBooks();
    fetchMemberCount();
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
    if (!isLoadMore) setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(
          'http://localhost/flutter_perpustakaan/api/get_book.php?page=$currentPage&per_page=$booksPerPage&search=$searchQuery'
        ),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'error') {
          throw Exception(data['message']);
        }

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
          totalBooks = data['total_books'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load books');
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshBooks() async {
    setState(() {
      currentPage = 1;
      books.clear(); // Bersihkan daftar buku yang ada
    });
    await fetchBooks();
  }

  Future<void> _deleteBook(int bookId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final response = await http.post(
        Uri.parse('http://localhost/flutter_perpustakaan/api/delete_book.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {'id': bookId.toString()},
      ).timeout(Duration(seconds: 10));

      Navigator.pop(context); // Tutup loading

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Buku berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshBooks();
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      Navigator.pop(context); // Tutup loading jika error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteConfirmation(Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Buku'),
        content: Text('Apakah Anda yakin ingin menghapus buku "${book.judul}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteBook(book.id);
            },
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _pinjamBuku(int bookId) async {
    try {
      // Inisialisasi tanggal default
      _tanggalPinjamController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _tanggalKembaliController.text = DateFormat('yyyy-MM-dd')
          .format(DateTime.now().add(Duration(days: 7)));

      // Tampilkan dialog pemilihan tanggal
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Konfirmasi Peminjaman'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _tanggalPinjamController,
                decoration: InputDecoration(
                  labelText: 'Tanggal Pinjam',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, true),
                  ),
                ),
                readOnly: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _tanggalKembaliController,
                decoration: InputDecoration(
                  labelText: 'Tanggal Kembali',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () => _selectDate(context, false),
                  ),
                ),
                readOnly: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Pinjam'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Tampilkan loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // Lakukan peminjaman
      final response = await http.post(
        Uri.parse('http://localhost/flutter_perpustakaan/api/borrow_book.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'buku_id': bookId.toString(),
          'anggota_id': '1',
          'tanggal_pinjam': _tanggalPinjamController.text,
          'tanggal_kembali': _tanggalKembaliController.text,
        },
      );

      // Tutup loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          // Tunggu sebentar sebelum refresh untuk memastikan database terupdate
          await Future.delayed(Duration(milliseconds: 500));
          
          // Reset halaman dan refresh data
          setState(() {
            currentPage = 1;
            books.clear();
          });
          
          await fetchBooks();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Buku berhasil dipinjam'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          throw Exception(data['message'] ?? 'Gagal meminjam buku');
        }
      } else {
        throw Exception('Gagal meminjam buku: ${response.statusCode}');
      }
    } catch (e) {
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _kembalikanBuku(int bookId) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      final response = await http.post(
        Uri.parse('http://localhost/flutter_perpustakaan/api/return_book.php'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'buku_id': bookId.toString(),
          'anggota_id': '1', // Ganti dengan ID anggota yang sedang login
        },
      );

      Navigator.pop(context); // Tutup dialog loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          if (data['data'] != null && data['data']['denda'] > 0) {
            await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Informasi Pengembalian'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Keterlambatan: ${data['data']['terlambat']} hari'),
                    Text('Denda: Rp ${data['data']['denda']}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _refreshBooks();
                    },
                    child: Text('OK'),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Buku berhasil dikembalikan'),
                backgroundColor: Colors.green,
              ),
            );
            await _refreshBooks();
          }
        } else {
          throw Exception(data['message'] ?? 'Gagal mengembalikan buku');
        }
      } else {
        throw Exception('Gagal mengembalikan buku: ${response.statusCode}');
      }
    } catch (e) {
      Navigator.pop(context); // Tutup dialog loading jika error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> fetchMemberCount() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/flutter_perpustakaan/api/get_members.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            totalMembers = (data['data'] as List).length;
          });
        }
      }
    } catch (e) {
      print('Error fetching member count: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPinjam) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
      locale: const Locale('id', 'ID'), // Untuk format tanggal Indonesia
    );

    if (picked != null) {
      setState(() {
        if (isPinjam) {
          _tanggalPinjamController.text = DateFormat('yyyy-MM-dd').format(picked);
          // Update tanggal kembali otomatis 7 hari setelah tanggal pinjam
          _tanggalKembaliController.text = DateFormat('yyyy-MM-dd')
              .format(picked.add(Duration(days: 7)));
        } else {
          // Validasi tanggal kembali tidak boleh kurang dari tanggal pinjam
          final tanggalPinjam = DateTime.parse(_tanggalPinjamController.text);
          if (picked.isBefore(tanggalPinjam)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Tanggal kembali tidak boleh kurang dari tanggal pinjam'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          _tanggalKembaliController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, Admin',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Selamat Datang di\nSistem Perpustakaan',
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

              // Tambahkan card statistik setelah header
              Container(
                margin: EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.people, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Total Anggota',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                '$totalMembers',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Bisa tambahkan statistik lain di sini
                  ],
                ),
              ),

              // Search Bar
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
                ),
              ),
              
              SizedBox(height: 20),

              // Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddBookScreen(),
                          ),
                        ).then((_) => _refreshBooks());
                      },
                      icon: Icon(Icons.add),
                      label: Text('Tambah Buku'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddMemberScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.person_add),
                      label: Text('Tambah Anggota'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BorrowHistoryScreen(),
                          ),
                        );
                      },
                      icon: Icon(Icons.history),
                      label: Text('Riwayat'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // Book List
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        controller: _scrollController,
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
                          return _buildBookCard(book);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      
      // Floating Action Button untuk mengelola anggota
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MemberListScreen(),
            ),
          );
        },
        child: Icon(Icons.people),
        backgroundColor: Colors.white,
      ),
    );
  }

  Widget _buildBookCard(Book book) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () async {
          final updatedBook = await Navigator.push<Book>(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: book),
            ),
          );
          
          if (updatedBook != null) {
            setState(() {
              final index = books.indexWhere((b) => b.id == updatedBook.id);
              if (index != -1) {
                books[index] = updatedBook;
              }
            });
          }
        },
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Book Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.image,
                  width: 80,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 120,
                      color: Colors.grey[300],
                      child: Icon(Icons.book, size: 30),
                    );
                  },
                ),
              ),
              SizedBox(width: 12),
              
              // Book Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.judul,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      book.pengarang,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: book.isDipinjam ? Colors.red[50] : Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: book.isDipinjam ? Colors.red : Colors.green,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            book.isDipinjam ? 'Dipinjam' : 'Tersedia',
                            style: TextStyle(
                              color: book.isDipinjam ? Colors.red : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue, size: 20),
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditBookScreen(book: book),
                              ),
                            );
                            if (result == true) {
                              _refreshBooks();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: () => _showDeleteConfirmation(book),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookDetailScreen(book: book),
                            ),
                          ).then((value) {
                            if (value == true) {
                              _refreshBooks();
                            }
                          }),
                          child: Text('Detail'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            textStyle: TextStyle(fontSize: 12),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tanggalPinjamController.dispose();
    _tanggalKembaliController.dispose();
    super.dispose();
  }
}