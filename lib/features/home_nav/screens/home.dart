import 'package:alzeh/core/resources/barallel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            spacing: 16.h,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderHomeSection(),
              TodaysDosesSection(),
              CheckStateSection(),
              Center(
                child: Text('Next dose in 00 : 00 : 35',
                    style: AppStyles.kTextStyle14primary
                    //  TextStyle(color: Colors.grey, fontSize: 14),
                    ),
              ),
              QuickAccessSection()
            ],
          ),
        ),
      ),
    );
  }
}
