import 'dart:convert';
import 'package:flutter/material.dart';

class PgImageWidget extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget? fallbackWidget;

  const PgImageWidget({
    Key? key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.fallbackWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildFallback();
    }

    try {
      final src = imageUrl.trim();
      final decodedSrc = Uri.decodeFull(src);
      
      if (decodedSrc.contains('data:image')) {
        final base64String = decodedSrc.substring(decodedSrc.indexOf('data:image')).split(',').last;
        
        String cleanBase64 = base64String;
        if (cleanBase64.contains('?')) {
          cleanBase64 = cleanBase64.split('?').first;
        }
        
        cleanBase64 = cleanBase64.replaceAll(' ', '+');
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'[\r\n]'), '');
        
        int padLength = cleanBase64.length % 4;
        if (padLength > 0) {
          cleanBase64 += '=' * (4 - padLength);
        }
        
        return Image.memory(
          base64Decode(cleanBase64),
          fit: fit,
          errorBuilder: (ctx, err, stack) => _buildFallback(),
        );
      } else if (src.startsWith('http')) {
        return Image.network(
          src, 
          fit: fit,
          errorBuilder: (ctx, err, stack) => _buildFallback(),
        );
      } else {
        String cleanBase64 = src.contains(',') ? src.split(',').last : src;
        if (cleanBase64.contains('?')) {
          cleanBase64 = cleanBase64.split('?').first;
        }
        cleanBase64 = cleanBase64.replaceAll(' ', '+');
        cleanBase64 = cleanBase64.replaceAll(RegExp(r'[\r\n]'), '');
        int padLength = cleanBase64.length % 4;
        if (padLength > 0) {
          cleanBase64 += '=' * (4 - padLength);
        }
        return Image.memory(
          base64Decode(cleanBase64),
          fit: fit,
          errorBuilder: (ctx, err, stack) => _buildFallback(),
        );
      }
    } catch (_) {
      return _buildFallback();
    }
  }

  Widget _buildFallback() {
    return fallbackWidget ?? const Icon(Icons.apartment_rounded, color: Colors.white, size: 28);
  }
}
