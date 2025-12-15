import 'package:alzeh/core/resources/barallel.dart';
import 'package:flutter_svg/svg.dart';

class AppStrings {
  static const String email = 'assets/icons/email.svg';
  static const String eys = 'assets/icons/eye.svg';
  static const String home = 'assets/icons/home.svg';
  static const String lock = 'assets/icons/lock.svg';
  static const String patient = 'assets/icons/patient.svg';
  static const String pen = 'assets/icons/pen.svg';
  static const String pill = 'assets/icons/pilld.svg';
  static const String pillOutline = 'assets/icons/pills_outline.svg';
  static const String quantinty = 'assets/icons/quantinty.svg';
  static const String settings = 'assets/icons/setting.svg';
  static const String listItems = 'assets/icons/list.svg';
  static const String shuffle = 'assets/icons/shuffle.svg';
  static const String notifications = 'assets/icons/notifcation.svg';
  static const String search = 'assets/icons/search.svg';
  static const String edit = 'assets/icons/edit.svg';
  static const String logOut = 'assets/icons/logout.svg';
  static const String share = 'assets/icons/share.svg';
  static const String about = 'assets/icons/aboutUs.svg';
  static const String fb = 'assets/icons/facebook.svg';
  static const String google = 'assets/icons/google.svg';
  static const String apple = 'assets/icons/apple.svg';
  static const String time = 'assets/icons/time.svg';
  static const String hands = 'assets/icons/hands.svg';

  //png images
  static const String medicine = 'assets/images/medicine.png';
  static const String person = 'assets/images/person.png';
  static const String splash = 'assets/images/splash-screen.png';
  static const String ellipse = 'assets/images/ellips.png';
  static const String done = 'assets/images/done.png';

  //network images
  static const String medicineNetwork =  'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?w=400';
}

class AppImage {
  static svgImage(String name, [ColorFilter? colorFilter, BoxFit? fit]) {
    return SvgPicture.asset(
      name,
      colorFilter: colorFilter,
      fit: fit ?? BoxFit.contain,
    );
  }

  static assetsImage(String name, [double? height, double? width,BoxFit? fit] ) {
    return Image.asset(
      name,
      height: height,
      alignment: AlignmentDirectional.center,
      width: width,
      fit:fit?? BoxFit.scaleDown,
    );
  }
}
