import 'dart:async';

import 'package:enjoy_lavash_mobile/core/error/failures.dart';
import 'package:enjoy_lavash_mobile/core/error/result.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/data/models/order_model.dart';
import 'package:enjoy_lavash_mobile/features/mobile_backend/presentation/mobile_backend_controller.dart';
import 'package:enjoy_lavash_mobile/l10n/app_localizations.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/theme/app_design_tokens.dart';
import 'package:enjoy_lavash_mobile/theme/app_motion.dart';
import 'package:enjoy_lavash_mobile/utils/format_cache.dart';
import 'package:enjoy_lavash_mobile/widgets/app_bottom_sheet_drag_handle.dart';
import 'package:enjoy_lavash_mobile/widgets/app_modal_bottom_sheet.dart';
import 'package:enjoy_lavash_mobile/widgets/confirm_dialog.dart';
import 'package:enjoy_lavash_mobile/widgets/utils/failure_message.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/order_review_limits.dart';
import '../data/review_photo_normalizer.dart';
import '../data/review_photo_picker.dart';
import 'review_photo_strip.dart';
import 'star_rating_input.dart';

Future<CustomerOrderModel?> showOrderReviewSheet(
  BuildContext context,
  CustomerOrderModel order,
) {
  final backend = context.read<MobileBackendController>();
  return showAppModalBottomSheet<CustomerOrderModel>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    // All dismissals go through the draft check; dragging a locked form is disabled.
    enableDrag: false,
    builder: (_) => ChangeNotifierProvider.value(
      value: backend,
      child: OrderReviewSheet(order: order),
    ),
  );
}

class OrderReviewSheet extends StatefulWidget {
  const OrderReviewSheet({
    super.key,
    required this.order,
    this.photoPicker = const DeviceReviewPhotoPicker(),
    this.photoNormalizer = const JpegReviewPhotoNormalizer(),
  });

  final CustomerOrderModel order;
  final ReviewPhotoPicker photoPicker;
  final ReviewPhotoNormalizer photoNormalizer;

  @override
  State<OrderReviewSheet> createState() => _OrderReviewSheetState();
}

class _OrderReviewSheetState extends State<OrderReviewSheet> {
  final _comment = TextEditingController();
  final _photos = <String>[];
  int _rating = 0;
  bool _isSaving = false;
  bool _isPreparingPhoto = false;
  bool _confirming = false;
  double? _progress;
  String? _errorText;

  bool get _locked => _isSaving || _isPreparingPhoto;
  bool get _hasDraft =>
      _rating > 0 || _comment.text.isNotEmpty || _photos.isNotEmpty;

  @override
  void dispose() {
    _comment.dispose();
    for (final path in _photos) {
      unawaited(widget.photoNormalizer.remove(path));
    }
    super.dispose();
  }

  Future<void> _requestClose() async {
    if (_locked || _confirming) return;
    if (_hasDraft) {
      _confirming = true;
      final t = L.of(context);
      var discard = false;
      await showConfirmDialog(
        context: context,
        title: t.reviewDiscardTitle,
        confirmText: t.reviewDiscard,
        cancelText: t.reviewKeep,
        onConfirm: () => discard = true,
        onCancel: () {},
      );
      _confirming = false;
      if (!mounted || !discard) return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _addPhoto() async {
    if (_locked || _photos.length >= maxOrderReviewPhotos) return;
    final source = await showAppModalBottomSheet<ReviewPhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppBottomSheetDragHandle(),
            ListTile(
              key: const ValueKey<String>('review-camera'),
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(L.of(context).reviewTakePhoto),
              onTap: () => Navigator.of(context).pop(ReviewPhotoSource.camera),
            ),
            ListTile(
              key: const ValueKey<String>('review-gallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(L.of(context).reviewChoosePhoto),
              onTap: () => Navigator.of(context).pop(ReviewPhotoSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;
    // Lock the form only once a source is chosen: cancelling the chooser
    // leaves it as it was.
    setState(() => _isPreparingPhoto = true);
    try {
      final path = await widget.photoPicker.pick(source);
      if (!mounted || path == null) return;
      final result = await widget.photoNormalizer.normalize(path);
      if (!mounted) {
        if (result case Success(:final data)) {
          await widget.photoNormalizer.remove(data);
        }
        return;
      }
      switch (result) {
        case Success(:final data):
          setState(() {
            _photos.add(data);
            _errorText = null;
          });
        case Error(:final failure):
          _showPhotoFailure(failure);
      }
    } catch (_) {
      if (mounted) _showPhotoFailure(const UnknownFailure());
    } finally {
      if (mounted) setState(() => _isPreparingPhoto = false);
    }
  }

  void _showPhotoFailure(Failure failure) {
    final t = L.of(context);
    setState(
      () => _errorText = failureMessage(
        t,
        failure,
        fallback: failure is PayloadTooLargeFailure
            ? t.reviewPhotoTooLarge
            : t.reviewPhotoFailed,
      ),
    );
  }

  Future<void> _send() async {
    if (_locked || _rating == 0 || !widget.order.canReview) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
      _progress = null;
    });
    final result = await context
        .read<MobileBackendController>()
        .submitOrderReview(
          orderId: widget.order.id,
          rating: _rating,
          comment: _comment.text.trim(),
          photoPaths: List.unmodifiable(_photos),
          onSendProgress: (sent, total) {
            if (mounted) {
              setState(
                () => _progress = total > 0
                    ? (sent / total).clamp(0.0, 1.0)
                    : null,
              );
            }
          },
        );
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        Navigator.of(context).pop(data);
      case Error(:final failure):
        setState(() {
          _isSaving = false;
          _errorText = failureMessage(L.of(context), failure);
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final id = widget.order.id.trim();
    final shortId = id.length > 8
        ? id.substring(id.length - 8).toUpperCase()
        : id;
    final createdAt = widget.order.createdAt;
    final date = createdAt == null
        ? ''
        : dateFormat(
            t.localeName,
            'yMMMd',
            DateFormat.yMMMd,
          ).format(createdAt.toLocal());
    final mutedStyle = TextStyle(color: AppDesignTokens.secondaryText(context));
    return PopScope<CustomerOrderModel>(
      canPop: !_locked && !_hasDraft,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestClose());
      },
      child: AnimatedPadding(
        duration: AppMotion.duration(context, AppMotion.state),
        curve: AppMotion.enter,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDesignTokens.gutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppBottomSheetDragHandle(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.reviewTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      key: const ValueKey<String>('review-close'),
                      tooltip: t.close,
                      onPressed: _locked
                          ? null
                          : () => unawaited(_requestClose()),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                Text(
                  '#$shortId${date.isEmpty ? '' : ' · $date'}',
                  style: mutedStyle,
                ),
                const SizedBox(height: AppDesignTokens.gutter),
                StarRatingInput(
                  rating: _rating,
                  onChanged: _locked
                      ? null
                      : (value) => setState(() => _rating = value),
                ),
                const SizedBox(height: AppDesignTokens.gutter),
                // The hint disappears once text is typed; the label keeps
                // the field named for screen readers.
                Semantics(
                  label: t.commentLabel,
                  textField: true,
                  child: TextField(
                    key: const ValueKey<String>('review-comment'),
                    controller: _comment,
                    enabled: !_locked,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: maxOrderReviewCommentLength,
                    textCapitalization: TextCapitalization.sentences,
                    cursorColor: BaseColors.primary,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: _rating == 0
                          ? t.reviewHint
                          : _rating <= 3
                          ? t.reviewHintLow
                          : t.reviewHintHigh,
                      prefixIcon: const Icon(
                        Icons.notes_rounded,
                        color: BaseColors.primary,
                      ),
                      filled: true,
                      fillColor: AppDesignTokens.inset(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDesignTokens.radiusInput,
                        ),
                        borderSide: BorderSide(
                          color: AppDesignTokens.controlBorder(context),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDesignTokens.gutter),
                ReviewPhotoStrip(
                  paths: _photos,
                  onAdd: _locked ? null : () => unawaited(_addPhoto()),
                  onRemove: _locked
                      ? null
                      : (path) {
                          setState(() => _photos.remove(path));
                          unawaited(widget.photoNormalizer.remove(path));
                        },
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: AppDesignTokens.gutter),
                  Text(
                    _errorText!,
                    key: const ValueKey<String>('review-error'),
                    style: TextStyle(
                      color: AppDesignTokens.dangerText(context),
                    ),
                  ),
                ],
                const SizedBox(height: AppDesignTokens.gutter),
                SizedBox(
                  width: double.infinity,
                  height: AppDesignTokens.primaryButtonHeight,
                  child: FilledButton(
                    key: const ValueKey<String>('review-send'),
                    onPressed:
                        _locked || _rating == 0 || !widget.order.canReview
                        ? null
                        : () => unawaited(_send()),
                    child: Text(_isSaving ? t.reviewSending : t.reviewSend),
                  ),
                ),
                if (_isSaving)
                  LinearProgressIndicator(
                    key: const ValueKey<String>('review-progress'),
                    value: AppMotion.reduced(context)
                        ? (_progress ?? 0)
                        : _progress,
                    color: BaseColors.primary,
                    semanticsLabel: t.reviewSending,
                  ),
                const SizedBox(height: AppDesignTokens.gutter / 2),
                Text(t.reviewFinalCaption, style: mutedStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
