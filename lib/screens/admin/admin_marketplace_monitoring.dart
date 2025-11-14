import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/responsive_wrapper.dart';
import '../../models/marketplace_model.dart';

class AdminMarketplaceMonitoring extends StatefulWidget {
  const AdminMarketplaceMonitoring({super.key});

  @override
  State<AdminMarketplaceMonitoring> createState() =>
      _AdminMarketplaceMonitoringState();
}

class _AdminMarketplaceMonitoringState
    extends State<AdminMarketplaceMonitoring> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Available', 'Sold', 'Reported'];

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
                    .collection('marketplace_items')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget();
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text('No marketplace items'),
                    );
                  }

                  var items = snapshot.data!.docs
                      .map((doc) => MarketplaceItemModel.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          ))
                      .toList();

                  if (_selectedFilter != 'All') {
                    if (_selectedFilter == 'Reported') {
                      // Filter reported items (would need a 'reported' field)
                      items = items.where((item) => false).toList();
                    } else {
                      items = items
                          .where((item) => item.status == _selectedFilter.toLowerCase())
                          .toList();
                    }
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
                    itemCount: items.length,
                    itemBuilder: (context, index) =>
                        _buildItemCard(items[index]),
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
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingS),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (v) {
                  setState(() => _selectedFilter = filter);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildItemCard(MarketplaceItemModel item) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.images.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.images.first,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: AppTheme.surfaceColor,
                      child: const Icon(Icons.image),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.image),
                ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      '₹${item.price.toStringAsFixed(0)} • ${item.category}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXS),
                    Text(
                      'Seller: ${item.sellerName}',
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
                  color: _getStatusColor(item.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: _getStatusColor(item.status),
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
                  onPressed: () => _showItemDetails(item),
                  size: ButtonSize.small,
                  type: ButtonType.secondary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingS),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _toggleItemStatus(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: item.status == 'available'
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                    side: BorderSide(
                      color: item.status == 'available'
                          ? AppTheme.errorColor
                          : AppTheme.primaryColor,
                    ),
                  ),
                  child: Text(
                    item.status == 'available' ? 'Remove' : 'Restore',
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return AppTheme.successColor;
      case 'sold':
        return AppTheme.secondaryTextColor;
      default:
        return AppTheme.warningColor;
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
              Text('Category: ${item.category}'),
              Text('Condition: ${item.condition}'),
              Text('Status: ${item.status}'),
              if (item.location != null) Text('Location: ${item.location}'),
              const SizedBox(height: AppTheme.spacingM),
              Text('Description:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              Text(item.description),
              const SizedBox(height: AppTheme.spacingM),
              Text('Seller: ${item.sellerName}'),
              Text('Seller ID: ${item.sellerId}'),
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

  Future<void> _toggleItemStatus(MarketplaceItemModel item) async {
    try {
      await FirebaseFirestore.instance
          .collection('marketplace_items')
          .doc(item.id)
          .update({
        'status': item.status == 'available' ? 'removed' : 'available',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              item.status == 'available'
                  ? 'Item removed'
                  : 'Item restored',
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

