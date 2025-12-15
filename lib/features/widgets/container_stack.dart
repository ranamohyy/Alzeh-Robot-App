import 'package:alzeh/core/resources/app_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContainerStack extends StatelessWidget {
  const ContainerStack({
    super.key,
    required this.child,
  });
  final Widget child;
  // final Widget childImage;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: AppImage.assetsImage(AppStrings.medicine, 200.h, 200.w),
              ),
            ),
            Positioned(
              top: 250,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40.r),
                      topRight: Radius.circular(40.r),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    color: Colors.white,
                  ),
                  child: child),
            ),
          ],
        ),
      ),
    );
  }
}
