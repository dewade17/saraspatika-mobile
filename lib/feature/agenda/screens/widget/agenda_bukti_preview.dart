import 'package:flutter/material.dart';
import 'package:saraspatika/feature/agenda/screens/agenda_ui_data.dart';

class AgendaBuktiPreview extends StatelessWidget {
  const AgendaBuktiPreview({super.key, required this.buktiKind, this.onTapPdf});

  final AgendaBuktiKind buktiKind;
  final VoidCallback? onTapPdf;

  @override
  Widget build(BuildContext context) {
    switch (buktiKind) {
      case AgendaBuktiKind.none:
        return const Text('Tidak ada bukti yang diunggah');

      case AgendaBuktiKind.image:
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.image, size: 56, color: Colors.grey),
              ),
            ),
          ),
        );

      case AgendaBuktiKind.pdf:
        return Card(
          color: Colors.red[50],
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Bukti PDF'),
            subtitle: const Text('UI Only: klik dummy'),
            onTap: onTapPdf,
          ),
        );

      case AgendaBuktiKind.unknown:
        return const Text('Format bukti tidak dikenali');
    }
  }
}
