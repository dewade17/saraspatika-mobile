class AgendaUiData {
  final String agendaId;
  final DateTime createdAt;
  final DateTime tanggal;
  final DateTime jamMulai;
  final DateTime jamSelesai;
  final String deskripsiPekerjaan;
  final AgendaBuktiKind buktiKind;

  const AgendaUiData({
    required this.agendaId,
    required this.createdAt,
    required this.tanggal,
    required this.jamMulai,
    required this.jamSelesai,
    required this.deskripsiPekerjaan,
    required this.buktiKind,
  });
}

enum AgendaBuktiKind { none, image, pdf, unknown }
