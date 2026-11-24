import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<String> initializeStorage() async {
  databaseFactory=databaseFactoryFfiWeb;
  // SQLite is stored persistently in IndexedDB for the current browser origin.
  return 'championnat.db';
}
