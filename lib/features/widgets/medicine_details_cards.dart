import '../../core/resources/barallel.dart';

class MedicineDetailsCards extends StatelessWidget {
  const MedicineDetailsCards({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: [
        MedicineCard(),
        MedicineCard(),
        MedicineCard(),
        MedicineCard(),
      ],
    );
  }
}
