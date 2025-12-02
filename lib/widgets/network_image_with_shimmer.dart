import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class NetworkImageWithShimmer extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const NetworkImageWithShimmer({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<NetworkImageWithShimmer> createState() =>
      _NetworkImageWithShimmerState();
}

class _NetworkImageWithShimmerState extends State<NetworkImageWithShimmer> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Shimmer effect shown while loading
          if (_isLoading)
            Shimmer.fromColors(
              baseColor: Colors.grey[400]!,
              highlightColor: Colors.grey[200]!,
              child: Container(
                width: widget.width,
                height: widget.height,
                color: Colors.white,
              ),
            ),

          Image.network(
            widget.imageUrl,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                if (_isLoading && mounted) {
                  Future.microtask(() {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  });
                }
                return child;
              }
              return Container();
            },
            errorBuilder: (context, error, stackTrace) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
              return Container(
                width: widget.width,
                height: widget.height,
                color: Colors.grey[300],
                child: const Center(
                  child: Icon(Icons.error, color: Colors.red),
                ),
              );
            },
          ),

          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                strokeWidth: 3,
              ),
            ),
        ],
      ),
    );
  }
}
