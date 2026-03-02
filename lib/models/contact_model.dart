// lib/models/contact_model.dart

class ContactModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool notificationsEnabled;
  final String? imageUrl;

  const ContactModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.notificationsEnabled = true,
    this.imageUrl,
  });

  ContactModel copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? notificationsEnabled,
    String? imageUrl,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
