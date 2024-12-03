import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/book_model.dart';
import '../utils/constants.dart';

class ApiService {
  static const baseUrl = kDebugMode 
    ? 'http://localhost/flutter_perpustakaan/api'
    : 'https://your-production-domain.com/api';
    
  static Future<Map<String, dynamic>> fetchStatistics() async {
    try {
      // Get total anggota
      final membersResponse = await http.get(
        Uri.parse('$baseUrl/get_members.php'),
      ).timeout(const Duration(seconds: 10));

      print('Members Response: ${membersResponse.body}');

      if (membersResponse.statusCode == 200) {
        final membersData = json.decode(membersResponse.body);
        
        if (membersData['status'] == 'success') {
          final totalAnggota = membersData['data']?.length ?? 0;
          
          return {
            'total_anggota': totalAnggota,
            'total_buku': 0,
            'total_tersedia': 0,
            'total_dipinjam': 0,
            'total_dikembalikan': 0,
            'total_denda': 0.0
          };
        } else {
          throw Exception(membersData['message'] ?? 'Failed to load members data');
        }
      } else {
        throw Exception('Server error: ${membersResponse.statusCode}');
      }
    } catch (e) {
      print('Error in fetchStatistics: $e');
      rethrow;
    }
  }
}