import 'package:alzeh/core/resources/barallel.dart';

class CheckBoxAndForgot extends StatefulWidget {
  const CheckBoxAndForgot({super.key, this.showForget = true, this.title});
  final bool? showForget;
  final Widget? title;

  @override
  State<CheckBoxAndForgot> createState() => _CheckBoxAndForgotState();
}

class _CheckBoxAndForgotState extends State<CheckBoxAndForgot> {
  bool rememberMe = false;
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
                onTap: () => setState(() => rememberMe = !rememberMe),
                child: Icon(
                  size: 25.r,
                  rememberMe == false
                      ? Icons.check_circle_outline
                      : Icons.check_circle_sharp,
                  color: rememberMe == false
                      ? Colors.grey
                      : AppColors.primaryColor,
                )),
            WidthSpace(8),
            widget.title ?? const Text('Remember me'),
          ],
        ),
        widget.showForget == true
            ? TextButton(
                onPressed: () {},
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: AppColors.primaryColor),
                ),
              )
            : SizedBox.shrink(),
      ],
    );
  }
}
