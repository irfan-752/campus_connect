import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/club_model.dart';

class AdminClubMonitoring extends StatefulWidget {
  const AdminClubMonitoring({super.key});

  @override
  State<AdminClubMonitoring> createState() => _AdminClubMonitoringState();
}

class _AdminClubMonitoringState extends State<AdminClubMonitoring> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'academic',
    'cultural',
    'sports',
    'technical',
    'social'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ResponsiveWrapper(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('clubs')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No clubs found'));
                  }

                  var clubs = snapshot.data!.docs
                      .map((doc) => ClubModel.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          ))
                      .toList();

                  if (_selectedCategory != 'All') {
                    clubs = clubs
                        .where((club) => club.category == _selectedCategory)
                        .toList();
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(
                      ResponsiveHelper.responsiveValue(
                        context,
                        mobile: AppTheme.spacingM,
                        tablet: AppTheme.spacingL,
                        desktop: AppTheme.spacingXL,
                      ),
                    ),
                    itemCount: clubs.length,
                    itemBuilder: (context, index) => _buildClubCard(clubs[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: AppTheme.spacingM,
          tablet: AppTheme.spacingL,
          desktop: AppTheme.spacingXL,
        ),
      ),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final isSelected = _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingS),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (v) {
                  setState(() => _selectedCategory = category);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildClubCard(ClubModel club) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (club.logoUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    club.logoUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: AppTheme.surfaceColor,
                      child: const Icon(Icons.group),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.group),
                ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      club.name,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      club.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      '${club.memberIds.length}/${club.maxMembers} members • ${club.category}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'President: ${club.presidentName}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: club.isActive
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  club.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: club.isActive
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: 'View Details',
                  onPressed: () => _showClubDetails(club),
                  size: ButtonSize.small,
                  type: ButtonType.secondary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _toggleClubStatus(club),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: club.isActive
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                    side: BorderSide(
                      color: club.isActive
                          ? AppTheme.errorColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                  child: Text(
                    club.isActive ? 'Deactivate' : 'Activate',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClubDetails(ClubModel club) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(club.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (club.logoUrl != null)
                Image.network(club.logoUrl!, height: 150, fit: BoxFit.cover),
              const SizedBox(height: AppTheme.spacingM),
              Text('Category: ${club.category}'),
              Text('President: ${club.presidentName}'),
              Text('Members: ${club.memberIds.length}/${club.maxMembers}'),
              if (club.meetingSchedule != null)
                Text('Meetings: ${club.meetingSchedule}'),
              if (club.contactEmail != null)
                Text('Contact: ${club.contactEmail}'),
              const SizedBox(height: AppTheme.spacingM),
              Text('Description:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text(club.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleClubStatus(ClubModel club) async {
    try {
      await FirebaseFirestore.instance.collection('clubs').doc(club.id).update({
        'isActive': !club.isActive,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              club.isActive ? 'Club deactivated' : 'Club activated',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}

