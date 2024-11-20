class Return {
  final int id;
  final int peminjamanId;
  final String tanggalDikembalikan;
  final int terlambat;
  final double denda;
  final String createdAt;
  // Tambahan data relasi
  final Map<String, dynamic>? peminjaman;

  Return({
    required this.id,
    required this.peminjamanId,
    required this.tanggalDikembalikan,
    required this.terlambat,
    required this.denda,
    required this.createdAt,
    this.peminjaman,
  });

  factory Return.fromJson(Map<String, dynamic> json) {
    return Return(
      id: json['id'],
      peminjamanId: json['peminjaman_id'],
      tanggalDikembalikan: json['tanggal_dikembalikan'],
      terlambat: json['terlambat'],
      denda: double.parse(json['denda'].toString()),
      createdAt: json['created_at'],
      peminjaman: json['peminjaman'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'peminjaman_id': peminjamanId,
      'tanggal_dikembalikan': tanggalDikembalikan,
      'terlambat': terlambat,
      'denda': denda,
      'created_at': createdAt,
      'peminjaman': peminjaman,
    };
  }
}