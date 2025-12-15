import 'package:alzeh/core/resources/barallel.dart';

class LabelField extends StatelessWidget {
  const LabelField(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.kTextStyle14primary,
        ),
        HeightSpace(8),
        AppFormField(hintText: value),
      ],
    );
  }
}
