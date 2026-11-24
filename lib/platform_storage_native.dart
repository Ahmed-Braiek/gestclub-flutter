import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<String> initializeStorage() async {
  if(Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory=databaseFactoryFfi;
  }
  final directory=await getApplicationDocumentsDirectory();
  await directory.create(recursive:true);
  return path.join(directory.path,'championnat.db');
}
