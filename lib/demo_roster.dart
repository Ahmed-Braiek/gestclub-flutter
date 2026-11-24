/// Authentic player/club identities and linked photos for a historical showcase.
/// Not a claim of current squad membership or real individual statistics.
class DemoClub {
 final String name,logo; final int colorValue;
 const DemoClub(this.name,this.logo,this.colorValue);
}
class DemoPlayer {
 final String club,prenom,nom,photo,position; final int shirt;
 const DemoPlayer(this.club,this.prenom,this.nom,this.photo,this.position,this.shirt);
}

String commonsPhoto(String filename) =>
 'https://commons.wikimedia.org/wiki/Special:FilePath/${Uri.encodeComponent(filename)}?width=350';

const demoClubs=<DemoClub>[
 DemoClub("Club Africain","https://commons.wikimedia.org/wiki/Special:FilePath/Logo_Club_Africain_officiel.png?width=300",0xFFC63143),
 DemoClub("Espérance Sportive","https://commons.wikimedia.org/wiki/Special:FilePath/Logo_1987.jpg?width=300",0xFFE3A416),
 DemoClub("Étoile Sportive","https://commons.wikimedia.org/wiki/Special:FilePath/Logo_historique_de_l%27Etoile_Sportive_du_Sahel_-_1925.jpg?width=300",0xFFC02733),
 DemoClub("CS Sfaxien","https://commons.wikimedia.org/wiki/Special:FilePath/Logo_Club_Sportif_Sfaxien.png?width=300",0xFF252C3B),
 DemoClub("US Monastir","https://commons.wikimedia.org/wiki/Special:FilePath/Usm_logo_1923.png?width=300",0xFF1761CE),
];
const demoPlayers=<DemoPlayer>[
 // Club Africain
 DemoPlayer("Club Africain","Farouk","Ben Mustapha","Farouk Ben Mustapha.jpg","Gardien",1),
 DemoPlayer("Club Africain","Bilel","Ifa","Bilel Ifa, Tunisia.jpg","Défenseur",4),
 DemoPlayer("Club Africain","Wissem","Ben Yahia","Wissem Ben Yahia, Tunisia.jpg","Milieu",8),
 DemoPlayer("Club Africain","Saber","Khelifa","Saber Khelifa, Tunisia.jpg","Attaquant",9),
 DemoPlayer("Club Africain","Oussama","Haddadi","Oussama Haddadi 20220219 1 (cropped).jpg","Défenseur",3),
 DemoPlayer("Club Africain","Yoann","Touzghar","Yoann Touzghar.JPG","Attaquant",11),
 DemoPlayer("Club Africain","Nader","Ghandri","Nader Ghandri.jpg","Défenseur",5),
 DemoPlayer("Club Africain","Amir","Akrout","Amir Akrout.jpg","Attaquant",10),
 DemoPlayer("Club Africain","Mehdi","Rsaïssi","Mehdi Rsaïssi.jpg","Milieu",6),
 DemoPlayer("Club Africain","Seifeddine","Akremi","Seifeddine Akremi.jpg","Défenseur",2),
 // Espérance Sportive
 DemoPlayer("Espérance Sportive","Moez","Ben Chrifia","Moez Ben Chrifia.jpg","Gardien",1),
 DemoPlayer("Espérance Sportive","Taha Yassine","Khenissi","Taha Yassine Khenissi.jpg","Attaquant",9),
 DemoPlayer("Espérance Sportive","Hamdi","Kasraoui","Hamdi Kasraoui.jpg","Gardien",16),
 DemoPlayer("Espérance Sportive","Khaled","Korbi","Khaled Korbi 2011.jpg","Milieu",8),
 DemoPlayer("Espérance Sportive","Haythem","Jouini","Haythem Jouini.jpg","Attaquant",10),
 DemoPlayer("Espérance Sportive","Mohamed Amine","Ben Hmida","Mohamed Amine Ben Hmida (cropped).jpg","Défenseur",3),
 DemoPlayer("Espérance Sportive","Iheb","Mbarki","Iheb Mbarki.jpg","Défenseur",2),
 DemoPlayer("Espérance Sportive","Rami","Jeridi","Rami Jeridi.jpg","Gardien",12),
 DemoPlayer("Espérance Sportive","Mohamed Ali","Ben Romdhane","Mohamed Ali Ben Romdhane.jpg","Milieu",7),
 DemoPlayer("Espérance Sportive","Youcef","Belaïli","Youcef Belaïli.jpg","Attaquant",11),
 // Étoile Sportive
 DemoPlayer("Étoile Sportive","Aymen","Mathlouthi","Aymen Mathlouthi, Tunisia.jpg","Gardien",1),
 DemoPlayer("Étoile Sportive","Yassine","Chikhaoui","Yassine-Chikhaoui.jpg","Attaquant",10),
 DemoPlayer("Étoile Sportive","Malek","Baayou","Malek Baayou in 2022 - 2.jpg","Milieu",6),
 DemoPlayer("Étoile Sportive","Saber","Ben Frej","Saber Ben Frej.JPG","Défenseur",2),
 DemoPlayer("Étoile Sportive","Hamza","Younés","Hamza Younés.jpg","Attaquant",9),
 DemoPlayer("Étoile Sportive","Mehdi","Meriah","Mehdi Meriah, Tunisia.jpg","Milieu",8),
 DemoPlayer("Étoile Sportive","Hamed","Kammoun","Hamed Kammoun 1973.png","Milieu",7),
 DemoPlayer("Étoile Sportive","Othman","Jenayah","Othman Jenayah 1973.png","Attaquant",11),
 DemoPlayer("Étoile Sportive","Raouf","Ben Aziza","Raouf Ben Aziza 1973.png","Attaquant",5),
 DemoPlayer("Étoile Sportive","Mohsen","Habacha","Mohsen Habacha.JPG","Défenseur",4),
 // CS Sfaxien
 DemoPlayer("CS Sfaxien","Ali","Maâloul","Ali Maâloul.jpg","Défenseur",10),
 DemoPlayer("CS Sfaxien","Ferjani","Sassi","Ferjani Sassi 2.jpg","Milieu",8),
 DemoPlayer("CS Sfaxien","Didier","Ndong","DidierNdong 20220219 4 (cropped).jpg","Milieu",6),
 DemoPlayer("CS Sfaxien","Karim","Aouadhi","Karim Aouadhi (cropped).jpg","Milieu",7),
 DemoPlayer("CS Sfaxien","Iyed","Belwafi","Iyed Belwafi.jpg","Attaquant",11),
 DemoPlayer("CS Sfaxien","Hamza","Younés","Hamza Younés.jpg","Attaquant",9),
 DemoPlayer("CS Sfaxien","Maher","Hannachi","Maher Hannachi.png","Milieu",14),
 DemoPlayer("CS Sfaxien","Sabri","Cheraitia","Sabri cheraitia.jpg","Défenseur",2),
 DemoPlayer("CS Sfaxien","Zied","Ziedi","Zied ziedi.jpg","Milieu",12),
 DemoPlayer("CS Sfaxien","Narcisse","Yaméogo","Narcisse yamego.jpg","Attaquant",15),
 // US Monastir
 DemoPlayer("US Monastir","Faissal","Mannai","https://cdn.al-ain.com/images/2024/3/21/192-193554-faycel-mannai-tunisia-national-team_700x400.jpg","Milieu",10),
 DemoPlayer("US Monastir","Hazem","Mestouri","https://cdn.foot-africa.com/20250706/c219c613f1a76185955b686134b006287b1b29bc1cb6409848876274e200e920-1200-675.jpg","Attaquant",9),
 DemoPlayer("US Monastir","Mahmoud","Ghorbel","https://maghreb-foot.com/wp-content/uploads/2025/01/Mahmoud-Ghorbel.webp","Défenseur",2),
 DemoPlayer("US Monastir","Ahmed","Jafeli","https://cdn.al-ain.com/lg/images/2025/1/14/124-171427-ahmed-jaffeli-tunisia-frensh-4.jpeg","Attaquant",7),
 DemoPlayer("US Monastir","Rayen","Besbes","https://www.alchourouk.com/sites/default/files/article/a.a_1113.jpeg","Gardien",1),
 DemoPlayer("US Monastir","Aymen","Harzi","https://content.mosaiquefm.net/uploads/content/large/1769447429.webp","Milieu",14),
 DemoPlayer("US Monastir","Mortadha","Ben Ouanes","Mortadha Ben Ouanes.jpg","Défenseur",3),
 DemoPlayer("US Monastir","Änis","Ben-Hatira","ÄNISBEN HATIRA.JPG","Milieu",8),
 DemoPlayer("US Monastir","Hichem","Essifi","https://content.mosaiquefm.net/uploads/content/thumbnails/union_sportive_monastirienn_essifi_rejoint_une_equipe_saoudienne_1517159103.jpg","Attaquant",11),
 DemoPlayer("US Monastir","Idriss","Mhirsi","Idriss Mhirsi.jpg","Milieu",17),
];
String demoPhotoUrl(DemoPlayer p)=>p.photo.startsWith('https://')?p.photo:commonsPhoto(p.photo);
int demoClubColor(String? name){for(final club in demoClubs){if(club.name==name)return club.colorValue;}return 0xFF315BDB;}
