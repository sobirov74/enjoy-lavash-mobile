import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/core/api/api_client.dart';
import 'package:enjoy_lavash_mobile/core/data/repositories/product_repository.dart';
import 'package:enjoy_lavash_mobile/theme/theme_extensions.dart';

class QuantityField extends StatefulWidget {
  final String initialValue;
  final String productId;
  final String id;

  const QuantityField({
    super.key,
    required this.initialValue,
    required this.productId,
    required this.id,
  });

  @override
  State<QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<QuantityField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  String _oldValue = "";

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.initialValue);
    _oldValue = widget.initialValue;

    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _onFocusLost();
      }
    });
  }

  Future<void> _onFocusLost() async {
    final newValue = _controller.text.trim();

    if (newValue != _oldValue) {
      await OrderProductRepository(ApiClient()).updateProds(
        productId: widget.productId,
        deliveredUnits: newValue,
        id: widget.id,
      );

      _oldValue = newValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.numberWithOptions(
        // signed: true,
        decimal: true,
      ),
      onTapOutside: (_) {
        _focusNode.unfocus(); // close keyboard when tap outside
        _onFocusLost();
      },
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: context.colors.border), // Enabled state
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
