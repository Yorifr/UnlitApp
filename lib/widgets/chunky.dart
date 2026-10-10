// Duolingo tarzı "tok" arayüz parçaları.
//
// Sırrı basit: her butonun altında, kendi renginin koyusundan 4 piksellik
// bir "gölge" var. Basınca buton 4 piksel aşağı iner ve gölge kaybolur;
// gerçek bir tuşa basıyormuş gibi hissettirir.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Buton renk türleri.
enum ChunkyVariant {
  /// Yeşil: ana eylem ("DEVAM").
  primary,

  /// Beyaz, gri çerçeveli: ikincil eylem ("ŞİMDİLİK GEÇ").
  secondary,

  /// Mavi: erteleme / yardım.
  blue,

  /// Altın: ödül.
  gold,

  /// Kırmızı: sadece silme gibi tehlikeli işlemler.
  danger,
}

/// Basınca aşağı inen, tok hisli buton.
class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ChunkyVariant.primary,
    this.icon,
    this.expand = true,
    this.height = 52,
  });

  /// Buton yazısı. Duolingo gibi BÜYÜK HARFLE yazın (elle!
  /// toUpperCase() Türkçe "i"yi bozar).
  final String label;

  /// null ise buton gri ve basılamaz olur.
  final VoidCallback? onPressed;
  final ChunkyVariant variant;
  final IconData? icon;

  /// true: bulunduğu alanın tüm genişliğini kaplar.
  final bool expand;
  final double height;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  static const double _depth = 4; // Gölgenin kalınlığı (piksel)
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final enabled = widget.onPressed != null;

    // Türe göre renkler: (zemin, alt gölge, yazı, çerçeve)
    final (Color face, Color shadow, Color textColor, Color? border) = !enabled
        ? (c.disabled, c.disabled, c.disabledText, null)
        : switch (widget.variant) {
            ChunkyVariant.primary => (
              c.greenButton,
              c.greenShadow,
              Colors.white,
              null,
            ),
            ChunkyVariant.secondary => (
              c.surface,
              c.border,
              c.blueText,
              c.border,
            ),
            ChunkyVariant.blue => (
              c.blueShadow,
              const Color(0xFF0B5A85),
              Colors.white,
              null,
            ),
            ChunkyVariant.gold => (
              c.gold,
              c.goldShadow,
              const Color(0xFF5A3E00),
              null,
            ),
            ChunkyVariant.danger => (c.red, c.redShadow, Colors.white, null),
          };

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: textColor, size: 22),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontFamily: appFontFamily,
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact(); // Telefonda hafif titreşim
                widget.onPressed!();
              }
            : null,
        child: SizedBox(
          height: widget.height + _depth,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            // Basılıyken butonu aşağı it, gölgeyi kaldır.
            margin: EdgeInsets.only(
              top: _pressed ? _depth : 0,
              bottom: _pressed ? 0 : _depth,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: face,
              borderRadius: BorderRadius.circular(16),
              border: border == null
                  ? null
                  : Border.all(color: border, width: 2),
              boxShadow: _pressed
                  ? null
                  : [BoxShadow(color: shadow, offset: const Offset(0, _depth))],
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

/// Çerçeveli, alt kenarı kalın kart (Duolingo kartları gibi).
class ChunkyCard extends StatelessWidget {
  const ChunkyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Zemin rengi (boşsa normal yüzey rengi).
  final Color? color;

  /// Çerçeve rengi (boşsa gri).
  final Color? borderColor;

  /// Doluysa kart dokunulabilir olur.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final edge = borderColor ?? c.border;
    final radius = BorderRadius.circular(16);

    return Container(
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: radius,
        border: Border.all(color: edge, width: 2),
        // Alt kenardaki kalınlık: kartın "üç boyutlu" durması için
        boxShadow: [BoxShadow(color: edge, offset: const Offset(0, 3))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Kalın, yuvarlak, üstünde parlak bir şerit olan ilerleme çubuğu.
/// Değer değişince dolarak ilerler (animasyon).
class ChunkyProgressBar extends StatelessWidget {
  const ChunkyProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 16,
  });

  /// 0.0 (boş) ile 1.0 (dolu) arası.
  final double value;
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final fill = color ?? c.green;
    final radius = BorderRadius.circular(height / 2);

    return Container(
      height: height,
      decoration: BoxDecoration(color: c.disabled, borderRadius: radius),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: animated,
          child: animated <= 0
              ? const SizedBox.shrink()
              : Container(
                  decoration: BoxDecoration(color: fill, borderRadius: radius),
                  // Üstteki beyaz parlak şerit
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      height: height * 0.28,
                      margin: EdgeInsets.fromLTRB(
                        height * 0.5,
                        height * 0.18,
                        height * 0.5,
                        0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.35),
                        borderRadius: radius,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Üst çubuktaki küçük sayaç: ikon + sayı (ör. alev + 5).
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    this.tooltip,
  });

  final IconData icon;
  final String value;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final pill = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontFamily: appFontFamily,
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
    return tooltip == null ? pill : Tooltip(message: tooltip, child: pill);
  }
}
