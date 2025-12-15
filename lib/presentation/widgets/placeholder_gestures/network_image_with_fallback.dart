import 'package:flutter/material.dart';

/// A reusable network image widget with loading and error states
/// Handles loading indicators and fallback icons gracefully
class NetworkImageWithFallback extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData fallbackIcon;
  final double fallbackIconSize;
  final Widget? loadingWidget;
  final Widget? errorWidget;

  const NetworkImageWithFallback({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 8,
    this.fallbackIcon = Icons.image,
    this.fallbackIconSize = 50,
    this.loadingWidget,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          
          if (loadingWidget != null) return loadingWidget!;
          
          return Container(
            width: width,
            height: height,
            color: theme.colorScheme.onSecondary,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                color: theme.colorScheme.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          if (errorWidget != null) return errorWidget!;
          
          return Container(
            width: width,
            height: height,
            color: theme.colorScheme.onSecondary,
            child: Icon(
              fallbackIcon,
              size: fallbackIconSize,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          );
        },
      ),
    );
  }
}
