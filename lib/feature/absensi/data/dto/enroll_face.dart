// ignore_for_file: unused_import

import 'dart:convert';

class EnrollFace {
  final String userId;
  final String? message;
  final bool? ok;
  final dynamic
  images; // Bisa berupa String (path file) atau int (jumlah dari response)

  EnrollFace({required this.userId, this.message, this.ok, this.images});

  // 1. Digunakan saat menerima data dari API (Response)
  factory EnrollFace.fromJson(Map<String, dynamic> json) {
    return EnrollFace(
      userId: json['user_id'] ?? '',
      message: json['message'] ?? '',
      ok: json['ok'] ?? false,
      images:
          json['images'], // Nilainya bisa berupa angka 1 (sesuai JSON response Anda)
    );
  }

  // 2. Digunakan saat ingin mengirim data ke API (Request/Payload)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'images': images,
      // 'message' dan 'ok' biasanya tidak dikirim balik ke server
    };
  }
}
