class Member {
  final int id;
  final String nim;
  final String nama;
  final String alamat;
  final String jenisKelamin;

  Member({
    required this.id,
    required this.nim,
    required this.nama,
    required this.alamat,
    required this.jenisKelamin,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'],
      nim: json['nim'],
      nama: json['nama'],
      alamat: json['alamat'],
      jenisKelamin: json['jenis_kelamin'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nim': nim,
      'nama': nama,
      'alamat': alamat,
      'jenis_kelamin': jenisKelamin,
    };
  }
}

class MemberCount {
  final int totalMembers;

  MemberCount({required this.totalMembers});

  factory MemberCount.fromJson(Map<String, dynamic> json) {
    return MemberCount(
      totalMembers: json['total_members'] ?? 0,
    );
  }
}