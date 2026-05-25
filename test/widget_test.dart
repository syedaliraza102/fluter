import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_management/home_page.dart';
import 'package:product_management/product_service.dart';

void main() {
  testWidgets('HomePage shows app bar title and FAB', (tester) async {
    final service = ProductService(firestore: FakeFirebaseFirestore());

    await tester.pumpWidget(
      MaterialApp(home: HomePage(productService: service)),
    );
    await tester.pump();

    expect(find.text('Product Management'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
