import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../utils/responsive_helper.dart';
import '../../models/event_model.dart';

class StudentEventsScreen extends StatefulWidget {
  const StudentEventsScreen({super.key});

  @override
  State<StudentEventsScreen> createState() => _StudentEventsScreenState();
}

class _StudentEventsScreenState extends State<StudentEventsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Academic',
    'Cultural',
    'Sports',
    'Technical',
    'Social',
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
      appBar: const CustomAppBar(title: "Events"),
      body: Column(
        children: [
          _buildCategoryFilter(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUpcomingEvents(),
                _buildMyEvents(),
                _buildPastEvents(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingM),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingS),
            child: FilterChip(
              label: Text(
                category,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
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
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppTheme.dividerColor)),
      ),
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
          Tab(text: "Upcoming"),
          Tab(text: "My Events"),
          Tab(text: "Past"),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getEventsStream(isUpcoming: true, category: _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading events...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: "No upcoming events",
            subtitle: "Check back later for new events",
            icon: Icons.event,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final event = EventModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildEventCard(event, isUpcoming: true);
          },
        );
      },
    );
  }

  Widget _buildMyEvents() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('registeredStudents', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('startDate')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading your events...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: "No registered events",
            subtitle: "Register for events to see them here",
            icon: Icons.event_available,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final event = EventModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildEventCard(event, isRegistered: true);
          },
        );
      },
    );
  }

  Widget _buildPastEvents() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getEventsStream(isPast: true, category: _selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget(message: "Loading past events...");
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const EmptyStateWidget(
            title: "No past events",
            subtitle: "Past events will appear here",
            icon: Icons.event_busy,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final event = EventModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return _buildEventCard(event, isPast: true);
          },
        );
      },
    );
  }

  Widget _buildEventCard(
    EventModel event, {
    bool isUpcoming = false,
    bool isRegistered = false,
    bool isPast = false,
  }) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final isUserRegistered = event.registeredStudents.contains(userId);

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppTheme.radiusM),
              ),
              child: Image.network(
                event.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: AppTheme.surfaceColor,
                    child: const Icon(
                      Icons.event,
                      size: 48,
                      color: AppTheme.lightTextColor,
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          event.category,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        event.category,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getCategoryColor(event.category),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isUserRegistered && !isPast)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Registered",
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  event.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryTextColor,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Text(
                  event.description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.secondaryTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy • hh:mm a',
                      ).format(event.startDate),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingXS),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppTheme.secondaryTextColor,
                    ),
                    const SizedBox(width: AppTheme.spacingXS),
                    Expanded(
                      child: Text(
                        event.location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${event.registeredStudents.length}/${event.maxParticipants} registered",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ),
                    if (!isPast && !isUserRegistered && !event.isFull)
                      CustomButton(
                        text: "Register",
                        onPressed: () => _registerForEvent(event),
                        size: ButtonSize.small,
                      )
                    else if (!isPast && isUserRegistered)
                      CustomButton(
                        text: "Unregister",
                        onPressed: () => _unregisterFromEvent(event),
                        type: ButtonType.secondary,
                        size: ButtonSize.small,
                      )
                    else if (isPast && isUserRegistered)
                      CustomButton(
                        text: "Feedback",
                        onPressed: () => _showFeedbackDialog(event),
                        size: ButtonSize.small,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getEventsStream({
    bool isUpcoming = false,
    bool isPast = false,
    String category = 'All',
  }) {
    Query query = FirebaseFirestore.instance
        .collection('events')
        .where('isActive', isEqualTo: true);

    if (isUpcoming) {
      query = query.where('startDate', isGreaterThan: DateTime.now());
    } else if (isPast) {
      query = query.where('endDate', isLessThan: DateTime.now());
    }

    if (category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy(isPast ? 'endDate' : 'startDate', descending: isPast)
        .snapshots();
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return AppTheme.primaryColor;
      case 'cultural':
        return AppTheme.warningColor;
      case 'sports':
        return AppTheme.successColor;
      case 'technical':
        return AppTheme.accentColor;
      case 'social':
        return Colors.purple;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _registerForEvent(EventModel event) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .update({
            'registeredStudents': FieldValue.arrayUnion([userId]),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully registered for ${event.title}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _unregisterFromEvent(EventModel event) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(event.id)
          .update({
            'registeredStudents': FieldValue.arrayRemove([userId]),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unregistered from ${event.title}'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unregister: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showFeedbackDialog(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Event Feedback',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Would you like to provide feedback for "${event.title}"?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to feedback form
            },
            child: const Text('Give Feedback'),
          ),
        ],
      ),
    );
  }
}
