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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left, color: AppColors.primary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      Text(
                        'Caregivers',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 48), // Spacer for balance
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Safety Status Banner
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.primary.withOpacity(0.05) : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.verified_user, color: AppColors.primary, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Safety Network Active',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.grey[300] : AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Contacts below will be instantly alerted if a fall is detected or your heart rate exceeds safe levels.',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'EMERGENCY CONTACTS',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: Colors.grey[400],
                              ),
                            ),
                            Text(
                              '${contacts.length} Total',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[400],
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
                                id: contact.id,
                                name: contact.name,
                                relationship: contact.relationship,
                                imageUrl: contact.imageUrl,
                                notificationsEnabled: contact.notificationsEnabled,
                                onToggle: (val) {
                                  ref.read(contactsProvider.notifier).updateContactTokens(contact.id, val);
                                },
                                statusColor: contact.notificationsEnabled ? Colors.green[500]! : Colors.grey[400]!,
                                isDark: isDark,
                                fadedText: !contact.notificationsEnabled,
                                contactModel: contact,
                              );
                            },
                          ),

                        const SizedBox(height: 32),

                        // Help Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[800] : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[100]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.info, color: AppColors.primary),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'How it works?',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Caregivers will receive a high-priority push notification and an automated SMS call during an emergency event.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100), // Padding for fixed bottom action
                      ],
                    ),
                  ),
                ),
              ],
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
                      isDark ? AppColors.bgDark : AppColors.bgLight,
                      isDark ? AppColors.bgDark.withOpacity(0.95) : AppColors.bgLight.withOpacity(0.95),
                      isDark ? AppColors.bgDark.withOpacity(0.0) : AppColors.bgLight.withOpacity(0.0),
                    ],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => const AddContactBottomSheet(),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppColors.primary,
                    elevation: 8,
                    shadowColor: AppColors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        'Add Emergency Contact',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required String id,
    required String name,
    required String relationship,
    required String? imageUrl,
    required bool notificationsEnabled,
    required ValueChanged<bool> onToggle,
    required Color statusColor,
    required bool isDark,
    required ContactModel contactModel, // Add full model reference
    bool fadedText = false,
  }) {
    return GestureDetector(
      onLongPress: () {
        _showOptionsSheet(context, contactModel, isDark);
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.2),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                              colorFilter: fadedText ? ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.dstATop) : null,
                            )
                          : null,
                    ),
                    child: imageUrl == null
                        ? Center(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.white, width: 2),
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
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: fadedText ? (isDark ? Colors.grey[400] : Colors.grey[600]) : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relationship,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'NOTIFICATIONS',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 24,
                child: Switch.adaptive(
                  value: notificationsEnabled,
                  onChanged: onToggle,
                  activeColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  void _showOptionsSheet(BuildContext context, ContactModel contact, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF18181B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
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
                color: isDark ? Colors.white : Colors.black87,
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
                  _showDeleteConfirmation(context, contact, isDark);
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

  void _showDeleteConfirmation(BuildContext context, ContactModel contact, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Delete Contact?',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to remove ${contact.name} from your emergency contacts?',
            style: GoogleFonts.inter(color: isDark ? Colors.grey[400] : Colors.grey[600]),
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
