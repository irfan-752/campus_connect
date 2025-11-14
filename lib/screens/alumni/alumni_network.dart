import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/alumni_model.dart';

class AlumniNetworkScreen extends StatefulWidget {
  const AlumniNetworkScreen({super.key});

  @override
  State<AlumniNetworkScreen> createState() => _AlumniNetworkScreenState();
}

class _AlumniNetworkScreenState extends State<AlumniNetworkScreen> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Alumni Network'),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('alumni')
                  .where('isVerified', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const EmptyStateWidget(
                    title: 'No alumni found',
                    subtitle: 'Check back later',
                    icon: Icons.people_outline,
                  );
                }

                var alumni = snapshot.data!.docs
                    .map(
                      (doc) => AlumniModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList();

                // Filter by search
                final query = _searchController.text.toLowerCase();
                if (query.isNotEmpty) {
                  alumni = alumni.where((a) {
                    return a.name.toLowerCase().contains(query) ||
                        a.department.toLowerCase().contains(query) ||
                        (a.currentCompany?.toLowerCase().contains(query) ??
                            false) ||
                        (a.currentPosition?.toLowerCase().contains(query) ??
                            false);
                  }).toList();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: alumni.length,
                  itemBuilder: (context, index) =>
                      _buildAlumniCard(alumni[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search alumni by name, company, or position...',
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
        ],
      ),
    );
  }

  Widget _buildAlumniCard(AlumniModel alumni) {
    final user = FirebaseAuth.instance.currentUser;
    final isCurrentUser = alumni.userId == user?.uid;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: alumni.avatarUrl != null
                    ? NetworkImage(alumni.avatarUrl!)
                    : null,
                child: alumni.avatarUrl == null
                    ? Text(
                        alumni.name[0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alumni.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (alumni.isVerified)
                          const Icon(
                            Icons.verified,
                            color: AppTheme.successColor,
                            size: 20,
                          ),
                      ],
                    ),
                    if (alumni.currentPosition != null) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        alumni.currentPosition!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.primaryTextColor,
                        ),
                      ),
                    ],
                    if (alumni.currentCompany != null) ...[
                      const SizedBox(height: AppTheme.spacingXS),
                      Text(
                        alumni.currentCompany!,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingM),
          Row(
            children: [
              Icon(Icons.school, size: 16, color: AppTheme.secondaryTextColor),
              const SizedBox(width: AppTheme.spacingXS),
              Text(
                '${alumni.department} • Class of ${alumni.graduationYear}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
          if (alumni.skills.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingM),
            Wrap(
              spacing: AppTheme.spacingXS,
              runSpacing: AppTheme.spacingXS,
              children: alumni.skills.take(5).map((skill) {
                return Chip(
                  label: Text(skill),
                  labelStyle: GoogleFonts.poppins(fontSize: 10),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
          ],
          if (!isCurrentUser) ...[
            const SizedBox(height: AppTheme.spacingM),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Connect',
                    onPressed: () => _connectAlumni(alumni),
                    size: ButtonSize.small,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewProfile(alumni),
                    child: const Text('View Profile'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _connectAlumni(AlumniModel alumni) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Check if connection already exists
      final existing = await FirebaseFirestore.instance
          .collection('connections')
          .where('fromUserId', isEqualTo: user.uid)
          .where('toUserId', isEqualTo: alumni.userId)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Already connected')));
        return;
      }

      // Check reverse connection
      final reverse = await FirebaseFirestore.instance
          .collection('connections')
          .where('fromUserId', isEqualTo: alumni.userId)
          .where('toUserId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (reverse.docs.isNotEmpty) {
        // Accept existing reverse connection
        await FirebaseFirestore.instance
            .collection('connections')
            .doc(reverse.docs.first.id)
            .update({'status': 'accepted'});
      } else {
        // Create new connection
        await FirebaseFirestore.instance.collection('connections').add({
          'fromUserId': user.uid,
          'toUserId': alumni.userId,
          'status': 'pending',
          'createdAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection request sent'),
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

  void _viewProfile(AlumniModel alumni) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alumni.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (alumni.currentPosition != null)
                Text('Position: ${alumni.currentPosition}'),
              if (alumni.currentCompany != null)
                Text('Company: ${alumni.currentCompany}'),
              Text('Department: ${alumni.department}'),
              Text('Graduation Year: ${alumni.graduationYear}'),
              if (alumni.bio != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                Text('Bio: ${alumni.bio}'),
              ],
              if (alumni.skills.isNotEmpty) ...[
                const SizedBox(height: AppTheme.spacingM),
                Text('Skills: ${alumni.skills.join(", ")}'),
              ],
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
}
