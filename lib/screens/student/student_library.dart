import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/library_model.dart';

class StudentLibraryScreen extends StatefulWidget {
  const StudentLibraryScreen({super.key});

  @override
  State<StudentLibraryScreen> createState() => _StudentLibraryScreenState();
}

class _StudentLibraryScreenState extends State<StudentLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Technical', 'Fiction', 'Science', 'History', 'Biography'];
  List<BorrowingModel> _myBorrowings = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMyBorrowings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMyBorrowings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('borrowings')
          .where('studentId', isEqualTo: user.uid)
          .get();

      setState(() {
        _myBorrowings = snapshot.docs
            .map((doc) => BorrowingModel.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList();
      });
    } catch (e) {
      print('Error loading borrowings: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Library',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryTextColor,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.secondaryTextColor,
            tabs: const [
              Tab(text: 'Browse Books'),
              Tab(text: 'My Borrowings'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBrowseBooks(),
            _buildMyBorrowings(),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseBooks() {
    return Column(
      children: [
        _buildSearchAndFilter(),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('books')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const EmptyStateWidget(
                  title: 'No books available',
                  subtitle: 'Check back later',
                  icon: Icons.library_books,
                );
              }

              var books = snapshot.data!.docs
                  .map((doc) => BookModel.fromMap(
                        doc.data(),
                        doc.id,
                      ))
                  .toList();

              if (_selectedCategory != 'All') {
                books = books
                    .where((b) => b.category == _selectedCategory)
                    .toList();
              }

              final query = _searchController.text.toLowerCase();
              if (query.isNotEmpty) {
                books = books.where((b) {
                  return b.title.toLowerCase().contains(query) ||
                      b.author.toLowerCase().contains(query) ||
                      b.isbn.toLowerCase().contains(query);
                }).toList();
              }

              final isTablet = ResponsiveHelper.isTablet(context);
              final isDesktop = ResponsiveHelper.isDesktop(context);
              final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

              if (crossAxisCount == 1) {
                return ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  itemCount: books.length,
                  itemBuilder: (context, index) =>
                      _buildBookCard(books[index]),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: AppTheme.spacingM,
                  crossAxisSpacing: AppTheme.spacingM,
                  childAspectRatio: 0.7,
                ),
                itemCount: books.length,
                itemBuilder: (context, index) => _buildBookCard(books[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search books...',
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

  Widget _buildBookCard(BookModel book) {
    return CustomCard(
      onTap: () => _showBookDetails(book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (book.coverUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.coverUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: AppTheme.surfaceColor,
                  child: const Icon(Icons.book, size: 48),
                ),
              ),
            )
          else
            Container(
              height: 200,
              color: AppTheme.surfaceColor,
              child: const Icon(Icons.book, size: 48),
            ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            book.title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingXS),
          Text(
            book.author,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.secondaryTextColor,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${book.availableCopies}/${book.totalCopies} available',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: book.availableCopies > 0
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                ),
              ),
              CustomButton(
                text: 'Borrow',
                onPressed: book.availableCopies > 0
                    ? () => _borrowBook(book)
                    : null,
                size: ButtonSize.small,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyBorrowings() {
    if (_loading) {
      return const LoadingWidget();
    }

    if (_myBorrowings.isEmpty) {
      return const EmptyStateWidget(
        title: 'No borrowings',
        subtitle: 'Borrow books to see them here',
        icon: Icons.library_books,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      itemCount: _myBorrowings.length,
      itemBuilder: (context, index) => _buildBorrowingCard(_myBorrowings[index]),
    );
  }

  Widget _buildBorrowingCard(BorrowingModel borrowing) {
    final isOverdue = borrowing.dueDate.isBefore(DateTime.now()) &&
        borrowing.status == 'borrowed';

    return CustomCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  borrowing.bookTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(borrowing.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  borrowing.status.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(borrowing.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            'Borrowed: ${DateFormat('MMM dd, yyyy').format(borrowing.borrowDate)}',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
          Text(
            'Due: ${DateFormat('MMM dd, yyyy').format(borrowing.dueDate)}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isOverdue ? AppTheme.errorColor : AppTheme.secondaryTextColor,
            ),
          ),
          if (isOverdue && borrowing.fineAmount != null) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              'Fine: ₹${borrowing.fineAmount!.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.errorColor,
              ),
            ),
          ],
          if (borrowing.status == 'borrowed') ...[
            const SizedBox(height: AppTheme.spacingM),
            CustomButton(
              text: 'Return Book',
              onPressed: () => _returnBook(borrowing),
              size: ButtonSize.small,
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'borrowed':
        return AppTheme.warningColor;
      case 'returned':
        return AppTheme.successColor;
      case 'overdue':
        return AppTheme.errorColor;
      default:
        return AppTheme.secondaryTextColor;
    }
  }

  Future<void> _borrowBook(BookModel book) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (book.availableCopies <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No copies available')),
      );
      return;
    }

    try {
      final dueDate = DateTime.now().add(const Duration(days: 14));
      await FirebaseFirestore.instance.collection('borrowings').add({
        'studentId': user.uid,
        'bookId': book.id,
        'bookTitle': book.title,
        'borrowDate': DateTime.now().millisecondsSinceEpoch,
        'dueDate': dueDate.millisecondsSinceEpoch,
        'status': 'borrowed',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      await FirebaseFirestore.instance.collection('books').doc(book.id).update({
        'availableCopies': book.availableCopies - 1,
      });

      _loadMyBorrowings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book borrowed successfully'),
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

  Future<void> _returnBook(BorrowingModel borrowing) async {
    try {
      final bookDoc = await FirebaseFirestore.instance
          .collection('books')
          .doc(borrowing.bookId)
          .get();

      if (bookDoc.exists) {
        final book = BookModel.fromMap(bookDoc.data()!, bookDoc.id);
        await FirebaseFirestore.instance
            .collection('books')
            .doc(borrowing.bookId)
            .update({
          'availableCopies': book.availableCopies + 1,
        });
      }

      await FirebaseFirestore.instance
          .collection('borrowings')
          .doc(borrowing.id)
          .update({
        'status': 'returned',
        'returnDate': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      _loadMyBorrowings();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book returned successfully'),
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

  void _showBookDetails(BookModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Author: ${book.author}'),
              Text('ISBN: ${book.isbn}'),
              Text('Category: ${book.category}'),
              if (book.description != null) ...[
                const SizedBox(height: AppTheme.spacingM),
                Text(book.description!),
              ],
              const SizedBox(height: AppTheme.spacingM),
              Text(
                'Available: ${book.availableCopies}/${book.totalCopies}',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (book.availableCopies > 0)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _borrowBook(book);
              },
              child: const Text('Borrow'),
            ),
        ],
      ),
    );
  }
}

