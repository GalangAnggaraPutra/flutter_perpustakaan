import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book_model.dart';
import '../utils/date_formatter.dart';
import 'package:intl/intl.dart';

class BorrowHistoryScreen extends StatefulWidget {
  final int anggotaId;
  final bool isAdmin;

  const BorrowHistoryScreen({
    Key? key, 
    required this.anggotaId,
    this.isAdmin = false,
  }) : super(key: key);

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
      String url = 'http://localhost/flutter_perpustakaan/api/get_borrow_history.php';
      if (!widget.isAdmin) {
        url += '?anggota_id=${widget.anggotaId}';
      }

      final response = await http.get(
        Uri.parse(url),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            history = List<Map<String, dynamic>>.from(data['data']);
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdmin ? 'Semua Riwayat Peminjaman' : 'Riwayat Peminjaman Saya'),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        widget.isAdmin 
                            ? 'Belum ada riwayat peminjaman'
                            : 'Anda belum memiliki riwayat peminjaman',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: history.length,
                  itemBuilder: (context, index) => _buildBookCard(history[index]),
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
                        item['judul_buku'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      if (widget.isAdmin) ...[
                        Text('Peminjam: ${item['nama_peminjam'] ?? ''}'),
                        Text('NIM: ${item['nim'] ?? ''}'),
                        SizedBox(height: 8),
                      ],
                      
                      // Status Peminjaman
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item['status'] == 'dipinjam' ? Colors.blue[50] : Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: item['status'] == 'dipinjam' ? Colors.blue : Colors.green,
                          ),
                        ),
                        child: Text(
                          item['status_peminjaman'] ?? '',
                          style: TextStyle(
                            color: item['status'] == 'dipinjam' ? Colors.blue : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      
                      // Status Keterlambatan jika ada
                      if (item['status_keterlambatan'].toString().contains('terlambat'))
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Text(
                            item['status_keterlambatan'],
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      // Status Denda jika ada
                      if (item['status_denda'].toString() != 'Tidak ada denda')
                        Container(
                          margin: EdgeInsets.only(top: 4),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange),
                          ),
                          child: Text(
                            item['status_denda'],
                            style: TextStyle(
                              color: Colors.orange[800],
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
                if (item['tanggal_dikembalikan'] != null)
                  _buildDateInfo('Dikembalikan', item['tanggal_dikembalikan']),
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