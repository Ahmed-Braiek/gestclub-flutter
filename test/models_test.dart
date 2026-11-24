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

  group('Version 2', () {
    test('club supports a linked image', () {
      final club=Club.from({
        'id': 4, 'libelle': 'Club Démo',
        'logo': 'https://example.org/club.png'
      });
      expect(club.logo,'https://example.org/club.png');
    });

    test('player statistics serialize and deserialize', () {
      const player=Joueur(nom:'Ben Ali',prenom:'Youssef',
        tel:'22111222',clubId:1,buts:8,passes:4,matchs:14,cartons:2);
      final stored=Map<String,Object?>.from(player.data)
        ..addAll({'id':9});
      final loaded=Joueur.from(stored);
      expect(loaded.buts,8);
      expect(loaded.passes,4);
      expect(loaded.matchs,14);
      expect(loaded.cartons,2);
    });

    test('match fixture roundtrip includes scores and stadium', () {
      final date=DateTime(2026,12,7,17,30);
      final fixture=Rencontre(domicile:1,exterieur:2,date:date,
        lieu:'Stade de Radès',statut:'Terminé',
        scoreDomicile:2,scoreExterieur:1);
      final map=Map<String,Object?>.from(fixture.data)
        ..addAll({'id':42});
      final result=Rencontre.from(map);
      expect(result.date,date);
      expect(result.domicile,1);
      expect(result.exterieur,2);
      expect(result.scoreDomicile,2);
      expect(result.scoreExterieur,1);
    });
  });
}
