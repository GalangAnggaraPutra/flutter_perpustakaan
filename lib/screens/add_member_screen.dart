import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/member_model.dart';

class AddMemberScreen extends StatefulWidget {
  @override
  _AddMemberScreenState createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  String _jenisKelamin = 'L';
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost/flutter_perpustakaan/api/add_member.php'),
        body: {
          'nim': _nimController.text,
          'nama': _namaController.text,
          'alamat': _alamatController.text,
          'jenis_kelamin': _jenisKelamin,
        },
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Anggota berhasil ditambahkan')),
        );
        Navigator.pop(context, true);
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
        title: Text('Tambah Anggota'),
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
                onPressed: _isLoading ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}