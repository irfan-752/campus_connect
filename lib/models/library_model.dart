class BookModel {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String? coverUrl;
  final String category;
  final String? description;
  final int totalCopies;
  final int availableCopies;
  final String? publisher;
  final int? publicationYear;
  final List<String> tags;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    this.coverUrl,
    required this.category,
    this.description,
    required this.totalCopies,
    required this.availableCopies,
    this.publisher,
    this.publicationYear,
    this.tags = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookModel.fromMap(Map<String, dynamic> map, String id) {
    return BookModel(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      isbn: map['isbn'] ?? '',
      coverUrl: map['coverUrl'],
      category: map['category'] ?? '',
      description: map['description'],
      totalCopies: map['totalCopies'] ?? 0,
      availableCopies: map['availableCopies'] ?? 0,
      publisher: map['publisher'],
      publicationYear: map['publicationYear'],
      tags: List<String>.from(map['tags'] ?? []),
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'author': author,
      'isbn': isbn,
      'coverUrl': coverUrl,
      'category': category,
      'description': description,
      'totalCopies': totalCopies,
      'availableCopies': availableCopies,
      'publisher': publisher,
      'publicationYear': publicationYear,
      'tags': tags,
      'isActive': isActive,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

class BorrowingModel {
  final String id;
  final String studentId;
  final String bookId;
  final String bookTitle;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String status; // 'borrowed', 'returned', 'overdue'
  final double? fineAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  BorrowingModel({
    required this.id,
    required this.studentId,
    required this.bookId,
    required this.bookTitle,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
    this.fineAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BorrowingModel.fromMap(Map<String, dynamic> map, String id) {
    return BorrowingModel(
      id: id,
      studentId: map['studentId'] ?? '',
      bookId: map['bookId'] ?? '',
      bookTitle: map['bookTitle'] ?? '',
      borrowDate: DateTime.fromMillisecondsSinceEpoch(map['borrowDate'] ?? 0),
      dueDate: DateTime.fromMillisecondsSinceEpoch(map['dueDate'] ?? 0),
      returnDate: map['returnDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['returnDate'])
          : null,
      status: map['status'] ?? 'borrowed',
      fineAmount: map['fineAmount']?.toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'borrowDate': borrowDate.millisecondsSinceEpoch,
      'dueDate': dueDate.millisecondsSinceEpoch,
      'returnDate': returnDate?.millisecondsSinceEpoch,
      'status': status,
      'fineAmount': fineAmount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

