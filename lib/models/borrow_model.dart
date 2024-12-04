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
      id: json['id'] is String ? int.parse(json['id']) : json['id'] as int,
      tanggalPinjam: json['tanggal_pinjam']?.toString() ?? '',
      tanggalKembali: json['tanggal_kembali']?.toString() ?? '',
      anggotaId: json['anggota_id'] is String 
          ? int.parse(json['anggota_id']) 
          : json['anggota_id'] as int,
      bukuId: json['buku_id'] is String 
          ? int.parse(json['buku_id']) 
          : json['buku_id'] as int,
      status: json['status']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      anggota: json['anggota'] != null 
          ? Map<String, dynamic>.from(json['anggota']) 
          : null,
      buku: json['buku'] != null 
          ? Map<String, dynamic>.from(json['buku']) 
          : null,
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