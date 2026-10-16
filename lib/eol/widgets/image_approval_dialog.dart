import 'package:flutter/material.dart';
import '../services/eol_catalog_service.dart';
import '../theme/eol_theme.dart';
import 'gloved_button.dart';

class ImageApprovalDialog extends StatefulWidget {
  final String brandId;
  final String currentImage;
  final String modelName;
  final String colourName;
  final ValueChanged<String> onImageApproved;

  const ImageApprovalDialog({
    super.key,
    required this.brandId,
    required this.currentImage,
    required this.modelName,
    required this.colourName,
    required this.onImageApproved,
  });

  @override
  State<ImageApprovalDialog> createState() => _ImageApprovalDialogState();
}

class _ImageApprovalDialogState extends State<ImageApprovalDialog> {
  late String _selectedImage;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.currentImage;
  }

  @override
  Widget build(BuildContext context) {
    final availableImages = EolCatalogService.getAuthorizedImagesForBrand(widget.brandId);

    return Dialog(
      backgroundColor: EolTheme.surfaceCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(EolTheme.borderRadius),
        side: const BorderSide(color: EolTheme.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: EolTheme.powerpedalBlueLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.image_search_rounded,
                    color: EolTheme.powerpedalBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visual Vehicle Inspection',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: EolTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Verify paint finish matches ${widget.modelName} (${widget.colourName})',
                        style: const TextStyle(
                          fontSize: 12,
                          color: EolTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Large Hero Image Preview
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: EolTheme.surfaceSubtle,
                borderRadius: BorderRadius.circular(EolTheme.borderRadius),
                border: Border.all(color: EolTheme.borderSubtle),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Image.asset(
                    _selectedImage,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.pedal_bike_rounded,
                      size: 64,
                      color: EolTheme.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Gallery of Brand Options
            const Text(
              'Brand Authorized Image Catalog:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: EolTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final img = availableImages[index];
                  final isSelected = img == _selectedImage;

                  return InkWell(
                    onTap: () => setState(() => _selectedImage = img),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: EolTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? EolTheme.powerpedalBlue
                              : EolTheme.borderSubtle,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: Image.asset(img, fit: BoxFit.contain),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: GlovedButton(
                    label: 'Cancel',
                    isSecondary: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: GlovedButton(
                    label: 'Approve Image',
                    icon: Icons.check_circle_rounded,
                    backgroundColor: EolTheme.statusSuccess,
                    onPressed: () {
                      widget.onImageApproved(_selectedImage);
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
