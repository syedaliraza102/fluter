import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/product.dart';

class ProductService {
  ProductService({FirebaseFirestore? firestore})
      : _collection = (firestore ?? FirebaseFirestore.instance)
            .collection('products');

  final CollectionReference<Map<String, dynamic>> _collection;

  static const Duration _timeout = Duration(seconds: 12);

  Stream<List<Product>> watchProducts() {
    return _collection.snapshots().map(_mapSnapshot).timeout(
      _timeout,
      onTimeout: (sink) {
        sink.addError(
          ProductServiceException(
            'Firestore timed out ($_timeout). '
            'Enable Cloud Firestore in Firebase Console and publish rules for "products".',
          ),
        );
      },
    );
  }

  Future<List<Product>> fetchProducts() async {
    try {
      final snapshot = await _collection.get().timeout(_timeout);
      return _mapSnapshot(snapshot);
    } on TimeoutException {
      throw ProductServiceException(
        'Firestore timed out ($_timeout). Enable Cloud Firestore in Firebase Console.',
      );
    } on FirebaseException catch (e) {
      throw ProductServiceException(_messageFromFirebase(e));
    } catch (e) {
      throw ProductServiceException('Failed to load products: $e');
    }
  }

  List<Product> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final products = snapshot.docs.map(Product.fromFirestore).toList();
    products.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return products;
  }

  Future<void> addProduct(Product product) async {
    try {
      await _collection
          .add(product.toFirestore(includeCreatedAt: true))
          .timeout(_timeout);
    } on TimeoutException {
      throw ProductServiceException(
        'Save timed out ($_timeout). Enable Cloud Firestore and publish rules for "products".',
      );
    } on FirebaseException catch (e) {
      throw ProductServiceException(_messageFromFirebase(e));
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    if (product.id == null || product.id!.isEmpty) {
      throw ProductServiceException('Product id is required for update.');
    }
    try {
      await _collection
          .doc(product.id)
          .update(product.toFirestore())
          .timeout(_timeout);
    } on TimeoutException {
      throw ProductServiceException(
        'Update timed out ($_timeout). Check Firestore connection and rules.',
      );
    } on FirebaseException catch (e) {
      throw ProductServiceException(_messageFromFirebase(e));
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _collection.doc(id).delete().timeout(_timeout);
    } on TimeoutException {
      throw ProductServiceException(
        'Delete timed out ($_timeout). Check Firestore connection and rules.',
      );
    } on FirebaseException catch (e) {
      throw ProductServiceException(_messageFromFirebase(e));
    } catch (e) {
      if (e is ProductServiceException) rethrow;
      throw ProductServiceException('Failed to delete product: $e');
    }
  }

  String _messageFromFirebase(FirebaseException e) {
    return e.message ?? 'Firebase error: ${e.code}';
  }
}

class ProductServiceException implements Exception {
  ProductServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
