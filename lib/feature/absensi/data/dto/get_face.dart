// ignore_for_file: unused_import

import 'dart:convert';

class GetFace {
  final int count;
  final List<UserFileItem> items;
  final bool ok;
  final String prefix;
  final String userId;

  GetFace({
    required this.count,
    required this.items,
    required this.ok,
    required this.prefix,
    required this.userId,
  });

  factory GetFace.fromJson(Map<String, dynamic> json) {
    return GetFace(
      count: json['count'] ?? 0,
      items:
          (json['items'] as List?)
              ?.map((item) => UserFileItem.fromJson(item))
              .toList() ??
          [],
      ok: json['ok'] ?? false,
      prefix: json['prefix'] ?? '',
      userId: json['user_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'items': items.map((e) => e.toJson()).toList(),
      'ok': ok,
      'prefix': prefix,
      'user_id': userId,
    };
  }
}

class UserFileItem {
  final String name;
  final String path;
  final String signedUrl;

  UserFileItem({
    required this.name,
    required this.path,
    required this.signedUrl,
  });

  factory UserFileItem.fromJson(Map<String, dynamic> json) {
    return UserFileItem(
      name: json['name'] ?? '',
      path: json['path'] ?? '',
      signedUrl: json['signed_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'path': path, 'signed_url': signedUrl};
  }
}
