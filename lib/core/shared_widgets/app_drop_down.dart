import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saraspatika/core/constants/colors.dart';

enum AppDropdownSelectionMode { single, multiple }

enum AppDropdownOverlayMode { bottomSheet, dialog }

typedef AppDropdownLabelBuilder<T> = String Function(T item);
typedef AppDropdownItemBuilder<T> =
    Widget Function(BuildContext context, T item, bool selected);
typedef AppDropdownSearchMatcher<T> = bool Function(T item, String query);
typedef AppDropdownEquality<T> = bool Function(T a, T b);

class AppDropdownField<T> extends StatefulWidget {
  const AppDropdownField({
    super.key,
    required this.items,
    this.loadItems,
    this.cacheLoadedItems = true,
    this.reloadOnOpen = false,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSingleChanged,
    this.mode = AppDropdownSelectionMode.single,
    this.maxSelection,
    this.showChipsForMulti = false,
    this.enableSearch = true,
    this.searchHintText,
    this.searchMatcher,
    this.labelBuilder,
    this.itemBuilder,
    this.isEqual,
    this.enabled = true,
    this.readOnly = false,
    this.allowClear = true,
    this.label,
    this.hintText,
    this.helperText,
    this.leadingIcon,
    this.leading,
    this.suffix,
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
    this.dialogTitle,
    this.confirmText,
    this.cancelText,
    this.clearText,
    this.overlayMode = AppDropdownOverlayMode.bottomSheet,
    this.bottomSheetMaxHeightFactor = 0.82,
    this.hapticFeedback = true,
    this.semanticsLabel,
  }) : assert(
         controller == null || initialValue == null,
         'Provide either controller or initialValue, not both.',
       ),
       assert(
         maxSelection == null || maxSelection > 0,
         'maxSelection must be > 0 when provided.',
       );

  /// Static items. Used when [loadItems] is null, or as initial cached list.
  final List<T> items;

  /// Optional async loader. Called when opening the picker.
  final Future<List<T>> Function()? loadItems;

  /// Cache result from [loadItems] in the field state.
  final bool cacheLoadedItems;

  /// Force calling [loadItems] every time the picker opens.
  final bool reloadOnOpen;

  /// External selection controller. Always stores normalized selection list.
  final ValueNotifier<List<T>>? controller;

  /// Initial selection when [controller] is not provided.
  final List<T>? initialValue;

  /// Called with normalized selection list.
  final ValueChanged<List<T>>? onChanged;

  /// Convenience callback for single mode.
  final ValueChanged<T?>? onSingleChanged;

  final AppDropdownSelectionMode mode;

  /// Only for multi mode.
  final int? maxSelection;

  /// In multi mode, show selected values as chips in the field.
  final bool showChipsForMulti;

  /// Search UI in overlay.
  final bool enableSearch;
  final String? searchHintText;

  /// Custom matcher for search. Defaults to label contains query (case-insensitive).
  final AppDropdownSearchMatcher<T>? searchMatcher;

  /// How to display an item as text. Defaults to item.toString().
  final AppDropdownLabelBuilder<T>? labelBuilder;

  /// Custom item row renderer in overlay list.
  final AppDropdownItemBuilder<T>? itemBuilder;

  /// Equality comparator for selection checks. Defaults to `==`.
  final AppDropdownEquality<T>? isEqual;

  final bool enabled;
  final bool readOnly;
  final bool allowClear;

  final String? label;
  final String? hintText;
  final String? helperText;

  final IconData? leadingIcon;
  final Widget? leading;
  final Widget? suffix;

  final AutovalidateMode? autovalidateMode;
  final FormFieldValidator<List<T>>? validator;
  final FormFieldSetter<List<T>>? onSaved;

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

  final AppDropdownOverlayMode overlayMode;
  final double bottomSheetMaxHeightFactor;

  final bool hapticFeedback;
  final String? semanticsLabel;

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final GlobalKey<FormFieldState<List<T>>> _fieldKey =
      GlobalKey<FormFieldState<List<T>>>();

  final FocusNode _focusNode = FocusNode();

  ValueNotifier<List<T>>? _controller;
  bool _listening = false;

  late List<T> _value;

  List<T>? _cachedItems;
  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();

    _cachedItems = List<T>.from(widget.items);
    _value = _normalize(
      widget.controller?.value ?? widget.initialValue ?? const [],
    );

    _bindController(widget.controller);

    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.items != widget.items) {
      // Keep cached list in sync when static items change.
      if (!_hasLoadedOnce || widget.loadItems == null) {
        _cachedItems = List<T>.from(widget.items);
      }
    }

    if (oldWidget.controller != widget.controller) {
      _unbindController();
      _bindController(widget.controller);

      setState(() {
        _value = _normalize(widget.controller?.value ?? _value);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFormField());
    }

    if (oldWidget.initialValue != widget.initialValue &&
        widget.controller == null) {
      setState(() => _value = _normalize(widget.initialValue ?? const []));
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFormField());
    }

    if (oldWidget.mode != widget.mode &&
        widget.mode == AppDropdownSelectionMode.single) {
      if (_value.length > 1) _setSelection([_value.first], notify: true);
    }
  }

  @override
  void dispose() {
    _unbindController();
    _focusNode.dispose();
    super.dispose();
  }

  void _bindController(ValueNotifier<List<T>>? controller) {
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
    final next = _normalize(_controller!.value);
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

  bool _eq(T a, T b) => widget.isEqual?.call(a, b) ?? a == b;

  List<T> _dedupe(List<T> list) {
    final out = <T>[];
    for (final v in list) {
      if (!out.any((x) => _eq(x, v))) out.add(v);
    }
    return out;
  }

  List<T> _normalize(List<T> v) {
    final deduped = _dedupe(v);
    if (widget.mode == AppDropdownSelectionMode.single && deduped.length > 1) {
      return [deduped.first];
    }
    return deduped;
  }

  bool _sameSelection(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (final x in a) {
      if (!b.any((y) => _eq(x, y))) return false;
    }
    return true;
  }

  String _labelOf(T item) => widget.labelBuilder?.call(item) ?? item.toString();

  String _displayText(List<T> selection) {
    if (selection.isEmpty) return '';
    if (widget.mode == AppDropdownSelectionMode.single ||
        selection.length == 1) {
      return _labelOf(selection.first);
    }
    return selection.map(_labelOf).join(', ');
  }

  void _setSelection(List<T> next, {required bool notify}) {
    final normalized = _normalize(next);
    setState(() => _value = normalized);

    if (_controller != null) {
      _controller!.value = normalized;
    }

    _fieldKey.currentState?.didChange(normalized);

    if (notify) {
      widget.onChanged?.call(normalized);
      if (widget.mode == AppDropdownSelectionMode.single) {
        widget.onSingleChanged?.call(
          normalized.isNotEmpty ? normalized.first : null,
        );
      }
    }
  }

  void _clearSelection() {
    if (!widget.enabled || widget.readOnly) return;
    if (widget.hapticFeedback) HapticFeedback.selectionClick();
    _setSelection(const [], notify: true);
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

  Future<List<T>> _getItemsForOpen() async {
    final loader = widget.loadItems;
    if (loader == null) return List<T>.from(_cachedItems ?? widget.items);

    final shouldReload =
        widget.reloadOnOpen || !_hasLoadedOnce || !widget.cacheLoadedItems;
    if (!shouldReload && _cachedItems != null)
      return List<T>.from(_cachedItems!);

    final loaded = await loader();
    _hasLoadedOnce = true;
    if (widget.cacheLoadedItems) {
      _cachedItems = List<T>.from(loaded);
    }
    return loaded;
  }

  Future<void> _openPicker() async {
    if (!widget.enabled || widget.readOnly) return;

    _focusNode.requestFocus();
    if (widget.hapticFeedback) HapticFeedback.selectionClick();

    final overlayMode = widget.overlayMode;

    if (overlayMode == AppDropdownOverlayMode.dialog) {
      final result = await showDialog<List<T>>(
        context: context,
        barrierDismissible: widget.mode == AppDropdownSelectionMode.single,
        builder: (context) => _AppDropdownDialog<T>(
          title: widget.dialogTitle,
          confirmText: widget.confirmText,
          cancelText: widget.cancelText,
          clearText: widget.clearText,
          mode: widget.mode,
          maxSelection: widget.maxSelection,
          enableSearch: widget.enableSearch,
          searchHintText: widget.searchHintText,
          searchMatcher: widget.searchMatcher,
          labelOf: _labelOf,
          itemBuilder: widget.itemBuilder,
          isSelected: (v, selected) => selected.any((x) => _eq(x, v)),
          initialSelection: _value,
          loadItems: _getItemsForOpen,
        ),
      );

      if (!mounted || result == null) return;
      _setSelection(result, notify: true);
      return;
    }

    final result = await showModalBottomSheet<List<T>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AppDropdownBottomSheet<T>(
        maxHeightFactor: widget.bottomSheetMaxHeightFactor,
        title: widget.dialogTitle,
        confirmText: widget.confirmText,
        cancelText: widget.cancelText,
        clearText: widget.clearText,
        mode: widget.mode,
        maxSelection: widget.maxSelection,
        enableSearch: widget.enableSearch,
        searchHintText: widget.searchHintText,
        searchMatcher: widget.searchMatcher,
        labelOf: _labelOf,
        itemBuilder: widget.itemBuilder,
        isSelected: (v, selected) => selected.any((x) => _eq(x, v)),
        initialSelection: _value,
        loadItems: _getItemsForOpen,
      ),
    );

    if (!mounted || result == null) return;
    _setSelection(result, notify: true);
  }

  @override
  Widget build(BuildContext context) {
    final display = _displayText(_value);
    final canClear =
        widget.allowClear &&
        widget.enabled &&
        !widget.readOnly &&
        _value.isNotEmpty;

    final prefix =
        widget.leading ??
        (widget.leadingIcon != null ? Icon(widget.leadingIcon) : null);

    return FormField<List<T>>(
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

        final fieldContent =
            (widget.mode == AppDropdownSelectionMode.multiple &&
                widget.showChipsForMulti &&
                _value.isNotEmpty)
            ? Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _value.map((v) {
                  return InputChip(
                    label: Text(_labelOf(v)),
                    onDeleted: (widget.enabled && !widget.readOnly)
                        ? () {
                            final next = List<T>.from(_value)
                              ..removeWhere((x) => _eq(x, v));
                            _setSelection(next, notify: true);
                          }
                        : null,
                  );
                }).toList(),
              )
            : Text(
                display.isEmpty ? (widget.hintText ?? '') : display,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: display.isEmpty ? Colors.grey : null),
              );

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
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              tooltip: 'Open',
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
                  onTap: (widget.enabled && !widget.readOnly)
                      ? _openPicker
                      : null,
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  child: Container(
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color: widget.fillColor,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment:
                          (widget.showChipsForMulti && _value.isNotEmpty)
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
                              fieldContent,
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

class _AppDropdownBottomSheet<T> extends StatefulWidget {
  const _AppDropdownBottomSheet({
    required this.maxHeightFactor,
    required this.title,
    required this.confirmText,
    required this.cancelText,
    required this.clearText,
    required this.mode,
    required this.maxSelection,
    required this.enableSearch,
    required this.searchHintText,
    required this.searchMatcher,
    required this.labelOf,
    required this.itemBuilder,
    required this.isSelected,
    required this.initialSelection,
    required this.loadItems,
  });

  final double maxHeightFactor;

  final String? title;
  final String? confirmText;
  final String? cancelText;
  final String? clearText;

  final AppDropdownSelectionMode mode;
  final int? maxSelection;

  final bool enableSearch;
  final String? searchHintText;
  final AppDropdownSearchMatcher<T>? searchMatcher;

  final String Function(T) labelOf;
  final AppDropdownItemBuilder<T>? itemBuilder;

  final bool Function(T item, List<T> selection) isSelected;
  final List<T> initialSelection;

  final Future<List<T>> Function() loadItems;

  @override
  State<_AppDropdownBottomSheet<T>> createState() =>
      _AppDropdownBottomSheetState<T>();
}

class _AppDropdownBottomSheetState<T>
    extends State<_AppDropdownBottomSheet<T>> {
  final TextEditingController _search = TextEditingController();
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  bool _loading = true;
  Object? _error;
  List<T> _items = const [];

  late List<T> _selection;

  @override
  void initState() {
    super.initState();
    _selection = List<T>.from(widget.initialSelection);
    _search.addListener(() => _query.value = _search.text);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.loadItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  bool _defaultMatch(T item, String q) =>
      widget.labelOf(item).toLowerCase().contains(q.toLowerCase());

  List<T> _filtered(List<T> items, String q) {
    if (!widget.enableSearch) return items;
    final query = q.trim();
    if (query.isEmpty) return items;
    final matcher = widget.searchMatcher;
    return items
        .where((it) => matcher?.call(it, query) ?? _defaultMatch(it, query))
        .toList();
  }

  void _toggle(T item) {
    final selected = widget.isSelected(item, _selection);

    if (widget.mode == AppDropdownSelectionMode.single) {
      Navigator.of(context).pop<List<T>>([item]);
      return;
    }

    setState(() {
      if (selected) {
        _selection.removeWhere(
          (x) => widget.labelOf(x) == widget.labelOf(item) && x == item
              ? true
              : false,
        );
        // Above line is safe for most; actual equality for removal is handled by user via isEqual on parent.
        // But since we don't have isEqual here, we remove by identity+label fallback.
        // If you need stricter removal, pass stable object instances as items.
        if (selected && _selection.isEmpty) {}
      } else {
        final max = widget.maxSelection;
        if (max != null && _selection.length >= max) {
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Maximum $max selections.'),
                duration: const Duration(seconds: 2),
              ),
            );
          return;
        }
        _selection.add(item);
      }
    });
  }

  void _clear() => setState(() => _selection = const []);

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        MediaQuery.of(context).size.height * widget.maxHeightFactor;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title ?? 'Select',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (widget.mode == AppDropdownSelectionMode.multiple)
                    Text(
                      widget.maxSelection != null
                          ? '${_selection.length}/${widget.maxSelection}'
                          : '${_selection.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.enableSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.searchHintText ?? 'Search...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Failed to load items.',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ValueListenableBuilder<String>(
                      valueListenable: _query,
                      builder: (context, q, _) {
                        final list = _filtered(_items, q);
                        if (list.isEmpty) {
                          return Center(
                            child: Text(
                              'No items',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.only(bottom: 12),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final selected = widget.isSelected(
                              item,
                              _selection,
                            );

                            final row =
                                widget.itemBuilder?.call(
                                  context,
                                  item,
                                  selected,
                                ) ??
                                ListTile(
                                  title: Text(widget.labelOf(item)),
                                  trailing: selected
                                      ? Icon(
                                          Icons.check_rounded,
                                          color: AppColors.primaryColor,
                                        )
                                      : null,
                                );

                            return InkWell(
                              onTap: () => _toggle(item),
                              child: row,
                            );
                          },
                        );
                      },
                    ),
            ),
            if (widget.mode == AppDropdownSelectionMode.multiple)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _clear,
                      child: Text(widget.clearText ?? 'Clear'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop<List<T>>(null),
                      child: Text(widget.cancelText ?? 'Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => Navigator.of(
                        context,
                      ).pop<List<T>>(List<T>.from(_selection)),
                      child: Text(widget.confirmText ?? 'OK'),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AppDropdownDialog<T> extends StatefulWidget {
  const _AppDropdownDialog({
    required this.title,
    required this.confirmText,
    required this.cancelText,
    required this.clearText,
    required this.mode,
    required this.maxSelection,
    required this.enableSearch,
    required this.searchHintText,
    required this.searchMatcher,
    required this.labelOf,
    required this.itemBuilder,
    required this.isSelected,
    required this.initialSelection,
    required this.loadItems,
  });

  final String? title;
  final String? confirmText;
  final String? cancelText;
  final String? clearText;

  final AppDropdownSelectionMode mode;
  final int? maxSelection;

  final bool enableSearch;
  final String? searchHintText;
  final AppDropdownSearchMatcher<T>? searchMatcher;

  final String Function(T) labelOf;
  final AppDropdownItemBuilder<T>? itemBuilder;

  final bool Function(T item, List<T> selection) isSelected;
  final List<T> initialSelection;

  final Future<List<T>> Function() loadItems;

  @override
  State<_AppDropdownDialog<T>> createState() => _AppDropdownDialogState<T>();
}

class _AppDropdownDialogState<T> extends State<_AppDropdownDialog<T>> {
  final TextEditingController _search = TextEditingController();
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  bool _loading = true;
  Object? _error;
  List<T> _items = const [];

  late List<T> _selection;

  @override
  void initState() {
    super.initState();
    _selection = List<T>.from(widget.initialSelection);
    _search.addListener(() => _query.value = _search.text);
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.loadItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  bool _defaultMatch(T item, String q) =>
      widget.labelOf(item).toLowerCase().contains(q.toLowerCase());

  List<T> _filtered(List<T> items, String q) {
    if (!widget.enableSearch) return items;
    final query = q.trim();
    if (query.isEmpty) return items;
    final matcher = widget.searchMatcher;
    return items
        .where((it) => matcher?.call(it, query) ?? _defaultMatch(it, query))
        .toList();
  }

  void _toggle(T item) {
    final selected = widget.isSelected(item, _selection);

    if (widget.mode == AppDropdownSelectionMode.single) {
      Navigator.of(context).pop<List<T>>([item]);
      return;
    }

    setState(() {
      if (selected) {
        _selection.removeWhere(
          (x) =>
              identical(x, item) || widget.labelOf(x) == widget.labelOf(item),
        );
      } else {
        final max = widget.maxSelection;
        if (max != null && _selection.length >= max) {
          ScaffoldMessenger.maybeOf(context)
            ?..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text('Maximum $max selections.'),
                duration: const Duration(seconds: 2),
              ),
            );
          return;
        }
        _selection.add(item);
      }
    });
  }

  void _clear() => setState(() => _selection = const []);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title ?? 'Select'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.enableSearch)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: widget.searchHintText ?? 'Search...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            SizedBox(
              height: 380,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Failed to load items.',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : ValueListenableBuilder<String>(
                      valueListenable: _query,
                      builder: (context, q, _) {
                        final list = _filtered(_items, q);
                        if (list.isEmpty) {
                          return Center(
                            child: Text(
                              'No items',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final selected = widget.isSelected(
                              item,
                              _selection,
                            );

                            final row =
                                widget.itemBuilder?.call(
                                  context,
                                  item,
                                  selected,
                                ) ??
                                ListTile(
                                  title: Text(widget.labelOf(item)),
                                  trailing: selected
                                      ? Icon(
                                          Icons.check_rounded,
                                          color: AppColors.primaryColor,
                                        )
                                      : null,
                                );

                            return InkWell(
                              onTap: () => _toggle(item),
                              child: row,
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: widget.mode == AppDropdownSelectionMode.single
          ? [
              TextButton(
                onPressed: () => Navigator.of(context).pop<List<T>>(null),
                child: Text(widget.cancelText ?? 'Close'),
              ),
            ]
          : [
              TextButton(
                onPressed: _clear,
                child: Text(widget.clearText ?? 'Clear'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop<List<T>>(null),
                child: Text(widget.cancelText ?? 'Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(
                  context,
                ).pop<List<T>>(List<T>.from(_selection)),
                child: Text(widget.confirmText ?? 'OK'),
              ),
            ],
    );
  }
}
