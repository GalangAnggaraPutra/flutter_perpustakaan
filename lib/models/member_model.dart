class Member {
  final int id;
  final String nim;
  final String nama;
  final String alamat;
  final String jenisKelamin;
  final String createdAt;

  Member({
    required this.id,
    required this.nim,
    required this.nama,
    required this.alamat,
    required this.jenisKelamin,
    required this.createdAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      nim: json['nim'],
      nama: json['nama'],
      alamat: json['alamat'],
      jenisKelamin: json['jenis_kelamin'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nim': nim,
      'nama': nama,
      'alamat': alamat,
      'jenis_kelamin': jenisKelamin,
      'created_at': createdAt,
    };
  }
}