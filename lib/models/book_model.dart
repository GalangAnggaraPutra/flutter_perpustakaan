class Book {
  final int id;
  final String judul;
  final String pengarang;
  final String penerbit;
  final int tahunTerbit;
  final String image;
  final int stok;
  final String createdAt;

  Book({
    required this.id,
    required this.judul,
    required this.pengarang,
    required this.penerbit,
    required this.tahunTerbit,
    required this.image,
    required this.stok,
    required this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'],
      judul: json['judul'],
      pengarang: json['pengarang'],
      penerbit: json['penerbit'],
      tahunTerbit: int.parse(json['tahun_terbit']),
      image: json['image'],
      stok: int.parse(json['stok'].toString()),
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'judul': judul,
      'pengarang': pengarang,
      'penerbit': penerbit,
      'tahun_terbit': tahunTerbit,
      'image': image,
      'stok': stok,
      'created_at': createdAt,
    };
  }
}