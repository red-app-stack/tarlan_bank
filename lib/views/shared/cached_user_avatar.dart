import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

/// Circular profile image backed by a disk cache: repeated loads (cold starts,
/// shell rebuilds, profile screen) reuse the cached file instead of hitting the
/// network again. Falls back to initials when there is no URL or it fails.
class CachedUserAvatar extends StatelessWidget {
  const CachedUserAvatar({
    super.key,
    required this.imageUrl,
    required this.initials,
    required this.backgroundColor,
    required this.foregroundColor,
    this.size = 44,
  });

  final String imageUrl;
  final String initials;
  final Color backgroundColor;
  final Color foregroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final url = imageUrl.trim();
    final placeholder = Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: foregroundColor,
          fontSize: size * 0.34,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: url.isEmpty
            ? placeholder
            : CachedNetworkImage(
                imageUrl: url,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * dpr).round(),
                fadeInDuration: const Duration(milliseconds: 180),
                placeholder: (_, _) => placeholder,
                errorWidget: (_, _, _) => placeholder,
              ),
      ),
    );
  }
}
