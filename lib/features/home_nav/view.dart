import 'package:alzeh/features/home_nav/screens/medication_details.dart';
import 'package:alzeh/features/widgets/custom_nav_bar.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';

import '../../core/resources/barallel.dart';

class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({super.key});

  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  int currentIndex = 1;
  List<Widget> screens = [
    PatiendDetails(),
    HomeScreen(),
    MedicineDetailsScreen(),
    ProfileScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      bottomNavigationBar: CustomNavBar(
        currentIndex: currentIndex,
        onTap: (value) => setState(() => currentIndex = value),
      ),
      body: screens[currentIndex],
    );
  }
}
