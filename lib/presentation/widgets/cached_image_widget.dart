import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/theme/app_colors.dart';
import '../../core/utils/image_cache_manager.dart';
import '../../presentation/widgets/shimmer_loader.dart';

class CachedImageWidget extends StatefulWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CachedImageWidget({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<CachedImageWidget> createState() => _CachedImageWidgetState();
}

class _CachedImageWidgetState extends State<CachedImageWidget> {
  File? _cachedFile;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (kIsWeb) {
      // Web doesn't support File operations
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final cachedFile = await ImageCacheManager.instance.getCachedImage(widget.imagePath);
      if (mounted) {
        setState(() {
          _cachedFile = cachedFile;
          _isLoading = false;
          _hasError = cachedFile == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          ShimmerLoader(
            width: widget.width ?? double.infinity,
            height: widget.height ?? double.infinity,
            borderRadius: 8,
          );
    }

    if (_hasError || _cachedFile == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.surface1,
            child: Icon(
              Icons.broken_image_rounded,
              color: AppColors.textSecondary,
              size: (widget.width != null && widget.height != null)
                  ? (widget.width! < widget.height! ? widget.width! : widget.height!) * 0.5
                  : 48,
            ),
          );
    }

    if (kIsWeb) {
      return Image.network(
        widget.imagePath,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                color: AppColors.surface1,
                child: Icon(
                  Icons.broken_image_rounded,
                  color: AppColors.textSecondary,
                ),
              );
        },
      );
    }

    return Image.file(
      _cachedFile!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: AppColors.surface1,
              child: Icon(
                Icons.broken_image_rounded,
                color: AppColors.textSecondary,
              ),
            );
      },
    );
  }
}

