import 'package:flutter/widgets.dart';

/// Physical-pixel width to decode a network image at so it fills
/// [constraints] sharply without decoding the full source resolution.
/// Returns null when the width is unbounded.
int? decodeWidthFor(BuildContext context, BoxConstraints constraints) {
  if (!constraints.hasBoundedWidth) return null;
  return (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context)).ceil();
}
