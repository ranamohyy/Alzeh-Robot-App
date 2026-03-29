// lib/features/widgets/photo_card.dart - FIXED

import 'dart:developer';
import 'package:alzeh/core/resources/barallel.dart';

class PhotoCard extends StatefulWidget {
  const PhotoCard(this.time, this.date, {super.key});
  final String time;
  final String date;

  @override
  State<PhotoCard> createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> {
  File? image;

  Future<void> takeImage() async {
    final pickedImage = await ImagePickerService().pickImageFromGallery();
    if (pickedImage == null) {
      log('No taken photo');
      return;
    }
    setState(() {
      image = pickedImage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: takeImage,
      child: Container(
        height: 150.h,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: image != null
                ? FileImage(image!)
                : NetworkImage(AppStrings.medicineNetwork),
            fit: BoxFit.cover,
          ),
        ),
        child: MedicineWithDate(
          time: widget.time,
          date: widget.date,
        ),
      ),
    );
  }
}