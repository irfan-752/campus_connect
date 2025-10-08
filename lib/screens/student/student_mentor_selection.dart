import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/mentor_model.dart';
import '../../models/chat_model.dart';
import 'student_chat.dart';

class StudentMentorSelectionScreen extends StatefulWidget {
  const StudentMentorSelectionScreen({super.key});

  @override
  State<StudentMentorSelectionScreen> createState() =>
      _StudentMentorSelectionScreenState();
}

class _StudentMentorSelectionScreenState
    extends State<StudentMentorSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedDepartment = 'All';
  List<String> _departments = ['All'];
  bool _showOnlyAvailable = true;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      final departments = await FirebaseFirestore.instance
          .collection('mentors')
          .get()
          .then((snapshot) {
            final deptSet = <String>{'All'};
            for (final doc in snapshot.docs) {
              final data = doc.data();
              final dept = data['department'] as String?;
              if (dept != null && dept.isNotEmpty) {
                deptSet.add(dept);
              }
            }
            return deptSet.toList()..sort();
          });

      setState(() {
        _departments = departments;
      });
    } catch (e) {
      // Handle error silently or show user-friendly message
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: "Find Mentors"),
      body: ResponsiveWrapper(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildMentorsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsiveValue(
          context,
          mobile: AppTheme.spacingM,
          tablet: AppTheme.spacingL,
          desktop: AppTheme.spacingXL,
        ),
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            style: GoogleFonts.poppins(),
            decoration: InputDecoration(
              hintText: ResponsiveHelper.isMobile(context)
                  ? "Search mentors..."
                  : "Search mentors by name or specialization...",
              hintStyle: GoogleFonts.poppins(
                color: AppTheme.secondaryTextColor,
                fontSize: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: 14.0,
                  tablet: 16.0,
                  desktop: 16.0,
                ),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.primaryColor,
              ),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: AppTheme.spacingM,
                  tablet: AppTheme.spacingL,
                  desktop: AppTheme.spacingL,
                ),
                vertical: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: AppTheme.spacingS,
                  tablet: AppTheme.spacingM,
                  desktop: AppTheme.spacingM,
                ),
              ),
            ),
          ),
          SizedBox(
            height: ResponsiveHelper.responsiveValue(
              context,
              mobile: AppTheme.spacingM,
              tablet: AppTheme.spacingL,
              desktop: AppTheme.spacingL,
            ),
          ),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _departments.map((dept) {
                final isSelected = dept == _selectedDepartment;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: FilterChip(
                    label: Text(
                      dept,
                      style: GoogleFonts.poppins(
                        fontSize: ResponsiveHelper.responsiveValue(
                          context,
                          mobile: 12.0,
                          tablet: 14.0,
                          desktop: 14.0,
                        ),
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : AppTheme.primaryColor,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedDepartment = dept;
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
          SizedBox(
            height: ResponsiveHelper.responsiveValue(
              context,
              mobile: AppTheme.spacingS,
              tablet: AppTheme.spacingM,
              desktop: AppTheme.spacingM,
            ),
          ),
          // Available only toggle
          Row(
            children: [
              Checkbox(
                value: _showOnlyAvailable,
                onChanged: (value) {
                  setState(() {
                    _showOnlyAvailable = value ?? true;
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
              Expanded(
                child: Text(
                  "Show only available mentors",
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 14.0,
                      tablet: 16.0,
                      desktop: 16.0,
                    ),
                    color: AppTheme.primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMentorsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getMentorsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading mentors...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: "No mentors found",
            subtitle: "Try adjusting your search criteria",
            icon: Icons.person_search,
          );
        }

        final mentors = snapshot.data!.docs.map((doc) {
          return MentorModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        // Filter by search text
        final searchText = _searchController.text.toLowerCase();
        final filteredMentors = mentors.where((mentor) {
          final matchesSearch =
              searchText.isEmpty ||
              mentor.name.toLowerCase().contains(searchText) ||
              mentor.specialization.toLowerCase().contains(searchText) ||
              mentor.designation.toLowerCase().contains(searchText);

          final matchesDepartment =
              _selectedDepartment == 'All' ||
              mentor.department == _selectedDepartment;

          final matchesAvailability = !_showOnlyAvailable || mentor.isAvailable;

          return matchesSearch && matchesDepartment && matchesAvailability;
        }).toList();

        if (filteredMentors.isEmpty) {
          return const EmptyStateWidget(
            title: "No mentors match your criteria",
            subtitle: "Try different search terms or filters",
            icon: Icons.search_off,
          );
        }

        return ResponsiveHelper.isMobile(context)
            ? ListView.builder(
                padding: EdgeInsets.all(
                  ResponsiveHelper.responsiveValue(
                    context,
                    mobile: AppTheme.spacingM,
                    tablet: AppTheme.spacingL,
                    desktop: AppTheme.spacingXL,
                  ),
                ),
                itemCount: filteredMentors.length,
                itemBuilder: (context, index) {
                  final mentor = filteredMentors[index];
                  return _buildMentorCard(mentor);
                },
              )
            : ResponsiveGrid(
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
                childAspectRatio: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: 1.2,
                  tablet: 1.4,
                  desktop: 1.6,
                ),
                crossAxisSpacing: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: AppTheme.spacingS,
                  tablet: AppTheme.spacingM,
                  desktop: AppTheme.spacingL,
                ),
                mainAxisSpacing: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: AppTheme.spacingS,
                  tablet: AppTheme.spacingM,
                  desktop: AppTheme.spacingL,
                ),
                shrinkWrap: false,
                physics: const AlwaysScrollableScrollPhysics(),
                children: filteredMentors
                    .map((mentor) => _buildMentorCard(mentor))
                    .toList(),
              );
      },
    );
  }

  Stream<QuerySnapshot> _getMentorsStream() {
    Query query = FirebaseFirestore.instance.collection('mentors');

    if (_showOnlyAvailable) {
      query = query.where('isAvailable', isEqualTo: true);
    }

    return query.orderBy('name').snapshots();
  }

  Widget _buildMentorCard(MentorModel mentor) {
    final isMobile = ResponsiveHelper.isMobile(context);

    return CustomCard(
      margin: EdgeInsets.only(
        bottom: ResponsiveHelper.responsiveValue(
          context,
          mobile: AppTheme.spacingS,
          tablet: AppTheme.spacingM,
          desktop: AppTheme.spacingM,
        ),
      ),
      onTap: () => _startMentorSession(mentor),
      child: isMobile
          ? _buildMobileMentorCard(mentor)
          : _buildDesktopMentorCard(mentor),
    );
  }

  Widget _buildMobileMentorCard(MentorModel mentor) {
    return Row(
      children: [
        CircleAvatar(
          radius: ResponsiveHelper.responsiveValue(
            context,
            mobile: 28.0,
            tablet: 32.0,
            desktop: 36.0,
          ),
          backgroundImage: mentor.avatarUrl != null
              ? NetworkImage(mentor.avatarUrl!)
              : null,
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: mentor.avatarUrl == null
              ? Text(
                  mentor.name.isNotEmpty ? mentor.name[0].toUpperCase() : 'M',
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 20.0,
                      tablet: 24.0,
                      desktop: 28.0,
                    ),
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                )
              : null,
        ),
        SizedBox(
          width: ResponsiveHelper.responsiveValue(
            context,
            mobile: AppTheme.spacingM,
            tablet: AppTheme.spacingL,
            desktop: AppTheme.spacingL,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mentor.name,
                      style: GoogleFonts.poppins(
                        fontSize: ResponsiveHelper.responsiveValue(
                          context,
                          mobile: 16.0,
                          tablet: 18.0,
                          desktop: 20.0,
                        ),
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryTextColor,
                      ),
                    ),
                  ),
                  _buildAvailabilityBadge(mentor.isAvailable),
                ],
              ),
              SizedBox(
                height: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: AppTheme.spacingXS,
                  tablet: AppTheme.spacingS,
                  desktop: AppTheme.spacingS,
                ),
              ),
              Text(
                mentor.designation,
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveHelper.responsiveValue(
                    context,
                    mobile: 12.0,
                    tablet: 14.0,
                    desktop: 16.0,
                  ),
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(
                height: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: AppTheme.spacingXS,
                  tablet: AppTheme.spacingS,
                  desktop: AppTheme.spacingS,
                ),
              ),
              Text(
                mentor.department,
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveHelper.responsiveValue(
                    context,
                    mobile: 10.0,
                    tablet: 12.0,
                    desktop: 14.0,
                  ),
                  color: AppTheme.secondaryTextColor,
                ),
              ),
              if (mentor.specialization.isNotEmpty) ...[
                SizedBox(
                  height: ResponsiveHelper.responsiveValue(
                    context,
                    mobile: AppTheme.spacingXS,
                    tablet: AppTheme.spacingS,
                    desktop: AppTheme.spacingS,
                  ),
                ),
                Text(
                  "Specialization: ${mentor.specialization}",
                  style: GoogleFonts.poppins(
                    fontSize: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 10.0,
                      tablet: 12.0,
                      desktop: 14.0,
                    ),
                    color: AppTheme.secondaryTextColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(
                height: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: AppTheme.spacingS,
                  tablet: AppTheme.spacingM,
                  desktop: AppTheme.spacingM,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 14.0,
                      tablet: 16.0,
                      desktop: 18.0,
                    ),
                    color: AppTheme.secondaryTextColor,
                  ),
                  SizedBox(
                    width: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: AppTheme.spacingXS,
                      tablet: AppTheme.spacingS,
                      desktop: AppTheme.spacingS,
                    ),
                  ),
                  Text(
                    "${mentor.studentIds.length} students",
                    style: GoogleFonts.poppins(
                      fontSize: ResponsiveHelper.responsiveValue(
                        context,
                        mobile: 10.0,
                        tablet: 12.0,
                        desktop: 14.0,
                      ),
                      color: AppTheme.secondaryTextColor,
                    ),
                  ),
                  const Spacer(),
                  _buildStartSessionButton(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopMentorCard(MentorModel mentor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with avatar and availability
        Row(
          children: [
            CircleAvatar(
              radius: ResponsiveHelper.responsiveValue(
                context,
                mobile: 24.0,
                tablet: 28.0,
                desktop: 32.0,
              ),
              backgroundImage: mentor.avatarUrl != null
                  ? NetworkImage(mentor.avatarUrl!)
                  : null,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: mentor.avatarUrl == null
                  ? Text(
                      mentor.name.isNotEmpty
                          ? mentor.name[0].toUpperCase()
                          : 'M',
                      style: GoogleFonts.poppins(
                        fontSize: ResponsiveHelper.responsiveValue(
                          context,
                          mobile: 16.0,
                          tablet: 20.0,
                          desktop: 24.0,
                        ),
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    )
                  : null,
            ),
            SizedBox(
              width: ResponsiveHelper.responsiveValue(
                context,
                mobile: AppTheme.spacingS,
                tablet: AppTheme.spacingM,
                desktop: AppTheme.spacingM,
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mentor.name,
                    style: GoogleFonts.poppins(
                      fontSize: ResponsiveHelper.responsiveValue(
                        context,
                        mobile: 14.0,
                        tablet: 16.0,
                        desktop: 18.0,
                      ),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    mentor.designation,
                    style: GoogleFonts.poppins(
                      fontSize: ResponsiveHelper.responsiveValue(
                        context,
                        mobile: 12.0,
                        tablet: 14.0,
                        desktop: 16.0,
                      ),
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _buildAvailabilityBadge(mentor.isAvailable),
          ],
        ),
        SizedBox(
          height: ResponsiveHelper.responsiveValue(
            context,
            mobile: AppTheme.spacingS,
            tablet: AppTheme.spacingM,
            desktop: AppTheme.spacingM,
          ),
        ),
        // Department and specialization
        Text(
          mentor.department,
          style: GoogleFonts.poppins(
            fontSize: ResponsiveHelper.responsiveValue(
              context,
              mobile: 12.0,
              tablet: 14.0,
              desktop: 16.0,
            ),
            color: AppTheme.secondaryTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (mentor.specialization.isNotEmpty) ...[
          SizedBox(
            height: ResponsiveHelper.responsiveValue(
              context,
              mobile: AppTheme.spacingXS,
              tablet: AppTheme.spacingS,
              desktop: AppTheme.spacingS,
            ),
          ),
          Text(
            "Specialization: ${mentor.specialization}",
            style: GoogleFonts.poppins(
              fontSize: ResponsiveHelper.responsiveValue(
                context,
                mobile: 11.0,
                tablet: 12.0,
                desktop: 14.0,
              ),
              color: AppTheme.secondaryTextColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (mentor.experience.isNotEmpty) ...[
          SizedBox(
            height: ResponsiveHelper.responsiveValue(
              context,
              mobile: AppTheme.spacingXS,
              tablet: AppTheme.spacingS,
              desktop: AppTheme.spacingS,
            ),
          ),
          Text(
            "Experience: ${mentor.experience}",
            style: GoogleFonts.poppins(
              fontSize: ResponsiveHelper.responsiveValue(
                context,
                mobile: 11.0,
                tablet: 12.0,
                desktop: 14.0,
              ),
              color: AppTheme.secondaryTextColor,
            ),
          ),
        ],
        SizedBox(
          height: ResponsiveHelper.responsiveValue(
            context,
            mobile: AppTheme.spacingM,
            tablet: AppTheme.spacingL,
            desktop: AppTheme.spacingL,
          ),
        ),
        // Footer with student count and start session button
        Row(
          children: [
            Icon(
              Icons.people,
              size: ResponsiveHelper.responsiveValue(
                context,
                mobile: 14.0,
                tablet: 16.0,
                desktop: 18.0,
              ),
              color: AppTheme.secondaryTextColor,
            ),
            SizedBox(
              width: ResponsiveHelper.responsiveValue(
                context,
                mobile: AppTheme.spacingXS,
                tablet: AppTheme.spacingS,
                desktop: AppTheme.spacingS,
              ),
            ),
            Text(
              "${mentor.studentIds.length} students",
              style: GoogleFonts.poppins(
                fontSize: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: 11.0,
                  tablet: 12.0,
                  desktop: 14.0,
                ),
                color: AppTheme.secondaryTextColor,
              ),
            ),
            const Spacer(),
            _buildStartSessionButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityBadge(bool isAvailable) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.responsiveValue(
          context,
          mobile: 6.0,
          tablet: 8.0,
          desktop: 10.0,
        ),
        vertical: ResponsiveHelper.responsiveValue(
          context,
          mobile: 3.0,
          tablet: 4.0,
          desktop: 5.0,
        ),
      ),
      decoration: BoxDecoration(
        color: isAvailable ? AppTheme.successColor : AppTheme.errorColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isAvailable ? "Available" : "Busy",
        style: GoogleFonts.poppins(
          fontSize: ResponsiveHelper.responsiveValue(
            context,
            mobile: 9.0,
            tablet: 10.0,
            desktop: 11.0,
          ),
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStartSessionButton() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.responsiveValue(
          context,
          mobile: 10.0,
          tablet: 12.0,
          desktop: 14.0,
        ),
        vertical: ResponsiveHelper.responsiveValue(
          context,
          mobile: 5.0,
          tablet: 6.0,
          desktop: 7.0,
        ),
      ),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        "Start Session",
        style: GoogleFonts.poppins(
          fontSize: ResponsiveHelper.responsiveValue(
            context,
            mobile: 10.0,
            tablet: 11.0,
            desktop: 12.0,
          ),
          fontWeight: FontWeight.w500,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Future<void> _startMentorSession(MentorModel mentor) async {
    if (!mentor.isAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${mentor.name} is currently busy'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      return;
    }

    final user = FirebaseAuth.instance.currentUser!;

    // Check if chat room already exists
    final existingChat = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('participants', arrayContains: user.uid)
        .where('type', isEqualTo: 'Direct')
        .get()
        .then((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data();
            final participants = List<String>.from(data['participants'] ?? []);
            return participants.contains(mentor.userId);
          }).toList();
        });

    if (existingChat.isNotEmpty) {
      // Open existing chat
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentChatScreen()),
        );
      }
    } else {
      // Create new chat room
      final now = DateTime.now();
      final chatRoom = ChatRoom(
        id: '',
        name: mentor.name,
        description: 'Direct chat with ${mentor.name}',
        type: 'Direct',
        participants: [user.uid, mentor.userId],
        avatarUrl: mentor.avatarUrl,
        createdBy: user.uid,
        createdAt: now,
        lastMessageAt: now,
        lastMessage: null,
        isActive: true,
      );

      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .add(chatRoom.toMap());
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const StudentChatScreen()),
        );
      }
    }
  }
}
