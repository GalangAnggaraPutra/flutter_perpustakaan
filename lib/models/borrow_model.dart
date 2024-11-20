class Borrow {
  final int id;
  final String tanggalPinjam;
  final String tanggalKembali;
  final int anggotaId;
  final int bukuId;
  final String status;
  final String createdAt;
  // Tambahan data relasi
  final Map<String, dynamic>? anggota;
  final Map<String, dynamic>? buku;

  Borrow({
    required this.id,
    required this.tanggalPinjam,
    required this.tanggalKembali,
    required this.anggotaId,
    required this.bukuId,
    required this.status,
    required this.createdAt,
    this.anggota,
    this.buku,
  });

  factory Borrow.fromJson(Map<String, dynamic> json) {
    return Borrow(
      id: json['id'],
      tanggalPinjam: json['tanggal_pinjam'],
      tanggalKembali: json['tanggal_kembali'],
      anggotaId: json['anggota_id'],
      bukuId: json['buku_id'],
      status: json['status'],
      createdAt: json['created_at'],
      anggota: json['anggota'],
      buku: json['buku'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tanggal_pinjam': tanggalPinjam,
      'tanggal_kembali': tanggalKembali,
      'anggota_id': anggotaId,
      'buku_id': bukuId,
      'status': status,
      'created_at': createdAt,
      'anggota': anggota,
      'buku': buku,
    };
  }
}