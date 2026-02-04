// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saraspatika/core/constants/colors.dart';

enum AppTimePickerOverlayMode { bottomSheet, dialog }

typedef AppTimeLabelBuilder =
    String Function(BuildContext context, TimeOfDay time);
typedef AppTimeItemBuilder =
    Widget Function(
      BuildContext context,
      TimeOfDay time,
      bool selected,
      bool enabled,
    );
typedef AppTimePredicate = bool Function(TimeOfDay time);

class AppTimePickerController extends ValueNotifier<TimeOfDay?> {
  AppTimePickerController([super.value]);

  void clear() => value = null;
  void setTime(TimeOfDay? time) => value = time;
}

class AppTimePickerField extends StatefulWidget {
  const AppTimePickerField({
    super.key,
    this.controller,
    this.initialTime,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.allowClear = true,
    this.label,
    this.hintText,
    this.helperText,
    this.leadingIcon,
    this.leading,
    this.suffix,
    this.overlayMode = AppTimePickerOverlayMode.bottomSheet,
    this.bottomSheetMaxHeightFactor = 0.82,
    this.dialogTitle,
    this.searchHintText,
    this.enableSearch = false,
    this.showNowShortcut = true,
    this.showCustomTimePicker = true,
    this.customTimePickerLabel,
    this.nowLabel,
    this.clearText,
    this.confirmText,
    this.cancelText,
    this.minuteStep = 15,
    this.alignStartToStep = true,
    this.startTime = const TimeOfDay(hour: 0, minute: 0),
    this.endTime = const TimeOfDay(hour: 23, minute: 59),
    this.selectableTimePredicate,
    this.use24HourFormat,
    this.labelBuilder,
    this.itemBuilder,
    this.autovalidateMode,
    this.validator,
    this.onSaved,
    this.borderRadius = 12,
    this.fillColor = Colors.white,
    this.borderColor,
    this.focusedBorderColor,
    this.disabledBorderColor,
    this.errorBorderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.semanticsLabel,
    this.hapticFeedback = true,
  }) : assert(
         controller == null || initialTime == null,
         'Provide either controller or initialTime, not both.',
       ),
       assert(
         minuteStep >= 1 && minuteStep <= 60,
         'minuteStep must be in [1..60].',
       );

  final AppTimePickerController? controller;
  final TimeOfDay? initialTime;

  final ValueChanged<TimeOfDay?>? onChanged;

  final bool enabled;
  final bool readOnly;
  final bool allowClear;

  final String? label;
  final String? hintText;
  final String? helperText;

  final IconData? leadingIcon;
  final Widget? leading;
  final Widget? suffix;

  final AppTimePickerOverlayMode overlayMode;
  final double bottomSheetMaxHeightFactor;

  final String? dialogTitle;

  final bool enableSearch;
  final String? searchHintText;

  final bool showNowShortcut;
  final bool showCustomTimePicker;

  final String? customTimePickerLabel;
  final String? nowLabel;
  final String? clearText;
  final String? confirmText;
  final String? cancelText;

  /// Times list step in minutes (1..60).
  final int minuteStep;

  /// If true, the first selectable time is rounded up to next step boundary.
  final bool alignStartToStep;

  /// Bounds for list generation.
  final TimeOfDay startTime;
  final TimeOfDay endTime;

  /// Extra filter (e.g., disable lunch break).
  final AppTimePredicate? selectableTimePredicate;

  /// If null, uses `MediaQuery.alwaysUse24HourFormat`.
  final bool? use24HourFormat;

  /// Customize displayed label of a time.
  final AppTimeLabelBuilder? labelBuilder;

  /// Customize list tile rows.
  final AppTimeItemBuilder? itemBuilder;

  final AutovalidateMode? autovalidateMode;
  final FormFieldValidator<TimeOfDay?>? validator;
  final FormFieldSetter<TimeOfDay?>? onSaved;

  final double borderRadius;
  final Color fillColor;

  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? disabledBorderColor;
  final Color? errorBorderColor;

  final EdgeInsetsGeometry padding;

  final String? semanticsLabel;
  final bool hapticFeedback;

  @override
  State<AppTimePickerField> createState() => _AppTimePickerFieldState();
}

class _AppTimePickerFieldState extends State<AppTimePickerField> {
  final GlobalKey<FormFieldState<TimeOfDay?>> _fieldKey =
      GlobalKey<FormFieldState<TimeOfDay?>>();
  final FocusNode _focusNode = FocusNode();

  AppTimePickerController? _controller;
  bool _listening = false;

  TimeOfDay? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.controller?.value ?? widget.initialTime;
    _bindController(widget.controller);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant AppTimePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _unbindController();
      _bindController(widget.controller);
      setState(() => _value = widget.controller?.value ?? _value);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFormField());
    }

    if (oldWidget.initialTime != widget.initialTime &&
        widget.controller == null) {
      setState(() => _value = widget.initialTime);
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFormField());
    }
  }

  @override
  void dispose() {
    _unbindController();
    _focusNode.dispose();
    super.dispose();
  }

  void _bindController(AppTimePickerController? controller) {
    _controller = controller;
    if (_controller != null && !_listening) {
      _controller!.addListener(_handleControllerChanged);
      _listening = true;
    }
  }

  void _unbindController() {
    if (_controller != null && _listening) {
      _controller!.removeListener(_handleControllerChanged);
      _listening = false;
    }
    _controller = null;
  }

  void _handleControllerChanged() {
    if (!mounted) return;
    final next = _controller!.value;
    if (_sameTime(_value, next)) return;
    setState(() => _value = next);
    _syncFormField();
  }

  void _syncFormField() {
    final state = _fieldKey.currentState;
    if (state == null) return;
    if (!_sameTime(state.value, _value)) {
      state.didChange(_value);
    }
  }

  bool _sameTime(TimeOfDay? a, TimeOfDay? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.hour == b.hour && a.minute == b.minute;
  }

  bool get _interactive => widget.enabled && !widget.readOnly;

  void _emit(TimeOfDay? next) {
    setState(() => _value = next);
    if (_controller != null) _controller!.value = next;
    _fieldKey.currentState?.didChange(next);
    widget.onChanged?.call(next);
  }

  void _clear() {
    if (!_interactive) return;
    if (widget.hapticFeedback) HapticFeedback.selectionClick();
    _emit(null);
  }

  bool _use24h(BuildContext context) =>
      widget.use24HourFormat ?? MediaQuery.of(context).alwaysUse24HourFormat;

  String _format(BuildContext context, TimeOfDay time) {
    final custom = widget.labelBuilder;
    if (custom != null) return custom(context, time);

    final loc = MaterialLocalizations.of(context);
    return loc.formatTimeOfDay(time, alwaysUse24HourFormat: _use24h(context));
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

  Future<void> _openPicker() async {
    if (!_interactive) return;

    _focusNode.requestFocus();
    if (widget.hapticFeedback) HapticFeedback.selectionClick();

    final result = widget.overlayMode == AppTimePickerOverlayMode.dialog
        ? await showDialog<TimeOfDay?>(
            context: context,
            barrierDismissible: true,
            builder: (context) => _TimePickerDialog(
              title: widget.dialogTitle,
              value: _value,
              start: widget.startTime,
              end: widget.endTime,
              stepMinutes: widget.minuteStep,
              alignStartToStep: widget.alignStartToStep,
              predicate: widget.selectableTimePredicate,
              enableSearch: widget.enableSearch,
              searchHintText: widget.searchHintText,
              showNowShortcut: widget.showNowShortcut,
              showCustomTimePicker: widget.showCustomTimePicker,
              customTimePickerLabel: widget.customTimePickerLabel,
              nowLabel: widget.nowLabel,
              clearText: widget.clearText,
              confirmText: widget.confirmText,
              cancelText: widget.cancelText,
              formatter: (t) => _format(context, t),
              use24HourFormat: _use24h(context),
              itemBuilder: widget.itemBuilder,
            ),
          )
        : await showModalBottomSheet<TimeOfDay?>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => _TimePickerBottomSheet(
              maxHeightFactor: widget.bottomSheetMaxHeightFactor,
              title: widget.dialogTitle,
              value: _value,
              start: widget.startTime,
              end: widget.endTime,
              stepMinutes: widget.minuteStep,
              alignStartToStep: widget.alignStartToStep,
              predicate: widget.selectableTimePredicate,
              enableSearch: widget.enableSearch,
              searchHintText: widget.searchHintText,
              showNowShortcut: widget.showNowShortcut,
              showCustomTimePicker: widget.showCustomTimePicker,
              customTimePickerLabel: widget.customTimePickerLabel,
              nowLabel: widget.nowLabel,
              clearText: widget.clearText,
              confirmText: widget.confirmText,
              cancelText: widget.cancelText,
              formatter: (t) => _format(context, t),
              use24HourFormat: _use24h(context),
              itemBuilder: widget.itemBuilder,
            ),
          );

    if (!mounted) return;
    if (result == null) return; // dismissed
    _emit(result);
  }

  @override
  Widget build(BuildContext context) {
    final display = _value == null ? '' : _format(context, _value!);
    final canClear = widget.allowClear && _interactive && _value != null;

    final prefix =
        widget.leading ??
        (widget.leadingIcon != null ? Icon(widget.leadingIcon) : null);

    return FormField<TimeOfDay?>(
      key: _fieldKey,
      initialValue: _value,
      validator: widget.validator,
      onSaved: widget.onSaved,
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
      builder: (field) {
        final hasError =
            field.errorText != null && field.errorText!.trim().isNotEmpty;
        final borderColor = _resolveBorderColor(hasError: hasError);

        final footerText = hasError ? field.errorText : widget.helperText;
        final showFooter = footerText != null && footerText.trim().isNotEmpty;

        final suffix = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canClear)
              IconButton(
                onPressed: _clear,
                icon: const Icon(Icons.close_rounded),
                tooltip: widget.clearText ?? 'Clear',
              ),
            IconButton(
              onPressed: _interactive ? _openPicker : null,
              icon: const Icon(Icons.access_time_rounded),
              tooltip: 'Pick time',
            ),
            if (widget.suffix != null) widget.suffix!,
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: widget.semanticsLabel ?? widget.label ?? widget.hintText,
              button: true,
              enabled: widget.enabled && !widget.readOnly,
              child: Focus(
                focusNode: _focusNode,
                child: InkWell(
                  onTap: _interactive ? _openPicker : null,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color: widget.fillColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (prefix != null) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: IconTheme(
                              data: IconThemeData(
                                color: widget.enabled ? null : Colors.grey,
                              ),
                              child: prefix,
                            ),
                          ),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (widget.label != null &&
                                  widget.label!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    widget.label!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.enabled
                                          ? Colors.grey.shade700
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                              Text(
                                display.isEmpty
                                    ? (widget.hintText ?? '')
                                    : display,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: display.isEmpty ? Colors.grey : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconTheme(
                          data: IconThemeData(
                            color: widget.enabled ? null : Colors.grey,
                          ),
                          child: suffix,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (showFooter)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 6),
                child: Text(
                  footerText,
                  style: TextStyle(
                    fontSize: 12,
                    color: hasError
                        ? Theme.of(context).colorScheme.error
                        : Colors.grey,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TimePickerBottomSheet extends StatelessWidget {
  const _TimePickerBottomSheet({
    required this.maxHeightFactor,
    required this.title,
    required this.value,
    required this.start,
    required this.end,
    required this.stepMinutes,
    required this.alignStartToStep,
    required this.predicate,
    required this.enableSearch,
    required this.searchHintText,
    required this.showNowShortcut,
    required this.showCustomTimePicker,
    required this.customTimePickerLabel,
    required this.nowLabel,
    required this.clearText,
    required this.confirmText,
    required this.cancelText,
    required this.formatter,
    required this.use24HourFormat,
    required this.itemBuilder,
  });

  final double maxHeightFactor;
  final String? title;

  final TimeOfDay? value;
  final TimeOfDay start;
  final TimeOfDay end;

  final int stepMinutes;
  final bool alignStartToStep;
  final AppTimePredicate? predicate;

  final bool enableSearch;
  final String? searchHintText;

  final bool showNowShortcut;
  final bool showCustomTimePicker;

  final String? customTimePickerLabel;
  final String? nowLabel;
  final String? clearText;
  final String? confirmText;
  final String? cancelText;

  final String Function(TimeOfDay) formatter;
  final bool use24HourFormat;

  final AppTimeItemBuilder? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * maxHeightFactor;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: _TimePickerOverlay(
          title: title,
          value: value,
          start: start,
          end: end,
          stepMinutes: stepMinutes,
          alignStartToStep: alignStartToStep,
          predicate: predicate,
          enableSearch: enableSearch,
          searchHintText: searchHintText,
          showNowShortcut: showNowShortcut,
          showCustomTimePicker: showCustomTimePicker,
          customTimePickerLabel: customTimePickerLabel,
          nowLabel: nowLabel,
          clearText: clearText,
          confirmText: confirmText,
          cancelText: cancelText,
          formatter: formatter,
          use24HourFormat: use24HourFormat,
          itemBuilder: itemBuilder,
          close: (t) => Navigator.of(context).pop<TimeOfDay?>(t),
        ),
      ),
    );
  }
}

class _TimePickerDialog extends StatelessWidget {
  const _TimePickerDialog({
    required this.title,
    required this.value,
    required this.start,
    required this.end,
    required this.stepMinutes,
    required this.alignStartToStep,
    required this.predicate,
    required this.enableSearch,
    required this.searchHintText,
    required this.showNowShortcut,
    required this.showCustomTimePicker,
    required this.customTimePickerLabel,
    required this.nowLabel,
    required this.clearText,
    required this.confirmText,
    required this.cancelText,
    required this.formatter,
    required this.use24HourFormat,
    required this.itemBuilder,
  });

  final String? title;

  final TimeOfDay? value;
  final TimeOfDay start;
  final TimeOfDay end;

  final int stepMinutes;
  final bool alignStartToStep;
  final AppTimePredicate? predicate;

  final bool enableSearch;
  final String? searchHintText;

  final bool showNowShortcut;
  final bool showCustomTimePicker;

  final String? customTimePickerLabel;
  final String? nowLabel;
  final String? clearText;
  final String? confirmText;
  final String? cancelText;

  final String Function(TimeOfDay) formatter;
  final bool use24HourFormat;

  final AppTimeItemBuilder? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      title: Text(title ?? 'Select time'),
      content: SizedBox(
        width: 460,
        child: _TimePickerOverlay(
          title: null,
          value: value,
          start: start,
          end: end,
          stepMinutes: stepMinutes,
          alignStartToStep: alignStartToStep,
          predicate: predicate,
          enableSearch: enableSearch,
          searchHintText: searchHintText,
          showNowShortcut: showNowShortcut,
          showCustomTimePicker: showCustomTimePicker,
          customTimePickerLabel: customTimePickerLabel,
          nowLabel: nowLabel,
          clearText: clearText,
          confirmText: confirmText,
          cancelText: cancelText,
          formatter: formatter,
          use24HourFormat: use24HourFormat,
          itemBuilder: itemBuilder,
          isDialog: true,
          close: (t) => Navigator.of(context).pop<TimeOfDay?>(t),
        ),
      ),
    );
  }
}

class _TimePickerOverlay extends StatefulWidget {
  const _TimePickerOverlay({
    required this.title,
    required this.value,
    required this.start,
    required this.end,
    required this.stepMinutes,
    required this.alignStartToStep,
    required this.predicate,
    required this.enableSearch,
    required this.searchHintText,
    required this.showNowShortcut,
    required this.showCustomTimePicker,
    required this.customTimePickerLabel,
    required this.nowLabel,
    required this.clearText,
    required this.confirmText,
    required this.cancelText,
    required this.formatter,
    required this.use24HourFormat,
    required this.itemBuilder,
    required this.close,
    this.isDialog = false,
  });

  final String? title;

  final TimeOfDay? value;
  final TimeOfDay start;
  final TimeOfDay end;

  final int stepMinutes;
  final bool alignStartToStep;
  final AppTimePredicate? predicate;

  final bool enableSearch;
  final String? searchHintText;

  final bool showNowShortcut;
  final bool showCustomTimePicker;

  final String? customTimePickerLabel;
  final String? nowLabel;
  final String? clearText;
  final String? confirmText;
  final String? cancelText;

  final String Function(TimeOfDay) formatter;
  final bool use24HourFormat;

  final AppTimeItemBuilder? itemBuilder;

  final void Function(TimeOfDay? time) close;
  final bool isDialog;

  @override
  State<_TimePickerOverlay> createState() => _TimePickerOverlayState();
}

class _TimePickerOverlayState extends State<_TimePickerOverlay> {
  final TextEditingController _search = TextEditingController();
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  late final List<TimeOfDay> _times;

  @override
  void initState() {
    super.initState();
    _times = _buildTimes();
    _search.addListener(() => _query.value = _search.text);
  }

  @override
  void dispose() {
    _search.dispose();
    _query.dispose();
    super.dispose();
  }

  int _toMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  TimeOfDay _fromMinutes(int m) {
    final mm = m % 1440;
    final h = mm ~/ 60;
    final min = mm % 60;
    return TimeOfDay(hour: h, minute: min);
  }

  bool _same(TimeOfDay? a, TimeOfDay? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.hour == b.hour && a.minute == b.minute;
  }

  List<TimeOfDay> _buildTimes() {
    final startM = _toMinutes(widget.start);
    final endM = _toMinutes(widget.end);

    if (endM < startM) {
      // If someone passes end earlier than start, treat as empty list.
      return const [];
    }

    var first = startM;
    if (widget.alignStartToStep && widget.stepMinutes > 1) {
      final mod = first % widget.stepMinutes;
      if (mod != 0) first = first + (widget.stepMinutes - mod);
    }

    final out = <TimeOfDay>[];
    for (var m = first; m <= endM; m += widget.stepMinutes) {
      final t = _fromMinutes(m);
      if (widget.predicate != null && !widget.predicate!(t)) continue;
      out.add(t);
    }
    return out;
  }

  bool _defaultMatch(TimeOfDay t, String q) =>
      widget.formatter(t).toLowerCase().contains(q.toLowerCase());

  List<TimeOfDay> _filtered(String q) {
    if (!widget.enableSearch) return _times;
    final query = q.trim();
    if (query.isEmpty) return _times;
    return _times.where((t) => _defaultMatch(t, query)).toList();
  }

  Future<void> _pickCustom() async {
    final initial = widget.value ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(alwaysUse24HourFormat: widget.use24HourFormat),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    if (!mounted) return;
    if (picked == null) return;

    if (widget.predicate != null && !widget.predicate!(picked)) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Selected time is not allowed.')),
        );
      return;
    }

    widget.close(picked);
  }

  void _pickNow() {
    final now = TimeOfDay.now();
    if (widget.predicate != null && !widget.predicate!(now)) {
      // If "now" isn't allowed, pick the nearest next allowed time from list.
      if (_times.isNotEmpty) {
        final nowM = _toMinutes(now);
        final next = _times.firstWhere(
          (t) => _toMinutes(t) >= nowM,
          orElse: () => _times.last,
        );
        widget.close(next);
        return;
      }
      return;
    }
    widget.close(now);
  }

  void _clear() => widget.close(null);

  @override
  Widget build(BuildContext context) {
    final header = widget.title != null
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (widget.showNowShortcut)
          OutlinedButton.icon(
            onPressed: _pickNow,
            icon: const Icon(Icons.today_rounded),
            label: Text(widget.nowLabel ?? 'Now'),
          ),
        if (widget.showCustomTimePicker)
          OutlinedButton.icon(
            onPressed: _pickCustom,
            icon: const Icon(Icons.more_time_rounded),
            label: Text(widget.customTimePickerLabel ?? 'Custom'),
          ),
        TextButton(onPressed: _clear, child: Text(widget.clearText ?? 'Clear')),
        if (widget.isDialog)
          TextButton(
            onPressed: () => widget.close(widget.value),
            child: Text(widget.cancelText ?? 'Close'),
          ),
      ],
    );

    return Column(
      children: [
        header,
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(children: [Expanded(child: actions)]),
        ),
        if (widget.enableSearch)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.searchHintText ?? 'Search time...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        Expanded(
          child: ValueListenableBuilder<String>(
            valueListenable: _query,
            builder: (context, q, _) {
              final list = _filtered(q);
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    'No times',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final t = list[index];
                  final selected = _same(widget.value, t);

                  // If it passed predicate, it is enabled.
                  final enabled = true;

                  final row =
                      widget.itemBuilder?.call(context, t, selected, enabled) ??
                      ListTile(
                        title: Text(widget.formatter(t)),
                        trailing: selected
                            ? Icon(
                                Icons.check_rounded,
                                color: AppColors.primaryColor,
                              )
                            : null,
                      );

                  return InkWell(onTap: () => widget.close(t), child: row);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
