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
  
  const BookDetailScreen({Key? key, required this.book}) : super(key: key);

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
    _initializeBookDetails();
  }

  // Consolidated initialization method
  void _initializeBookDetails() {
    _initializeDates();
    _loadBookStatus();
  }

  void _initializeDates() {
    final now = DateTime.now();
    _tanggalPinjamController.text = DateFormat('yyyy-MM-dd').format(now);
    _tanggalKembaliController.text = DateFormat('yyyy-MM-dd')
        .format(now.add(const Duration(days: 7)));
  }

  // Improved error handling for network requests
  Future<dynamic> _safeApiCall(Future<http.Response> Function() apiCall) async {
    for (int attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await apiCall().timeout(_timeoutDuration);
        
        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
        
        // Log non-200 responses
        Logger.error('API call failed with status code: ${response.statusCode}');
        throw Exception('Server error');
      } on TimeoutException {
        _showErrorSnackBar('Koneksi timeout. Silakan coba lagi.');
        if (attempt == _maxRetries - 1) rethrow;
      } on http.ClientException catch (e) {
        Logger.error('Network error: $e');
        _showErrorSnackBar('Kesalahan jaringan. Silakan periksa koneksi.');
        if (attempt == _maxRetries - 1) rethrow;
      } catch (e) {
        Logger.error('Unexpected error: $e');
        _showErrorSnackBar('Terjadi kesalahan tidak terduga');
        if (attempt == _maxRetries - 1) rethrow;
      }
      
      // Wait before retrying
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  Future<void> _loadBookStatus() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final data = await _safeApiCall(() => http.get(
        Uri.parse('$_baseUrl/check_book.php?book_id=${widget.book.id}')
      ));

      setState(() {
        _currentBook = _currentBook.copyWith(
          isDipinjam: data['status'] == 'dipinjam'
        );
      });
    } catch (e) {
      Logger.error('Error loading book status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pinjamBuku() async {
    try {
      if (!mounted) return;

      _showLoadingDialog();

      final data = await _safeApiCall(() => http.post(
        Uri.parse('$_baseUrl/borrow_book.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'buku_id': _currentBook.id.toString(),
          'anggota_id': '1',
          'tanggal_pinjam': _tanggalPinjamController.text,
          'tanggal_kembali': _tanggalKembaliController.text,
        },
      ));

      _dismissLoadingDialog();

      if (data['status'] == 'success') {
        _updateBookAfterBorrowing();
        _showSuccessMessage('Buku berhasil dipinjam');
      } else {
        _showErrorSnackBar('Gagal meminjam buku: ${data['message']}');
      }
    } catch (e) {
      _dismissLoadingDialog();
      _showErrorSnackBar('Error: ${e.toString()}');
      Logger.error('Error in _pinjamBuku: $e');
    }
  }

  Future<void> _kembalikanBuku() async {
    if (!mounted) return;

    try {
      _showLoadingDialog();

      final data = await _safeApiCall(() => http.post(
        Uri.parse('$_baseUrl/return_book.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'buku_id': _currentBook.id.toString(),
        },
      ));

      _dismissLoadingDialog();

      if (data['status'] == 'success') {
        _handleSuccessfulReturn(data);
      } else {
        _showErrorSnackBar('Gagal mengembalikan buku: ${data['message']}');
      }
    } catch (e) {
      _dismissLoadingDialog();
      _showErrorSnackBar('Error: ${e.toString()}');
      Logger.error('Error in _kembalikanBuku: $e');
    }
  }

  void _handleSuccessfulReturn(Map<String, dynamic> data) {
    setState(() {
      _currentBook = _currentBook.copyWith(
        isDipinjam: false,
        tanggalPinjam: null,
        tanggalKembali: null,
      );
    });

    if (data['data'] != null && data['data']['denda'] > 0) {
      _showFineDialog(data['data']);
    } else {
      _showSuccessMessage('Buku berhasil dikembalikan');
    }
  }

  Future<void> _showFineDialog(Map<String, dynamic> fineData) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Informasi Pengembalian'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Keterlambatan: ${fineData['terlambat']} hari'),
            Text('Denda: Rp ${fineData['denda']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      builder: (context) => const Center(child: CircularProgressIndicator()),
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

  void _updateBookAfterBorrowing() {
    setState(() {
      _currentBook = _currentBook.copyWith(
        isDipinjam: true,
        tanggalPinjam: _tanggalPinjamController.text,
        tanggalKembali: _tanggalKembaliController.text,
      );
    });
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
        backgroundColor: Colors.white,
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
          _currentBook.judul,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        _buildDetailRow('Pengarang', _currentBook.pengarang),
        _buildDetailRow('Penerbit', _currentBook.penerbit),
        _buildDetailRow('Tahun Terbit', _currentBook.tahunTerbit),
        if (_currentBook.isDipinjam) ...[
          _buildDetailRow(
            'Tanggal Pinjam',
            DateFormatter.formatDate(_currentBook.tanggalPinjam ?? ''),
          ),
          _buildDetailRow(
            'Tanggal Kembali',
            DateFormatter.formatDate(_currentBook.tanggalKembali ?? ''),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
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