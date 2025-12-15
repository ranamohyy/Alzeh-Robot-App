import 'package:alzeh/core/resources/barallel.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({super.key, this.hint});
  final String? hint;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return AppFormField(
      obscurePassword: obscurePassword,
      hintText: widget.hint ?? '| Enter Your Password',
      prefixIcon: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        child: AppImage.svgImage(
          AppStrings.lock,
          ColorFilter.mode(
            Colors.black,
            BlendMode.srcIn,
          ),
        ),
      ),
      suffixIcon: IconButton(
        icon: Icon(
          obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
        ),
        onPressed: () {
          setState(() {
            obscurePassword = !obscurePassword;
          });
        },
      ),
    );
  }
}
