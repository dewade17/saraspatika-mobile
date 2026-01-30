class Endpoints {
  static const String baseURL = "https://7qdb4npf-3000.asse.devtunnels.ms/api";
  static const String faceBaseURL = "http://localhost:8080";

  //auth
  static const String login = "$baseURL/auth/login";
  static const String getdataprivate = "$baseURL/auth/getdataprivate";
  //reset-password&&get-token
  static const String resetRequestToken = "$baseURL/auth/request-token";
  static const String resetConfirm = "$baseURL/auth/reset-password";
}
