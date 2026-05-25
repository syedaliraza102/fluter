import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_management/models/product.dart';
import 'package:product_management/product_service.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late ProductService service;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    service = ProductService(firestore: fakeFirestore);
  });

  test('addProduct creates document in products collection', () async {
    const product = Product(
      name: 'Widget',
      description: 'A useful widget',
      price: 9.99,
      stock: 100,
    );

    await service.addProduct(product);

    final snapshot = await fakeFirestore.collection('products').get();
    expect(snapshot.docs.length, 1);
    expect(snapshot.docs.first.data()['name'], 'Widget');
    expect(snapshot.docs.first.data()['price'], 9.99);
    expect(snapshot.docs.first.data()['stock'], 100);
    expect(snapshot.docs.first.data()['createdAt'], isNotNull);
  });

  test('updateProduct modifies existing document', () async {
    final doc = await fakeFirestore.collection('products').add({
      'name': 'Old',
      'description': '',
      'price': 1.0,
      'stock': 1,
    });

    await service.updateProduct(
      Product(
        id: doc.id,
        name: 'New',
        description: 'Updated',
        price: 2.5,
        stock: 5,
      ),
    );

    final updated = await fakeFirestore.collection('products').doc(doc.id).get();
    expect(updated.data()?['name'], 'New');
    expect(updated.data()?['price'], 2.5);
  });

  test('deleteProduct removes document', () async {
    final doc = await fakeFirestore.collection('products').add({
      'name': 'To Delete',
      'description': '',
      'price': 1.0,
      'stock': 1,
    });

    await service.deleteProduct(doc.id);

    final deleted = await fakeFirestore.collection('products').doc(doc.id).get();
    expect(deleted.exists, false);
  });

  test('updateProduct throws when id is missing', () async {
    const product = Product(
      name: 'No Id',
      description: '',
      price: 1,
      stock: 1,
    );

    expect(
      () => service.updateProduct(product),
      throwsA(isA<ProductServiceException>()),
    );
  });
}
