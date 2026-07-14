import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sm_networking/configurations/frontend_configs.dart';
import 'package:sm_networking/presentation/elements/custom_text.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class VisitBottomSheet extends StatefulWidget {
  final Function(File?) onImageSelected;

  const VisitBottomSheet({
    super.key,
    required this.onImageSelected,
  });

  @override
  State<VisitBottomSheet> createState() => _VisitBottomSheetState();
}

class _VisitBottomSheetState extends State<VisitBottomSheet> {
  File? selectedImage;
  bool isProcessing = false;

  Future<void> pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      imageQuality: 70,
      source: source,
    );

    if (pickedFile != null) {
      setState(() {
        isProcessing = true;
      });

      // Compress the image
      final compressedFile = await compressImage(File(pickedFile.path));

      setState(() {
        selectedImage = compressedFile;
        isProcessing = false;
      });

      // Automatically proceed after image selection
      if (mounted) {
        Navigator.pop(context);
        widget.onImageSelected(compressedFile);
      }
    }
  }

  Future<File> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = path.join(
        dir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 50, // Adjust quality (0-100, lower = smaller file)
        minWidth: 1024, // Maximum width
        minHeight: 1024, // Maximum height
        format: CompressFormat.jpeg,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original if compression fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          CustomText(
            text: "Upload Visit Image",
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),

          const SizedBox(height: 10),

          Text(
            "Take a photo",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          // Show processing indicator
          if (isProcessing) ...[
            const Center(
              child: CircularProgressIndicator(),
            ),
            const SizedBox(height: 10),
            Text(
              "Processing image...",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Camera Option
          ListTile(
            enabled: !isProcessing,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FrontendConfigs.kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                CupertinoIcons.camera,
                color: FrontendConfigs.kPrimaryColor,
              ),
            ),
            title: const Text(
              'Camera',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text('Take a photo to continue'),
            onTap: isProcessing
                ? null
                : () async {
                    await pickImage(ImageSource.camera);
                  },
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

// Helper function to show the bottom sheet
Future<void> showVisitBottomSheet(
  BuildContext context,
  Function(File?) onImageSelected,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => VisitBottomSheet(
      onImageSelected: onImageSelected,
    ),
  );
}
