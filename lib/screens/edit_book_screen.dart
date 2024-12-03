import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book_model.dart';

class EditBookScreen extends StatefulWidget {
  final Book book;

  EditBookScreen({required this.book});

  @override
  _EditBookScreenState createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _pengarangController;
  late TextEditingController _penerbitController;
  late TextEditingController _tahunTerbitController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.book.judul);
    _pengarangController = TextEditingController(text: widget.book.pengarang);
    _penerbitController = TextEditingController(text: widget.book.penerbit);
    _tahunTerbitController = TextEditingController(text: widget.book.tahunTerbit.toString());
  }

  Future<void> _updateBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://localhost/flutter_perpustakaan/api/update_book.php'),
        body: {
          'id': widget.book.id.toString(),
          'judul': _judulController.text,
          'pengarang': _pengarangController.text,
          'penerbit': _penerbitController.text,
          'tahun_terbit': _tahunTerbitController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Buku berhasil diupdate')),
          );
        } else {
          throw Exception(data['message']);
        }
      } else {
        throw Exception('Failed to update book');
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
        title: Text('Edit Buku'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _judulController,
                decoration: InputDecoration(labelText: 'Judul'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _pengarangController,
                decoration: InputDecoration(labelText: 'Pengarang'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Pengarang tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _penerbitController,
                decoration: InputDecoration(labelText: 'Penerbit'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Penerbit tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _tahunTerbitController,
                decoration: InputDecoration(labelText: 'Tahun Terbit'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tahun terbit tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Tahun terbit harus berupa angka';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updateBook,
                child: _isLoading
                    ? CircularProgressIndicator()
                    : Text('Update Buku'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 48),
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
    _judulController.dispose();
    _pengarangController.dispose();
    _penerbitController.dispose();
    _tahunTerbitController.dispose();
    super.dispose();
  }
}