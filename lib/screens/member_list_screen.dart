import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/member_model.dart';
import '../utils/constants.dart';
import 'add_member_screen.dart';
import 'edit_member_screen.dart';

class MemberListScreen extends StatefulWidget {
  @override
  _MemberListScreenState createState() => _MemberListScreenState();
}

class _MemberListScreenState extends State<MemberListScreen> {
  List<Member> members = [];
  bool isLoading = true;
  String searchQuery = '';
  int totalMembers = 0;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      setState(() => isLoading = true);
      
      final response = await http.get(
        Uri.parse('${Constants.baseUrl}/get_members.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            members = (data['data'] as List)
                .map((member) => Member.fromJson(member))
                .toList();
            isLoading = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load members');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching members: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data anggota: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMember(Member member) async {
    try {
      // Tampilkan dialog konfirmasi
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Konfirmasi'),
          content: Text('Yakin ingin menghapus anggota ${member.nama}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Hapus'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;

      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/delete_member.php'),
        body: {'id': member.id.toString()},
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anggota berhasil dihapus')),
        );
        fetchMembers();
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
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
        title: Text('Daftar Anggota'),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Counter Card
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Anggota',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${members.length}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.people,
                    size: 40,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          // Search Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) {
                searchQuery = value;
                fetchMembers();
              },
              decoration: InputDecoration(
                hintText: 'Cari anggota...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 8),
          
          // Info Text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  'Menampilkan ${members.length} anggota',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 8),
          
          // Member List
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : members.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Belum ada anggota',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(member.nama[0].toUpperCase()),
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              title: Text(member.nama),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('NIM: ${member.nim}'),
                                  Text('Alamat: ${member.alamat}'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditMemberScreen(member: member),
                                        ),
                                      ).then((value) {
                                        if (value == true) {
                                          fetchMembers();
                                        }
                                      });
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteMember(member),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddMemberScreen(),
            ),
          ).then((_) => fetchMembers());
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.black,
      ),
    );
  }
} 