// lib/features/home_nav/screens/home.dart - FIXED

import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/features/widgets/todays_doses_section.dart';

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
                child: Text(
                  'Next dose in 00 : 00 : 35',
                  style: AppStyles.kTextStyle14primary,
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