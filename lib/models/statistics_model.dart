class Statistics {
  final int totalAnggota;
  final int totalBuku;
  final int totalTersedia;
  final int totalDipinjam;
  final int totalDikembalikan;
  final double totalDenda;

  Statistics({
    required this.totalAnggota,
    required this.totalBuku,
    required this.totalTersedia,
    required this.totalDipinjam,
    required this.totalDikembalikan,
    required this.totalDenda,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) {
    return Statistics(
      totalAnggota: json['total_anggota'] ?? 0,
      totalBuku: json['total_buku'] ?? 0,
      totalTersedia: json['total_tersedia'] ?? 0,
      totalDipinjam: json['total_dipinjam'] ?? 0,
      totalDikembalikan: json['total_dikembalikan'] ?? 0,
      totalDenda: (json['total_denda'] ?? 0).toDouble(),
    );
  }
} 