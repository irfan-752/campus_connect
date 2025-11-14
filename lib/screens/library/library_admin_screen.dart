import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../models/library_model.dart';

class LibraryAdminScreen extends StatefulWidget {
  const LibraryAdminScreen({super.key});

  @override
  State<LibraryAdminScreen> createState() => _LibraryAdminScreenState();
}

class _LibraryAdminScreenState extends State<LibraryAdminScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const LibraryDashboard(),
    const BookManagementScreen(),
    const BorrowingManagementScreen(),
    const LibraryAnalyticsScreen(),
  ];

  final List<BottomNavigationBarItem> _bottomNavItems = [
    const BottomNavigationBarItem(
      icon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.library_books),
      label: 'Books',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.swap_horiz),
      label: 'Borrowings',
    ),
    const BottomNavigationBarItem(
      icon: Icon(Icons.analytics),
      label: 'Analytics',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _bottomNavItems,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.secondaryTextColor,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        elevation: 8,
      ),
    );
  }
}

class LibraryDashboard extends StatelessWidget {
  const LibraryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Library Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSection(),
            const SizedBox(height: AppTheme.spacingL),
            _buildRecentBorrowings(),
            const SizedBox(height: AppTheme.spacingL),
            _buildOverdueBooks(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Library Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('books')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, snapshot) {
              final totalBooks = snapshot.data?.docs.length ?? 0;
              int totalCopies = 0;
              int availableCopies = 0;

              if (snapshot.hasData) {
                for (final doc in snapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  totalCopies += (data['totalCopies'] ?? 0) as int;
                  availableCopies += (data['availableCopies'] ?? 0) as int;
                }
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('borrowings')
                    .where('status', isEqualTo: 'borrowed')
                    .snapshots(),
                builder: (context, borrowSnapshot) {
                  final activeBorrowings = borrowSnapshot.data?.docs.length ?? 0;

                  return Row(
                    children: [
                      Expanded(
                        child: _buildStatItem('Total Books', totalBooks.toString(), Icons.book),
                      ),
                      Expanded(
                        child: _buildStatItem('Total Copies', totalCopies.toString(), Icons.library_books),
                      ),
                      Expanded(
                        child: _buildStatItem('Available', availableCopies.toString(), Icons.check_circle),
                      ),
                      Expanded(
                        child: _buildStatItem('Borrowed', activeBorrowings.toString(), Icons.swap_horiz),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 32),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBorrowings() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Borrowings',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('borrowings')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingL),
                    child: Text('No recent borrowings'),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    title: Text(data['bookTitle'] ?? ''),
                    subtitle: Text('Status: ${data['status'] ?? ''}'),
                    trailing: Text(
                      DateFormat('MMM dd').format(
                        DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueBooks() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overdue Books',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('borrowings')
                .where('status', isEqualTo: 'borrowed')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final now = DateTime.now();
              final overdue = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final dueDate = DateTime.fromMillisecondsSinceEpoch(data['dueDate'] ?? 0);
                return dueDate.isBefore(now);
              }).toList();

              if (overdue.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppTheme.spacingL),
                    child: Text('No overdue books'),
                  ),
                );
              }

              return Column(
                children: overdue.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final dueDate = DateTime.fromMillisecondsSinceEpoch(data['dueDate'] ?? 0);
                  final daysOverdue = now.difference(dueDate).inDays;
                  return ListTile(
                    title: Text(data['bookTitle'] ?? ''),
                    subtitle: Text('${daysOverdue} days overdue'),
                    trailing: Text(
                      DateFormat('MMM dd').format(dueDate),
                      style: GoogleFonts.poppins(
                        color: AppTheme.errorColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BookManagementScreen extends StatefulWidget {
  const BookManagementScreen({super.key});

  @override
  State<BookManagementScreen> createState() => _BookManagementScreenState();
}

class _BookManagementScreenState extends State<BookManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalCopiesController = TextEditingController();
  final _publisherController = TextEditingController();
  final _publicationYearController = TextEditingController();

  String? _editingBookId;
  bool _loading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _totalCopiesController.dispose();
    _publisherController.dispose();
    _publicationYearController.dispose();
    super.dispose();
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final bookData = {
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'isbn': _isbnController.text.trim(),
        'category': _categoryController.text.trim(),
        'description': _descriptionController.text.trim(),
        'totalCopies': int.parse(_totalCopiesController.text.trim()),
        'availableCopies': int.parse(_totalCopiesController.text.trim()),
        'publisher': _publisherController.text.trim().isEmpty
            ? null
            : _publisherController.text.trim(),
        'publicationYear': _publicationYearController.text.trim().isEmpty
            ? null
            : int.tryParse(_publicationYearController.text.trim()),
        'isActive': true,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (_editingBookId != null) {
        await FirebaseFirestore.instance
            .collection('books')
            .doc(_editingBookId)
            .update(bookData);
      } else {
        bookData['createdAt'] = DateTime.now().millisecondsSinceEpoch;
        await FirebaseFirestore.instance.collection('books').add(bookData);
      }

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book saved successfully'),
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _authorController.clear();
    _isbnController.clear();
    _categoryController.clear();
    _descriptionController.clear();
    _totalCopiesController.clear();
    _publisherController.clear();
    _publicationYearController.clear();
    _editingBookId = null;
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Book Management',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.primaryTextColor,
          elevation: 0,
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: AppTheme.secondaryTextColor,
            tabs: const [
              Tab(text: 'Add/Edit'),
              Tab(text: 'All Books'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookForm(),
            _buildAllBooks(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingM),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Information',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextFormField(
                    controller: _authorController,
                    decoration: const InputDecoration(labelText: 'Author *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextFormField(
                    controller: _isbnController,
                    decoration: const InputDecoration(labelText: 'ISBN *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextFormField(
                    controller: _categoryController,
                    decoration: const InputDecoration(labelText: 'Category *'),
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextFormField(
                    controller: _totalCopiesController,
                    decoration: const InputDecoration(labelText: 'Total Copies *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextFormField(
                    controller: _publisherController,
                    decoration: const InputDecoration(labelText: 'Publisher'),
                  ),
                  const SizedBox(height: AppTheme.spacingM),
                  TextFormField(
                    controller: _publicationYearController,
                    decoration: const InputDecoration(labelText: 'Publication Year'),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            CustomButton(
              text: _loading ? 'Saving...' : 'Save Book',
              onPressed: _loading ? null : _saveBook,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllBooks() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('books')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingWidget();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No books in catalog'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final book = BookModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
            return CustomCard(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
              child: ListTile(
                title: Text(book.title),
                subtitle: Text('${book.author} • ${book.category}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${book.availableCopies}/${book.totalCopies}'),
                    const SizedBox(width: AppTheme.spacingS),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editBook(book),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                      onPressed: () => _deleteBook(book.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editBook(BookModel book) {
    setState(() {
      _editingBookId = book.id;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _isbnController.text = book.isbn;
      _categoryController.text = book.category;
      _descriptionController.text = book.description ?? '';
      _totalCopiesController.text = book.totalCopies.toString();
      _publisherController.text = book.publisher ?? '';
      _publicationYearController.text = book.publicationYear?.toString() ?? '';
    });
  }

  Future<void> _deleteBook(String bookId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Book'),
        content: const Text('Are you sure? This will mark the book as inactive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance.collection('books').doc(bookId).update({
        'isActive': false,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book deleted'),
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

class BorrowingManagementScreen extends StatelessWidget {
  const BorrowingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Borrowing Management'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('borrowings')
            .where('status', isEqualTo: 'borrowed')
            .orderBy('dueDate')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No active borrowings'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final borrowing = BorrowingModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              final isOverdue = borrowing.dueDate.isBefore(DateTime.now());

              return CustomCard(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
                child: ListTile(
                  title: Text(borrowing.bookTitle),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Student ID: ${borrowing.studentId}'),
                      Text(
                        'Due: ${DateFormat('MMM dd, yyyy').format(borrowing.dueDate)}',
                        style: GoogleFonts.poppins(
                          color: isOverdue ? AppTheme.errorColor : AppTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  trailing: CustomButton(
                    text: 'Mark Returned',
                    onPressed: () => _markReturned(context, borrowing),
                    size: ButtonSize.small,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markReturned(BuildContext context, BorrowingModel borrowing) async {
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

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Book marked as returned'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
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

class LibraryAnalyticsScreen extends StatelessWidget {
  const LibraryAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const CustomAppBar(title: 'Library Analytics'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUsageStats(),
            const SizedBox(height: AppTheme.spacingL),
            _buildPopularBooks(),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStats() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('borrowings')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final total = snapshot.data!.docs.length;
              final returned = snapshot.data!.docs
                  .where((doc) => (doc.data() as Map)['status'] == 'returned')
                  .length;
              final active = snapshot.data!.docs
                  .where((doc) => (doc.data() as Map)['status'] == 'borrowed')
                  .length;

              return Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Total', total.toString(), Icons.swap_horiz),
                  ),
                  Expanded(
                    child: _buildStatItem('Returned', returned.toString(), Icons.check_circle),
                  ),
                  Expanded(
                    child: _buildStatItem('Active', active.toString(), Icons.book),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 32),
        const SizedBox(height: AppTheme.spacingXS),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppTheme.secondaryTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPopularBooks() {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most Borrowed Books',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('borrowings')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final bookCounts = <String, int>{};
              for (final doc in snapshot.data!.docs) {
                final bookTitle = (doc.data() as Map)['bookTitle'] ?? '';
                bookCounts[bookTitle] = (bookCounts[bookTitle] ?? 0) + 1;
              }

              final sorted = bookCounts.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

              return Column(
                children: sorted.take(10).map((entry) {
                  return ListTile(
                    leading: const Icon(Icons.book),
                    title: Text(entry.key),
                    trailing: Text(
                      '${entry.value} times',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

