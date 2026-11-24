import 'package:flutter/material.dart';

/// One visual language for web, Windows and Android.
abstract final class AppPalette {
  static const ink = Color(0xFF101C34);
  static const navy = Color(0xFF101C34);
  static const primary = Color(0xFF315BDB);
  static const primaryLight = Color(0xFFEAF0FF);
  static const canvas = Color(0xFFF4F7FC);
  static const border = Color(0xFFE3E9F2);
  static const muted = Color(0xFF63728A);
  static const emerald = Color(0xFF099879);
  static const emeraldLight = Color(0xFFE4F8F1);
  static const amber = Color(0xFFE6A13D);
  static const danger = Color(0xFFD84255);
  static const dangerLight = Color(0xFFFFEEF1);
}

abstract final class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppPalette.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppPalette.primary,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: AppPalette.ink,
        error: AppPalette.danger,
      ),
      scaffoldBackgroundColor: AppPalette.canvas,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppPalette.ink,
        displayColor: AppPalette.ink,
        fontFamily: 'Roboto',
      ),
      iconTheme: const IconThemeData(color: AppPalette.ink, size: 21),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppPalette.border),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.canvas,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppPalette.ink,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          shape: shape,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.ink,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 16),
          shape: shape,
          side: const BorderSide(color: AppPalette.border),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 17,
        ),
        hintStyle: const TextStyle(color: AppPalette.muted),
        floatingLabelStyle: const TextStyle(color: AppPalette.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppPalette.primary, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: AppPalette.danger),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppPalette.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(17),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppPalette.border, thickness: 1, space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppPalette.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

/// Standard section title with optional action in the trailing position.
class SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;
  const SectionTitle({
    super.key, required this.title, required this.subtitle, this.action,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Row(children: [
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 21, fontWeight: FontWeight.w800,
            letterSpacing: -.6, color: AppPalette.ink,
          )),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(
            fontSize: 13, color: AppPalette.muted,
          )),
        ],
      )),
      if (action != null) action!,
    ]),
  );
}

class EmptyPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? action;
  const EmptyPanel({
    super.key, required this.title, required this.subtitle,
    this.icon = Icons.inbox_outlined, this.action,
  });
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppPalette.border),
    ),
    child: Column(children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: AppPalette.primaryLight,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: AppPalette.primary, size: 28),
      ),
      const SizedBox(height: 17),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(
        fontSize: 17, fontWeight: FontWeight.w800,
      )),
      const SizedBox(height: 7),
      Text(subtitle, textAlign: TextAlign.center,
        style: const TextStyle(color: AppPalette.muted)),
      if (action != null) ...[
        const SizedBox(height: 18), action!,
      ],
    ]),
  );
}

/// Accessible actions with names rather than ambiguous icon-only controls.
class CrudActions extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;
  const CrudActions({
    super.key, required this.onEdit, required this.onDelete, this.onOpen,
  });
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    spacing: 5,
    runSpacing: 4,
    children: [
      if (onOpen != null)
        IconButton.filledTonal(
          onPressed: onOpen,
          tooltip: 'Consulter',
          icon: const Icon(Icons.arrow_outward_rounded, size: 19),
        ),
      IconButton(
        onPressed: onEdit,
        tooltip: 'Modifier',
        icon: const Icon(Icons.edit_outlined, size: 19),
      ),
      IconButton(
        onPressed: onDelete,
        tooltip: 'Supprimer',
        style: IconButton.styleFrom(
          foregroundColor: AppPalette.danger,
          backgroundColor: AppPalette.dangerLight,
        ),
        icon: const Icon(Icons.delete_outline_rounded, size: 19),
      ),
    ],
  );
}

class StatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  const StatusPill({
    super.key, required this.text,
    this.color = AppPalette.emerald,
    this.background = AppPalette.emeraldLight,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(100),
    ),
    child: Text(text, style: TextStyle(
      color: color, fontWeight: FontWeight.w800, fontSize: 11,
    )),
  );
}

class StatPanel extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color accent;
  const StatPanel({
    super.key, required this.value, required this.label,
    required this.icon, this.accent = AppPalette.primary,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: AppPalette.border),
      borderRadius: BorderRadius.circular(21),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(children: [
          Container(
            width: 39, height: 39,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: accent.withValues(alpha: .1),
            ),
            child: Icon(icon, color: accent, size: 21),
          ),
          const Spacer(),
          const Icon(Icons.north_east_rounded,
            color: AppPalette.border, size: 18),
        ]),
        const SizedBox(height: 12),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: double.tryParse(value) ?? 0),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => Text(
            v.round().toString(),
            style: const TextStyle(
              fontWeight: FontWeight.w900, fontSize: 29,
              letterSpacing: -1.1, color: AppPalette.ink,
            ),
          ),
        ),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 12,
            color: AppPalette.muted,
          )),
      ],
    ),
  );
}

class PressableCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  const PressableCard({
    super.key, required this.child, this.onTap,
    this.padding = const EdgeInsets.all(18),
  });
  @override
  State<PressableCard> createState() => _PressableCardState();
}
class _PressableCardState extends State<PressableCard> {
  bool hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hover = true),
    onExit: (_) => setState(() => hover = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      transform: Matrix4.translationValues(0, hover ? -3 : 0, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hover ? AppPalette.primary.withValues(alpha: .4)
            : AppPalette.border,
        ),
        boxShadow: hover ? [
          BoxShadow(color: AppPalette.ink.withValues(alpha: .065),
            blurRadius: 22, offset: const Offset(0, 9)),
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(padding: widget.padding, child: widget.child),
        ),
      ),
    ),
  );
}
