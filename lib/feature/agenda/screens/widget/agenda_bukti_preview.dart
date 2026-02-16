import 'package:flutter/material.dart';
import 'package:saraspatika/feature/agenda/data/dto/agenda.dart';
import 'package:url_launcher/url_launcher.dart';

class AgendaBuktiPreview extends StatelessWidget {
  const AgendaBuktiPreview({
    super.key,
    required this.buktiPendukungUrl,
    this.onTapPdf, // Tetap dipertahankan jika ingin kustomisasi tambahan
  });

  final String? buktiPendukungUrl;
  final VoidCallback? onTapPdf;

  Future<void> _launchURL(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Link tidak valid')));
      }
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final buktiKind = agendaBuktiKindFromUrl(buktiPendukungUrl);

    switch (buktiKind) {
      case AgendaBuktiKind.none:
        return const Text('Tidak ada bukti yang diunggah');

      case AgendaBuktiKind.image:
        return Card(
          color: Colors.blue[50],
          child: ListTile(
            leading: const Icon(Icons.image, color: Colors.blue),
            title: const Text('Bukti Gambar'),
            subtitle: const Text('Klik untuk melihat atau mengunduh gambar'),
            onTap: () => _launchURL(context, buktiPendukungUrl!),
          ),
        );

      case AgendaBuktiKind.pdf:
        return Card(
          color: Colors.red[50],
          child: ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Bukti PDF'),
            subtitle: const Text('Klik untuk melihat file PDF'),
            onTap: () {
              if (onTapPdf != null) {
                onTapPdf!();
              } else {
                _launchURL(context, buktiPendukungUrl!);
              }
            },
          ),
        );

      case AgendaBuktiKind.unknown:
        return Card(
          color: Colors.grey[100],
          child: ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.grey),
            title: const Text('Format Tidak Dikenali'),
            subtitle: Text(buktiPendukungUrl ?? '-'),
            onTap: () => _launchURL(context, buktiPendukungUrl!),
          ),
        );
    }
  }
}
