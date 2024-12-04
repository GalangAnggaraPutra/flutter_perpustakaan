import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/book_model.dart';
import 'dart:async';
import '../utils/date_formatter.dart';
import '../services/api_service.dart';
import '../utils/logger.dart'; // Assume we've created a custom logger

class BookDetailScreen extends StatefulWidget {
  final Book book;
  final int anggotaId;

  const BookDetailScreen({
    Key? key, 
    required this.book,
    required this.anggotaId,
  }) : super(key: key);

  @override
  _BookDetailScreenState createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  // Constants
  static const int _maxRetries = 3;
  static const Duration _timeoutDuration = Duration(seconds: 30);
  static const String _baseUrl = 'http://localhost/flutter_perpustakaan/api';

  // State variables
  late Book _currentBook;
  bool _isLoading = false;
  final _tanggalPinjamController = TextEditingController();
  final _tanggalKembaliController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _updateBookStatus();
  }

  // Tambahkan fungsi untuk update status
  Future<void> _updateBookStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/flutter_perpustakaan/api/check_book.php?book_id=${_currentBook.id}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _currentBook = _currentBook.copyWith(
              isDipinjam: data['status'] == 'dipinjam',
              tanggalPinjam: data['tanggal_pinjam'],
              tanggalKembali: data['tanggal_kembali'],
            );
          });
        }
      }
    } catch (e) {
      print('Error updating book status: $e');
    }
  }

  // Fungsi untuk peminjaman buku
  Future<void> _pinjamBuku() async {
    try {
      _showLoadingDialog();
      
      final response = await http.post(
        Uri.parse('http://localhost/flutter_perpustakaan/api/borrow_book.php'),
        body: {
          'buku_id': _currentBook.id.toString(),
          'anggota_id': widget.anggotaId.toString(),
          'tanggal_pinjam': _tanggalPinjamController.text,
          'tanggal_kembali': _tanggalKembaliController.text,
        },
      ).timeout(Duration(seconds: 10));

      _dismissLoadingDialog();

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        await _updateBookStatus();
        _showSuccessMessage('Buku berhasil dipinjam');
        Navigator.pop(context, _currentBook);
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      _dismissLoadingDialog();
      _showErrorSnackBar('Error: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  // Fungsi untuk pengembalian buku
  Future<void> _kembalikanBuku() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost/flutter_perpustakaan/api/return_book.php'),
        body: {
          'buku_id': _currentBook.id.toString(),
          'anggota_id': widget.anggotaId.toString(),
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        // Tampilkan informasi denda jika ada
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
                  onPressed: () => Navigator.pop(context),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }

        await _updateBookStatus();
        _showSuccessMessage('Buku berhasil dikembalikan');
        Navigator.pop(context, _currentBook);
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  void _showPinjamDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pinjam Buku'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _tanggalPinjamController,
              decoration: InputDecoration(
                labelText: 'Tanggal Pinjam',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, true),
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tanggalKembaliController,
              decoration: InputDecoration(
                labelText: 'Tanggal Kembali',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, false),
                ),
              ),
              readOnly: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pinjamBuku();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: const Text('Pinjam'),
          ),
        ],
      ),
    );
  }

  // Helper methods for UI and navigation
  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
  }

  void _dismissLoadingDialog() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPinjam) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        if (isPinjam) {
          _tanggalPinjamController.text = DateFormat('yyyy-MM-dd').format(picked);
          _tanggalKembaliController.text = DateFormat('yyyy-MM-dd')
              .format(picked.add(const Duration(days: 7)));
        } else {
          _tanggalKembaliController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Buku'),
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _currentBook);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookImage(),
            const SizedBox(height: 20),
            _buildBookStatusBadge(),
            const SizedBox(height: 20),
            _buildBookDetails(),
            const SizedBox(height: 20),
            _buildActionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookImage() {
    return Center(
      child: Hero(
        tag: 'book-${_currentBook.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _currentBook.image,
            width: 200,
            height: 300,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 200,
                height: 300,
                color: Colors.grey[300],
                child: const Icon(Icons.book, size: 50),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBookStatusBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _currentBook.isDipinjam ? Colors.red[50] : Colors.green[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _currentBook.isDipinjam ? Colors.red : Colors.green,
          ),
        ),
        child: Text(
          _currentBook.isDipinjam ? 'Dipinjam' : 'Tersedia',
          style: TextStyle(
            color: _currentBook.isDipinjam ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildBookDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Judul: ${_currentBook.judul}',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          'Pengarang: ${_currentBook.pengarang}',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          'Penerbit: ${_currentBook.penerbit}',
          style: TextStyle(fontSize: 16),
        ),
        Text(
          'Tahun Terbit: ${_currentBook.tahunTerbit}',
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 16),
        
        // Tambahkan informasi tanggal pinjam dan kembali
        if (_currentBook.isDipinjam) ...[
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Peminjaman:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal Pinjam:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _currentBook.tanggalPinjam != null
                                ? DateFormatter.formatDate(_currentBook.tanggalPinjam!)
                                : '-',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tanggal Kembali:',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _currentBook.tanggalKembali != null
                                ? DateFormatter.formatDate(_currentBook.tanggalKembali!)
                                : '-',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton() {
    return Center(
      child: _currentBook.isDipinjam
          ? ElevatedButton(
              onPressed: _kembalikanBuku,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(200, 45),
              ),
              child: const Text('Kembalikan Buku'),
            )
          : ElevatedButton(
              onPressed: _showPinjamDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(200, 45),
              ),
              child: const Text('Pinjam Buku'),
            ),
    );
  }

  @override
  void dispose() {
    _tanggalPinjamController.dispose();
    _tanggalKembaliController.dispose();
    super.dispose();
  }
}