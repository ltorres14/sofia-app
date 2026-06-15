import 'package:flutter/material.dart';

class SafeAppImage extends StatelessWidget {
  const SafeAppImage.asset({
    super.key,
    required this.assetPath,
    required this.fallbackIcon,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.iconColor,
    this.iconSize = 28,
  }) : imageUrl = null;

  const SafeAppImage.network({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.iconColor,
    this.iconSize = 28,
  }) : assetPath = null;

  final String? assetPath;
  final String? imageUrl;
  final IconData fallbackIcon;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? iconColor;
  final double iconSize;

  bool get _hasValidNetworkUrl {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) return false;
    final uri = Uri.tryParse(value);
    return uri != null &&
        uri.hasScheme &&
        (uri.isScheme('http') || uri.isScheme('https'));
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = _hasValidNetworkUrl
        ? Image.network(
            imageUrl!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _fallback(context),
          )
        : assetPath != null
        ? Image.asset(
            assetPath!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _fallback(context),
          )
        : _fallback(context);

    if (borderRadius == null) {
      return imageWidget;
    }

    return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
  }

  Widget _fallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        size: iconSize,
        color: iconColor ?? colorScheme.onSurfaceVariant,
      ),
    );
  }
}
