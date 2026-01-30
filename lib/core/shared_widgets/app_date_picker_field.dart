import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saraspatika/core/constants/colors.dart';

enum AppDateSelectionMode { single, multiple }

typedef AppDateSelectionFormatter =
    String Function(BuildContext context, List<DateTime> dates);

class AppDatePickerField extends StatefulWidget {
  AppDatePickerField({
    super.key,
    this.controller,
    this.initialDates,
    this.onChanged,
    this.onSingleChanged,
    this.mode = AppDateSelectionMode.single,
    required this.firstDate,
    required this.lastDate,
    this.initialMonth,
    this.selectableDayPredicate,
    this.maxMultiSelection,
    this.enableRangeSelectionInMulti = false,
    this.showChipsForMulti = false,
    this.label,
    this.hintText,
    this.helperText,
    this.enabled = true,
    this.allowClear = true,
    this.leadingIcon,
    this.leading,
    this.formatter,
    this.autovalidateMode,
    this.validator,
    this.onSaved,
    this.borderRadius = 12,
    this.fillColor = Colors.white,
    this.borderColor,
    this.focusedBorderColor,
    this.disabledBorderColor,
    this.errorBorderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.dialogTitle,
    this.confirmText,
    this.cancelText,
    this.clearText,
    this.showTodayShortcut = true,
    this.semanticsLabel,
    this.hapticFeedback = true,
  }) : assert(
         firstDate.isBefore(lastDate) || _isSameDay(firstDate, lastDate),
         'firstDate must be on or before lastDate.',
       );

  /// External selection controller. If provided, this widget will read/write selection here.
  final ValueNotifier<List<DateTime>>? controller;

  /// Initial selection when [controller] is not provided.
  final List<DateTime>? initialDates;

  /// Always called with the normalized and sorted selected dates.
  final ValueChanged<List<DateTime>>? onChanged;

  /// Convenience callback for single mode. Receives the picked date or null when cleared.
  final ValueChanged<DateTime?>? onSingleChanged;

  final AppDateSelectionMode mode;

  final DateTime firstDate;
  final DateTime lastDate;

  /// Month displayed when picker opens. If null, uses first selected date's month or today.
  final DateTime? initialMonth;

  /// Return true if [day] is selectable. If null, all days in range are selectable.
  final SelectableDayPredicate? selectableDayPredicate;

  /// Only used in multi mode. When set, user cannot select more than this number of days.
  final int? maxMultiSelection;

  /// Optional: in multi mode, after selecting an "anchor" date, tapping another date selects
  /// all days in-between (inclusive), subject to predicate/range and maxMultiSelection.
  final bool enableRangeSelectionInMulti;

  /// In multi mode, show selected dates as chips inside the field (with delete).
  final bool showChipsForMulti;

  final String? label;
  final String? hintText;
  final String? helperText;

  final bool enabled;
  final bool allowClear;

  final IconData? leadingIcon;
  final Widget? leading;

  /// Customize how selected dates are displayed in the field.
  /// Default: single uses MaterialLocalizations.formatShortDate; multi joins by ", ".
  final AppDateSelectionFormatter? formatter;

  final AutovalidateMode? autovalidateMode;
  final FormFieldValidator<List<DateTime>>? validator;
  final FormFieldSetter<List<DateTime>>? onSaved;

  final double borderRadius;
  final Color fillColor;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? disabledBorderColor;
  final Color? errorBorderColor;
  final EdgeInsetsGeometry padding;

  final String? dialogTitle;
  final String? confirmText;
  final String? cancelText;
  final String? clearText;
  final bool showTodayShortcut;

  final String? semanticsLabel;
  final bool hapticFeedback;

  @override
  State<AppDatePickerField> createState() => _AppDatePickerFieldState();

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _AppDatePickerFieldState extends State<AppDatePickerField> {
  final GlobalKey<FormFieldState<List<DateTime>>> _fieldKey =
      GlobalKey<FormFieldState<List<DateTime>>>();

  final FocusNode _focusNode = FocusNode();

  late List<DateTime> _value;
  ValueNotifier<List<DateTime>>? _controller;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _value = _normalizeAndSort(
      widget.controller?.value ?? widget.initialDates ?? const [],
    );
    _bindController(widget.controller);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant AppDatePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _unbindController();
      _bindController(widget.controller);
      setState(() {
        _value = _normalizeAndSort(widget.controller?.value ?? _value);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFormField());
    }

    if (oldWidget.initialDates != widget.initialDates &&
        widget.controller == null) {
      setState(
        () => _value = _normalizeAndSort(widget.initialDates ?? const []),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFormField());
    }

    if (oldWidget.mode != widget.mode &&
        widget.mode == AppDateSelectionMode.single) {
      if (_value.length > 1) _setSelection([_value.first], notify: true);
    }
  }

  @override
  void dispose() {
    _unbindController();
    _focusNode.dispose();
    super.dispose();
  }

  void _bindController(ValueNotifier<List<DateTime>>? controller) {
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
    final next = _normalizeAndSort(_controller!.value);
    if (_sameSelection(_value, next)) return;
    setState(() => _value = next);
    _syncFormField();
  }

  void _syncFormField() {
    final state = _fieldKey.currentState;
    if (state == null) return;
    if (!_sameSelection(state.value ?? const [], _value)) {
      state.didChange(_value);
    }
  }

  bool _sameSelection(List<DateTime> a, List<DateTime> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.year != y.year || x.month != y.month || x.day != y.day)
        return false;
    }
    return true;
  }

  List<DateTime> _normalizeAndSort(List<DateTime> dates) {
    final map = <int, DateTime>{};
    for (final d in dates) {
      final n = DateTime(d.year, d.month, d.day);
      map[_key(n)] = n;
    }
    final out = map.values.toList()..sort((a, b) => a.compareTo(b));
    if (widget.mode == AppDateSelectionMode.single && out.length > 1) {
      return [out.first];
    }
    return out;
  }

  int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  DateTime _clampToRange(DateTime date) {
    final n = DateTime(date.year, date.month, date.day);
    if (n.isBefore(_normalize(widget.firstDate)))
      return _normalize(widget.firstDate);
    if (n.isAfter(_normalize(widget.lastDate)))
      return _normalize(widget.lastDate);
    return n;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  String _defaultFormat(BuildContext context, List<DateTime> dates) {
    if (dates.isEmpty) return '';
    final localizations = MaterialLocalizations.of(context);
    if (widget.mode == AppDateSelectionMode.single || dates.length == 1) {
      return localizations.formatShortDate(dates.first);
    }
    return dates.map(localizations.formatShortDate).join(', ');
  }

  String _displayText(BuildContext context, List<DateTime> dates) {
    final fmt = widget.formatter;
    if (fmt != null) return fmt(context, dates);
    return _defaultFormat(context, dates);
  }

  void _setSelection(List<DateTime> next, {required bool notify}) {
    final normalized = _normalizeAndSort(next);
    setState(() => _value = normalized);

    if (_controller != null) {
      _controller!.value = normalized;
    }

    _fieldKey.currentState?.didChange(normalized);

    if (notify) {
      widget.onChanged?.call(normalized);
      if (widget.mode == AppDateSelectionMode.single) {
        widget.onSingleChanged?.call(
          normalized.isNotEmpty ? normalized.first : null,
        );
      }
    }
  }

  void _clearSelection() {
    if (!widget.enabled) return;
    if (widget.hapticFeedback) HapticFeedback.selectionClick();
    _setSelection(const [], notify: true);
  }

  Future<void> _openPicker() async {
    if (!widget.enabled) return;

    _focusNode.requestFocus();
    if (widget.hapticFeedback) HapticFeedback.selectionClick();

    if (widget.mode == AppDateSelectionMode.single) {
      final picked = await _showSinglePicker(context);
      if (!mounted) return;
      if (picked == null) return;
      _setSelection([picked], notify: true);
      return;
    }

    final picked = await _showMultiPicker(context);
    if (!mounted) return;
    if (picked == null) return;
    _setSelection(picked, notify: true);
  }

  Future<DateTime?> _showSinglePicker(BuildContext context) async {
    final initial = _value.isNotEmpty
        ? _clampToRange(_value.first)
        : _clampToRange(widget.initialMonth ?? DateTime.now());

    return showDatePicker(
      context: context,
      firstDate: _normalize(widget.firstDate),
      lastDate: _normalize(widget.lastDate),
      initialDate: initial,
      selectableDayPredicate: widget.selectableDayPredicate,
      helpText: widget.dialogTitle,
      confirmText: widget.confirmText,
      cancelText: widget.cancelText,
    );
  }

  Future<List<DateTime>?> _showMultiPicker(BuildContext context) async {
    return showDialog<List<DateTime>>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AppMultiDatePickerDialog(
          initialSelection: _value,
          firstDate: _normalize(widget.firstDate),
          lastDate: _normalize(widget.lastDate),
          initialMonth: _normalize(
            widget.initialMonth ??
                (_value.isNotEmpty ? _value.first : DateTime.now()),
          ),
          selectableDayPredicate: widget.selectableDayPredicate,
          maxSelection: widget.maxMultiSelection,
          enableRangeSelection: widget.enableRangeSelectionInMulti,
          title: widget.dialogTitle,
          confirmText: widget.confirmText,
          cancelText: widget.cancelText,
          clearText: widget.clearText,
          showTodayShortcut: widget.showTodayShortcut,
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    final display = _displayText(context, _value);
    final canClear = widget.allowClear && widget.enabled && _value.isNotEmpty;

    return FormField<List<DateTime>>(
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

        final prefix =
            widget.leading ??
            (widget.leadingIcon != null ? Icon(widget.leadingIcon) : null);

        final suffix = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canClear)
              IconButton(
                onPressed: _clearSelection,
                icon: const Icon(Icons.close_rounded),
                tooltip: widget.clearText ?? 'Clear',
              ),
            IconButton(
              onPressed: _openPicker,
              icon: const Icon(Icons.calendar_month_rounded),
              tooltip: 'Pick date',
            ),
          ],
        );

        final content =
            widget.mode == AppDateSelectionMode.multiple &&
                widget.showChipsForMulti &&
                _value.isNotEmpty
            ? Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _value.map((d) {
                  final label = MaterialLocalizations.of(
                    context,
                  ).formatShortDate(d);
                  return InputChip(
                    label: Text(label),
                    onDeleted: widget.enabled
                        ? () {
                            final next = List<DateTime>.from(_value)
                              ..removeWhere(
                                (x) => AppDatePickerField._isSameDay(x, d),
                              );
                            _setSelection(next, notify: true);
                          }
                        : null,
                  );
                }).toList(),
              )
            : Text(
                display.isEmpty ? (widget.hintText ?? '') : display,
                style: TextStyle(color: display.isEmpty ? Colors.grey : null),
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: widget.semanticsLabel ?? widget.label ?? widget.hintText,
              button: true,
              enabled: widget.enabled,
              child: Focus(
                focusNode: _focusNode,
                child: InkWell(
                  onTap: widget.enabled ? _openPicker : null,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color: widget.fillColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: widget.showChipsForMulti
                          ? CrossAxisAlignment.start
                          : CrossAxisAlignment.center,
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
                              content,
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
                  footerText!,
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

class AppMultiDatePickerDialog extends StatefulWidget {
  const AppMultiDatePickerDialog({
    super.key,
    required this.initialSelection,
    required this.firstDate,
    required this.lastDate,
    required this.initialMonth,
    this.selectableDayPredicate,
    this.maxSelection,
    this.enableRangeSelection = false,
    this.title,
    this.confirmText,
    this.cancelText,
    this.clearText,
    this.showTodayShortcut = true,
  });

  final List<DateTime> initialSelection;
  final DateTime firstDate;
  final DateTime lastDate;
  final DateTime initialMonth;

  final SelectableDayPredicate? selectableDayPredicate;
  final int? maxSelection;

  final bool enableRangeSelection;

  final String? title;
  final String? confirmText;
  final String? cancelText;
  final String? clearText;
  final bool showTodayShortcut;

  @override
  State<AppMultiDatePickerDialog> createState() =>
      _AppMultiDatePickerDialogState();
}

class _AppMultiDatePickerDialogState extends State<AppMultiDatePickerDialog> {
  late DateTime _month;
  late List<DateTime> _selected;
  DateTime? _rangeAnchor;

  @override
  void initState() {
    super.initState();
    _month = DateTime(widget.initialMonth.year, widget.initialMonth.month, 1);
    _selected = _normalizeAndSort(widget.initialSelection);
  }

  int _key(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  List<DateTime> _normalizeAndSort(List<DateTime> dates) {
    final map = <int, DateTime>{};
    for (final d in dates) {
      final n = _normalize(d);
      map[_key(n)] = n;
    }
    final out = map.values.toList()..sort((a, b) => a.compareTo(b));
    return out;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _contains(DateTime day) => _selected.any((d) => _isSameDay(d, day));

  bool _isSelectable(DateTime day) {
    final n = _normalize(day);
    if (n.isBefore(widget.firstDate) || n.isAfter(widget.lastDate))
      return false;
    final pred = widget.selectableDayPredicate;
    if (pred != null && !pred(n)) return false;
    return true;
  }

  void _toggle(DateTime day) {
    if (!_isSelectable(day)) return;

    final exists = _contains(day);
    if (exists) {
      setState(() {
        _selected.removeWhere((d) => _isSameDay(d, day));
        if (_rangeAnchor != null && _isSameDay(_rangeAnchor!, day)) {
          _rangeAnchor = null;
        }
      });
      return;
    }

    final max = widget.maxSelection;
    if (max != null && _selected.length >= max) {
      _showMaxSnack(max);
      return;
    }

    setState(() {
      _selected = _normalizeAndSort([..._selected, day]);
    });
  }

  void _showMaxSnack(int max) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        content: Text('Maximum $max dates can be selected.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _selectRange(DateTime end) {
    if (_rangeAnchor == null) {
      _rangeAnchor = end;
      _toggle(end);
      return;
    }

    final start = _normalize(_rangeAnchor!);
    final finish = _normalize(end);

    final from = start.isBefore(finish) ? start : finish;
    final to = start.isBefore(finish) ? finish : start;

    final dates = <DateTime>[];
    var cur = from;
    while (!cur.isAfter(to)) {
      if (_isSelectable(cur)) {
        dates.add(cur);
      }
      cur = cur.add(const Duration(days: 1));
    }

    final max = widget.maxSelection;
    final nextSet = <int, DateTime>{for (final d in _selected) _key(d): d};
    for (final d in dates) {
      if (max != null && nextSet.length >= max) {
        _showMaxSnack(max);
        break;
      }
      nextSet[_key(d)] = d;
    }

    setState(() {
      _selected = nextSet.values.toList()..sort((a, b) => a.compareTo(b));
      _rangeAnchor = null;
    });
  }

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1, 1));
  void _nextMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1, 1));

  bool _canGoPrev() {
    final prev = DateTime(_month.year, _month.month - 1, 1);
    return !prev.isBefore(
      DateTime(widget.firstDate.year, widget.firstDate.month, 1),
    );
  }

  bool _canGoNext() {
    final next = DateTime(_month.year, _month.month + 1, 1);
    return !next.isAfter(
      DateTime(widget.lastDate.year, widget.lastDate.month, 1),
    );
  }

  void _jumpToToday() {
    final today = DateTime.now();
    final normalized = _normalize(today);
    if (normalized.isBefore(widget.firstDate) ||
        normalized.isAfter(widget.lastDate))
      return;
    setState(() => _month = DateTime(normalized.year, normalized.month, 1));
  }

  List<String> _weekdayLabels(MaterialLocalizations loc, int firstDayIndex) {
    final base = loc.narrowWeekdays; // length 7
    final out = <String>[];
    for (var i = 0; i < 7; i++) {
      out.add(base[(firstDayIndex + i) % 7]);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final title = widget.title ?? 'Select dates';
    final firstDayIndex = loc.firstDayOfWeekIndex;

    final monthLabel = loc.formatMonthYear(_month);
    final weekdayLabels = _weekdayLabels(loc, firstDayIndex);

    final firstOfMonth = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);

    // Convert DateTime.weekday to 0..6 where 0=Sunday.
    final firstDow0 = firstOfMonth.weekday % 7;
    final leadingBlanks = (firstDow0 - firstDayIndex + 7) % 7;

    final totalCellsRaw = leadingBlanks + daysInMonth;
    final trailingBlanks = (7 - (totalCellsRaw % 7)) % 7;
    final totalCells = totalCellsRaw + trailingBlanks;

    final maxInfo = widget.maxSelection != null
        ? '(${_selected.length}/${widget.maxSelection})'
        : '(${_selected.length})';

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: 4),
          Text(
            'Selected $maxInfo',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          if (widget.enableRangeSelection) ...[
            const SizedBox(height: 2),
            Text(
              _rangeAnchor == null
                  ? 'Tap to select. Tap again to select a range.'
                  : 'Select end date for range.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _canGoPrev() ? _prevMonth : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous month',
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      monthLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (widget.showTodayShortcut)
                  IconButton(
                    onPressed: _jumpToToday,
                    icon: const Icon(Icons.today_rounded),
                    tooltip: 'Today',
                  ),
                IconButton(
                  onPressed: _canGoNext() ? _nextMonth : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next month',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: weekdayLabels
                  .map(
                    (w) => Expanded(
                      child: Center(
                        child: Text(
                          w,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 330,
              child: GridView.builder(
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.2,
                ),
                itemBuilder: (context, index) {
                  final dayNumber = index - leadingBlanks + 1;
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final day = DateTime(_month.year, _month.month, dayNumber);
                  final isToday = _isSameDay(day, _normalize(DateTime.now()));
                  final selected = _contains(day);
                  final enabled = _isSelectable(day);

                  final bg = selected
                      ? AppColors.primaryColor.withOpacity(0.18)
                      : Colors.transparent;

                  final border = selected
                      ? Border.all(color: AppColors.primaryColor, width: 1.2)
                      : isToday
                      ? Border.all(
                          color: AppColors.secondaryColor.withOpacity(0.7),
                          width: 1,
                        )
                      : Border.all(color: Colors.grey.shade300, width: 1);

                  final textColor = !enabled
                      ? Colors.grey.shade400
                      : selected
                      ? AppColors.primaryColor
                      : null;

                  return InkWell(
                    onTap: !enabled
                        ? null
                        : () {
                            if (widget.enableRangeSelection) {
                              _selectRange(day);
                            } else {
                              _toggle(day);
                            }
                          },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: border,
                      ),
                      child: Center(
                        child: Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _selected = const [];
            _rangeAnchor = null;
          }),
          child: Text(widget.clearText ?? 'Clear'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop<List<DateTime>>(null),
          child: Text(widget.cancelText ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(
            context,
          ).pop<List<DateTime>>(_normalizeAndSort(_selected)),
          child: Text(widget.confirmText ?? 'OK'),
        ),
      ],
    );
  }
}
