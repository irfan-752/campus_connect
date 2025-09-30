import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/custom_button.dart';
import '../../models/notice_model.dart';

class AdminNoticeManagement extends StatefulWidget {
  const AdminNoticeManagement({super.key});

  @override
  State<AdminNoticeManagement> createState() => _AdminNoticeManagementState();
}

class _AdminNoticeManagementState extends State<AdminNoticeManagement>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // String _searchQuery = '';
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
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Column(
        children: [
          _buildSearchAndFilter(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllNotices(),
                _buildActiveNotices(),
                _buildNoticeStatistics(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateNoticeDialog,
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              // setState(() {
              //   _searchQuery = value;
              // });
            },
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: 'Search notices...',
              hintStyle: GoogleFonts.poppins(
                color: AppTheme.secondaryTextColor,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.primaryColor,
              ),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _priorities.map((priority) {
                      final isSelected = _selectedPriority == priority;
                      return Padding(
                        padding: const EdgeInsets.only(
                          right: AppTheme.spacingS,
                        ),
                        child: FilterChip(
                          label: Text(
                            priority,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPriority = priority;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppTheme.primaryColor,
                          checkmarkColor: Colors.white,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppTheme.accentColor,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppTheme.accentColor,
                    checkmarkColor: Colors.white,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: AppTheme.secondaryTextColor,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
        indicatorColor: AppTheme.primaryColor,
        tabs: const [
          Tab(text: 'All Notices'),
          Tab(text: 'Active'),
          Tab(text: 'Statistics'),
        ],
      ),
    );
  }

  Widget _buildAllNotices() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildNoticesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading notices...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No notices found",
              style: TextStyle(color: AppTheme.secondaryTextColor),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
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

  Widget _buildActiveNotices() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notices')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading active notices...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No active notices",
              style: TextStyle(color: AppTheme.secondaryTextColor),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final notice = NoticeModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildNoticeCard(notice, isActive: true);
          },
        );
      },
    );
  }

  Widget _buildNoticeStatistics() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('notices').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading statistics...");
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("No data available"));
        }

        final notices = snapshot.data!.docs.map((doc) {
          return NoticeModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        final totalNotices = notices.length;
        final activeNotices = notices.where((n) => n.isActive).length;
        final highPriority = notices.where((n) => n.priority == 'High').length;
        final totalReads = notices
            .map((n) => n.readBy.length)
            .fold(0, (a, b) => a + b);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "Total Notices",
                      "$totalNotices",
                      Icons.campaign,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildStatCard(
                      "Active",
                      "$activeNotices",
                      Icons.visibility,
                      AppTheme.successColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingS),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      "High Priority",
                      "$highPriority",
                      Icons.priority_high,
                      AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: _buildStatCard(
                      "Total Reads",
                      "$totalReads",
                      Icons.visibility,
                      AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingL),
              _buildCategoryDistribution(notices),
              const SizedBox(height: AppTheme.spacingL),
              _buildPriorityDistribution(notices),
              const SizedBox(height: AppTheme.spacingL),
              _buildMostReadNotices(notices),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoticeCard(NoticeModel notice, {bool isActive = false}) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (notice.isActive
                              ? AppTheme.successColor
                              : AppTheme.secondaryTextColor)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notice.isActive ? "Active" : "Inactive",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: notice.isActive
                        ? AppTheme.successColor
                        : AppTheme.secondaryTextColor,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleNoticeAction(value, notice),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: notice.isActive ? 'deactivate' : 'activate',
                    child: Text(notice.isActive ? 'Deactivate' : 'Activate'),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate'),
                  ),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
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
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Icon(Icons.visibility, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                "${notice.readBy.length} reads",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (notice.attachmentUrl != null) ...[
                const SizedBox(width: AppTheme.spacingM),
                Icon(Icons.attach_file, size: 16, color: AppTheme.accentColor),
                const SizedBox(width: AppTheme.spacingXS),
                Text(
                  "Attachment",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const Spacer(),
              CustomButton(
                text: "View Details",
                onPressed: () => _showNoticeDetails(notice),
                size: ButtonSize.small,
                type: ButtonType.secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryDistribution(List<NoticeModel> notices) {
    final categories = [
      'Academic',
      'Administrative',
      'Event',
      'Examination',
      'Holiday',
      'General',
    ];
    final colors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      AppTheme.errorColor,
      AppTheme.secondaryTextColor,
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Category Distribution",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            final count = notices.where((n) => n.category == category).length;
            final total = notices.length;
            final percentage = total > 0 ? (count / total) * 100 : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      category,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                  ),
                  Text(
                    "$count (${percentage.toStringAsFixed(1)}%)",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPriorityDistribution(List<NoticeModel> notices) {
    final priorities = ['High', 'Medium', 'Low'];
    final colors = [
      AppTheme.errorColor,
      AppTheme.warningColor,
      AppTheme.successColor,
    ];

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Priority Distribution",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          ...priorities.asMap().entries.map((entry) {
            final index = entry.key;
            final priority = entry.value;
            final count = notices.where((n) => n.priority == priority).length;
            final total = notices.length;
            final percentage = total > 0 ? (count / total) * 100 : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
              child: Row(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors[index],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingS),
                  Expanded(
                    child: Text(
                      priority,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                  ),
                  Text(
                    "$count (${percentage.toStringAsFixed(1)}%)",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTextColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMostReadNotices(List<NoticeModel> notices) {
    final sortedNotices = notices.toList()
      ..sort((a, b) => b.readBy.length.compareTo(a.readBy.length));
    final topNotices = sortedNotices.take(5).toList();

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Most Read Notices",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          if (topNotices.isEmpty)
            Text(
              "No notices available",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.secondaryTextColor,
              ),
            )
          else
            ...topNotices.asMap().entries.map((entry) {
              final index = entry.key;
              final notice = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingS),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          "${index + 1}",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingS),
                    Expanded(
                      child: Text(
                        notice.title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.primaryTextColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "${notice.readBy.length} reads",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _buildNoticesStream() {
    Query query = FirebaseFirestore.instance
        .collection('notices')
        .orderBy('createdAt', descending: true);

    if (_selectedPriority != 'All') {
      query = query.where('priority', isEqualTo: _selectedPriority);
    }

    if (_selectedCategory != 'All') {
      query = query.where('category', isEqualTo: _selectedCategory);
    }

    return query.snapshots();
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppTheme.errorColor;
      case 'Medium':
        return AppTheme.warningColor;
      case 'Low':
        return AppTheme.successColor;
      default:
        return AppTheme.secondaryTextColor;
    }
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'High':
        return Icons.priority_high;
      case 'Medium':
        return Icons.remove;
      case 'Low':
        return Icons.keyboard_arrow_down;
      default:
        return Icons.info;
    }
  }

  void _handleNoticeAction(String action, NoticeModel notice) {
    switch (action) {
      case 'edit':
        _showEditNoticeDialog(notice);
        break;
      case 'duplicate':
        _duplicateNotice(notice);
        break;
      case 'activate':
        _toggleNoticeStatus(notice, true);
        break;
      case 'deactivate':
        _toggleNoticeStatus(notice, false);
        break;
      case 'delete':
        _deleteNotice(notice);
        break;
    }
  }

  void _showCreateNoticeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Create New Notice',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will open a form to create a new notice with all necessary details.',
          style: GoogleFonts.poppins(),
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

  void _showEditNoticeDialog(NoticeModel notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Notice',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Edit details for "${notice.title}"',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNoticeDetails(NoticeModel notice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          notice.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(
                        notice.priority,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notice.priority,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getPriorityColor(notice.priority),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      notice.category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Description:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              Text(notice.description, style: GoogleFonts.poppins()),
              const SizedBox(height: 8),
              Text(
                'Author:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              Text(notice.authorName, style: GoogleFonts.poppins()),
              const SizedBox(height: 8),
              Text(
                'Created:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(notice.createdAt),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 8),
              Text(
                'Reads:',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              Text("${notice.readBy.length}", style: GoogleFonts.poppins()),
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

  void _duplicateNotice(NoticeModel notice) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final newNotice = NoticeModel(
        id: '',
        title: "${notice.title} (Copy)",
        description: notice.description,
        category: notice.category,
        priority: notice.priority,
        authorId: currentUser.uid,
        authorName: currentUser.displayName ?? 'Admin',
        targetAudience: notice.targetAudience,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: false,
        readBy: [],
        attachmentUrl: notice.attachmentUrl,
      );

      await FirebaseFirestore.instance
          .collection('notices')
          .add(newNotice.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notice duplicated successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate notice: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _toggleNoticeStatus(NoticeModel notice, bool isActive) async {
    try {
      await FirebaseFirestore.instance
          .collection('notices')
          .doc(notice.id)
          .update({'isActive': isActive});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notice ${isActive ? "activated" : "deactivated"} successfully',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update notice status: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _deleteNotice(NoticeModel notice) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Notice',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${notice.title}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('notices')
                    .doc(notice.id)
                    .delete();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notice deleted successfully'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete notice: $e'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
