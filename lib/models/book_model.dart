class Book {
  final int id;
  final String judul;
  final String pengarang;
  final String penerbit;
  final String tahunTerbit;
  final String image;
  final bool isDipinjam;
  final String? tanggalPinjam;
  final String? tanggalKembali;

  Book({
    required this.id,
    required this.judul,
    required this.pengarang,
    required this.penerbit,
    required this.tahunTerbit,
    required this.image,
    required this.isDipinjam,
    this.tanggalPinjam,
    this.tanggalKembali,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: int.parse(json['id'].toString()),
      judul: json['judul'] ?? '',
      pengarang: json['pengarang'] ?? '',
      penerbit: json['penerbit'] ?? '',
      tahunTerbit: json['tahun_terbit'] ?? '',
      image: json['image'] ?? '',
      isDipinjam: json['peminjaman_status'] == 'dipinjam',
      tanggalPinjam: json['tanggal_pinjam'],
      tanggalKembali: json['tanggal_kembali'],
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
      'isDipinjam': isDipinjam,
      'tanggal_pinjam': tanggalPinjam,
      'tanggal_kembali': tanggalKembali,
    };
  }

  Book copyWith({
    int? id,
    String? judul,
    String? pengarang,
    String? penerbit,
    String? tahunTerbit,
    String? image,
    bool? isDipinjam,
    String? tanggalPinjam,
    String? tanggalKembali,
  }) {
    return Book(
      id: id ?? this.id,
      judul: judul ?? this.judul,
      pengarang: pengarang ?? this.pengarang,
      penerbit: penerbit ?? this.penerbit,
      tahunTerbit: tahunTerbit ?? this.tahunTerbit,
      image: image ?? this.image,
      isDipinjam: isDipinjam ?? this.isDipinjam,
      tanggalPinjam: tanggalPinjam ?? this.tanggalPinjam,
      tanggalKembali: tanggalKembali ?? this.tanggalKembali,
    );
  }
}