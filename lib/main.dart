import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:url_launcher/url_launcher.dart';

const blue=Color(0xFF425CE8), navy=Color(0xFF101B38), bg=Color(0xFFF5F7FB);
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if(Platform.isWindows||Platform.isLinux){sqfliteFfiInit();databaseFactory=databaseFactoryFfi;}
  runApp(const ChampionnatApp());
}
class Club {
  final int? id;final String libelle;
  const Club(this.libelle,{this.id});
  factory Club.from(Map<String,Object?> row)=>Club(row['libelle'] as String,id:row['id'] as int);
}
class Joueur {
  final int? id;final String nom,prenom,tel;final String? naissance,photo;final int clubId;final bool favori;
  const Joueur({this.id,required this.nom,required this.prenom,required this.tel,required this.clubId,this.naissance,this.photo,this.favori=false});
  factory Joueur.from(Map<String,Object?> row)=>Joueur(id:row['id'] as int,nom:row['nom'] as String,prenom:row['prenom'] as String,tel:row['tel'] as String,clubId:row['club_id'] as int,naissance:row['date_naiss'] as String?,photo:row['photo'] as String?,favori:(row['favorite'] as int? ?? 0)==1);
  Map<String,Object?> get data=>{'nom':nom,'prenom':prenom,'tel':tel,'club_id':clubId,'date_naiss':naissance,'photo':photo,'favorite':favori?1:0};
  String get fullName=>prenom+' '+nom;
}
class Repository {
  Repository._();static final instance=Repository._();Database? _db;
  Future<Database> get db async {
    if(_db!=null)return _db!;
    final directory=await getApplicationDocumentsDirectory();
    await directory.create(recursive:true);
    _db=await openDatabase(path.join(directory.path,'championnat.db'),version:1,
      onConfigure:(db) async=>db.execute('PRAGMA foreign_keys = ON'),
      onCreate:(db,version) async {
        await db.execute('CREATE TABLE clubs (id INTEGER PRIMARY KEY AUTOINCREMENT,libelle TEXT NOT NULL COLLATE NOCASE UNIQUE)');
        await db.execute('CREATE TABLE joueurs (id INTEGER PRIMARY KEY AUTOINCREMENT,nom TEXT NOT NULL,prenom TEXT NOT NULL,date_naiss TEXT,tel TEXT NOT NULL,photo TEXT,club_id INTEGER NOT NULL REFERENCES clubs(id) ON DELETE RESTRICT,favorite INTEGER NOT NULL DEFAULT 0)');
        await db.execute('CREATE INDEX joueur_club_index ON joueurs(club_id)');
        for(final name in ['Club Africain','Espérance Sportive','Étoile Sportive']){await db.insert('clubs',{'libelle':name});}
        final demo=[['Ben Ali','Youssef','22111222',1],['Trabelsi','Amine','98333444',1],['Mansour','Rayen','55123456',2],['Jaziri','Malek','20456789',2],['Gharbi','Sami','29123456',3],['Khalfallah','Karim','95123456',3]];
        for(final row in demo){await db.insert('joueurs',{'nom':row[0],'prenom':row[1],'tel':row[2],'club_id':row[3]});}
      });
    return _db!;
  }
  Future<List<Club>> clubs() async=>(await (await db).query('clubs',orderBy:'libelle COLLATE NOCASE')).map(Club.from).toList();
  Future<List<Joueur>> joueurs() async=>(await (await db).query('joueurs',orderBy:'prenom COLLATE NOCASE')).map(Joueur.from).toList();
  Future<void> saveClub(Club c) async {final d=await db;if(c.id==null){await d.insert('clubs',{'libelle':c.libelle});}else{await d.update('clubs',{'libelle':c.libelle},where:'id=?',whereArgs:[c.id]);}}
  Future<void> deleteClub(int id) async {await (await db).delete('clubs',where:'id=?',whereArgs:[id]);}
  Future<void> saveJoueur(Joueur j) async {final d=await db;if(j.id==null){await d.insert('joueurs',j.data);}else{await d.update('joueurs',j.data,where:'id=?',whereArgs:[j.id]);}}
  Future<void> deleteJoueur(int id) async {await (await db).delete('joueurs',where:'id=?',whereArgs:[id]);}
  Future<void> favori(Joueur j) async {await (await db).update('joueurs',{'favorite':j.favori?0:1},where:'id=?',whereArgs:[j.id]);}
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
  List<Club> clubs=[];List<Joueur> joueurs=[];
  @override void initState(){super.initState();reload();}
  Future<void> reload() async {
    try{final c=await Repository.instance.clubs();final j=await Repository.instance.joueurs();
      if(mounted)setState((){clubs=c;joueurs=j;loading=false;});
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
    final input=TextEditingController(text:club?.libelle??'');
    final value=await showDialog<String>(context:context,builder:(c)=>AlertDialog(
      title:Text(club==null?'Ajouter un club':'Modifier le club'),
      content:TextField(controller:input,autofocus:true,decoration:const InputDecoration(labelText:'Nom du club')),
      actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('Annuler')),
        FilledButton(onPressed:()=>Navigator.pop(c,input.text.trim()),child:const Text('Enregistrer'))]));
    if(value==null||value.trim().isEmpty)return;
    try{await Repository.instance.saveClub(Club(value,id:club?.id));await reload();}
    catch(e){notify('Ce nom est déjà utilisé ou une erreur est survenue.');}
  }
  Future<void> removeClub(Club club) async {
    if(joueurs.any((j)=>j.clubId==club.id)){notify('Transférez les joueurs avant de supprimer leur club.');return;}
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
  Future<void> toggle(Joueur joueur) async {await Repository.instance.favori(joueur);await reload();}
  Future<void> appeler(Joueur joueur) async {
    try{final numero=joueur.tel.replaceAll(RegExp(r'[^0-9+]'),'');
      if(!await launchUrl(Uri(scheme:'tel',path:numero))){notify('Téléphone non disponible sur cet appareil.');}
    }catch(e){notify('Impossible de lancer un appel.');}
  }
  Future<void> exporter() async {
    try{
      String quote(String x)=>'"'+x.replaceAll('"','""')+'"';
      final lines=['ID;Nom;Prenom;DateNaiss;Telephone;Club;Favori'];
      for(final j in joueurs){lines.add([j.id.toString(),j.nom,j.prenom,j.naissance??'',j.tel,clubName(j.clubId),j.favori?'Oui':'Non'].map(quote).join(';'));}
      final dir=await getTemporaryDirectory();
      final output=File(path.join(dir.path,'joueurs_championnat.csv'));
      await output.writeAsString('\uFEFF'+lines.join('\r\n'));
      await SharePlus.instance.share(ShareParams(files:[XFile(output.path)],text:'Export des joueurs'));
    }catch(e){notify('Export CSV impossible : '+e.toString());}
  }
  Widget navigation(bool wide){
    final icons=[Icons.dashboard_rounded,Icons.shield_rounded,Icons.groups_rounded,Icons.star_rounded];
    final names=['Tableau de bord','Clubs','Joueurs','Favoris'];
    return Container(width:wide?240:null,color:navy,child:SafeArea(child:Column(children:[
      const Padding(padding:EdgeInsets.all(25),child:Row(children:[
        Icon(Icons.emoji_events,color:Color(0xFFFFC76D),size:29),SizedBox(width:8),
        Expanded(child:Text('CHAMPIONNAT',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)))])),
      for(var i=0;i<4;i++)Padding(padding:const EdgeInsets.symmetric(horizontal:10,vertical:3),
        child:ListTile(selected:section==i,selectedTileColor:const Color(0xFF293859),
          shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(12)),
          leading:Icon(icons[i],color:Colors.white70),
          title:Text(names[i],style:const TextStyle(color:Colors.white)),
          onTap:(){navigate(i);if(!wide)Navigator.pop(context);})),
      const Spacer(),const Padding(padding:EdgeInsets.all(20),
        child:Text('GESTION LOCALE • SQLite',style:TextStyle(color:Colors.white54,fontSize:11)))
    ]))));
  }
  @override Widget build(BuildContext context)=>LayoutBuilder(builder:(c,layout){
    final wide=layout.maxWidth>=850;
    return Scaffold(drawer:wide?null:Drawer(child:navigation(false)),
      body:Row(children:[if(wide)navigation(true),Expanded(child:SafeArea(child:Column(children:[
        Padding(padding:const EdgeInsets.all(16),child:Row(children:[
          if(!wide)Builder(builder:(x)=>IconButton(icon:const Icon(Icons.menu),onPressed:()=>Scaffold.of(x).openDrawer())),
          Expanded(child:Text(['Vue d’ensemble','Gestion des clubs','Gestion des joueurs','Joueurs favoris'][section],
            style:const TextStyle(color:navy,fontSize:22,fontWeight:FontWeight.w800))),
          if(section>=2)IconButton(onPressed:exporter,tooltip:'Exporter CSV',icon:const Icon(Icons.download)),
          const CircleAvatar(child:Icon(Icons.sports_soccer))
        ])),
        Expanded(child:loading?const Center(child:CircularProgressIndicator()):
          RefreshIndicator(onRefresh:reload,child:SingleChildScrollView(
            physics:const AlwaysScrollableScrollPhysics(),
            padding:EdgeInsets.fromLTRB(wide?32:16,12,wide?32:16,100),
            child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1200),
              child:section==0?dashboard():section==1?clubPage():joueurPage()))))
      ])))]),
      floatingActionButton:section==0?null:FloatingActionButton.extended(
        onPressed:()=>section==1?editClub():editJoueur(),icon:const Icon(Icons.add),
        label:Text(section==1?'Nouveau club':'Nouveau joueur')));
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
        Text(number,style:const TextStyle(color:navy,fontSize:26,fontWeight:FontWeight.w900)),
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
        statistic(joueurs.where((j)=>j.favori).length.toString(),'Favoris',Icons.star)
      ])),
    const SizedBox(height:25),heading('Effectifs par club','Cliquez sur un club pour filtrer les joueurs'),
    if(clubs.isEmpty)empty('Aucun club') else for(final club in clubs)
      Card(child:ListTile(onTap:()=>navigate(2,club:club.id),
        leading:const Icon(Icons.shield,color:blue),title:Text(club.libelle),
        trailing:Text(joueurs.where((j)=>j.clubId==club.id).length.toString()+' joueurs')))
  ]);
  Widget clubPage()=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    heading('Tous les clubs',clubs.length.toString()+' clubs enregistrés'),
    if(clubs.isEmpty)empty('Ajoutez votre premier club')
    else LayoutBuilder(builder:(c,b)=>GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
      itemCount:clubs.length,gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:b.maxWidth>850?3:b.maxWidth>510?2:1,mainAxisExtent:170,crossAxisSpacing:12,mainAxisSpacing:12),
      itemBuilder:(c,i){final club=clubs[i];return Card(child:InkWell(onTap:()=>navigate(2,club:club.id),
        child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Row(children:[const CircleAvatar(child:Icon(Icons.shield)),const Spacer(),
            IconButton(onPressed:()=>editClub(club),tooltip:'Modifier',icon:const Icon(Icons.edit_outlined)),
            IconButton(onPressed:()=>removeClub(club),tooltip:'Supprimer',icon:const Icon(Icons.delete_outline,color:Colors.redAccent))]),
          const Spacer(),Text(club.libelle,maxLines:1,overflow:TextOverflow.ellipsis,
            style:const TextStyle(color:navy,fontSize:17,fontWeight:FontWeight.bold)),
          Text(joueurs.where((j)=>j.clubId==club.id).length.toString()+' joueurs • Voir l’effectif')
        ]))));}))
  ]);
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
          crossAxisCount:b.maxWidth>1050?3:b.maxWidth>650?2:1,mainAxisExtent:194,
          mainAxisSpacing:12,crossAxisSpacing:12),
        itemBuilder:(c,i){final j=filtered[i];final file=j.photo;
          final hasPhoto=file!=null&&File(file).existsSync();
          return Card(child:Padding(padding:const EdgeInsets.all(15),child:Column(children:[
            Row(children:[CircleAvatar(radius:25,backgroundImage:hasPhoto?FileImage(File(file!)):null,
                child:hasPhoto?null:Text(j.prenom.isEmpty?'?':j.prenom.substring(0,1))),
              const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(j.fullName,maxLines:1,overflow:TextOverflow.ellipsis,
                  style:const TextStyle(color:navy,fontSize:16,fontWeight:FontWeight.bold)),
                Text(clubName(j.clubId),maxLines:1,overflow:TextOverflow.ellipsis,
                  style:const TextStyle(color:Colors.black54))])),
              IconButton(onPressed:()=>toggle(j),tooltip:'Favori',
                icon:Icon(j.favori?Icons.star:Icons.star_border,color:j.favori?Colors.amber:Colors.black38))]),
            const SizedBox(height:12),Row(children:[const Icon(Icons.phone_outlined,size:16),
              const SizedBox(width:8),Text(j.tel)]),
            const Spacer(),const Divider(),
            Row(mainAxisAlignment:MainAxisAlignment.end,children:[
              TextButton.icon(onPressed:()=>appeler(j),icon:const Icon(Icons.call,size:16),label:const Text('Appeler')),
              IconButton(onPressed:()=>editJoueur(j),tooltip:'Modifier',icon:const Icon(Icons.edit_outlined)),
              IconButton(onPressed:()=>removeJoueur(j),tooltip:'Supprimer',
                icon:const Icon(Icons.delete_outline,color:Colors.redAccent))
            ])
          ])));
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
  int? clubId;DateTime? birth;String? photo;bool photoLoading=false;
  @override void initState(){
    super.initState();final j=widget.joueur;
    nom=TextEditingController(text:j?.nom??'');prenom=TextEditingController(text:j?.prenom??'');
    tel=TextEditingController(text:j?.tel??'');clubId=j?.clubId??widget.clubs.first.id;
    photo=j?.photo;birth=j?.naissance==null?null:DateTime.tryParse(j!.naissance!);
  }
  @override void dispose(){nom.dispose();prenom.dispose();tel.dispose();super.dispose();}
  Future<void> choosePhoto() async {
    try{
      final selected=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:75,maxWidth:1000);
      if(selected==null)return;
      setState(()=>photoLoading=true);
      final dir=await getApplicationDocumentsDirectory();
      final folder=Directory(path.join(dir.path,'photos'));await folder.create(recursive:true);
      final ext=path.extension(selected.path);final dest=path.join(folder.path,
        'joueur_'+DateTime.now().microsecondsSinceEpoch.toString()+(ext.isEmpty?'.jpg':ext));
      await File(selected.path).copy(dest);
      if(mounted)setState(()=>photo=dest);
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Photo impossible : '+e.toString())));}
    finally{if(mounted)setState(()=>photoLoading=false);}
  }
  String? requiredField(String? s)=>s==null||s.trim().isEmpty?'Champ obligatoire':null;
  @override Widget build(BuildContext context){
    final hasPhoto=photo!=null&&File(photo!).existsSync();
    return AlertDialog(title:Text(widget.joueur==null?'Ajouter un joueur':'Modifier un joueur'),
      content:SizedBox(width:430,child:SingleChildScrollView(child:Form(key:form,
        child:Column(mainAxisSize:MainAxisSize.min,children:[
          CircleAvatar(radius:34,backgroundImage:hasPhoto?FileImage(File(photo!)):null,
            child:hasPhoto?null:const Icon(Icons.person,size:32)),
          TextButton.icon(onPressed:photoLoading?null:choosePhoto,
            icon:const Icon(Icons.photo_camera_outlined),label:const Text('Choisir une photo')),
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
              birth!.day.toString().padLeft(2,'0')+'/'+birth!.month.toString().padLeft(2,'0')+'/'+birth!.year.toString())))
        ])))),
      actions:[TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Annuler')),
        FilledButton(onPressed:photoLoading?null:(){
          if(!form.currentState!.validate())return;
          final naissance=birth==null?null:
            birth!.year.toString()+'-'+birth!.month.toString().padLeft(2,'0')+'-'+birth!.day.toString().padLeft(2,'0');
          Navigator.pop(context,Joueur(id:widget.joueur?.id,nom:nom.text.trim(),prenom:prenom.text.trim(),
            tel:tel.text.trim(),clubId:clubId!,naissance:naissance,photo:photo,
            favori:widget.joueur?.favori??false));
        },child:const Text('Enregistrer'))]
    );
  }
}
