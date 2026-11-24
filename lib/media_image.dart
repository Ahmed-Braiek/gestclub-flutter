import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Image sources stored in SQLite:
/// - HTTPS URL (linked image; an internet connection is needed to display it).
/// - Base64 bytes (uploaded image; available offline).
/// An empty value means the fallback icon will be shown.
bool validImageUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && (uri.scheme == 'https' || uri.scheme == 'http') &&
      uri.host.isNotEmpty;
}

class MediaImage extends StatelessWidget {
  final String? source;
  final double size;
  final IconData fallback;
  const MediaImage({super.key, this.source, this.size = 52,
    this.fallback = Icons.person_outline});

  @override
  Widget build(BuildContext context) {
    final raw = source?.trim() ?? '';
    Widget placeholder() => Container(
      width: size, height: size,
      decoration: BoxDecoration(color: const Color(0xFFE9EEFF),
          borderRadius: BorderRadius.circular(size / 4)),
      alignment: Alignment.center,
      child: Icon(fallback, size: size * .5, color: const Color(0xFF425CE8)),
    );

    if (raw.isEmpty) return placeholder();
    late final ImageProvider provider;
    try {
      if (validImageUrl(raw)) {
        provider = NetworkImage(raw);
      } else {
        provider = MemoryImage(base64Decode(raw));
      }
    } catch (_) {
      return placeholder();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: Image(image: provider, width: size, height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => placeholder()),
    );
  }
}

class MediaField extends StatefulWidget {
  final String? initial;
  final String title;
  final ValueChanged<String?> onChanged;
  const MediaField({super.key, this.initial, required this.title,
    required this.onChanged});
  @override
  State<MediaField> createState() => _MediaFieldState();
}

class _MediaFieldState extends State<MediaField> {
  late final TextEditingController url;
  String? value;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    value = widget.initial;
    url = TextEditingController(text:validImageUrl(value??'')?value:'');
  }

  @override
  void dispose() {
    url.dispose();
    super.dispose();
  }

  void change(String? next) {
    setState(() => value = next);
    widget.onChanged(next);
  }

  Future<void> pick() async {
    try {
      final file = await ImagePicker().pickImage(source: ImageSource.gallery,
        imageQuality: 68, maxWidth: 640, maxHeight: 640);
      if (file == null) return;
      setState(() => uploading = true);
      final bytes = await file.readAsBytes();
      if (bytes.length > 1500000) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image trop volumineuse (maximum 1,5 Mo).')));
        return;
      }
      url.clear();
      change(base64Encode(bytes));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sélection de l’image impossible : $e')));
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 9),
      Row(children: [
        MediaImage(source: value, size: 68, fallback: Icons.image_outlined),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(onPressed: uploading?null:pick,
              icon: const Icon(Icons.upload_file),
              label: Text(uploading?'Importation...':'Importer une image')),
            TextButton.icon(
              onPressed: () { url.clear(); change(null); },
              icon: const Icon(Icons.delete_outline, size: 17),
              label: const Text('Retirer l’image')),
          ])),
      ]),
      const SizedBox(height: 8),
      TextFormField(
        controller: url,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.link),
          labelText: 'Ou coller un lien image (https://...)',
          helperText: 'Une URL nécessite internet ; un fichier importé reste hors ligne.'),
        onChanged: (v) {
          final trimmed=v.trim();
          if (trimmed.isEmpty) {
            if (validImageUrl(value??'')) change(null);
          } else if (validImageUrl(trimmed)) {
            change(trimmed);
          }
        },
        validator: (v) {
          if (v!=null && v.trim().isNotEmpty && !validImageUrl(v)) {
            return 'Utilisez une URL http:// ou https:// valide';
          }
          return null;
        },
      ),
    ],
  );
}
