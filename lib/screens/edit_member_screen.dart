import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/member_model.dart';
import '../utils/constants.dart';

class EditMemberScreen extends StatefulWidget {
  final Member member;

  EditMemberScreen({required this.member});

  @override
  _EditMemberScreenState createState() => _EditMemberScreenState();
}

class _EditMemberScreenState extends State<EditMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nimController;
  late TextEditingController _namaController;
  late TextEditingController _alamatController;
  String _jenisKelamin = 'L';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nimController = TextEditingController(text: widget.member.nim);
    _namaController = TextEditingController(text: widget.member.nama);
    _alamatController = TextEditingController(text: widget.member.alamat);
    _jenisKelamin = widget.member.jenisKelamin;
  }

  Future<void> _updateMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('${Constants.baseUrl}/update_member.php'),
        body: {
          'id': widget.member.id.toString(),
          'nim': _nimController.text,
          'nama': _namaController.text,
          'alamat': _alamatController.text,
          'jenis_kelamin': _jenisKelamin,
        },
      );

      final data = json.decode(response.body);
      if (data['status'] == 'success') {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anggota berhasil diupdate')),
        );
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Anggota'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nimController,
                decoration: InputDecoration(
                  labelText: 'NIM',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'NIM tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _namaController,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _alamatController,
                decoration: InputDecoration(
                  labelText: 'Alamat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Alamat tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: _jenisKelamin,
                decoration: InputDecoration(
                  labelText: 'Jenis Kelamin',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                  DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                ],
                onChanged: (value) {
                  setState(() {
                    _jenisKelamin = value!;
                  });
                },
              ),
              SizedBox(height: 24),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _updateMember,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nimController.dispose();
    _namaController.dispose();
    _alamatController.dispose();
    super.dispose();
  }
} 