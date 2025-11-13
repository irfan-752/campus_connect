class MarketplaceItemModel {
  final String id;
  final String sellerId;
  final String sellerName;
  final String title;
  final String description;
  final double price;
  final String category; // 'books', 'electronics', 'furniture', 'clothing', 'other'
  final List<String> images;
  final String condition; // 'new', 'like-new', 'good', 'fair'
  final String? location;
  final String status; // 'available', 'sold', 'reserved'
  final String? buyerId;
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketplaceItemModel({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    this.images = const [],
    required this.condition,
    this.location,
    this.status = 'available',
    this.buyerId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MarketplaceItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MarketplaceItemModel(
      id: id,
      sellerId: map['sellerId'] ?? '',
      sellerName: map['sellerName'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      category: map['category'] ?? 'other',
      images: List<String>.from(map['images'] ?? []),
      condition: map['condition'] ?? 'good',
      location: map['location'],
      status: map['status'] ?? 'available',
      buyerId: map['buyerId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'images': images,
      'condition': condition,
      'location': location,
      'status': status,
      'buyerId': buyerId,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

