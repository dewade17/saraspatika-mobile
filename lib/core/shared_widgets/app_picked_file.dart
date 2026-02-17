// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:saraspatika/core/constants/colors.dart';
import 'package:saraspatika/core/utils/image_compress_utils.dart';

enum AppFileSource { fileSystem, gallery, camera }

enum AppFilePickerMode { any, imagesOnly, videosOnly, media, custom }

class AppFilePicker {
  static Future<AppFileSource?> showSourceChooser(
    BuildContext context, {
    bool allowCamera = true,
    bool allowGallery = true,
    bool allowFileSystem = false,
    String cameraLabel = 'Camera',
    String galleryLabel = 'Gallery',
    String filesLabel = 'Files',
    bool hapticFeedback = true,
    String dialogTitle = 'Choose source',
  }) async {
    final items = <_SourceItem>[
      if (allowCamera)
        const _SourceItem(
          AppFileSource.camera,
          'Camera',
          Icons.photo_camera_rounded,
        ),
      if (allowGallery)
        const _SourceItem(
          AppFileSource.gallery,
          'Gallery',
          Icons.photo_library_rounded,
        ),
      if (allowFileSystem)
        const _SourceItem(
          AppFileSource.fileSystem,
          'Files',
          Icons.attach_file_rounded,
        ),
    ];

    final normalized = items
        .map(
          (it) => _SourceItem(
            it.source,
            it.source == AppFileSource.camera
                ? cameraLabel
                : it.source == AppFileSource.gallery
                ? galleryLabel
                : filesLabel,
            it.icon,
          ),
        )
        .toList();

    if (normalized.isEmpty) return null;

    if (normalized.length == 1) return normalized.first.source;

    return showModalBottomSheet<AppFileSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        dialogTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...normalized.map((it) {
                return ListTile(
                  leading: Icon(it.icon),
                  title: Text(it.label),
                  onTap: () async {
                    if (hapticFeedback) HapticFeedback.selectionClick();
                    Navigator.of(ctx).pop(it.source);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static Future<List<AppPickedFile>> pickFromFileSystem({
    required BuildContext context,
    required AppFilePickerMode mode,
    required FileType fileType,
    required bool allowMultiple,
    List<String>? allowedExtensions,
    int? maxFileSizeBytes,
  }) async {
    final type = mode == AppFilePickerMode.custom ? FileType.custom : fileType;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: allowMultiple,
      type: type,
      allowedExtensions: type == FileType.custom ? allowedExtensions : null,
      withData: false,
    );

    if (result == null) return const [];

    final picked = <AppPickedFile>[];
    for (final pf in result.files) {
      final path = pf.path;
      if (path == null) continue;
      final file = File(path);

      final size = await _safeLength(file);
      if (!_passesSizeLimit(context, size, maxFileSizeBytes)) continue;

      picked.add(
        AppPickedFile(
          file: file,
          source: AppFileSource.fileSystem,
          name: pf.name,
          sizeBytes: size,
          extension: (pf.extension ?? '').toLowerCase(),
        ),
      );
    }

    return picked;
  }

  static Future<List<AppPickedFile>> pickFromGallery({
    required BuildContext context,
    required AppFilePickerMode mode,
    required bool allowMultiple,
    int? maxFileSizeBytes,
  }) async {
    final picker = ImagePicker();

    if (mode == AppFilePickerMode.videosOnly) {
      final x = await picker.pickVideo(source: ImageSource.gallery);
      if (x == null) return const [];
      final file = File(x.path);

      final size = await _safeLength(file);
      if (!_passesSizeLimit(context, size, maxFileSizeBytes)) return const [];

      return [
        AppPickedFile(
          file: file,
          source: AppFileSource.gallery,
          sizeBytes: size,
        ),
      ];
    }

    if (allowMultiple &&
        (mode == AppFilePickerMode.imagesOnly ||
            mode == AppFilePickerMode.media)) {
      final xs = await picker.pickMultiImage();
      final out = <AppPickedFile>[];
      for (final x in xs) {
        final file = File(x.path);
        final size = await _safeLength(file);
        if (!_passesSizeLimit(context, size, maxFileSizeBytes)) continue;
        out.add(
          AppPickedFile(
            file: file,
            source: AppFileSource.gallery,
            sizeBytes: size,
          ),
        );
      }
      return out;
    }

    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return const [];
    final file = File(x.path);

    final size = await _safeLength(file);
    if (!_passesSizeLimit(context, size, maxFileSizeBytes)) return const [];

    return [
      AppPickedFile(file: file, source: AppFileSource.gallery, sizeBytes: size),
    ];
  }

  static Future<List<AppPickedFile>> pickFromCamera({
    required BuildContext context,
    required bool compressCameraImage,
    required ImageCompressOptions cameraCompressOptions,
    int? maxFileSizeBytes,
  }) async {
    final picker = ImagePicker();

    final x = await picker.pickImage(source: ImageSource.camera);
    if (x == null) return const [];

    File file = File(x.path);

    if (compressCameraImage) {
      file = await ImageCompressUtils.compressImageFile(
        file,
        options: cameraCompressOptions,
      );
    }

    final size = await _safeLength(file);
    if (!_passesSizeLimit(context, size, maxFileSizeBytes)) return const [];

    return [
      AppPickedFile(file: file, source: AppFileSource.camera, sizeBytes: size),
    ];
  }

  static Future<int> _safeLength(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return 0;
    }
  }

  static bool _passesSizeLimit(BuildContext context, int bytes, int? maxBytes) {
    final max = maxBytes;
    if (max == null || max <= 0) return true;
    if (bytes <= max) return true;

    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'File too large. Max ${(max / (1024 * 1024)).toStringAsFixed(1)} MB',
          ),
          duration: const Duration(seconds: 2),
        ),
      );

    return false;
  }
}

class _SourceItem {
  const _SourceItem(this.source, this.label, this.icon);
  final AppFileSource source;
  final String label;
  final IconData icon;
}

class AppPickedFile {
  AppPickedFile({
    required this.file,
    required this.source,
    String? name,
    int? sizeBytes,
    String? extension,
    bool? isImage,
  }) : name = name ?? p.basename(file.path),
       sizeBytes = sizeBytes ?? 0,
       extension = extension ?? _extOf(file.path),
       isImage = isImage ?? _isImagePath(file.path);

  final File file;
  final AppFileSource source;

  final String name;
  final int sizeBytes;
  final String extension;
  final bool isImage;

  String get path => file.path;

  static String _extOf(String path) {
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();
    return ext;
  }

  static bool _isImagePath(String path) {
    final ext = _extOf(path);
    return <String>{
      'jpg',
      'jpeg',
      'png',
      'webp',
      'heic',
      'heif',
      'gif',
      'bmp',
    }.contains(ext);
  }
}

class AppFilePickerController extends ValueNotifier<List<AppPickedFile>> {
  AppFilePickerController([List<AppPickedFile>? value])
    : super(value ?? const []);

  void clear() => value = const [];
  void setFiles(List<AppPickedFile> files) => value = files;

  Future<AppPickedFile?> pickProfilePhoto(
    BuildContext context, {
    bool allowCamera = true,
    bool allowGallery = true,
    bool compressCameraImage = true,
    ImageCompressOptions cameraCompressOptions = const ImageCompressOptions(),
    int? maxFileSizeBytes,
    String cameraLabel = 'Camera',
    String galleryLabel = 'Gallery',
    bool hapticFeedback = true,
  }) async {
    try {
      final source = await AppFilePicker.showSourceChooser(
        context,
        allowCamera: allowCamera,
        allowGallery: allowGallery,
        allowFileSystem: false,
        cameraLabel: cameraLabel,
        galleryLabel: galleryLabel,
        hapticFeedback: hapticFeedback,
      );

      if (source == null) return null;

      List<AppPickedFile> picked = const [];
      switch (source) {
        case AppFileSource.camera:
          picked = await AppFilePicker.pickFromCamera(
            context: context,
            compressCameraImage: compressCameraImage,
            cameraCompressOptions: cameraCompressOptions,
            maxFileSizeBytes: maxFileSizeBytes,
          );
          break;
        case AppFileSource.gallery:
          picked = await AppFilePicker.pickFromGallery(
            context: context,
            mode: AppFilePickerMode.imagesOnly,
            allowMultiple: false,
            maxFileSizeBytes: maxFileSizeBytes,
          );
          break;
        case AppFileSource.fileSystem:
          picked = const [];
          break;
      }

      if (picked.isEmpty) return null;

      final file = picked.first;
      setFiles([file]);
      return file;
    } on PlatformException catch (e) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Failed to pick photo.'),
            duration: const Duration(seconds: 2),
          ),
        );
      return null;
    } catch (e) {
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      return null;
    }
  }
}

typedef AppPickedFilesValidator = String? Function(List<AppPickedFile> files);

class AppFilePickerField extends StatefulWidget {
  const AppFilePickerField({
    super.key,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.mode = AppFilePickerMode.any,
    this.fileType = FileType.any,
    this.allowedExtensions,
    this.allowMultiple = false,
    this.maxFiles,
    this.maxFileSizeBytes,
    this.allowFileSystem = true,
    this.allowGallery = true,
    this.allowCamera = true,
    this.compressCameraImage = true,
    this.cameraCompressOptions = const ImageCompressOptions(),
    this.showChips = false,
    this.showPreviewThumbnails = true,
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
    this.cameraLabel,
    this.galleryLabel,
    this.filesLabel,
    this.clearText,
    this.semanticsLabel,
    this.hapticFeedback = true,
  }) : assert(
         controller == null || initialValue == null,
         'Provide either controller or initialValue, not both.',
       ),
       assert(
         maxFiles == null || maxFiles > 0,
         'maxFiles must be > 0 when provided.',
       );

  final AppFilePickerController? controller;
  final List<AppPickedFile>? initialValue;

  final ValueChanged<List<AppPickedFile>>? onChanged;

  final AppFilePickerMode mode;

  final FileType fileType;

  final List<String>? allowedExtensions;

  final bool allowMultiple;
  final int? maxFiles;
  final int? maxFileSizeBytes;

  final bool allowFileSystem;
  final bool allowGallery;
  final bool allowCamera;

  final bool compressCameraImage;
  final ImageCompressOptions cameraCompressOptions;

  final bool showChips;
  final bool showPreviewThumbnails;

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
  final AppPickedFilesValidator? validator;
  final FormFieldSetter<List<AppPickedFile>>? onSaved;

  final double borderRadius;
  final Color fillColor;

  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? disabledBorderColor;
  final Color? errorBorderColor;

  final EdgeInsets padding;

  final String? dialogTitle;
  final String? cameraLabel;
  final String? galleryLabel;
  final String? filesLabel;

  final String? clearText;

  final String? semanticsLabel;

  final bool hapticFeedback;

  @override
  State<AppFilePickerField> createState() => _AppFilePickerFieldState();
}

class _AppFilePickerFieldState extends State<AppFilePickerField> {
  final _fieldKey = GlobalKey<FormFieldState<List<AppPickedFile>>>();
  final _focusNode = FocusNode();

  AppFilePickerController? _controller;
  bool _listening = false;

  List<AppPickedFile> _value = const [];
  bool _busy = false;

  bool get _interactive => widget.enabled && !widget.readOnly && !_busy;

  @override
  void initState() {
    super.initState();
    _value = _normalize(
      widget.controller?.value ?? widget.initialValue ?? const [],
    );
    _bindController(widget.controller);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant AppFilePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      _unbindController();
      _bindController(widget.controller);

      setState(() => _value = _normalize(widget.controller?.value ?? _value));
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFormField());
    }

    if (oldWidget.initialValue != widget.initialValue &&
        widget.controller == null) {
      setState(() => _value = _normalize(widget.initialValue ?? const []));
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncFormField());
    }
  }

  @override
  void dispose() {
    _unbindController();
    _focusNode.dispose();
    super.dispose();
  }

  void _bindController(AppFilePickerController? controller) {
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

  List<AppPickedFile> _normalize(List<AppPickedFile> files) {
    final out = <AppPickedFile>[];
    for (final f in files) {
      if (!out.any((x) => x.path == f.path)) out.add(f);
    }

    if (!widget.allowMultiple && out.length > 1) {
      return [out.first];
    }

    final max = widget.maxFiles;
    if (max != null && out.length > max) {
      return out.take(max).toList();
    }

    return out;
  }

  bool _sameSelection(List<AppPickedFile> a, List<AppPickedFile> b) {
    if (a.length != b.length) return false;
    for (final x in a) {
      if (!b.any((y) => y.path == x.path)) return false;
    }
    return true;
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

  void _emit(List<AppPickedFile> next) {
    final normalized = _normalize(next);
    setState(() => _value = normalized);

    if (_controller != null) _controller!.value = normalized;
    _fieldKey.currentState?.didChange(normalized);
    widget.onChanged?.call(normalized);
  }

  void _clear() {
    if (!_interactive) return;
    if (widget.hapticFeedback) HapticFeedback.selectionClick();
    _emit(const []);
  }

  void _removeAt(int index) {
    if (!_interactive) return;
    final next = List<AppPickedFile>.from(_value)..removeAt(index);
    _emit(next);
  }

  Future<void> _openSourceChooser() async {
    if (!_interactive) return;
    _focusNode.requestFocus();
    if (widget.hapticFeedback) HapticFeedback.selectionClick();

    final options = <_SourceOption>[];
    if (widget.allowCamera && _cameraApplicable()) {
      options.add(
        _SourceOption(
          source: AppFileSource.camera,
          label: widget.cameraLabel ?? 'Camera',
          icon: Icons.photo_camera_rounded,
        ),
      );
    }
    if (widget.allowGallery && _galleryApplicable()) {
      options.add(
        _SourceOption(
          source: AppFileSource.gallery,
          label: widget.galleryLabel ?? 'Gallery',
          icon: Icons.photo_library_rounded,
        ),
      );
    }
    if (widget.allowFileSystem && _fileSystemApplicable()) {
      options.add(
        _SourceOption(
          source: AppFileSource.fileSystem,
          label: widget.filesLabel ?? 'Files',
          icon: Icons.attach_file_rounded,
        ),
      );
    }

    if (options.isEmpty) return;

    if (options.length == 1) {
      await _pickFrom(options.first.source);
      return;
    }

    final chosen = await showModalBottomSheet<AppFileSource>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.dialogTitle ?? 'Choose source',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...options.map((o) {
                return ListTile(
                  leading: Icon(o.icon),
                  title: Text(o.label),
                  onTap: () => Navigator.of(context).pop(o.source),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!mounted || chosen == null) return;
    await _pickFrom(chosen);
  }

  bool _cameraApplicable() {
    return widget.mode == AppFilePickerMode.imagesOnly ||
        widget.mode == AppFilePickerMode.media;
  }

  bool _galleryApplicable() {
    return widget.mode == AppFilePickerMode.imagesOnly ||
        widget.mode == AppFilePickerMode.videosOnly ||
        widget.mode == AppFilePickerMode.media;
  }

  bool _fileSystemApplicable() {
    return true;
  }

  Future<void> _pickFrom(AppFileSource source) async {
    if (!_interactive) return;

    setState(() => _busy = true);
    try {
      List<AppPickedFile> picked = const [];

      switch (source) {
        case AppFileSource.camera:
          picked = await _pickFromCamera();
          break;
        case AppFileSource.gallery:
          picked = await _pickFromGallery();
          break;
        case AppFileSource.fileSystem:
          picked = await _pickFromFileSystem();
          break;
      }

      if (!mounted) return;

      if (picked.isEmpty) return;

      final merged = widget.allowMultiple
          ? [..._value, ...picked]
          : [picked.first];

      final max = widget.maxFiles;
      final trimmed = (max != null && merged.length > max)
          ? merged.take(max).toList()
          : merged;

      _emit(_normalize(trimmed));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<List<AppPickedFile>> _pickFromFileSystem() {
    return AppFilePicker.pickFromFileSystem(
      context: context,
      mode: widget.mode,
      fileType: widget.fileType,
      allowMultiple: widget.allowMultiple,
      allowedExtensions: widget.allowedExtensions,
      maxFileSizeBytes: widget.maxFileSizeBytes,
    );
  }

  Future<List<AppPickedFile>> _pickFromGallery() {
    return AppFilePicker.pickFromGallery(
      context: context,
      mode: widget.mode,
      allowMultiple: widget.allowMultiple,
      maxFileSizeBytes: widget.maxFileSizeBytes,
    );
  }

  Future<List<AppPickedFile>> _pickFromCamera() {
    return AppFilePicker.pickFromCamera(
      context: context,
      compressCameraImage: widget.compressCameraImage,
      cameraCompressOptions: widget.cameraCompressOptions,
      maxFileSizeBytes: widget.maxFileSizeBytes,
    );
  }

  Widget _buildSelectedPreview(List<AppPickedFile> files) {
    if (files.isEmpty) {
      return Text(
        widget.hintText ?? '',
        style: const TextStyle(color: Colors.grey),
      );
    }

    if (widget.showChips) {
      return Wrap(
        spacing: 6,
        runSpacing: 6,
        children: List.generate(files.length, (i) {
          final f = files[i];
          return InputChip(
            avatar: (widget.showPreviewThumbnails && f.isImage)
                ? CircleAvatar(
                    backgroundImage: FileImage(f.file),
                    backgroundColor: Colors.transparent,
                  )
                : null,
            label: Text(f.name, overflow: TextOverflow.ellipsis),
            onDeleted: _interactive ? () => _removeAt(i) : null,
          );
        }),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(files.length, (i) {
        final f = files[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              if (widget.showPreviewThumbnails && f.isImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    f.file,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _fileIcon(),
                  ),
                )
              else
                _fileIcon(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _sizeLabel(f.sizeBytes),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              if (_interactive)
                IconButton(
                  onPressed: () => _removeAt(i),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Remove',
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _fileIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.insert_drive_file_rounded),
    );
  }

  String _sizeLabel(int bytes) {
    if (bytes <= 0) return '—';
    const kb = 1024.0;
    const mb = kb * 1024.0;
    const gb = mb * 1024.0;

    if (bytes >= gb) return '${(bytes / gb).toStringAsFixed(2)} GB';
    if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(2)} MB';
    return '${(bytes / kb).toStringAsFixed(1)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final canClear = widget.allowClear && _interactive && _value.isNotEmpty;

    final prefix =
        widget.leading ??
        (widget.leadingIcon != null ? Icon(widget.leadingIcon) : null);

    return FormField<List<AppPickedFile>>(
      key: _fieldKey,
      initialValue: _value,
      validator: (v) => widget.validator?.call(v ?? const []),
      onSaved: (v) => widget.onSaved?.call(v ?? _value),
      autovalidateMode: widget.autovalidateMode,
      enabled: widget.enabled,
      builder: (field) {
        final hasError =
            field.errorText != null && field.errorText!.trim().isNotEmpty;
        final borderColor = _resolveBorderColor(hasError: hasError);

        final footerText = hasError ? field.errorText : widget.helperText;
        final showFooter = footerText != null && footerText.trim().isNotEmpty;

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            if (canClear)
              IconButton(
                onPressed: _clear,
                icon: const Icon(Icons.close_rounded),
                tooltip: widget.clearText ?? 'Clear',
              ),
            IconButton(
              onPressed: _interactive ? _openSourceChooser : null,
              icon: const Icon(Icons.upload_file_rounded),
              tooltip: 'Pick file',
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
                  onTap: _interactive ? _openSourceChooser : null,
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
                          (widget.showChips && _value.isNotEmpty)
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
                              _buildSelectedPreview(_value),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconTheme(
                          data: IconThemeData(
                            color: widget.enabled ? null : Colors.grey,
                          ),
                          child: actions,
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

class _SourceOption {
  const _SourceOption({
    required this.source,
    required this.label,
    required this.icon,
  });

  final AppFileSource source;
  final String label;
  final IconData icon;
}
