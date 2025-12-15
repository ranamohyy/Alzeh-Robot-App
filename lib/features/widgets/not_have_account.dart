import '../../core/resources/barallel.dart';

class NotHaveAccount extends StatelessWidget {
  const NotHaveAccount({
    super.key,
    required this.text,
    required this.screen,
    this.title,
  });
  final String text;
  final String? title;

  final Widget screen;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title ?? "Don't have an account? ",
          style: AppStyles.kTextStyle16Grey,
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => screen,
              ),
            );
          },
          child: Text(text),
        ),
      ],
    );
  }
}
