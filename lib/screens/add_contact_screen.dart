// lib/screens/add_contact_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
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
      // Basic validation: Could show snackbar here
      return;
    }

    if (widget.initialContact != null) {
      ref.read(contactsProvider.notifier).updateContactDetails(
        widget.initialContact!.id, 
        name, 
        phone, 
        _selectedRelationship!
      );
    } else {
      final newContact = ContactModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // generate unique ID
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom, // Handle keyboard
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF18181B) : Colors.white, // zinc-900 / white
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border(
            top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Header
            Text(
              widget.initialContact != null ? 'Edit Contact' : 'Add New Contact',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.initialContact != null 
                  ? 'Update emergency contact details.' 
                  : 'This person will be alerted in emergencies.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildInputField(
              label: 'FULL NAME',
              child: TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: _inputDecoration(isDark, hintText: 'e.g. John Doe'),
              ),
            ),
            const SizedBox(height: 24),

            _buildInputField(
              label: 'PHONE NUMBER',
              child: TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: _inputDecoration(
                  isDark,
                  hintText: '+1 (555) 000-0000',
                  prefixIcon: const Icon(Icons.call_outlined, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 24),

            _buildInputField(
              label: 'RELATIONSHIP',
              child: DropdownButtonFormField<String>(
                value: _selectedRelationship,
                items: _relationships.map((rel) {
                  return DropdownMenuItem(
                    value: rel,
                    child: Text(rel, style: GoogleFonts.inter(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedRelationship = val),
                icon: const Icon(Icons.expand_more, color: Colors.grey),
                decoration: _inputDecoration(isDark, hintText: 'Select Relationship'),
              ),
            ),
            const SizedBox(height: 32),

            // Actions
            ElevatedButton(
              onPressed: _saveContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBDB0D0), // Primary-muted
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
                shadowColor: AppColors.primary.withOpacity(0.4),
              ),
              child: Text(
                widget.initialContact != null ? 'Update Contact' : 'Save Contact',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: Colors.grey[400],
            ),
          ),
        ),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(bool isDark, {required String hintText, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.inter(color: isDark ? Colors.grey[700] : Colors.grey[400]),
      filled: true,
      fillColor: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[50],
      prefixIcon: prefixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.primary.withOpacity(0.2), width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }
}
