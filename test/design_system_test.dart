import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:championnat_pro/design_system.dart';

void main() {
  testWidgets('Theme renders brand primary button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(
        child: FilledButton(
          onPressed: () {},
          child: const Text('Enregistrer'),
        ),
      )),
    ));
    expect(find.text('Enregistrer'), findsOneWidget);
    expect(Theme.of(tester.element(find.text('Enregistrer')))
        .colorScheme.primary, AppPalette.primary);
  });

  testWidgets('Empty state explains next step', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: EmptyPanel(
        title: 'Aucun joueur',
        subtitle: 'Ajoutez un joueur pour commencer.',
      )),
    ));
    expect(find.text('Aucun joueur'), findsOneWidget);
    expect(find.text('Ajoutez un joueur pour commencer.'), findsOneWidget);
  });

  testWidgets('CRUD actions expose descriptive tooltips', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: CrudActions(
        onEdit: () {},
        onDelete: () {},
      )),
    ));
    expect(find.byTooltip('Modifier'), findsOneWidget);
    expect(find.byTooltip('Supprimer'), findsOneWidget);
  });
}
