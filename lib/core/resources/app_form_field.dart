import 'barallel.dart';

class AppFormField extends StatelessWidget {
  const AppFormField(
      {super.key,
      required this.hintText,
      this.keyboardType,
      this.obscurePassword = false,
      this.suffixIcon,
      this.prefixIcon});
  final String hintText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;

  final bool? obscurePassword;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 45.h,
      child: TextField(
        obscureText: obscurePassword ?? false,
        keyboardType: keyboardType,
        cursorColor: AppColors.primaryColor,
        decoration: InputDecoration(
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14.sp),
          prefixIcon: prefixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primaryColor),
          ),
        ),
      ),
    );
  }
}
