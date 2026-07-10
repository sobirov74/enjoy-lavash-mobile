part of 'package:enjoy_lavash_mobile/navigation/main_tabs.dart';

class _PromoCodeField extends StatelessWidget {
  const _PromoCodeField({
    required this.controller,
    required this.hasPromoCodeInput,
    required this.isLoading,
    required this.onApply,
  });

  final TextEditingController controller;
  final bool hasPromoCodeInput;
  final bool isLoading;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2522) : const Color(0xFFF8F4EF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A332D) : const Color(0xFFEDE2D7),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.local_offer_outlined, color: BaseColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.done,
              cursorColor: BaseColors.primary,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: t.enterPromoCode,
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF9E9790) : BaseColors.textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onSubmitted: (_) => onApply(),
            ),
          ),
          if (hasPromoCodeInput) ...[
            const SizedBox(width: 8),
            SizedBox(
              height: 38,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: BaseColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: isLoading ? null : onApply,
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: BaseColors.white,
                        ),
                      )
                    : TypographyText(
                        t.apply,
                        style: const TextStyle(
                          color: BaseColors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
