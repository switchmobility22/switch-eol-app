class AssemblerUser {
  final String uid;
  final String assemblerId;
  final String fullName;
  final String email;
  final String brandId;
  final String brandName;
  final String role; // 'line_assembler'

  const AssemblerUser({
    this.uid = '',
    required this.assemblerId,
    required this.fullName,
    required this.email,
    required this.brandId,
    required this.brandName,
    this.role = 'line_assembler',
  });

  factory AssemblerUser.fromMap(Map<String, dynamic> map, {String uid = ''}) {
    return AssemblerUser(
      uid: (map['uid'] as String?) ?? uid,
      assemblerId: (map['assemblerId'] as String?) ?? '',
      fullName: (map['fullName'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      brandId: (map['brandId'] as String?) ?? '',
      brandName: (map['brandName'] as String?) ?? '',
      role: (map['role'] as String?) ?? 'line_assembler',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (uid.isNotEmpty) 'uid': uid,
      'assemblerId': assemblerId,
      'fullName': fullName,
      'email': email,
      'brandId': brandId,
      'brandName': brandName,
      'role': role,
    };
  }
}
