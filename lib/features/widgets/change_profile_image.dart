import 'dart:io';
import 'package:alzeh/features/widgets/profile_image.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/resources/barallel.dart';

class ChangeProfileImage extends StatefulWidget {
  const ChangeProfileImage({
    super.key,
  });

  @override
  State<ChangeProfileImage> createState() => _ChangeProfileImageState();
}

class _ChangeProfileImageState extends State<ChangeProfileImage> {
  File? image;
  bool _isPickingImage = false;
  Future<void> changeImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {
      image = File(pickedImage!.path);
      _isPickingImage = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: _isPickingImage == true,
      child: GestureDetector(
        onTap: changeImage,
        child: Center(
          child: Stack(
            children: [
              ProfileImage(
                radius: 50.r,
                image: image != null
                    ? FileImage(image!)
                    : AssetImage(
                        AppStrings.person,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: AppImage.svgImage(AppStrings.edit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
