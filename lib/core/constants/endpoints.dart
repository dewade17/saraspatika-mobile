class Endpoints {
  static const String baseURL = "https://7qdb4npf-3000.asse.devtunnels.ms/api";
  static const String faceBaseURL = "https://7qdb4npf-8000.asse.devtunnels.ms/api";

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
}
