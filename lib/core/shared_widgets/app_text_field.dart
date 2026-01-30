import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saraspatika/core/constants/colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.label,
    this.hintText,
    this.helperText,
    this.leadingIcon,
    this.leading,
    this.suffix,
    this.isPassword = false,
    this.enableVisibilityToggle = true,
    this.initiallyObscured = true,
    this.onVisibilityChanged,
    this.showClearButton = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.hintStyle,
    this.helperStyle,
    this.errorStyle,
    this.containerPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 6,
    ),
    this.borderRadius = 12,
    this.fillColor = Colors.white,
    this.borderColor,
    this.focusedBorderColor,
    this.disabledBorderColor,
    this.errorBorderColor,
    this.obscuringCharacter = '•',
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onTap,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableSuggestions,
    this.autocorrect,
  }) : assert(
         controller == null || initialValue == null,
         'Provide either controller or initialValue, not both.',
       ),
       assert(
         !isPassword || maxLines == 1,
         'Password field should be single line.',
       );

  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;

  final String? label;
  final String? hintText;
  final String? helperText;

  final IconData? leadingIcon;
  final Widget? leading;

  final Widget? suffix;

  final bool isPassword;
  final bool enableVisibilityToggle;
  final bool initiallyObscured;
  final ValueChanged<bool>? onVisibilityChanged;

  final bool showClearButton;

  final bool enabled;
  final bool readOnly;

  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  final int? maxLength;
  final int? minLines;
  final int maxLines;

  final TextAlign textAlign;

  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextStyle? helperStyle;
  final TextStyle? errorStyle;

  final EdgeInsetsGeometry containerPadding;
  final double borderRadius;
  final Color fillColor;

  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? disabledBorderColor;
  final Color? errorBorderColor;

  final String obscuringCharacter;

  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final AutovalidateMode? autovalidateMode;

  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onEditingComplete;
  final VoidCallback? onTap;

  final EdgeInsets scrollPadding;

  final bool? enableSuggestions;
  final bool? autocorrect;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  final GlobalKey<FormFieldState<String>> _fieldKey =
      GlobalKey<FormFieldState<String>>();

  late TextEditingController _controller;
  late FocusNode _focusNode;

  bool _ownsController = false;
  bool _ownsFocusNode = false;

  late bool _obscure;

  @override
  void initState() {
    super.initState();

    _obscure = widget.isPassword ? widget.initiallyObscured : false;

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _ownsController = true;
      _controller = TextEditingController(text: widget.initialValue ?? '');
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _ownsFocusNode = true;
      _focusNode = FocusNode();
    }

    _controller.addListener(_syncFormField);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_syncFormField);

      if (_ownsController) {
        _controller.dispose();
        _ownsController = false;
      }

      if (widget.controller != null) {
        _controller = widget.controller!;
      } else {
        _ownsController = true;
        _controller = TextEditingController(text: widget.initialValue ?? '');
      }

      _controller.addListener(_syncFormField);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFormField());
    }

    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChange);

      if (_ownsFocusNode) {
        _focusNode.dispose();
        _ownsFocusNode = false;
      }

      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
      } else {
        _ownsFocusNode = true;
        _focusNode = FocusNode();
      }

      _focusNode.addListener(_handleFocusChange);
      setState(() {});
    }

    if (oldWidget.isPassword != widget.isPassword) {
      setState(() {
        _obscure = widget.isPassword ? widget.initiallyObscured : false;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncFormField);
    _focusNode.removeListener(_handleFocusChange);

    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();

    super.dispose();
  }

  void _handleFocusChange() => setState(() {});

  void _syncFormField() {
    final state = _fieldKey.currentState;
    if (state == null) return;

    final text = _controller.text;
    if (state.value != text) state.didChange(text);
  }

  void _toggleVisibility() {
    setState(() {
      _obscure = !_obscure;
    });
    widget.onVisibilityChanged?.call(!_obscure);
  }

  void _clearText() {
    if (!widget.enabled || widget.readOnly) return;
    _controller.clear();
    widget.onChanged?.call('');
  }

  Color _resolveBorderColor({required bool hasError}) {
    final theme = Theme.of(context);

    final normal = widget.borderColor ?? Colors.grey.shade300;
    final focused = widget.focusedBorderColor ?? AppColors.primaryColor;
    final disabled =
        widget.disabledBorderColor ?? Colors.grey.shade300.withOpacity(0.6);
    final error = widget.errorBorderColor ?? theme.colorScheme.error;

    if (!widget.enabled) return disabled;
    if (hasError) return error;
    if (_focusNode.hasFocus) return focused;
    return normal;
  }

  Widget _buildSuffix(TextEditingValue value) {
    final actions = <Widget>[];

    final canClear =
        widget.showClearButton &&
        widget.enabled &&
        !widget.readOnly &&
        value.text.isNotEmpty;
    if (canClear) {
      actions.add(
        IconButton(
          onPressed: _clearText,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Clear',
        ),
      );
    }

    final canToggle = widget.isPassword && widget.enableVisibilityToggle;
    if (canToggle) {
      actions.add(
        IconButton(
          onPressed: _toggleVisibility,
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          tooltip: _obscure ? 'Show' : 'Hide',
        ),
      );
    }

    if (widget.suffix != null) {
      actions.add(widget.suffix!);
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _fieldKey,
      initialValue: _controller.text,
      validator: widget.validator,
      onSaved: (v) => widget.onSaved?.call(v ?? _controller.text),
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
      builder: (field) {
        final hasError =
            field.errorText != null && field.errorText!.trim().isNotEmpty;
        final borderColor = _resolveBorderColor(hasError: hasError);

        final helperOrError = hasError ? field.errorText : widget.helperText;
        final showFooter =
            (helperOrError != null && helperOrError.trim().isNotEmpty) ||
            widget.maxLength != null;

        final defaultHelperStyle = TextStyle(
          fontSize: 12,
          color: hasError ? Theme.of(context).colorScheme.error : Colors.grey,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: widget.containerPadding,
              decoration: BoxDecoration(
                color: widget.fillColor,
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(color: borderColor),
              ),
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  return TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    readOnly: widget.readOnly,
                    onTap: widget.onTap,
                    onChanged: (v) {
                      field.didChange(v);
                      widget.onChanged?.call(v);
                    },
                    onSubmitted: widget.onSubmitted,
                    onEditingComplete: widget.onEditingComplete,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.textCapitalization,
                    autofillHints: widget.autofillHints,
                    inputFormatters: widget.inputFormatters,
                    maxLength: widget.maxLength,
                    minLines: widget.minLines,
                    maxLines: widget.isPassword ? 1 : widget.maxLines,
                    textAlign: widget.textAlign,
                    style: widget.textStyle,
                    scrollPadding: widget.scrollPadding,
                    obscureText: widget.isPassword ? _obscure : false,
                    obscuringCharacter: widget.obscuringCharacter,
                    enableSuggestions:
                        widget.enableSuggestions ?? !widget.isPassword,
                    autocorrect: widget.autocorrect ?? !widget.isPassword,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      labelText: widget.label,
                      hintText: widget.hintText,
                      hintStyle: widget.hintStyle,
                      prefixIcon:
                          widget.leading ??
                          (widget.leadingIcon != null
                              ? Icon(widget.leadingIcon)
                              : null),
                      suffixIcon: _buildSuffix(value),
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  );
                },
              ),
            ),
            if (showFooter)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
                child: Row(
                  children: [
                    Expanded(
                      child:
                          (helperOrError != null &&
                              helperOrError.trim().isNotEmpty)
                          ? Text(
                              helperOrError,
                              style:
                                  (hasError
                                      ? widget.errorStyle
                                      : widget.helperStyle) ??
                                  defaultHelperStyle,
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (widget.maxLength != null)
                      Text(
                        '${_controller.text.length}/${widget.maxLength}',
                        style:
                            (hasError
                                ? widget.errorStyle
                                : widget.helperStyle) ??
                            defaultHelperStyle,
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
