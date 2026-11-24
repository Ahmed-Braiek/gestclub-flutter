import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('clubs and players obey foreign key and uniqueness constraints', () async {
    final dir = await Directory.systemTemp.createTemp('championnat_test_');
    final db = await openDatabase(
      p.join(dir.path, 'constraints.db'),
      version: 1,
      onConfigure: (d) async => d.execute('PRAGMA foreign_keys = ON'),
      onCreate: (d, _) async {
        await d.execute('CREATE TABLE clubs (id INTEGER PRIMARY KEY AUTOINCREMENT, libelle TEXT NOT NULL COLLATE NOCASE UNIQUE)');
        await d.execute('CREATE TABLE joueurs (id INTEGER PRIMARY KEY AUTOINCREMENT, nom TEXT NOT NULL, prenom TEXT NOT NULL, tel TEXT NOT NULL, club_id INTEGER NOT NULL REFERENCES clubs(id) ON DELETE RESTRICT)');
      },
    );
    try {
      final clubId = await db.insert('clubs', {'libelle': 'Club Demo'});
      expect(clubId, 1);
      await expectLater(
        db.insert('clubs', {'libelle': 'club demo'}),
        throwsA(isA<DatabaseException>()),
      );
      await expectLater(
        db.insert('joueurs', {
          'nom': 'Test', 'prenom': 'Player',
          'tel': '22222222', 'club_id': 999,
        }),
        throwsA(isA<DatabaseException>()),
      );
      await db.insert('joueurs', {
        'nom': 'Test', 'prenom': 'Player',
        'tel': '22222222', 'club_id': clubId,
      });
      await expectLater(
        db.delete('clubs', where: 'id=?', whereArgs: [clubId]),
        throwsA(isA<DatabaseException>()),
      );
      expect((await db.query('joueurs')).length, 1);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });
}
