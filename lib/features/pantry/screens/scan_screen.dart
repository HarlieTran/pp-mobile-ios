import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../services/pantry_service.dart';
import '../providers/pantry_provider.dart';
import '../widgets/add_item_sheet.dart';

/// Feature: 3.5 Image Scan — Camera / Gallery
/// Wired to: getUploadUrl → uploadToS3 → parseImage → review
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isProcessing = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _processImage(XFile image) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Uploading image...';
    });

    try {
      final service = ref.read(pantryServiceProvider);
      final bytes = await image.readAsBytes();
      final contentType = 'image/${image.name.split('.').last}';

      // Step 1: Get presigned upload URL
      setState(() => _statusMessage = 'Preparing upload...');
      final uploadData =
          await service.getUploadUrl(image.name, contentType);
      final presignedUrl = uploadData['uploadUrl'] as String;
      final imageKey = uploadData['imageKey'] as String;

      // Step 2: Upload to S3
      setState(() => _statusMessage = 'Uploading image...');
      await service.uploadToS3(presignedUrl, bytes.toList(), contentType);

      // Step 3: Parse image with AI
      setState(() => _statusMessage = 'AI is detecting grocery items...');
      final parsedItems = await service.parseImage(imageKey);

      // Step 4: Navigate to review
      if (mounted) {
        await context.push('/pantry/scan/review', extra: parsedItems);
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _statusMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusMessage = null;
        });
        
        String errorMsg = e.toString();
        if (e is DioException && e.response != null) {
          errorMsg = 'Server Error: ${e.response?.statusCode} - ${e.response?.data}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Scan failed: $errorMsg'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _processImage(image);
    }
  }

  Future<void> _captureFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      await _processImage(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Center(
              child: _isProcessing
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 80,
                          width: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          _statusMessage ?? 'Processing...',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This may take a moment',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Pantry Magic',
                                style: GoogleFonts.outfit(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(LucideIcons.sparkles, color: AppColors.warning, size: 28),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan items to add them to your inventory instantly',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 64),
                          
                          // Pulse SCAN button
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 180 + (_pulseController.value * 40),
                                    height: 180 + (_pulseController.value * 40),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryLight.withValues(alpha: 0.3 * (1 - _pulseController.value)),
                                    ),
                                  ),
                                  Container(
                                    width: 160 + (_pulseController.value * 20),
                                    height: 160 + (_pulseController.value * 20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryLight.withValues(alpha: 0.5 * (1 - _pulseController.value)),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _captureFromCamera,
                                    child: Container(
                                      width: 160,
                                      height: 160,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.4),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(LucideIcons.camera, color: Colors.white, size: 48),
                                          const SizedBox(height: 8),
                                          Text(
                                            'SCAN',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 2,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const Spacer(),
                          
                          // Bottom buttons
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => AddItemSheet(
                                        onAdd: (payload) {
                                          ref.read(pantryProvider.notifier).addItem(payload);
                                        },
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(LucideIcons.edit2, size: 18, color: AppColors.textPrimary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Manual',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _pickFromGallery,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(LucideIcons.image, size: 18, color: AppColors.textPrimary),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Upload',
                                          style: GoogleFonts.outfit(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
