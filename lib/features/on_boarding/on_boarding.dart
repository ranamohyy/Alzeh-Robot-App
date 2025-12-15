import 'package:alzeh/core/resources/barallel.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  @override
  void initState() {
     Future.delayed(const Duration(seconds: 3)).then((value) {
      if (mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final fullSize=MediaQuery.of(context).size;
    return AppImage.assetsImage(
      AppStrings.splash,
        fullSize.height,
        fullSize.width,
      BoxFit.cover
    );
  }
}
