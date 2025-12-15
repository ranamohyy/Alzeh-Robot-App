import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HeightSpace extends StatelessWidget {
  const HeightSpace(this.height, {super.key});
  final double height;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height.h,
    );
  }
}

class WidthSpace extends StatelessWidget {
  const WidthSpace(this.width, {super.key});
  final double width;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width.w,
    );
  }
}
