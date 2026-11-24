import 'package:flutter_test/flutter_test.dart';
import 'package:championnat_pro/demo_roster.dart';

void main() {
  test('Showcase contains five authentic club identities', () {
    expect(demoClubs.length, 5);
    expect(demoClubs.map((e)=>e.name).toSet().length,5);
    for(final club in demoClubs) {
      expect(Uri.tryParse(club.logo)?.hasAbsolutePath, true);
      expect(club.colorValue, greaterThan(0));
    }
  });

  test('Exactly ten distinct player records per showcase club', () {
    expect(demoPlayers.length, 50);
    for(final club in demoClubs) {
      final members=demoPlayers.where((p)=>p.club==club.name).toList();
      expect(members.length, 10,reason:'Club: ${club.name}');
      expect(members.map((p)=>'${p.prenom} ${p.nom}').toSet().length, 10);
      for(final player in members){
        expect(player.prenom.isNotEmpty,true);
        expect(player.nom.isNotEmpty,true);
        expect(player.photo.isNotEmpty,true);
        final url=Uri.parse(demoPhotoUrl(player));
        expect(url.scheme,'https');
        expect(url.host.isNotEmpty,true);
      }
    }
  });

  test('Club colors resolve consistently and unknown clubs fallback', () {
    expect(demoClubColor('Club Africain'),0xFFC63143);
    expect(demoClubColor('Espérance Sportive'),0xFFE3A416);
    expect(demoClubColor('Club créé par utilisateur'),0xFF315BDB);
  });
}
