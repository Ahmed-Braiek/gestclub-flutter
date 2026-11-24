import 'package:flutter_test/flutter_test.dart';
import 'package:championnat_pro/main.dart';

void main() {
  group('Club', () {
    test('reads SQLite map', () {
      final club = Club.from({'id': 7, 'libelle': 'Étoile Sportive'});
      expect(club.id, 7);
      expect(club.libelle, 'Étoile Sportive');
    });
  });

  group('Joueur', () {
    test('reads SQLite map and constructs full name', () {
      final joueur = Joueur.from({
        'id': 1,
        'nom': 'Ben Ali',
        'prenom': 'Youssef',
        'tel': '22111222',
        'club_id': 7,
        'date_naiss': '2001-04-13',
        'photo': null,
        'favorite': 1,
      });
      expect(joueur.fullName, 'Youssef Ben Ali');
      expect(joueur.favori, isTrue);
      expect(joueur.clubId, 7);
      expect(joueur.naissance, '2001-04-13');
    });

    test('converts favorite status into a SQLite integer', () {
      const joueur = Joueur(
        nom: 'Mansour', prenom: 'Rayen', tel: '55123456',
        clubId: 2, favori: true,
      );
      expect(joueur.data['favorite'], 1);
      expect(joueur.data['club_id'], 2);
      expect(joueur.data['nom'], 'Mansour');
    });

    test('defaults missing favorite field to false', () {
      final joueur = Joueur.from({
        'id': 2, 'nom': 'A', 'prenom': 'B',
        'tel': '12345678', 'club_id': 1,
      });
      expect(joueur.favori, isFalse);
      expect(joueur.data['favorite'], 0);
    });
  });
}
