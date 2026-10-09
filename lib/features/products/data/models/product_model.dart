import '../../domain/entities/product.dart';

class ProductReviewModel extends ProductReview {
  const ProductReviewModel({
    required super.rating,
    required super.comment,
    required super.date,
    required super.reviewerName,
    required super.reviewerEmail,
  });

  factory ProductReviewModel.fromJson(Map<String, dynamic> json) {
    return ProductReviewModel(
      rating: json['rating'] is int ? json['rating'] as int : (double.tryParse(json['rating']?.toString() ?? '5') ?? 5).round(),
      comment: json['comment']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      reviewerName: json['reviewerName']?.toString() ?? 'Anonymous',
      reviewerEmail: json['reviewerEmail']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'comment': comment,
      'date': date,
      'reviewerName': reviewerName,
      'reviewerEmail': reviewerEmail,
    };
  }
}

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    required super.description,
    required super.category,
    required super.price,
    required super.discountPercentage,
    required super.rating,
    required super.stock,
    required super.brand,
    required super.thumbnail,
    required super.images,
    super.reviews,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    var imagesList = <String>[];
    if (json['images'] is List) {
      imagesList = (json['images'] as List).map((e) => e.toString()).toList();
    }
    if (imagesList.isEmpty && json['thumbnail'] != null) {
      imagesList = [json['thumbnail'].toString()];
    }

    var reviewsList = <ProductReviewModel>[];
    if (json['reviews'] is List) {
      reviewsList = (json['reviews'] as List)
          .map((e) => ProductReviewModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }

    return ProductModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : (double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0),
      discountPercentage: (json['discountPercentage'] is num) ? (json['discountPercentage'] as num).toDouble() : 0.0,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : (double.tryParse(json['rating']?.toString() ?? '0.0') ?? 0.0),
      stock: json['stock'] is int ? json['stock'] as int : int.tryParse(json['stock']?.toString() ?? '0') ?? 0,
      brand: json['brand']?.toString() ?? 'Generic',
      thumbnail: json['thumbnail']?.toString() ?? (imagesList.isNotEmpty ? imagesList.first : ''),
      images: imagesList,
      reviews: reviewsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'price': price,
      'discountPercentage': discountPercentage,
      'rating': rating,
      'stock': stock,
      'brand': brand,
      'thumbnail': thumbnail,
      'images': images,
      'reviews': reviews.map((r) {
        if (r is ProductReviewModel) return r.toJson();
        return {
          'rating': r.rating,
          'comment': r.comment,
          'date': r.date,
          'reviewerName': r.reviewerName,
          'reviewerEmail': r.reviewerEmail,
        };
      }).toList(),
    };
  }
}
