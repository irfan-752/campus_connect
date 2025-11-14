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
import '../../models/marketplace_model.dart';

class StudentMarketplaceScreen extends StatefulWidget {
  const StudentMarketplaceScreen({super.key});

  @override
  State<StudentMarketplaceScreen> createState() =>
      _StudentMarketplaceScreenState();
}

class _StudentMarketplaceScreenState extends State<StudentMarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'books',
    'electronics',
    'furniture',
    'clothing',
    'other'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Marketplace',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryTextColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateListingDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: ResponsiveWrapper(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('marketplace_items')
                    .where('status', isEqualTo: 'available')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No items available',
                      subtitle: 'Be the first to list an item!',
                      icon: Icons.store,
                    );
                  }

                  var items = snapshot.data!.docs
                      .map((doc) => MarketplaceItemModel.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          ))
                      .toList();

                  if (_selectedCategory != 'All') {
                    items = items
                        .where((item) => item.category == _selectedCategory)
                        .toList();
                  }

                  final query = _searchController.text.toLowerCase();
                  if (query.isNotEmpty) {
                    items = items.where((item) {
                      return item.title.toLowerCase().contains(query) ||
                          item.description.toLowerCase().contains(query);
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
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _buildItemCard(items[index]),
                    );
                  }

                  return ResponsiveGrid(
                    mobileColumns: 1,
                    tabletColumns: 2,
                    desktopColumns: 3,
                    childAspectRatio: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 0.75,
                      tablet: 0.8,
                      desktop: 0.85,
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
                    children: items.map((item) => _buildItemCard(item)).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
              hintText: 'Search items...',
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

  Widget _buildItemCard(MarketplaceItemModel item) {
    final user = FirebaseAuth.instance.currentUser;
    final isMyItem = item.sellerId == user?.uid;

    return CustomCard(
      onTap: () => _showItemDetails(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.images.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.images.first,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 150,
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.image, size: 48),
                ),
              ),
            )
          else
            Container(
              height: 150,
              color: AppTheme.surfaceColor,
              child: const Icon(Icons.image, size: 48),
            ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            item.title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            item.description,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.secondaryTextColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${item.price.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConditionColor(item.condition).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.condition,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _getConditionColor(item.condition),
                  ),
                ),
              ),
            ],
          ),
          if (isMyItem) ...[
            const SizedBox(height: AppTheme.spacingS),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Edit',
                    onPressed: () => _editItem(item),
                    size: ButtonSize.small,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingS),
                Expanded(
                  child: CustomButton(
                    text: item.status == 'available' ? 'Mark Sold' : 'Available',
                    onPressed: () => _toggleItemStatus(item),
                    type: ButtonType.secondary,
                    size: ButtonSize.small,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppTheme.spacingS),
            CustomButton(
              text: 'Contact Seller',
              onPressed: () => _contactSeller(item),
              size: ButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition) {
      case 'new':
        return AppTheme.successColor;
      case 'like-new':
        return AppTheme.primaryColor;
      case 'good':
        return AppTheme.warningColor;
      default:
        return AppTheme.secondaryTextColor;
    }
  }

  void _showItemDetails(MarketplaceItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.images.isNotEmpty)
                Image.network(item.images.first, height: 200, fit: BoxFit.cover),
              const SizedBox(height: AppTheme.spacingM),
              Text('Price: ₹${item.price.toStringAsFixed(0)}'),
              Text('Condition: ${item.condition}'),
              Text('Category: ${item.category}'),
              if (item.location != null) Text('Location: ${item.location}'),
              const SizedBox(height: AppTheme.spacingM),
              Text('Description:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text(item.description),
              const SizedBox(height: AppTheme.spacingM),
              Text('Seller: ${item.sellerName}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (item.sellerId != FirebaseAuth.instance.currentUser?.uid)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _contactSeller(item);
              },
              child: const Text('Contact Seller'),
            ),
        ],
      ),
    );
  }

  Future<void> _contactSeller(MarketplaceItemModel item) async {
    // Get seller contact info
    try {
      final sellerDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(item.sellerId)
          .get();

      if (sellerDoc.exists) {
        final data = sellerDoc.data()!;
        final email = data['email'] ?? '';
        final phone = data['phoneNumber'] ?? '';

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Contact Seller'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (email.isNotEmpty) Text('Email: $email'),
                if (phone.isNotEmpty) Text('Phone: $phone'),
                const SizedBox(height: AppTheme.spacingM),
                const Text('You can also start a chat from the chat section.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showCreateListingDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final locationController = TextEditingController();
    String category = 'books';
    String condition = 'good';
    bool loading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('List Item for Sale'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Item Title *'),
                ),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description *'),
                  maxLines: 3,
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (₹) *'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<String>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ['books', 'electronics', 'furniture', 'clothing', 'other']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v ?? 'books'),
                ),
                DropdownButtonFormField<String>(
                  value: condition,
                  decoration: const InputDecoration(labelText: 'Condition'),
                  items: ['new', 'like-new', 'good', 'fair']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => condition = v ?? 'good'),
                ),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: 'Location'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (titleController.text.isEmpty ||
                          descriptionController.text.isEmpty ||
                          priceController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields')),
                        );
                        return;
                      }

                      setDialogState(() => loading = true);
                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;

                        final studentDoc = await FirebaseFirestore.instance
                            .collection('students')
                            .doc(user.uid)
                            .get();

                        final sellerName = studentDoc.data()?['name'] ?? 'Student';

                        await FirebaseFirestore.instance
                            .collection('marketplace_items')
                            .add({
                          'sellerId': user.uid,
                          'sellerName': sellerName,
                          'title': titleController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'price': double.parse(priceController.text.trim()),
                          'category': category,
                          'images': <String>[],
                          'condition': condition,
                          'location': locationController.text.trim().isEmpty
                              ? null
                              : locationController.text.trim(),
                          'status': 'available',
                          'createdAt': DateTime.now().millisecondsSinceEpoch,
                          'updatedAt': DateTime.now().millisecondsSinceEpoch,
                        });

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Item listed successfully'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        }
                      } catch (e) {
                        setDialogState(() => loading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('List Item'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editItem(MarketplaceItemModel item) async {
    // Similar to create but pre-filled
    _showCreateListingDialog();
  }

  Future<void> _toggleItemStatus(MarketplaceItemModel item) async {
    try {
      await FirebaseFirestore.instance
          .collection('marketplace_items')
          .doc(item.id)
          .update({
        'status': item.status == 'available' ? 'sold' : 'available',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

