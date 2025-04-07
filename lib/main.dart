import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ortak/app.dart';
import 'package:ortak/core/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SQLite database
  await DatabaseHelper.instance.database;
  
  runApp(
    const ProviderScope(
      child: OrtakApp(),
    ),
  );
}
