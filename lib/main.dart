import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'media_image.dart';
import 'package:image_picker/image_picker.dart';
import 'platform_storage_native.dart' if (dart.library.js_interop) 'platform_storage_web.dart' as storage;
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:url_launcher/url_launcher.dart';

const blue=Color(0xFF425CE8), navy=Color(0xFF101B38), bg=Color(0xFFF5F7FB);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChampionnatApp());
}
class Club {
  final int? id;
  final String libelle;
  final String? logo;
  const Club(this.libelle,{this.id,this.logo});
  factory Club.from(Map<String,Object?> row)=>Club(
    row['libelle'] as String,id:row['id'] as int,logo:row['logo'] as String?);
}
class Rencontre {
  final int? id;
  final int domicile,exterieur;
  final DateTime date;
  final String lieu,statut;
  final int? scoreDomicile,scoreExterieur;
  const Rencontre({this.id,required this.domicile,required this.exterieur,
    required this.date,required this.lieu,this.statut='À venir',
    this.scoreDomicile,this.scoreExterieur});
  factory Rencontre.from(Map<String,Object?> r)=>Rencontre(id:r['id'] as int,
    domicile:r['domicile'] as int,exterieur:r['exterieur'] as int,
    date:DateTime.parse(r['date_match'] as String),lieu:r['lieu'] as String,
    statut:r['statut'] as String,scoreDomicile:r['score_domicile'] as int?,
    scoreExterieur:r['score_exterieur'] as int?);
  Map<String,Object?> get data=>{
    'domicile':domicile,'exterieur':exterieur,
    'date_match':date.toIso8601String(),'lieu':lieu,'statut':statut,
    'score_domicile':scoreDomicile,'score_exterieur':scoreExterieur};
}
class Joueur {
  final int? id;final String nom,prenom,tel;final String? naissance,photo;final int clubId;final bool favori;
  final int buts,passes,matchs,cartons;
  const Joueur({this.id,required this.nom,required this.prenom,required this.tel,
    required this.clubId,this.naissance,this.photo,this.favori=false,
    this.buts=0,this.passes=0,this.matchs=0,this.cartons=0});
  factory Joueur.from(Map<String,Object?> row)=>Joueur(id:row['id'] as int,nom:row['nom'] as String,prenom:row['prenom'] as String,tel:row['tel'] as String,clubId:row['club_id'] as int,naissance:row['date_naiss'] as String?,photo:row['photo'] as String?,favori:(row['favorite'] as int? ?? 0)==1,
    buts:(row['goals'] as int? ?? 0),passes:(row['assists'] as int? ?? 0),
    matchs:(row['appearances'] as int? ?? 0),cartons:(row['yellow_cards'] as int? ?? 0));
  Map<String,Object?> get data=>{'nom':nom,'prenom':prenom,'tel':tel,'club_id':clubId,'date_naiss':naissance,'photo':photo,'favorite':favori?1:0,
    'goals':buts,'assists':passes,'appearances':matchs,'yellow_cards':cartons};
  String get fullName=>prenom+' '+nom;
}
class Repository {
  Repository._();static final instance=Repository._();Database? _db;
  Future<Database> get db async {
    if(_db!=null)return _db!;
    final databasePath=await storage.initializeStorage();
    _db=await openDatabase(databasePath,version:2,
      onConfigure:(db) async=>db.execute('PRAGMA foreign_keys = ON'),
      onCreate:(db,version) async {
        await db.execute('CREATE TABLE clubs (id INTEGER PRIMARY KEY AUTOINCREMENT,libelle TEXT NOT NULL COLLATE NOCASE UNIQUE,logo TEXT)');
        await db.execute('CREATE TABLE joueurs (id INTEGER PRIMARY KEY AUTOINCREMENT,nom TEXT NOT NULL,prenom TEXT NOT NULL,date_naiss TEXT,tel TEXT NOT NULL,photo TEXT,club_id INTEGER NOT NULL REFERENCES clubs(id) ON DELETE RESTRICT,favorite INTEGER NOT NULL DEFAULT 0,goals INTEGER NOT NULL DEFAULT 0,assists INTEGER NOT NULL DEFAULT 0,appearances INTEGER NOT NULL DEFAULT 0,yellow_cards INTEGER NOT NULL DEFAULT 0)');
        await db.execute('CREATE INDEX joueur_club_index ON joueurs(club_id)');
        final logos=[
          'https://commons.wikimedia.org/wiki/Special:FilePath/Club_africain.logo.png',
          'https://commons.wikimedia.org/wiki/Special:FilePath/Logo_1987.jpg',
          'https://commons.wikimedia.org/wiki/Special:FilePath/Logo_historique_de_l%27Etoile_Sportive_du_Sahel_-_1925.jpg'
        ];
        final names=['Club Africain','Espérance Sportive','Étoile Sportive'];
        for(var i=0;i<names.length;i++){
          await db.insert('clubs',{'libelle':names[i],'logo':logos[i]});
        }
        final demo=[['Ben Ali','Youssef','22111222',1],['Trabelsi','Amine','98333444',1],['Mansour','Rayen','55123456',2],['Jaziri','Malek','20456789',2],['Gharbi','Sami','29123456',3],['Khalfallah','Karim','95123456',3]];
        for(var i=0;i<demo.length;i++){
          final row=demo[i];
          await db.insert('joueurs',{'nom':row[0],'prenom':row[1],
            'tel':row[2],'club_id':row[3],
            'photo':'https://randomuser.me/api/portraits/men/${[11,12,14,19,22,35][i]}.jpg',
            'goals':[8,3,12,5,7,2][i],'assists':[4,6,2,5,3,4][i],
            'appearances':[14,12,15,13,12,11][i],
            'yellow_cards':[2,1,3,2,0,1][i]});
        }
        await _createRencontres(db);
        await _seedRencontres(db);
      },
      onUpgrade:(db,oldVersion,newVersion) async {
        if(oldVersion<2){
          await db.execute('ALTER TABLE clubs ADD COLUMN logo TEXT');
          await db.execute('ALTER TABLE joueurs ADD COLUMN goals INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE joueurs ADD COLUMN assists INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE joueurs ADD COLUMN appearances INTEGER NOT NULL DEFAULT 0');
          await db.execute('ALTER TABLE joueurs ADD COLUMN yellow_cards INTEGER NOT NULL DEFAULT 0');
          await _createRencontres(db);
          final logos=[
            'https://commons.wikimedia.org/wiki/Special:FilePath/Club_africain.logo.png',
            'https://commons.wikimedia.org/wiki/Special:FilePath/Logo_1987.jpg',
            'https://commons.wikimedia.org/wiki/Special:FilePath/Logo_historique_de_l%27Etoile_Sportive_du_Sahel_-_1925.jpg'
          ];
          final names=['Club Africain','Espérance Sportive','Étoile Sportive'];
          for(var i=0;i<names.length;i++){
            await db.update('clubs',{'logo':logos[i]},
              where:'libelle = ? AND (logo IS NULL OR logo = ?)',whereArgs:[names[i],'']);
          }
          final demoNames=['Ben Ali','Trabelsi','Mansour','Jaziri','Gharbi','Khalfallah'];
          final demoFirst=['Youssef','Amine','Rayen','Malek','Sami','Karim'];
          for(var i=0;i<demoNames.length;i++){
            await db.update('joueurs',{
              'photo':'https://randomuser.me/api/portraits/men/${[11,12,14,19,22,35][i]}.jpg',
              'goals':[8,3,12,5,7,2][i],'assists':[4,6,2,5,3,4][i],
              'appearances':[14,12,15,13,12,11][i],
              'yellow_cards':[2,1,3,2,0,1][i]},
              where:'nom = ? AND prenom = ? AND photo IS NULL',
              whereArgs:[demoNames[i],demoFirst[i]]);
          }
          await _seedRencontres(db);
        }
      });
    return _db!;
  }
  static Future<void> _createRencontres(Database db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS rencontres ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT,'
      'domicile INTEGER NOT NULL REFERENCES clubs(id) ON DELETE RESTRICT,'
      'exterieur INTEGER NOT NULL REFERENCES clubs(id) ON DELETE RESTRICT,'
      'date_match TEXT NOT NULL,lieu TEXT NOT NULL,'
      "statut TEXT NOT NULL DEFAULT 'À venir',"
      'score_domicile INTEGER,score_exterieur INTEGER,'
      'CHECK(domicile <> exterieur))');
  }
  static Future<void> _seedRencontres(Database db) async {
    final count=Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM rencontres'))??0;
    if(count>0)return;
    final rows=await db.query('clubs',
      where:'libelle IN (?,?,?)',
      whereArgs:['Club Africain','Espérance Sportive','Étoile Sportive']);
    if(rows.length<3)return;
    int id(String name)=>rows.firstWhere((r)=>r['libelle']==name)['id'] as int;
    final now=DateTime.now();
    final fixtures=[
      ['Club Africain','Espérance Sportive',3,'Stade de Radès'],
      ['Étoile Sportive','Club Africain',7,'Stade olympique de Sousse'],
      ['Espérance Sportive','Étoile Sportive',12,'Stade de Radès']
    ];
    for(final fixture in fixtures){
      final day=(fixture[2] as int);
      final date=DateTime(now.year,now.month,now.day+day,17,30);
      await db.insert('rencontres',{
        'domicile':id(fixture[0] as String),
        'exterieur':id(fixture[1] as String),
        'date_match':date.toIso8601String(),
        'lieu':fixture[3],'statut':'À venir'});
    }

  }
  Future<List<Club>> clubs() async=>(await (await db).query('clubs',orderBy:'libelle COLLATE NOCASE')).map(Club.from).toList();
  Future<List<Joueur>> joueurs() async=>(await (await db).query('joueurs',orderBy:'prenom COLLATE NOCASE')).map(Joueur.from).toList();
  Future<void> saveClub(Club c) async {final d=await db;if(c.id==null){await d.insert('clubs',{'libelle':c.libelle,'logo':c.logo});}else{await d.update('clubs',{'libelle':c.libelle,'logo':c.logo},where:'id=?',whereArgs:[c.id]);}}
  Future<void> deleteClub(int id) async {await (await db).delete('clubs',where:'id=?',whereArgs:[id]);}
  Future<void> saveJoueur(Joueur j) async {final d=await db;if(j.id==null){await d.insert('joueurs',j.data);}else{await d.update('joueurs',j.data,where:'id=?',whereArgs:[j.id]);}}
  Future<void> deleteJoueur(int id) async {await (await db).delete('joueurs',where:'id=?',whereArgs:[id]);}
  Future<void> favori(Joueur j) async {await (await db).update('joueurs',{'favorite':j.favori?0:1},where:'id=?',whereArgs:[j.id]);}
  Future<List<Rencontre>> rencontres() async =>
    (await (await db).query('rencontres',orderBy:'date_match ASC'))
       .map(Rencontre.from).toList();
  Future<void> saveRencontre(Rencontre m) async {
    final d=await db;
    if(m.id==null){await d.insert('rencontres',m.data);}
    else{await d.update('rencontres',m.data,where:'id=?',whereArgs:[m.id]);}
  }
  Future<void> deleteRencontre(int id) async {
    await (await db).delete('rencontres',where:'id=?',whereArgs:[id]);
  }
}
class ChampionnatApp extends StatelessWidget {
  const ChampionnatApp({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Championnat Pro',
    theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:bg,colorScheme:ColorScheme.fromSeed(seedColor:blue),
      inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,
        border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none))),
    home:const Accueil());
}
class Accueil extends StatefulWidget {const Accueil({super.key});@override State<Accueil> createState()=>_AccueilState();}
class _AccueilState extends State<Accueil> {
  int section=0;int? clubFilter;String query='';bool favoritesOnly=false,loading=true;
  List<Club> clubs=[];List<Joueur> joueurs=[];List<Rencontre> rencontres=[];
  @override void initState(){super.initState();reload();}
  Future<void> reload() async {
    try{final c=await Repository.instance.clubs();final j=await Repository.instance.joueurs();
      final matches=await Repository.instance.rencontres();
      if(mounted)setState((){clubs=c;joueurs=j;rencontres=matches;loading=false;});
    }catch(e){if(mounted){setState(()=>loading=false);notify('Erreur SQLite : '+e.toString());}}
  }
  void notify(String message){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(message)));}
  String clubName(int id)=>clubs.where((c)=>c.id==id).map((c)=>c.libelle).firstOrNull??'Club inconnu';
  void navigate(int n,{int? club})=>setState((){section=n;clubFilter=club;query='';favoritesOnly=false;});
  Future<bool> confirmation(String message) async=>await showDialog<bool>(context:context,builder:(c)=>AlertDialog(
    title:const Text('Confirmer'),content:Text(message),actions:[
      TextButton(onPressed:()=>Navigator.pop(c,false),child:const Text('Annuler')),
      FilledButton(onPressed:()=>Navigator.pop(c,true),child:const Text('Supprimer'))]))??false;
  Future<void> editClub([Club? club]) async {
    final value=await showDialog<Club>(context:context,
      builder:(c)=>ClubForm(club:club));
    if(value==null)return;
    try{await Repository.instance.saveClub(value);await reload();}
    catch(e){notify('Ce nom est déjà utilisé ou une erreur est survenue.');}
  }
  Future<void> removeClub(Club club) async {
    if(joueurs.any((j)=>j.clubId==club.id)||rencontres.any((m)=>m.domicile==club.id||m.exterieur==club.id)){
      notify('Supprimez les rencontres associées et transférez les joueurs avant de supprimer ce club.');return;
    }
    if(!await confirmation('Supprimer '+club.libelle+' ?'))return;
    await Repository.instance.deleteClub(club.id!);await reload();
  }
  Future<void> editJoueur([Joueur? joueur]) async {
    if(clubs.isEmpty){notify('Ajoutez un club avant le premier joueur.');return;}
    final value=await showDialog<Joueur>(context:context,builder:(c)=>JoueurForm(clubs:clubs,joueur:joueur));
    if(value==null)return;
    try{await Repository.instance.saveJoueur(value);await reload();}
    catch(e){notify('Erreur enregistrement : '+e.toString());}
  }
  Future<void> removeJoueur(Joueur joueur) async {
    if(!await confirmation('Supprimer '+joueur.fullName+' ?'))return;
    await Repository.instance.deleteJoueur(joueur.id!);await reload();
  }
  Future<void> editRencontre([Rencontre? rencontre]) async {
    if(clubs.length<2){notify('Créez au moins deux clubs.');return;}
    final value=await showDialog<Rencontre>(context:context,
      builder:(c)=>RencontreForm(clubs:clubs,rencontre:rencontre));
    if(value==null)return;
    try{await Repository.instance.saveRencontre(value);await reload();}
    catch(e){notify('Enregistrement du match impossible : $e');}
  }
  Future<void> removeRencontre(Rencontre rencontre) async {
    if(!await confirmation('Supprimer cette rencontre ?'))return;
    await Repository.instance.deleteRencontre(rencontre.id!);await reload();
  }
  Future<void> toggle(Joueur joueur) async {await Repository.instance.favori(joueur);await reload();}
  Future<void> appeler(Joueur joueur) async {
    try{final numero=joueur.tel.replaceAll(RegExp(r'[^0-9+]'),'');
      if(!await launchUrl(Uri(scheme:'tel',path:numero))){notify('Téléphone non disponible sur cet appareil.');}
    }catch(e){notify('Impossible de lancer un appel.');}
  }
  Future<void> exporter() async {
    try{
      String quote(String x)=>'"'+x.replaceAll('"','""')+'"';
      final lines=['ID;Nom;Prenom;DateNaiss;Telephone;Club;Favori;Buts;Passes;Apparitions;CartonsJaunes'];
      for(final j in joueurs){lines.add([j.id.toString(),j.nom,j.prenom,j.naissance??'',j.tel,clubName(j.clubId),j.favori?'Oui':'Non',j.buts.toString(),j.passes.toString(),j.matchs.toString(),j.cartons.toString()].map(quote).join(';'));}
      final bytes=utf8.encode('\uFEFF'+lines.join('\r\n'));
      await SharePlus.instance.share(ShareParams(files:[XFile.fromData(Uint8List.fromList(bytes),mimeType:'text/csv',name:'joueurs_championnat.csv')],fileNameOverrides:['joueurs_championnat.csv'],text:'Export des joueurs'));
    }catch(e){notify('Export CSV impossible : '+e.toString());}
  }
  Widget navigation(bool wide){
    final icons=[Icons.dashboard_rounded,Icons.shield_rounded,Icons.groups_rounded,Icons.star_rounded,Icons.leaderboard_rounded,Icons.event_rounded];
    final names=['Tableau de bord','Clubs','Joueurs','Favoris','Statistiques','Matchs'];
    return Container(width:wide?240:null,color:navy,child:SafeArea(child:Column(children:[
      const Padding(padding:EdgeInsets.all(25),child:Row(children:[
        Icon(Icons.emoji_events,color:Color(0xFFFFC76D),size:29),SizedBox(width:8),
        Expanded(child:Text('CHAMPIONNAT',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)))])),
      for(var i=0;i<6;i++)Padding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:3),
        child:ListTile(selected:section==i,selectedTileColor:const Color(0xFF293859),
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
          leading:Icon(icons[i],color:Colors.white70),
          title:Text(names[i],style:const TextStyle(color:Colors.white)),
          onTap:(){navigate(i);if(!wide)Navigator.pop(context);})),
      const Spacer(),const Padding(padding:EdgeInsets.all(20),
        child:Text('GESTION LOCALE • SQLite',style:TextStyle(color:Colors.white54,fontSize:11)))
    ])));
  }
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(c,layout){
    final wide=layout.maxWidth>=850;
    return Scaffold(drawer:wide?null:Drawer(child:navigation(false)),
      body:Row(children:[if(wide)navigation(true),Expanded(child:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.all(16),child:Row(children:[
          if(!wide)Builder(builder:(x)=>IconButton(icon:const Icon(Icons.menu),onPressed:()=>Scaffold.of(x).openDrawer())),
          Expanded(child:Text(['Vue d’ensemble','Gestion des clubs','Gestion des joueurs','Joueurs favoris','Statistiques joueurs','Calendrier des matchs'][section],
            style:const TextStyle(color:navy,fontSize:22,fontWeight:FontWeight.w800))),
          if(section>=2)IconButton(onPressed:exporter,tooltip:'Exporter CSV',icon:const Icon(Icons.download)),
          const CircleAvatar(child:Icon(Icons.sports_soccer))
        ])),
        Expanded(child:loading?const Center(child:CircularProgressIndicator()):
          RefreshIndicator(onRefresh:reload,child:SingleChildScrollView(
            physics:const AlwaysScrollableScrollPhysics(),
            padding:EdgeInsets.fromLTRB(wide?32:16,12,wide?32:16,100),
            child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1200),
              child:AnimatedSwitcher(duration:const Duration(milliseconds:320),
                switchInCurve:Curves.easeOutCubic,switchOutCurve:Curves.easeInCubic,
                transitionBuilder:(child,animation)=>FadeTransition(opacity:animation,
                  child:SlideTransition(position:Tween<Offset>(begin:const Offset(0,.025),end:Offset.zero).animate(animation),child:child)),
                child:KeyedSubtree(key:ValueKey(section),child:section==0?dashboard():section==1?clubPage():section==4?statistiquesPage():section==5?matchsPage():joueurPage()))))))
      ])))]),
      floatingActionButton:section==0||section==4?null:FloatingActionButton.extended(
        onPressed:()=>section==1?editClub():section==5?editRencontre():editJoueur(),icon:const Icon(Icons.add),
        label:Text(section==1?'Nouveau club':section==5?'Nouveau match':'Nouveau joueur')));
  });
  Widget heading(String title,String caption)=>Padding(padding:const EdgeInsets.only(bottom:18),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Text(title,style:const TextStyle(color:navy,fontSize:22,fontWeight:FontWeight.bold)),
      const SizedBox(height:5),Text(caption,style:const TextStyle(color:Colors.black54))]));
  Widget empty(String message)=>Card(child:SizedBox(width:double.infinity,height:150,
    child:Center(child:Text(message,textAlign:TextAlign.center))));
  Widget statistic(String number,String name,IconData icon)=>Card(child:Padding(padding:const EdgeInsets.all(17),
    child:Row(children:[CircleAvatar(child:Icon(icon)),const SizedBox(width:12),
      Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        TweenAnimationBuilder<double>(tween:Tween(begin:0,end:double.tryParse(number)??0),duration:const Duration(milliseconds:720),
          curve:Curves.easeOutCubic,builder:(context,value,child)=>Text(value.round().toString(),
          style:const TextStyle(color:navy,fontSize:26,fontWeight:FontWeight.w900))),
        Text(name,style:const TextStyle(color:Colors.black54,fontSize:12))])])));
  Widget dashboard()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Container(width:double.infinity,padding:const EdgeInsets.all(24),
      decoration:BoxDecoration(borderRadius:BorderRadius.circular(22),
        gradient:const LinearGradient(colors:[navy,Color(0xFF3B4D9E)])),
      child:Wrap(alignment:WrapAlignment.spaceBetween,runSpacing:16,spacing:15,children:[
        const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text('VOTRE ESPACE SPORTIF',style:TextStyle(color:Color(0xFFB7C5FF))),
          SizedBox(height:10),Text('Gérez votre championnat\nen toute simplicité.',
            style:TextStyle(color:Colors.white,fontSize:26,fontWeight:FontWeight.bold)),
          Text('Clubs, joueurs et statistiques au même endroit.',style:TextStyle(color:Colors.white70))]),
        FilledButton.icon(onPressed:()=>editJoueur(),icon:const Icon(Icons.add),
          label:const Text('Ajouter un joueur'),
          style:FilledButton.styleFrom(backgroundColor:Colors.white,foregroundColor:navy))
      ])),
    const SizedBox(height:25),heading('Statistiques','Données enregistrées localement'),
    LayoutBuilder(builder:(c,b)=>GridView.count(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
      crossAxisCount:b.maxWidth>740?3:b.maxWidth>430?2:1,childAspectRatio:2.1,
      crossAxisSpacing:12,mainAxisSpacing:12,children:[
        statistic(clubs.length.toString(),'Clubs',Icons.shield),
        statistic(joueurs.length.toString(),'Joueurs',Icons.groups),
        statistic(joueurs.where((j)=>j.favori).length.toString(),'Favoris',Icons.star),
        statistic(rencontres.where((m)=>m.statut=='À venir'&&!m.date.isBefore(DateTime.now())).length.toString(),'Matchs à venir',Icons.event)
      ])),
    const SizedBox(height:25),heading('Effectifs par club','Cliquez sur un club pour filtrer les joueurs'),
    if(clubs.isEmpty)empty('Aucun club') else for(final club in clubs)
      Card(child:ListTile(onTap:()=>navigate(2,club:club.id),
        leading:MediaImage(source:club.logo,size:44,fallback:Icons.shield),title:Text(club.libelle),
        trailing:Text(joueurs.where((j)=>j.clubId==club.id).length.toString()+' joueurs'))),
    const SizedBox(height:22),
    heading('Prochaines rencontres','Calendrier de démonstration'),
    if(rencontres.where((m)=>m.statut=='À venir'&&!m.date.isBefore(DateTime.now())).isEmpty)
      empty('Aucun match à venir.')
    else for(final match in rencontres.where(
      (m)=>m.statut=='À venir'&&!m.date.isBefore(DateTime.now())).take(3))
      Card(child:ListTile(onTap:()=>navigate(5),
        leading:const Icon(Icons.event_available,color:blue),
        title:Text(clubName(match.domicile)+'  VS  '+clubName(match.exterieur),
          maxLines:2,overflow:TextOverflow.ellipsis),
        subtitle:Text(formatDate(match.date)+' • '+formatHour(match.date)+' • '+match.lieu),
        trailing:const Icon(Icons.chevron_right)))
  ]);
  Widget clubPage()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    heading('Tous les clubs',clubs.length.toString()+' clubs enregistrés'),
    if(clubs.isEmpty)empty('Ajoutez votre premier club')
    else LayoutBuilder(builder:(c,b)=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
      itemCount:clubs.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:b.maxWidth>850?3:b.maxWidth>510?2:1,mainAxisExtent:170,crossAxisSpacing:12,mainAxisSpacing:12),
      itemBuilder:(c,i){final club=clubs[i];return TweenAnimationBuilder<double>(tween:Tween(begin:0,end:1),
        duration:Duration(milliseconds:280+(i%6)*55),curve:Curves.easeOutCubic,
        builder:(context,value,child)=>Opacity(opacity:value,
          child:Transform.translate(offset:Offset(0,12*(1-value)),child:child)),
        child:Card(child:InkWell(onTap:()=>navigate(2,club:club.id),
        child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[MediaImage(source:club.logo,size:55,fallback:Icons.shield),const Spacer(),
            IconButton(onPressed:()=>editClub(club),tooltip:'Modifier',icon:const Icon(Icons.edit_outlined)),
            IconButton(onPressed:()=>removeClub(club),tooltip:'Supprimer',icon:const Icon(Icons.delete_outline,color:Colors.redAccent))]),
          const Spacer(),Text(club.libelle,maxLines:1,overflow:TextOverflow.ellipsis,
            style:const TextStyle(color:navy,fontSize:17,fontWeight:FontWeight.bold)),
          Text(joueurs.where((j)=>j.clubId==club.id).length.toString()+' joueurs • Voir l’effectif')
        ])))));}))
  ]);
  Widget _miniMetric(String icon,String value,String label)=>Row(mainAxisSize:MainAxisSize.min,
    children:[Text(icon),const SizedBox(width:3),Text(value,style:const TextStyle(fontWeight:FontWeight.bold)),
      const SizedBox(width:3),Text(label,style:const TextStyle(fontSize:10,color:Colors.black54))]);

  String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  String formatHour(DateTime d) =>
    '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  Widget statistiquesPage() {
    final classement=[...joueurs]..sort((a,b){
      final goals=b.buts.compareTo(a.buts);
      return goals==0?b.passes.compareTo(a.passes):goals;
    });
    final totalGoals=joueurs.fold<int>(0,(sum,j)=>sum+j.buts);
    final totalAssists=joueurs.fold<int>(0,(sum,j)=>sum+j.passes);
    final totalMatches=joueurs.fold<int>(0,(sum,j)=>sum+j.matchs);
    final maxGoals=classement.isEmpty?1:(classement.first.buts>0?classement.first.buts:1);
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      heading('Performance des joueurs','Les performances sont des données de démonstration modifiables.'),
      LayoutBuilder(builder:(context,box)=>GridView.count(
        crossAxisCount:box.maxWidth>760?3:box.maxWidth>430?2:1,
        childAspectRatio:2.15,mainAxisSpacing:12,crossAxisSpacing:12,
        shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        children:[
          statistic('$totalGoals','Buts inscrits',Icons.sports_soccer),
          statistic('$totalAssists','Passes décisives',Icons.assistant_direction),
          statistic('$totalMatches','Apparitions cumulées',Icons.timer_outlined),
        ])),
      const SizedBox(height:24),
      heading('Classement des buteurs','Tri par buts puis passes décisives'),
      if(classement.isEmpty)empty('Aucun joueur à afficher')
      else for(var i=0;i<classement.length;i++)
        Card(child:Padding(padding:const EdgeInsets.all(16),
          child:Row(children:[
            SizedBox(width:29,child:Text('${i+1}',style:const TextStyle(
              color:blue,fontSize:19,fontWeight:FontWeight.bold))),
            MediaImage(source:classement[i].photo,size:48),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,
              children:[
                Text(classement[i].fullName,
                  style:const TextStyle(fontWeight:FontWeight.bold)),
                Text(clubName(classement[i].clubId),style:const TextStyle(
                  color:Colors.black54,fontSize:12)),
                const SizedBox(height:8),
                LinearProgressIndicator(value:classement[i].buts/maxGoals,
                  minHeight:6,borderRadius:BorderRadius.circular(8)),
              ])),
            const SizedBox(width:12),
            Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
              Text('${classement[i].buts} buts',style:const TextStyle(
                fontWeight:FontWeight.bold,color:navy)),
              Text('${classement[i].passes} passes • ${classement[i].matchs} matchs',
                style:const TextStyle(fontSize:11,color:Colors.black54)),
              Text('${classement[i].cartons} cartons jaunes',
                style:const TextStyle(fontSize:11,color:Colors.black54)),
            ])
          ]))),
    ]);
  }

  Widget matchsPage() {
    final now=DateTime.now();
    final prochains=rencontres.where((m)=>m.statut=='À venir'&&!m.date.isBefore(now)).toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      heading('Calendrier des rencontres',
        '${prochains.length} rencontre(s) à venir • calendrier fictif pour la démonstration.'),
      if(rencontres.isEmpty)empty('Aucun match planifié. Créez votre première rencontre.')
      else for(final m in rencontres)
        Card(child:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
          Wrap(spacing:8,runSpacing:4,
            crossAxisAlignment:WrapCrossAlignment.center,children:[
            Icon(m.statut=='Terminé'?Icons.verified:Icons.event,color:blue,size:18),
            Text('${formatDate(m.date)} • ${formatHour(m.date)}',
              style:const TextStyle(fontWeight:FontWeight.w700)),
            Chip(label:Text(m.statut)),
            IconButton(icon:const Icon(Icons.edit_outlined),
              tooltip:'Modifier le match',onPressed:()=>editRencontre(m)),
            IconButton(icon:const Icon(Icons.delete_outline,color:Colors.redAccent),
              tooltip:'Supprimer le match',onPressed:()=>removeRencontre(m)),
          ]),
          const SizedBox(height:12),
          Row(children:[
            Expanded(child:Column(children:[
              MediaImage(source:clubs.where((c)=>c.id==m.domicile)
                .map((c)=>c.logo).firstOrNull,size:55,fallback:Icons.shield_outlined),
              const SizedBox(height:7),
              Text(clubName(m.domicile),maxLines:2,textAlign:TextAlign.center,
                style:const TextStyle(fontWeight:FontWeight.bold))
            ])),
            Padding(padding:const EdgeInsets.symmetric(horizontal:12),
              child:Text(m.statut=='Terminé'
                ? '${m.scoreDomicile??0} : ${m.scoreExterieur??0}' : 'VS',
                style:const TextStyle(fontSize:24,color:navy,fontWeight:FontWeight.w900))),
            Expanded(child:Column(children:[
              MediaImage(source:clubs.where((c)=>c.id==m.exterieur)
                .map((c)=>c.logo).firstOrNull,size:55,fallback:Icons.shield_outlined),
              const SizedBox(height:7),
              Text(clubName(m.exterieur),maxLines:2,textAlign:TextAlign.center,
                style:const TextStyle(fontWeight:FontWeight.bold))
            ])),
          ]),
          const SizedBox(height:14),
          Row(mainAxisAlignment:MainAxisAlignment.center,children:[
            const Icon(Icons.place_outlined,size:17,color:Colors.black54),
            const SizedBox(width:6),
            Flexible(child:Text(m.lieu,textAlign:TextAlign.center,
              style:const TextStyle(color:Colors.black54))),
          ])
        ])))
    ]);
  }

  Widget joueurPage(){
    final q=query.trim().toLowerCase();
    final filtered=joueurs.where((j){
      if(section==3&&!j.favori)return false;
      if(favoritesOnly&&!j.favori)return false;
      if(clubFilter!=null&&clubFilter!=j.clubId)return false;
      return q.isEmpty||[j.nom,j.prenom,j.tel,clubName(j.clubId)].any((v)=>v.toLowerCase().contains(q));
    }).toList();
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      heading(section==3?'Joueurs favoris':'Tous les joueurs',filtered.length.toString()+' résultat(s)'),
      Wrap(spacing:10,runSpacing:10,children:[
        SizedBox(width:310,child:TextField(onChanged:(v)=>setState(()=>query=v),
          decoration:const InputDecoration(prefixIcon:Icon(Icons.search),hintText:'Nom, prénom, téléphone ou club'))),
        if(section==2)SizedBox(width:210,child:DropdownButtonFormField<int?>(
          key:ValueKey(clubFilter),initialValue:clubFilter,isExpanded:true,
          decoration:const InputDecoration(labelText:'Filtrer par club'),
          items:[const DropdownMenuItem<int?>(value:null,child:Text('Tous les clubs')),
            ...clubs.map((c)=>DropdownMenuItem<int?>(value:c.id,child:Text(c.libelle,overflow:TextOverflow.ellipsis)))],
          onChanged:(v)=>setState(()=>clubFilter=v))),
        if(section==2)FilterChip(label:const Text('Favoris uniquement'),selected:favoritesOnly,
          onSelected:(v)=>setState(()=>favoritesOnly=v)),
        OutlinedButton.icon(onPressed:exporter,icon:const Icon(Icons.download),label:const Text('Exporter CSV'))
      ]),
      const SizedBox(height:18),
      if(filtered.isEmpty)empty('Aucun joueur trouvé')
      else LayoutBuilder(builder:(c,b)=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        itemCount:filtered.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount:b.maxWidth>1050?3:b.maxWidth>650?2:1,mainAxisExtent:214,
          mainAxisSpacing:12,crossAxisSpacing:12),
        itemBuilder:(c,i){final j=filtered[i];final file=j.photo;
          return TweenAnimationBuilder<double>(tween:Tween(begin:0,end:1),
          duration:Duration(milliseconds:280+(i%6)*55),curve:Curves.easeOutCubic,
          builder:(context,value,child)=>Opacity(opacity:value,
            child:Transform.translate(offset:Offset(0,12*(1-value)),child:child)),
          child:Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(children:[
            Row(children:[MediaImage(source:file,size:50,fallback:Icons.person_outline),
              const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(j.fullName,maxLines:1,overflow:TextOverflow.ellipsis,
                  style:const TextStyle(color:navy,fontSize:16,fontWeight:FontWeight.bold)),
                Text(clubName(j.clubId),maxLines:1,overflow:TextOverflow.ellipsis,
                  style:const TextStyle(color:Colors.black54))])),
              IconButton(onPressed:()=>toggle(j),tooltip:'Favori',
                icon:AnimatedSwitcher(duration:const Duration(milliseconds:220),
                  transitionBuilder:(child,animation)=>ScaleTransition(scale:animation,child:child),
                  child:Icon(j.favori?Icons.star:Icons.star_border,key:ValueKey(j.favori),color:j.favori?Colors.amber:Colors.black38)))]),
            const SizedBox(height:8),Row(children:[
              _miniMetric('⚽',j.buts.toString(),'Buts'),
              const SizedBox(width:12),_miniMetric('↗',j.passes.toString(),'Passes'),
              const SizedBox(width:12),_miniMetric('◷',j.matchs.toString(),'Matchs')]),
            const SizedBox(height:8),Row(children:[const Icon(Icons.phone_outlined,size:16),
              const SizedBox(width:8),Text(j.tel)]),
            const Spacer(),const Divider(),
            Row(mainAxisAlignment:MainAxisAlignment.end,children:[
              TextButton.icon(onPressed:()=>appeler(j),icon:const Icon(Icons.call,size:16),label:const Text('Appeler')),
              IconButton(onPressed:()=>editJoueur(j),tooltip:'Modifier',icon:const Icon(Icons.edit_outlined)),
              IconButton(onPressed:()=>removeJoueur(j),tooltip:'Supprimer',
                icon:const Icon(Icons.delete_outline,color:Colors.redAccent))
            ])
          ]))));
        }))
    ]);
  }
}
class JoueurForm extends StatefulWidget {
  final Joueur? joueur;final List<Club> clubs;
  const JoueurForm({super.key,this.joueur,required this.clubs});
  @override State<JoueurForm> createState()=>_JoueurFormState();
}
class _JoueurFormState extends State<JoueurForm> {
  final form=GlobalKey<FormState>();late final TextEditingController nom,prenom,tel;
  int? clubId;DateTime? birth;String? photo;
  late final TextEditingController buts,passes,matchs,cartons;
  @override void initState(){
    super.initState();final j=widget.joueur;
    nom=TextEditingController(text:j?.nom??'');prenom=TextEditingController(text:j?.prenom??'');
    tel=TextEditingController(text:j?.tel??'');clubId=j?.clubId??widget.clubs.first.id;
    photo=j?.photo;birth=j?.naissance==null?null:DateTime.tryParse(j!.naissance!);
    buts=TextEditingController(text:'${j?.buts??0}');passes=TextEditingController(text:'${j?.passes??0}');
    matchs=TextEditingController(text:'${j?.matchs??0}');cartons=TextEditingController(text:'${j?.cartons??0}');
  }
  @override void dispose(){nom.dispose();prenom.dispose();tel.dispose();
    buts.dispose();passes.dispose();matchs.dispose();cartons.dispose();super.dispose();}
  String? requiredField(String? s)=>s==null||s.trim().isEmpty?'Champ obligatoire':null;
  Widget _statInput(TextEditingController controller,String label)=>TextFormField(
    controller:controller,keyboardType:TextInputType.number,
    decoration:InputDecoration(labelText:label),
    validator:(v){final n=int.tryParse(v??'');return n==null||n<0?'Entier ≥ 0 requis':null;});

  @override Widget build(BuildContext context){
    return AlertDialog(title:Text(widget.joueur==null?'Ajouter un joueur':'Modifier un joueur'),
      content:SizedBox(width:430,child:SingleChildScrollView(child:Form(key:form,
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          MediaField(initial:photo,title:'Photo du joueur',
            onChanged:(v)=>photo=v),
          const SizedBox(height:8),TextFormField(controller:prenom,validator:requiredField,
            decoration:const InputDecoration(labelText:'Prénom *')),
          const SizedBox(height:12),TextFormField(controller:nom,validator:requiredField,
            decoration:const InputDecoration(labelText:'Nom *')),
          const SizedBox(height:12),TextFormField(controller:tel,keyboardType:TextInputType.phone,
            validator:(v)=>v==null||!RegExp(r'^\+?[0-9 ]{6,16}$').hasMatch(v.trim())?'Numéro invalide':null,
            decoration:const InputDecoration(labelText:'Téléphone *')),
          const SizedBox(height:12),DropdownButtonFormField<int>(initialValue:clubId,isExpanded:true,
            decoration:const InputDecoration(labelText:'Club *'),
            items:widget.clubs.map((c)=>DropdownMenuItem(value:c.id,
              child:Text(c.libelle,overflow:TextOverflow.ellipsis))).toList(),
            onChanged:(v)=>setState(()=>clubId=v),validator:(v)=>v==null?'Club obligatoire':null),
          const SizedBox(height:12),InkWell(onTap:() async {
            final date=await showDatePicker(context:context,initialDate:birth??DateTime(2002),
              firstDate:DateTime(1940),lastDate:DateTime.now());
            if(date!=null)setState(()=>birth=date);
          },child:InputDecorator(decoration:const InputDecoration(labelText:'Date de naissance',
              suffixIcon:Icon(Icons.calendar_month_outlined)),

            child:Text(birth==null?'Choisir une date':
              birth!.day.toString().padLeft(2,'0')+'/'+birth!.month.toString().padLeft(2,'0')+'/'+birth!.year.toString()))),
          const SizedBox(height:17),
          const Align(alignment:Alignment.centerLeft,child:Text('Statistiques du joueur',
            style:TextStyle(fontWeight:FontWeight.bold))),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child:_statInput(buts,'Buts')),
            const SizedBox(width:8),
            Expanded(child:_statInput(passes,'Passes'))
          ]),
          const SizedBox(height:10),
          Row(children:[
            Expanded(child:_statInput(matchs,'Matchs')),
            const SizedBox(width:8),
            Expanded(child:_statInput(cartons,'Cartons jaunes'))
          ])
        ])))),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Annuler')),
        FilledButton(onPressed:(){
          if(!form.currentState!.validate())return;
          final naissance=birth==null?null:
            birth!.year.toString()+'-'+birth!.month.toString().padLeft(2,'0')+'-'+birth!.day.toString().padLeft(2,'0');
          Navigator.pop(context,Joueur(id:widget.joueur?.id,nom:nom.text.trim(),prenom:prenom.text.trim(),
            tel:tel.text.trim(),clubId:clubId!,naissance:naissance,photo:photo,
            favori:widget.joueur?.favori??false,
            buts:int.parse(buts.text),passes:int.parse(passes.text),
            matchs:int.parse(matchs.text),cartons:int.parse(cartons.text)));
        },child:const Text('Enregistrer'))]
    );
  }
}


class ClubForm extends StatefulWidget {
  final Club? club;
  const ClubForm({super.key,this.club});
  @override State<ClubForm> createState()=>_ClubFormState();
}
class _ClubFormState extends State<ClubForm> {
  final keyForm=GlobalKey<FormState>();
  late final TextEditingController nom;
  String? logo;
  @override void initState(){
    super.initState();nom=TextEditingController(text:widget.club?.libelle??'');
    logo=widget.club?.logo;
  }
  @override void dispose(){nom.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>AlertDialog(
    title:Text(widget.club==null?'Nouveau club':'Modifier le club'),
    content:SizedBox(width:440,child:SingleChildScrollView(child:Form(
      key:keyForm,child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextFormField(controller:nom,autofocus:true,
          decoration:const InputDecoration(labelText:'Nom du club *'),
          validator:(v)=>v==null||v.trim().isEmpty?'Nom obligatoire':null),
        const SizedBox(height:18),
        MediaField(initial:logo,title:'Logo / image du club',
          onChanged:(v)=>logo=v)
      ])))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Annuler')),
      FilledButton(onPressed:(){
        if(!keyForm.currentState!.validate())return;
        Navigator.pop(context,Club(nom.text.trim(),id:widget.club?.id,logo:logo));
      },child:const Text('Enregistrer'))
    ]);
}

class RencontreForm extends StatefulWidget {
  final List<Club> clubs;final Rencontre? rencontre;
  const RencontreForm({super.key,required this.clubs,this.rencontre});
  @override State<RencontreForm> createState()=>_RencontreFormState();
}
class _RencontreFormState extends State<RencontreForm> {
  final form=GlobalKey<FormState>();
  late final TextEditingController lieu,scoreD,scoreE;
  late DateTime date;
  late int domicile,exterieur;
  late String statut;
  @override void initState(){
    super.initState();final m=widget.rencontre;
    domicile=m?.domicile??widget.clubs.first.id!;
    exterieur=m?.exterieur??widget.clubs.firstWhere(
      (c)=>c.id!=domicile).id!;
    date=m?.date??DateTime.now().add(const Duration(days:3));
    statut=m?.statut??'À venir';
    lieu=TextEditingController(text:m?.lieu??'Stade municipal');
    scoreD=TextEditingController(text:m?.scoreDomicile?.toString()??'');
    scoreE=TextEditingController(text:m?.scoreExterieur?.toString()??'');
  }
  @override void dispose(){
    lieu.dispose();scoreD.dispose();scoreE.dispose();super.dispose();
  }
  Widget clubSelect(String label,int value,ValueChanged<int?> change)=>
    DropdownButtonFormField<int>(value:value,isExpanded:true,
      decoration:InputDecoration(labelText:label),
      items:widget.clubs.map((c)=>DropdownMenuItem(value:c.id,
        child:Text(c.libelle,overflow:TextOverflow.ellipsis))).toList(),
      onChanged:change);
  String get displayDate=> '${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year}';
  String get displayTime=> '${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
  @override Widget build(BuildContext context)=>AlertDialog(
    title:Text(widget.rencontre==null?'Planifier un match':'Modifier le match'),
    content:SizedBox(width:440,child:SingleChildScrollView(child:Form(
      key:form,child:Column(mainAxisSize:MainAxisSize.min,children:[
        clubSelect('Club à domicile',domicile,(v){if(v!=null)setState(()=>domicile=v);}),
        const SizedBox(height:12),
        clubSelect('Club visiteur',exterieur,(v){if(v!=null)setState(()=>exterieur=v);}),
        const SizedBox(height:12),
        TextFormField(controller:lieu,decoration:const InputDecoration(
          labelText:'Stade / lieu *'),
          validator:(v)=>v==null||v.trim().isEmpty?'Lieu obligatoire':null),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child:OutlinedButton.icon(icon:const Icon(Icons.calendar_month),
            label:Text(displayDate),onPressed:() async {
              final value=await showDatePicker(context:context,initialDate:date,
                firstDate:DateTime(2020),lastDate:DateTime(2100));
              if(value!=null)setState(()=>date=DateTime(value.year,value.month,
                value.day,date.hour,date.minute));
            })),
          const SizedBox(width:9),
          Expanded(child:OutlinedButton.icon(icon:const Icon(Icons.schedule),
            label:Text(displayTime),onPressed:() async {
              final value=await showTimePicker(context:context,
                initialTime:TimeOfDay.fromDateTime(date));
              if(value!=null)setState(()=>date=DateTime(date.year,date.month,date.day,
                value.hour,value.minute));
            }))
        ]),
        const SizedBox(height:12),
        DropdownButtonFormField<String>(value:statut,
          decoration:const InputDecoration(labelText:'Statut'),
          items:['À venir','En cours','Terminé','Reporté'].map((v)=>
            DropdownMenuItem(value:v,child:Text(v))).toList(),
          onChanged:(v){if(v!=null)setState(()=>statut=v);}),
        if(statut=='Terminé') ...[
          const SizedBox(height:12),
          Row(children:[
            Expanded(child:TextFormField(controller:scoreD,
              keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Buts domicile'),
              validator:(v)=>int.tryParse(v??'')==null||int.parse(v!)<0?'Score invalide':null)),
            const SizedBox(width:10),
            Expanded(child:TextFormField(controller:scoreE,
              keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Buts extérieur'),
              validator:(v)=>int.tryParse(v??'')==null||int.parse(v!)<0?'Score invalide':null))
          ])
        ]
      ])))),
    actions:[
      TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Annuler')),
      FilledButton(onPressed:(){
        if(!form.currentState!.validate())return;
        if(domicile==exterieur){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:Text('Choisissez deux clubs différents.')));
          return;
        }
        Navigator.pop(context,Rencontre(id:widget.rencontre?.id,
          domicile:domicile,exterieur:exterieur,date:date,lieu:lieu.text.trim(),
          statut:statut,scoreDomicile:statut=='Terminé'?int.tryParse(scoreD.text):null,
          scoreExterieur:statut=='Terminé'?int.tryParse(scoreE.text):null));
      },child:const Text('Enregistrer'))
    ]);
}
