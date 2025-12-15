import 'package:alzeh/features/model/user_model.dart';

import '../../core/resources/barallel.dart';

class PersonData extends StatelessWidget {
  const PersonData({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    UserModel user = UserModel();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(user.name, style: AppStyles.kTextStyle18Primary),
        const SizedBox(height: 4),
        Text(
          user.email,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          user.phoneNumber,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }
}
