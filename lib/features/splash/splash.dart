import '../../core/resources/barallel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState()  {
     Future.delayed(const Duration(seconds: 3)).then((value) {
      if (mounted) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => OnBoardingScreen()));
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: Padding(
        padding: EdgeInsets.all(16.r),
        child: Center(
            child: Stack(alignment: Alignment.center, children: [
          AppImage.assetsImage(
            AppStrings.ellipse,
          ),
          AppImage.svgImage(
            AppStrings.hands,
          ),
        ])),
      ),
    );
  }
}
