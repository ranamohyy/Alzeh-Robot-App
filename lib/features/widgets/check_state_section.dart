import 'package:alzeh/features/widgets/check_medicine_card.dart';
import 'package:flutter/material.dart';
import '../../core/resources/app_utils.dart';

class CheckStateSection extends StatelessWidget {
  const CheckStateSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        CheckMedicineCard(
          status: Status.taken,
        ),
        CheckMedicineCard(
          status: Status.taken,
        ),
        CheckMedicineCard(
          status: Status.notTaken,
        ),
        CheckMedicineCard(
          status: Status.missed,
        ),
      ],
    );
  }
}
