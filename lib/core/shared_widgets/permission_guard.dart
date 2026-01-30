import 'package:flutter/material.dart';
import 'package:saraspatika/core/utils/rbac_helper.dart';

class PermissionGuard extends StatefulWidget {
  const PermissionGuard({
    super.key,
    required this.resource,
    required this.action,
    required this.child,
    this.fallback,
    this.loading,
  });

  final String resource;
  final String action;
  final Widget child;

  /// Widget shown when permission is missing (or on error).
  final Widget? fallback;

  /// Widget shown while checking permission.
  final Widget? loading;

  @override
  State<PermissionGuard> createState() => _PermissionGuardState();
}

class _PermissionGuardState extends State<PermissionGuard> {
  late Future<bool> _future;

  @override
  void initState() {
    super.initState();
    _future = Rbac.can(widget.resource, widget.action);
  }

  @override
  void didUpdateWidget(covariant PermissionGuard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resource != widget.resource ||
        oldWidget.action != widget.action) {
      _future = Rbac.can(widget.resource, widget.action);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _future,
      builder: (context, snapshot) {
        final state = snapshot.connectionState;

        if (state == ConnectionState.waiting ||
            state == ConnectionState.active) {
          return widget.loading ?? const SizedBox.shrink();
        }

        final allowed = snapshot.data == true;
        if (!allowed) {
          return widget.fallback ?? const SizedBox.shrink();
        }

        return widget.child;
      },
    );
  }
}
