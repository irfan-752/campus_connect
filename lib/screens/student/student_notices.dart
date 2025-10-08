import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/notice_model.dart';

class StudentNoticesScreen extends StatefulWidget {
  const StudentNoticesScreen({super.key});

  @override
  State<StudentNoticesScreen> createState() => _StudentNoticesScreenState();
}

class _StudentNoticesScreenState extends State<StudentNoticesScreen> {
  String _selectedPriority = 'All';
  String _selectedCategory = 'All';

  final List<String> _priorities = ['All', 'High', 'Medium', 'Low'];
  final List<String> _categories = [
    'All',
    'Academic',
    'Administrative',
    'Event',
    'Examination',
    'Holiday',
    'General',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: "Notices"),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(child: _buildNoticesList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "Priority:",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _priorities.map((priority) {
                      final isSelected = priority == _selectedPriority;
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppTheme.spacingS,
                        ),
                        child: FilterChip(
                          label: Text(
                            priority,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : _getPriorityColor(priority),
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPriority = priority;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: _getPriorityColor(priority),
                          checkmarkColor: Colors.white,
                          side: BorderSide(color: _getPriorityColor(priority)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Text(
                "Category:",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryTextColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categories.map((category) {
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppTheme.spacingS,
                        ),
                        child: FilterChip(
                          label: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppTheme.primaryColor,
                          checkmarkColor: Colors.white,
                          side: const BorderSide(color: AppTheme.primaryColor),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoticesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getNoticesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading notices...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print('DEBUG STUDENT: No notices found in Firestore');
          return const EmptyStateWidget(
            title: "No notices found",
            subtitle: "Check back later for new notices",
            icon: Icons.campaign,
          );
        }

        print(
          'DEBUG STUDENT: Found ${snapshot.data!.docs.length} notices in Firestore',
        );

        // Filter notices by target audience
        final filteredNotices = snapshot.data!.docs.where((doc) {
          final notice = NoticeModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );

          // Debug logging
          print(
            'DEBUG STUDENT: Notice - Title: ${notice.title}, Author: ${notice.authorName}, Target: ${notice.targetAudience}',
          );

          // Show notices that are either for 'All' or specifically for 'Student'
          // Also show notices with no target audience specified (backward compatibility)
          final shouldShow =
              notice.targetAudience.isEmpty ||
              notice.targetAudience.contains('All') ||
              notice.targetAudience.contains('Student');

          print(
            'DEBUG STUDENT: Should show notice "${notice.title}": $shouldShow',
          );
          return shouldShow;
        }).toList();

        print(
          'DEBUG STUDENT: After filtering, ${filteredNotices.length} notices remain',
        );

        if (filteredNotices.isEmpty) {
          return const EmptyStateWidget(
            title: "No notices found",
            subtitle: "Check back later for new notices",
            icon: Icons.campaign,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: filteredNotices.length,
          itemBuilder: (context, index) {
            final doc = filteredNotices[index];
            final notice = NoticeModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildNoticeCard(notice);
          },
        );
      },
    );
  }

  Widget _buildNoticeCard(NoticeModel notice) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isRead = notice.isReadBy(userId);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      onTap: () => _showNoticeDetails(notice),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(notice.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getPriorityIcon(notice.priority),
                      size: 12,
                      color: _getPriorityColor(notice.priority),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      notice.priority,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getPriorityColor(notice.priority),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notice.category,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const Spacer(),
              if (!isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            notice.title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            notice.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.secondaryTextColor,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: AppTheme.secondaryTextColor),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                notice.authorName,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM dd, yyyy').format(notice.createdAt),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
          if (notice.attachmentUrl != null) ...[
            const SizedBox(height: AppTheme.spacingS),
            Row(
              children: [
                Icon(
                  _getAttachmentIcon(notice.attachmentType),
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: AppTheme.spacingXS),
                Text(
                  notice.attachmentName ?? "Attachment available",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getNoticesStream() {
    // Get notices that are either for 'All' or specifically for 'Student'
    // We'll use a compound query approach
    Query query = FirebaseFirestore.instance
        .collection('notices')
        .where('isActive', isEqualTo: true);

    if (_selectedPriority != 'All') {
      query = query.where('priority', isEqualTo: _selectedPriority);
    }

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots();
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
        return AppTheme.successColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Icons.priority_high;
      case 'medium':
        return Icons.remove;
      case 'low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.info;
    }
  }

  IconData _getAttachmentIcon(String? attachmentType) {
    switch (attachmentType) {
      case 'image':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'link':
        return Icons.link;
      default:
        return Icons.attach_file;
    }
  }

  void _showNoticeDetails(NoticeModel notice) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Mark as read if not already read
    if (!notice.isReadBy(userId)) {
      FirebaseFirestore.instance.collection('notices').doc(notice.id).update({
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusL),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AppTheme.dividerColor),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        "Notice Details",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTextColor,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getPriorityColor(
                                  notice.priority,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPriorityIcon(notice.priority),
                                    size: 16,
                                    color: _getPriorityColor(notice.priority),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    notice.priority,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getPriorityColor(notice.priority),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppTheme.spacingS),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                notice.category,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        Text(
                          notice.title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        Container(
                          padding: const EdgeInsets.all(AppTheme.spacingM),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusM,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 18,
                                color: AppTheme.secondaryTextColor,
                              ),
                              const SizedBox(width: AppTheme.spacingS),
                              Text(
                                notice.authorName,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.primaryTextColor,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy • hh:mm a',
                                ).format(notice.createdAt),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.secondaryTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        Text(
                          notice.description,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            height: 1.6,
                            color: AppTheme.primaryTextColor,
                          ),
                        ),
                        if (notice.attachmentUrl != null) ...[
                          const SizedBox(height: AppTheme.spacingL),
                          Container(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.primaryColor),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusM,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _getAttachmentIcon(notice.attachmentType),
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: AppTheme.spacingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notice.attachmentName ?? "Attachment",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryTextColor,
                                        ),
                                      ),
                                      Text(
                                        notice.attachmentType == 'link'
                                            ? 'External Link'
                                            : 'Tap to download or view',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: AppTheme.secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    notice.attachmentType == 'link'
                                        ? Icons.open_in_new
                                        : Icons.download,
                                    color: AppTheme.primaryColor,
                                  ),
                                  onPressed: () =>
                                      _openAttachment(notice.attachmentUrl!),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open attachment: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
