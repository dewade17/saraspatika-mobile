import 'package:flutter/foundation.dart';
import 'package:saraspatika/core/services/api_service.dart';

@immutable
class Rbac {
  const Rbac._();

  /// Checks permission using backend format: 'resource:action' (lowercased).
  static Future<bool> can(String resource, String action) async {
    final r = resource.trim().toLowerCase();
    final a = action.trim().toLowerCase();

    if (r.isEmpty || a.isEmpty) return false;

    final requiredKey = '$r:$a';
    final perms = (await ApiService().getPermissions())
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toSet();

    return perms.contains(requiredKey);
  }
}
