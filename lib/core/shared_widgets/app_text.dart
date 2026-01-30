import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.height,
    this.letterSpacing,
  }) : span = null;

  const AppText.rich(
    this.span, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.color,
    this.fontSize,
    this.fontWeight,
    this.height,
    this.letterSpacing,
  }) : data = null;

  final String? data;
  final InlineSpan? span;

  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? height;
  final double? letterSpacing;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final merged = base.copyWith(
      color: color ?? base.color,
      fontSize: fontSize ?? base.fontSize,
      fontWeight: fontWeight ?? base.fontWeight,
      height: height ?? base.height,
      letterSpacing: letterSpacing ?? base.letterSpacing,
    );

    final poppinsStyle = GoogleFonts.poppins(textStyle: merged);

    if (span != null) {
      return Text.rich(
        span!,
        style: poppinsStyle,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
      );
    }

    return Text(
      data ?? '',
      style: poppinsStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}
