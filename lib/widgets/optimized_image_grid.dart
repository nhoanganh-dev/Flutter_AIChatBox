import 'package:chat_box/widgets/network_image_with_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OptimizedImageGrid extends StatelessWidget {
  const OptimizedImageGrid({super.key, required this.imageUrls});

  final List<String> imageUrls;
  @override
  Widget build(BuildContext context) {
    final int imageCount = imageUrls.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double maxWidth = constraints.maxWidth;

          if (imageCount == 1) {
            return _buildSingleImage(context, imageUrls[0], maxWidth);
          } else if (imageCount == 2) {
            return _buildTwoImagesRow(context, imageUrls, maxWidth);
          } else {
            return _buildThreeImagesGrid(
              context,
              imageUrls,
              maxWidth,
              imageCount > 3 ? imageCount - 3 : 0,
            );
          }
        },
      ),
    );
  }

  Widget _buildSingleImage(
    BuildContext context,
    String imageUrl,
    double maxWidth,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: GestureDetector(
        onTap: () => _showImagePreview(context, imageUrl),
        child: NetworkImageWithShimmer(
          imageUrl: imageUrl,
          width: maxWidth * 0.8,
          fit: BoxFit.cover,
          height: 250,
        ),
      ),
    );
  }

  Widget _buildTwoImagesRow(
    BuildContext context,
    List<String> imageUrls,
    double maxWidth,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () => _showImagePreview(context, imageUrls[0]),
            child: NetworkImageWithShimmer(
              imageUrl: imageUrls[0],
              width: maxWidth * 0.4,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () => _showImagePreview(context, imageUrls[1]),
            child: NetworkImageWithShimmer(
              imageUrl: imageUrls[1],
              width: maxWidth * 0.4,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThreeImagesGrid(
    BuildContext context,
    List<String> imageUrls,
    double maxWidth,
    int remainingCount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // First column - larger image
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GestureDetector(
            onTap: () => _showImagePreview(context, imageUrls[0]),
            child: NetworkImageWithShimmer(
              imageUrl: imageUrls[0],
              width: maxWidth * 0.4,
              height: 240,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Second column - two stacked images
        Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () => _showImagePreview(context, imageUrls[1]),
                child: NetworkImageWithShimmer(
                  imageUrl: imageUrls[1],
                  width: maxWidth * 0.4,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () {
                  if (remainingCount > 0) {
                    _showAllImages(context, imageUrls);
                  } else {
                    _showImagePreview(context, imageUrls[2]);
                  }
                },
                child: Stack(
                  children: [
                    NetworkImageWithShimmer(
                      imageUrl: imageUrls[2],
                      width: maxWidth * 0.4,
                      height: 120,
                      fit: BoxFit.cover,
                    ),

                    if (remainingCount > 0)
                      Container(
                        width: maxWidth * 0.4,
                        height: 120,
                        color: Colors.black.withOpacity(0.5),
                        child: Center(
                          child: Text(
                            '+$remainingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _shimmerLoadingBuilder(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress, {
    double? width,
    double? height,
  }) {
    if (loadingProgress == null) return child;

    final double? progress =
        loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                (loadingProgress.expectedTotalBytes ?? 1)
            : null;

    return Container(
      width: width,
      height: height,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(width: width, height: height, color: Colors.white),
          ),
          if (progress != null)
            Center(
              child: CircularProgressIndicator(
                value: progress,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }

  Widget _errorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      color: Colors.grey[300],
      child: const Center(child: Icon(Icons.error, color: Colors.red)),
    );
  }

  void _showImagePreview(BuildContext context, String imageUrl) {
    // Implement image preview functionality
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      return _shimmerLoadingBuilder(
                        context,
                        child,
                        loadingProgress,
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.6,
                      );
                    },
                    errorBuilder: _errorBuilder,
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showAllImages(BuildContext context, List<String> imageUrls) {
    // Implement gallery view to show all images
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'All Images (${imageUrls.length})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap:
                            () => _showImagePreview(context, imageUrls[index]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: NetworkImageWithShimmer(
                            imageUrl: imageUrls[index],
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
