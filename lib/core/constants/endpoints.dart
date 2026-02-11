class Endpoints {
  static const String baseURL = "https://7qdb4npf-3000.asse.devtunnels.ms/api";
  static const String faceBaseURL =
      "https://7qdb4npf-8000.asse.devtunnels.ms/api";

  //auth
  static const String login = "$baseURL/auth/login";
  static const String getdataprivate = "$baseURL/auth/getdataprivate";
  //reset-password&&get-token
  static const String resetRequestToken = "$baseURL/auth/request-token";
  static const String resetConfirm = "$baseURL/auth/reset-password";
  static const String userProfile = "$baseURL/users";

  static const String jadwalShift = "$baseURL/jadwal-shift-kerja";

  static const String location = "$faceBaseURL/location";

  //post-enrollface
  static const String faceEnroll = "$faceBaseURL/face/enroll";

  //get-face
  static const String getFace = "$faceBaseURL/face";

  //status-absensi
  static const String statusAbsensi = "$faceBaseURL/absensi/status";

  //absensi-checkin
  static const String absensiCheckin = "$faceBaseURL/absensi/checkin";

  //absensi-checkout
  static const String absensiCheckout = "$faceBaseURL/absensi/checkout";

  //face-reset-requests
  static const String faceResetRequests = "$baseURL/face-reset-request";

  //absensi-history
  static const String absensiHistory = "$baseURL/absensi";

  //pengajuan-absensi
  static const String pengajuanAbsensiS = "$baseURL/pengajuan-absensi";
}
