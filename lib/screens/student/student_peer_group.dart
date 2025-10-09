import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../services/group_service.dart';

class StudentPeerGroupScreen extends StatefulWidget {
  const StudentPeerGroupScreen({super.key});

  @override
  State<StudentPeerGroupScreen> createState() => _StudentPeerGroupScreenState();
}

class _StudentPeerGroupScreenState extends State<StudentPeerGroupScreen> {
  final GroupService _groupService = GroupService();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedIds = {};
  List<Map<String, dynamic>> _peers = [];
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadPeers();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPeers() async {
    setState(() => _loading = true);
    try {
      final list = await _groupService.fetchEligiblePeers();
      setState(() => _peers = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load peers: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredPeers {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _peers;
    return _peers.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final reg = (p['regNo'] ?? '').toString().toLowerCase();
      return name.contains(q) || reg.contains(q);
    }).toList();
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a group name')));
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select at least one peer')));
      return;
    }
    setState(() => _creating = true);
    try {
      final id = await _groupService.createPeerGroup(
        groupName: _groupNameController.text.trim(),
        memberStudentIds: _selectedIds.toList(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group created (ID: $id)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Create Peer Group'),
      body: _loading
          ? const LoadingWidget(message: 'Loading peers...')
          : Column(
              children: [
                _buildHeader(),
                const SizedBox(height: AppTheme.spacingS),
                Expanded(child: _buildPeerList()),
                _buildFooter(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final isDesktop = ResponsiveHelper.isDesktop(context);
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: isDesktop ? 2 : 3,
            child: TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Group name',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingS),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                hintText: 'Search peers by name or reg. no',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeerList() {
    final peers = _filteredPeers;
    if (peers.isEmpty) {
      return const Center(
        child: EmptyStateWidget(
          title: 'No peers found',
          subtitle: 'Try a different search keyword',
          icon: Icons.people_outline,
        ),
      );
    }

    final isTablet = ResponsiveHelper.isTablet(context);
    final isDesktop = ResponsiveHelper.isDesktop(context);
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    if (crossAxisCount == 1) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        itemCount: peers.length,
        itemBuilder: (context, index) => _buildPeerTile(peers[index]),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: AppTheme.spacingM.toDouble(),
        crossAxisSpacing: AppTheme.spacingM.toDouble(),
        childAspectRatio: 3.8,
      ),
      itemCount: peers.length,
      itemBuilder: (context, index) => _buildPeerTile(peers[index]),
    );
  }

  Widget _buildPeerTile(Map<String, dynamic> peer) {
    final isSelected = _selectedIds.contains(peer['id']);
    final name = (peer['name'] ?? 'Student').toString();
    final department = (peer['department'] ?? '').toString();
    final semester = (peer['semester'] ?? '').toString();
    final regNo = (peer['regNo'] ?? '').toString();

    return CustomCard(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          regNo.isNotEmpty
              ? '$department • $semester • $regNo'
              : '$department • $semester',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.secondaryTextColor,
          ),
        ),
        trailing: Checkbox(
          value: isSelected,
          onChanged: (_) {
            setState(() {
              if (isSelected) {
                _selectedIds.remove(peer['id']);
              } else {
                _selectedIds.add(peer['id']);
              }
            });
          },
        ),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(peer['id']);
            } else {
              _selectedIds.add(peer['id']);
            }
          });
        },
      ),
    );
  }

  Widget _buildFooter() {
    final total = _selectedIds.length;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppTheme.dividerColor)),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Row(
        children: [
          Expanded(
            child: Text(
              total > 0 ? '$total selected' : 'Select peers',
              style: GoogleFonts.poppins(color: AppTheme.secondaryTextColor),
            ),
          ),
          CustomButton(
            text: _creating ? 'Creating...' : 'Create Group',
            onPressed: _creating ? null : _createGroup,
          ),
        ],
      ),
    );
  }
}
