import 'package:alzeh/core/resources/barallel.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(appBarTiltle: 'Camera'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            spacing: 20.h,
            children: [
              PhotoCard('12:00 PM', '25/12/2025'),
              PhotoCard('01:00 PM', '24/12/2025'),
              PhotoCard('02:00 PM', '30/12/2025'),
            ],
          ),
        ),
      ),
    );
  }
}
