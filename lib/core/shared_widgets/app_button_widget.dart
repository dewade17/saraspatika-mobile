// ignore_for_file: deprecated_member_use, sort_child_properties_last

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saraspatika/core/constants/colors.dart';

enum AppButtonVariant { primary, secondary, outline, danger, ghost }

enum AppButtonSize { sm, md, lg }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    this.text,
    this.child,
    this.onPressed,
    this.onPressedAsync,
    this.onLongPress,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.enabled = true,
    this.isLoading = false,
    this.manageInternalLoading = true,
    this.fullWidth = false,
    this.width,
    this.height,
    this.padding,
    this.alignment = Alignment.center,
    this.leading,
    this.trailing,
    this.gap = 10,
    this.hapticFeedback = true,
    this.debounceDuration = const Duration(milliseconds: 250),
    this.borderRadius = 12,
    this.elevation = 0,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.gradient,
    this.overlayColor,
    this.textStyle,
    this.semanticsLabel,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
  }) : assert(text != null || child != null, 'Provide either text or child.'),
       assert(
         onPressed == null || onPressedAsync == null,
         'Provide either onPressed or onPressedAsync, not both.',
       );

  final String? text;
  final Widget? child;

  final VoidCallback? onPressed;
  final Future<void> Function()? onPressedAsync;
  final VoidCallback? onLongPress;

  final AppButtonVariant variant;
  final AppButtonSize size;

  final bool enabled;

  /// External loading control.
  final bool isLoading;

  /// If onPressedAsync is provided, the button can manage its own loading state.
  final bool manageInternalLoading;

  final bool fullWidth;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  final Widget? leading;
  final Widget? trailing;
  final double gap;

  final bool hapticFeedback;
  final Duration debounceDuration;

  final double borderRadius;
  final double elevation;

  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final List<Color>? gradient;
  final Color? overlayColor;

  final TextStyle? textStyle;

  final String? semanticsLabel;
  final String? tooltip;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _internalLoading = false;
  bool _tapLocked = false;

  bool get _loading => widget.isLoading || _internalLoading;

  bool get _interactive =>
      widget.enabled &&
      !_loading &&
      (widget.onPressed != null || widget.onPressedAsync != null);

  Future<void> _handleTap() async {
    if (!_interactive) return;
    if (_tapLocked) return;

    if (widget.debounceDuration > Duration.zero) {
      setState(() => _tapLocked = true);
      Future.delayed(widget.debounceDuration, () {
        if (mounted) setState(() => _tapLocked = false);
      });
    }

    if (widget.hapticFeedback) {
      HapticFeedback.selectionClick();
    }

    if (widget.onPressed != null) {
      widget.onPressed!.call();
      return;
    }

    final fn = widget.onPressedAsync;
    if (fn == null) return;

    if (widget.manageInternalLoading) {
      setState(() => _internalLoading = true);
    }

    try {
      await fn();
    } catch (e, st) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: e,
          stack: st,
          library: 'AppButton',
          context: ErrorDescription('while executing onPressedAsync'),
        ),
      );
      if (kDebugMode) {
        debugPrint('AppButton onPressedAsync error: $e');
      }
    } finally {
      if (mounted && widget.manageInternalLoading) {
        setState(() => _internalLoading = false);
      }
    }
  }

  void _handleLongPress() {
    if (!_interactive) return;
    widget.onLongPress?.call();
  }

  _SizeSpec _sizeSpec(BuildContext context) {
    switch (widget.size) {
      case AppButtonSize.sm:
        return _SizeSpec(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontSize: 14),
          loaderSize: 16,
          loaderStroke: 2,
        );
      case AppButtonSize.md:
        return _SizeSpec(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontSize: 15),
          loaderSize: 18,
          loaderStroke: 2.2,
        );
      case AppButtonSize.lg:
        return _SizeSpec(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontSize: 16),
          loaderSize: 20,
          loaderStroke: 2.4,
        );
    }
  }

  _StyleSpec _styleSpec(BuildContext context) {
    final theme = Theme.of(context);

    final baseBg = widget.backgroundColor;
    final baseFg = widget.foregroundColor;
    final baseBorder = widget.borderColor;

    Color bg;
    Color fg;
    Color border;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = baseBg ?? AppColors.primaryColor;
        fg = baseFg ?? Colors.white;
        border = baseBorder ?? Colors.transparent;
        break;
      case AppButtonVariant.secondary:
        bg = baseBg ?? AppColors.secondaryColor;
        fg = baseFg ?? Colors.white;
        border = baseBorder ?? Colors.transparent;
        break;
      case AppButtonVariant.danger:
        bg = baseBg ?? AppColors.errorColor;
        fg = baseFg ?? Colors.white;
        border = baseBorder ?? Colors.transparent;
        break;
      case AppButtonVariant.outline:
        bg = baseBg ?? Colors.transparent;
        fg = baseFg ?? AppColors.primaryColor;
        border = baseBorder ?? AppColors.primaryColor;
        break;
      case AppButtonVariant.ghost:
        bg = baseBg ?? Colors.transparent;
        fg =
            baseFg ??
            (theme.textTheme.labelLarge?.color ?? AppColors.textColor);
        border = baseBorder ?? Colors.transparent;
        break;
    }

    final effectiveOverlay =
        widget.overlayColor ??
        (widget.variant == AppButtonVariant.ghost ||
                widget.variant == AppButtonVariant.outline
            ? fg.withOpacity(0.10)
            : Colors.white.withOpacity(0.12));

    return _StyleSpec(
      background: bg,
      foreground: fg,
      border: border,
      overlay: effectiveOverlay,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = _sizeSpec(context);
    final style = _styleSpec(context);

    final radius = BorderRadius.circular(widget.borderRadius);
    final effectiveHeight = widget.height ?? size.height;
    final effectivePadding = widget.padding ?? size.padding;

    final content = _ButtonContent(
      text: widget.text,
      child: widget.child,
      leading: widget.leading,
      trailing: widget.trailing,
      gap: widget.gap,
      loading: _loading,
      foreground: style.foreground,
      textStyle: widget.textStyle ?? size.textStyle,
      loaderSize: size.loaderSize,
      loaderStroke: size.loaderStroke,
    );

    final decorated = Material(
      color: Colors.transparent,
      elevation: _interactive ? widget.elevation : 0,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          color: widget.gradient == null ? style.background : null,
          gradient: widget.gradient != null
              ? LinearGradient(colors: widget.gradient!)
              : null,
          borderRadius: radius,
          border: Border.all(
            color: style.border,
            width: style.border == Colors.transparent ? 0 : 1,
          ),
        ),
        child: InkWell(
          onTap: _interactive ? _handleTap : null,
          onLongPress: (_interactive && widget.onLongPress != null)
              ? _handleLongPress
              : null,
          borderRadius: radius,
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered)) {
              return style.overlay;
            }
            return null;
          }),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: widget.enabled ? 1.0 : 0.55,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: effectiveHeight,
                minWidth: widget.fullWidth ? double.infinity : 0,
              ),
              child: Padding(
                padding: effectivePadding,
                child: Align(alignment: widget.alignment, child: content),
              ),
            ),
          ),
        ),
      ),
    );

    final wrapped = widget.tooltip != null
        ? Tooltip(message: widget.tooltip!, child: decorated)
        : decorated;

    return Semantics(
      button: true,
      enabled: _interactive,
      label: widget.semanticsLabel ?? widget.text,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : widget.width,
          child: wrapped,
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.text,
    required this.child,
    required this.leading,
    required this.trailing,
    required this.gap,
    required this.loading,
    required this.foreground,
    required this.textStyle,
    required this.loaderSize,
    required this.loaderStroke,
  });

  final String? text;
  final Widget? child;

  final Widget? leading;
  final Widget? trailing;
  final double gap;

  final bool loading;

  final Color foreground;
  final TextStyle? textStyle;

  final double loaderSize;
  final double loaderStroke;

  @override
  Widget build(BuildContext context) {
    final baseChild =
        child ??
        Text(
          text ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
        );

    final parts = <Widget>[];

    if (loading) {
      parts.add(
        SizedBox(
          width: loaderSize,
          height: loaderSize,
          child: CircularProgressIndicator(
            strokeWidth: loaderStroke,
            valueColor: AlwaysStoppedAnimation<Color>(foreground),
          ),
        ),
      );
    } else if (leading != null) {
      parts.add(
        IconTheme(
          data: IconThemeData(color: foreground),
          child: leading!,
        ),
      );
    }

    parts.add(baseChild);

    if (!loading && trailing != null) {
      parts.add(
        IconTheme(
          data: IconThemeData(color: foreground),
          child: trailing!,
        ),
      );
    }

    return DefaultTextStyle.merge(
      style: (textStyle ?? const TextStyle()).copyWith(color: foreground),
      child: IconTheme(
        data: IconThemeData(color: foreground),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: _withGaps(parts, gap),
        ),
      ),
    );
  }

  List<Widget> _withGaps(List<Widget> children, double gap) {
    if (children.length <= 1) return children;
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      out.add(children[i]);
      if (i != children.length - 1) out.add(SizedBox(width: gap));
    }
    return out;
  }
}

class _SizeSpec {
  const _SizeSpec({
    required this.height,
    required this.padding,
    required this.textStyle,
    required this.loaderSize,
    required this.loaderStroke,
  });

  final double height;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final double loaderSize;
  final double loaderStroke;
}

class _StyleSpec {
  const _StyleSpec({
    required this.background,
    required this.foreground,
    required this.border,
    required this.overlay,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color overlay;
}
