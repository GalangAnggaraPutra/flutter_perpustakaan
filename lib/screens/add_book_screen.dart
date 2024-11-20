import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/book_model.dart';

class AddBookScreen extends StatefulWidget {
  @override
  _AddBookScreenState createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _pengarangController = TextEditingController();
  final _penerbitController = TextEditingController();
  final _tahunController = TextEditingController();
  final _stokController = TextEditingController();
  File? _image;
  bool _isLoading = false;

   Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
      );
      
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memilih gambar')),
      );
    }
  }
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? imageName;
      
      // Upload image if selected
      if (_image != null) {
        final imageRequest = http.MultipartRequest(
          'POST',
          Uri.parse('http://localhost/flutter_perpustakaan/api/upload_image.php'),
        );
        
        imageRequest.files.add(
          await http.MultipartFile.fromPath('image', _image!.path),
        );
        
        final imageResponse = await imageRequest.send();
        final imageResponseData = await imageResponse.stream.bytesToString();
        final imageData = json.decode(imageResponseData);
        
        if (imageData['status'] == 'success') {
          imageName = imageData['image'];
        }
      }

      // Add book data
      final response = await http.post(
        Uri.parse('http://localhost/flutter_perpustakaan/api/add_book.php'),
        body: {
          'judul': _judulController.text,
          'pengarang': _pengarangController.text,
          'penerbit': _penerbitController.text,
          'tahun_terbit': _tahunController.text,
          'stok': _stokController.text,
          'image': imageName ?? 'default_book.jpg',
        },
      );

      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Buku berhasil ditambahkan')),
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
        title: Text('Tambah Buku'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _image != null
                      ? Image.file(_image!, fit: BoxFit.cover)
                      : Icon(Icons.add_photo_alternate, size: 50),
                ),
              ),
              SizedBox(height: 16),
              
              // Form Fields
              TextFormField(
                controller: _judulController,
                decoration: InputDecoration(
                  labelText: 'Judul Buku',
                  border: OutlineInputBorder(),
                ),
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
                decoration: InputDecoration(
                  labelText: 'Pengarang',
                  border: OutlineInputBorder(),
                ),
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
                decoration: InputDecoration(
                  labelText: 'Penerbit',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Penerbit tidak boleh kosong';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _tahunController,
                decoration: InputDecoration(
                  labelText: 'Tahun Terbit',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tahun terbit tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Tahun harus berupa angka';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _stokController,
                decoration: InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Stok harus berupa angka';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              
              // Submit Button
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