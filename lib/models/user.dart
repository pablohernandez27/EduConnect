class UserModel {
  final String uid;
  final String username;
  final String bornDate;
  final String phone;
  final String profileImage;

  UserModel({
    required this.uid,
    required this.username,
    required this.bornDate,
    required this.phone,
    required this.profileImage,
  });

  // De Firestore a objeto
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      username: map['username'] ?? '',
      bornDate: map['bornDate'] ?? '',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
    );
  }

  // De objeto a Firestore
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'bornDate': bornDate,
      'phone': phone,
      'profileImage': profileImage,
    };
  }
}
