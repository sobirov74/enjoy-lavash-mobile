part of '../preset_packaging_visual.dart';

class _BrandSeal extends StatelessWidget {
  const _BrandSeal();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff393832), Color(0xff252522), Color(0xff2c2b26)],
      ),
      borderRadius: BorderRadius.circular(7),
      border: Border.all(color: const Color(0xffd7b570), width: .8),
      boxShadow: const [
        BoxShadow(
          color: Color(0x39000000),
          blurRadius: 1.3,
          offset: Offset(.3, .7),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.all(2),
      child: Image.asset(
        'assets/images/enjoy-logo.png',
        cacheWidth: 144,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        excludeFromSemantics: true,
        errorBuilder: (_, _, _) => const Center(
          child: Text(
            'Enjoy',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Color(0xffffd322),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    ),
  );
}
