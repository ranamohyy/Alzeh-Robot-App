import 'package:alzeh/core/resources/barallel.dart';

class MedicineDetailsScreen extends StatelessWidget {
  const MedicineDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        appBarTiltle: 'Medicine Details',
        showBackButton: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            spacing: 20.h,
            children: [MedicineDetailsCards(), AddMedicineButton()],
          ),
        ),
      ),
    );
  }
}
