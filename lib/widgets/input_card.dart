import 'package:flutter/material.dart';
import 'package:enjoy_lavash_mobile/theme/app_colors.dart';
import 'package:enjoy_lavash_mobile/widgets/typography.dart';

class MainInput extends StatefulWidget {
  final String? label;
  final String? placeholder;
  final TextEditingController? controller;
  final bool secureTextEntry;
  final String? error;
  final bool multiline;
  final int? numberOfLines;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const MainInput({
    super.key,
    this.label,
    this.placeholder,
    this.controller,
    this.secureTextEntry = false,
    this.error,
    this.multiline = false,
    this.numberOfLines,
    this.padding,
    this.textStyle,
  });

  @override
  State<MainInput> createState() => _MainInputState();
}

class _MainInputState extends State<MainInput>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Color?> _borderColor;

  // bool _isFocused = false;
  late bool _showPassword;

  @override
  void initState() {
    super.initState();

    _showPassword = !widget.secureTextEntry;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _borderColor = ColorTween(
      begin: Colors.grey.shade400,
      end: BaseColors.primary,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: TypographyText(
              widget.label!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

        AnimatedBuilder(
          animation: _borderColor,
          builder: (context, child) {
            return Container(
              padding:
                  widget.padding ?? const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade900 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _borderColor.value!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Focus(
                      // onFocusChange: (focused) {
                      //   setState(() => _isFocused = focused);
                      //   focused ? _controller.forward() : _controller.reverse();
                      // },
                      child: TextField(
                        controller: widget.controller,
                        obscureText: widget.secureTextEntry && !_showPassword,
                        maxLines: widget.multiline ? widget.numberOfLines : 1,
                        textAlignVertical: TextAlignVertical.top,
                        style:
                            widget.textStyle ??
                            TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                        decoration: InputDecoration(
                          hintText: widget.placeholder,
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),

                  if (widget.secureTextEntry)
                    IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility : Icons.visibility_off,
                        color: BaseColors.primary,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                ],
              ),
            );
          },
        ),

        if (widget.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TypographyText(
              widget.error!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
