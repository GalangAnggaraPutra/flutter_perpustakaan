import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book_model.dart';
import '../utils/date_formatter.dart';
import 'package:intl/intl.dart';

class BorrowHistoryScreen extends StatefulWidget {
  @override
  _BorrowHistoryScreenState createState() => _BorrowHistoryScreenState();
}

class _BorrowHistoryScreenState extends State<BorrowHistoryScreen> {
  List<Map<String, dynamic>> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost/flutter_perpustakaan/api/get_borrow_history.php'),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            // Pastikan data tidak null sebelum dikonversi
            history = (data['data'] as List?)?.map((item) => {
              'id': item['id'] ?? 0,
              'judul': item['judul'] ?? '',
              'image': item['image'] ?? '',
              'nama_peminjam': item['nama_peminjam'] ?? '',
              'nim': item['nim'] ?? '',
              'tanggal_pinjam': item['tanggal_pinjam'] ?? '',
              'tanggal_kembali': item['tanggal_kembali'] ?? '',
              'tanggal_dikembalikan': item['tanggal_dikembalikan'],
              'terlambat': item['terlambat'] ?? 0,
              'denda': item['denda'] ?? 0,
              'status': item['status'] ?? ''
            }).toList() ?? [];
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load history');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e'); // Debug
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Peminjaman'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? Center(child: Text('Tidak ada riwayat peminjaman'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final item = history[index];
                    return _buildBookCard(item);
                  },
                ),
    );
  }

  Widget _buildBookCard(Map<String, dynamic> item) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gambar buku
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['image'] ?? '',
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
                SizedBox(width: 16),
                
                // Detail buku dan peminjam
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['judul'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text('Peminjam: ${item['nama_peminjam'] ?? ''}'),
                      Text('NIM: ${item['nim'] ?? ''}'),
                      SizedBox(height: 8),
                      // Status peminjaman
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item['status'] == 'dipinjam' 
                              ? Colors.orange[50] 
                              : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: item['status'] == 'dipinjam' 
                                ? Colors.orange 
                                : Colors.green,
                          ),
                        ),
                        child: Text(
                          item['status'] == 'dipinjam' ? 'Dipinjam' : 'Dikembalikan',
                          style: TextStyle(
                            color: item['status'] == 'dipinjam' 
                                ? Colors.orange 
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            
            // Informasi tanggal
            Column(
              children: [
                _buildDateInfo('Tanggal Pinjam', item['tanggal_pinjam'] ?? ''),
                _buildDateInfo('Batas Kembali', item['tanggal_kembali'] ?? ''),
                if (item['tanggal_dikembalikan'] != null) ...[
                  _buildDateInfo('Dikembalikan', item['tanggal_dikembalikan']),
                  // Informasi keterlambatan dan denda
                  if (item['terlambat'] > 0) ...[
                    SizedBox(height: 8),
                    Text(
                      'Terlambat: ${item['terlambat']} hari',
                      style: TextStyle(color: Colors.red),
                    ),
                    Text(
                      'Denda: Rp ${NumberFormat('#,###').format(item['denda'])}',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateInfo(String label, String date) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(': ${DateFormatter.formatDate(date)}'),
        ],
      ),
    );
  }
}