/// DTO untuk tahap pertama: Kirim Email Reset Password
class ForgotPasswordRequest {
  final String email;

  ForgotPasswordRequest({required this.email});

  Map<String, dynamic> toJson() {
    return {'email': email};
  }
}

/// DTO untuk tahap kedua: Verifikasi Kode dan Password Baru
class ResetPasswordRequest {
  final String email;
  final String code;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'code': code, 'newPassword': newPassword};
  }
}

/// DTO untuk Response Umum (karena kedua respons hanya berisi "ok": true)
class BaseResponse {
  final bool ok;

  BaseResponse({required this.ok});

  factory BaseResponse.fromJson(Map<String, dynamic> json) {
    return BaseResponse(ok: json['ok'] ?? false);
  }
}
