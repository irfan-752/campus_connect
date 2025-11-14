import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/club_model.dart';

class StudentClubsScreen extends StatefulWidget {
  const StudentClubsScreen({super.key});

  @override
  State<StudentClubsScreen> createState() => _StudentClubsScreenState();
}

class _StudentClubsScreenState extends State<StudentClubsScreen> {
  final TextEditingController _searchController = TextEditingController();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Clubs & Societies',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryTextColor,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.secondaryTextColor,
            tabs: const [
              Tab(text: 'Browse Clubs'),
              Tab(text: 'My Clubs'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBrowseClubs(),
            _buildMyClubs(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseClubs() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('clubs')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No clubs available',
                  subtitle: 'Check back later',
                  icon: Icons.group,
                );
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

              final query = _searchController.text.toLowerCase();
              if (query.isNotEmpty) {
                clubs = clubs.where((club) {
                  return club.name.toLowerCase().contains(query) ||
                      club.description.toLowerCase().contains(query);
                }).toList();
              }

              if (ResponsiveHelper.isMobile(context)) {
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
              }

              return ResponsiveGrid(
                mobileColumns: 1,
                tabletColumns: 2,
                desktopColumns: 3,
                childAspectRatio: ResponsiveHelper.responsiveValue(
                  context,
                  mobile: 0.8,
                  tablet: 0.85,
                  desktop: 0.9,
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
                children: clubs.map((club) => _buildClubCard(club)).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
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
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search clubs...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (v) {
                      setState(() => _selectedCategory = cat);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(ClubModel club) {
    final user = FirebaseAuth.instance.currentUser;
    final isMember = club.memberIds.contains(user?.uid ?? '');
    final isFull = club.memberIds.length >= club.maxMembers;

    return CustomCard(
      onTap: () => _showClubDetails(club),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (club.logoUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                club.logoUrl!,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 120,
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.group, size: 48),
                ),
              ),
            )
          else
            Container(
              height: 120,
              color: AppTheme.surfaceColor,
              child: const Icon(Icons.group, size: 48),
            ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            club.name,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: AppTheme.spacingS),
          Row(
            children: [
              Icon(Icons.people, size: 14, color: AppTheme.secondaryTextColor),
              const SizedBox(width: 4),
              Text(
                '${club.memberIds.length}/${club.maxMembers} members',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isMember)
            CustomButton(
              text: 'View Club',
              onPressed: () => _showClubDetails(club),
              size: ButtonSize.small,
            )
          else
            CustomButton(
              text: isFull ? 'Full' : 'Join Club',
              onPressed: isFull ? null : () => _joinClub(club),
              size: ButtonSize.small,
            ),
        ],
      ),
    );
  }

  Widget _buildMyClubs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not authenticated'));

    return ResponsiveWrapper(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('clubs')
            .where('memberIds', arrayContains: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const EmptyStateWidget(
              title: 'No clubs joined',
              subtitle: 'Browse and join clubs to see them here',
              icon: Icons.group,
            );
          }

          final clubs = snapshot.data!.docs
              .map((doc) => ClubModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();

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
            itemBuilder: (context, index) => _buildMyClubCard(clubs[index]),
          );
        },
      ),
    );
  }

  Widget _buildMyClubCard(ClubModel club) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      onTap: () => _showClubDetails(club),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: club.logoUrl != null
              ? Image.network(club.logoUrl!)
              : const Icon(Icons.group, color: AppTheme.primaryColor),
        ),
        title: Text(club.name),
        subtitle: Text('${club.memberIds.length} members'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  Future<void> _joinClub(ClubModel club) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (club.memberIds.length >= club.maxMembers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Club is full')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('clubs').doc(club.id).update({
        'memberIds': FieldValue.arrayUnion([user.uid]),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joined club successfully'),
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

  void _showClubDetails(ClubModel club) {
    final user = FirebaseAuth.instance.currentUser;
    final isMember = club.memberIds.contains(user?.uid ?? '');

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
          if (!isMember)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _joinClub(club);
              },
              child: const Text('Join Club'),
            ),
        ],
      ),
    );
  }
}

