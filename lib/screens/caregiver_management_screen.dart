// lib/screens/caregiver_management_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_theme.dart';
import '../models/contact_model.dart';
import '../providers/providers.dart';
import 'add_contact_screen.dart';

class CaregiverManagementScreen extends ConsumerStatefulWidget {
  const CaregiverManagementScreen({super.key});

  @override
  ConsumerState<CaregiverManagementScreen> createState() => _CaregiverManagementScreenState();
}

class _CaregiverManagementScreenState extends ConsumerState<CaregiverManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);

    // Gradient Background from blush theme
    final gradientDecoration = BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFC09D), const Color(0xFFFFCACB)],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFFFAF8), // creamy
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: gradientDecoration,
              child: Container(
                color: Colors.white.withOpacity(0.25), // Backdrop blur equivalent
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            width: 40, height: 40,
                            alignment: Alignment.centerLeft,
                            child: const Icon(Icons.arrow_back_ios, color: Color(0xFF181818), size: 20),
                          ),
                        ),
                      ),
                      Text(
                        'Caregivers',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF181818).withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, top: 24, bottom: 24),
                    child: Text(
                      'Emergency Contacts',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF181818),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Safety Status Banner
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFC09D).withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFFFFC09D), size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Safety Network Active',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF181818),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Contacts below will be instantly alerted if a fall is detected or your heart rate exceeds safe levels.',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: Colors.grey[500],
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Section Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'TRUSTED CAREGIVERS',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    color: const Color(0xFF181818).withOpacity(0.5),
                                  ),
                                ),
                                Text(
                                  '${contacts.length} Total',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: const Color(0xFF181818).withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Contact List
                            if (contacts.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Text(
                                  'No emergency contacts added yet.',
                                  style: GoogleFonts.inter(color: Colors.grey[500]),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: contacts.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final contact = contacts[index];
                                  return _buildContactCard(
                                    contactModel: contact,
                                    onToggle: (val) {
                                      ref.read(contactsProvider.notifier).updateContactTokens(contact.id, val);
                                    },
                                  );
                                },
                              ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                      
                      // Fixed Bottom Action Area
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                const Color(0xFFFFFAF8),
                                const Color(0xFFFFFAF8).withOpacity(0.9),
                                const Color(0xFFFFFAF8).withOpacity(0.0),
                              ],
                            ),
                          ),
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (context) => const AddContactBottomSheet(),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF181818),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Add Caregiver',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required ContactModel contactModel,
    required ValueChanged<bool> onToggle,
  }) {
    final fadedText = !contactModel.notificationsEnabled;
    return GestureDetector(
      onLongPress: () {
        _showOptionsSheet(context, contactModel);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFC09D).withOpacity(0.3),
                        image: contactModel.imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(contactModel.imageUrl!),
                                fit: BoxFit.cover,
                                colorFilter: fadedText ? ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.dstATop) : null,
                              )
                            : null,
                      ),
                      child: contactModel.imageUrl == null
                          ? Center(
                              child: Text(
                                contactModel.name.isNotEmpty ? contactModel.name[0].toUpperCase() : '?',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF181818),
                                ),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: contactModel.notificationsEnabled ? Colors.green[500] : Colors.grey[400],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contactModel.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: fadedText ? Colors.grey[400] : const Color(0xFF181818),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      contactModel.relationship,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Custom Toggle imitating Tailwind UI
            GestureDetector(
              onTap: () => onToggle(!contactModel.notificationsEnabled),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: contactModel.notificationsEnabled ? const Color(0xFFFFC09D) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  alignment: contactModel.notificationsEnabled ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
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

  void _showOptionsSheet(BuildContext context, ContactModel contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Manage Contact',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF181818),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                contact.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 32),
              
              // Actions
              _buildOptionTile(
                icon: Icons.edit_outlined,
                title: 'Edit Contact',
                color: const Color(0xFF181818),
                onTap: () {
                  Navigator.pop(ctx);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AddContactBottomSheet(initialContact: contact),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildOptionTile(
                icon: Icons.delete_outline,
                title: 'Delete Contact',
                color: AppColors.dangerRed,
                onTap: () {
                  Navigator.pop(ctx);
                  _showDeleteConfirmation(context, contact);
                },
              ),
              const SizedBox(height: 16),
              _buildOptionTile(
                icon: Icons.close,
                title: 'Cancel',
                color: Colors.grey[500]!,
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, ContactModel contact) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Contact?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF181818)),
          ),
          content: Text(
            'Are you sure you want to remove ${contact.name} from your emergency contacts?',
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: Colors.grey[500], fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(contactsProvider.notifier).removeContact(contact.id);
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.dangerRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}

