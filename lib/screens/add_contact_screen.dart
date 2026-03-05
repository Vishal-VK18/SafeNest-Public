// lib/screens/add_contact_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../models/contact_model.dart';

class AddContactBottomSheet extends ConsumerStatefulWidget {
  final ContactModel? initialContact;

  const AddContactBottomSheet({super.key, this.initialContact});

  @override
  ConsumerState<AddContactBottomSheet> createState() => _AddContactBottomSheetState();
}

class _AddContactBottomSheetState extends ConsumerState<AddContactBottomSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedRelationship;

  final List<String> _relationships = [
    'Husband',
    'Partner',
    'Mother',
    'Father',
    'Doctor',
    'Sister',
    'Brother',
    'Friend',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialContact != null) {
      _nameController.text = widget.initialContact!.name;
      _phoneController.text = widget.initialContact!.phoneNumber;
      _selectedRelationship = widget.initialContact!.relationship;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _saveContact() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || phone.isEmpty || _selectedRelationship == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please fill in all fields.',
            style: GoogleFonts.inter(fontSize: 14),
          ),
          backgroundColor: const Color(0xFF181818),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (widget.initialContact != null) {
      ref.read(contactsProvider.notifier).updateContactDetails(
        widget.initialContact!.id,
        name,
        phone,
        _selectedRelationship!,
      );
    } else {
      final newContact = ContactModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phoneNumber: phone,
        relationship: _selectedRelationship!,
        notificationsEnabled: true,
      );
      ref.read(contactsProvider.notifier).addContact(newContact);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialContact != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(28, 12, 28, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Header row with icon
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC09D).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit : Icons.person_add,
                    color: const Color(0xFFFFC09D),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Contact' : 'Add New Contact',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF181818),
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      isEdit
                          ? 'Update emergency contact details.'
                          : 'This person will be alerted in emergencies.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF181818).withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Full Name field
            _buildLabel('FULL NAME'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hintText: 'e.g. John Doe',
              keyboardType: TextInputType.name,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 20),

            // Phone Number field
            _buildLabel('PHONE NUMBER'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _phoneController,
              hintText: '+1 (555) 000-0000',
              keyboardType: TextInputType.phone,
              prefixIcon: Icon(Icons.call_outlined, color: const Color(0xFFFFC09D), size: 20),
            ),
            const SizedBox(height: 20),

            // Relationship dropdown
            _buildLabel('RELATIONSHIP'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFAF8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFC09D).withOpacity(0.3), width: 1.5),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: _selectedRelationship,
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  items: _relationships.map((rel) {
                    return DropdownMenuItem(
                      value: rel,
                      child: Text(rel, style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF181818))),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRelationship = val),
                  icon: Icon(Icons.expand_more, color: const Color(0xFF181818).withOpacity(0.4)),
                  hint: Text(
                    'Select Relationship',
                    style: GoogleFonts.inter(color: const Color(0xFF181818).withOpacity(0.3), fontSize: 15),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Save button — gradient to match Blush theme
            GestureDetector(
              onTap: _saveContact,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC09D), Color(0xFFFFCACB)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC09D).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    isEdit ? 'Update Contact' : 'Save Contact',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Cancel
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF181818).withOpacity(0.4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: const Color(0xFF181818).withOpacity(0.35),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFC09D).withOpacity(0.3), width: 1.5),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: GoogleFonts.inter(fontSize: 15, color: const Color(0xFF181818)),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFF181818).withOpacity(0.3),
          ),
          prefixIcon: prefixIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: prefixIcon,
                )
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
