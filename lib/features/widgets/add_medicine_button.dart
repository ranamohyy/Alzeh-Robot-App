import 'package:alzeh/core/resources/app_colors.dart';
import 'package:alzeh/core/resources/barallel.dart';
import 'package:flutter/material.dart';

class AddMedicineButton extends StatelessWidget {
  const AddMedicineButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100.h,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Center(
        child: Icon(
          Icons.add_circle_outline,
          size: 40.sp,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}
