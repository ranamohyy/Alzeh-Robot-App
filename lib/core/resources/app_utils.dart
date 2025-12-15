import 'dart:developer';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

import 'barallel.dart';

enum Status {
  taken,
  missed,
  notTaken,
}

Color bgColor(Status state) {
  return state == Status.taken
      ? AppColors.whiteColor
      : state == Status.missed
          ? AppColors.pinkyColor
          : AppColors.primaryColor;
}

Color textColor(Status state) {
  return state == Status.taken
      ? AppColors.primaryColor
      : state == Status.missed
          ? Colors.red
          : Colors.transparent;
}

void closeKeyboard(BuildContext context) => FocusScope.of(context).unfocus();

Widget getIcon(Status state) {
  return state == Status.taken
      ? const Icon(Icons.check, color: AppColors.primaryColor)
      : state == Status.missed
          ? const Icon(Icons.close, color: Colors.red)
          : SizedBox.shrink();
}

// Success Dialog
Future<void> showSuccessDialog(BuildContext context, String message) async {
  await showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppImage.assetsImage(AppStrings.done, 100.h, 100.w),
            HeightSpace(12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppStyles.kTextStyle18Primary,
            ),
          ],
        ),
      ),
    ),
  );
}

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
      );

      if (pickedImage == null) return null;

      return File(pickedImage.path);
    } catch (e) {
      log('Error picking image: $e');
      return null;
    }
  }
//handle if you want camera
}
