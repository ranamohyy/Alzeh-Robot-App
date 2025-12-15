import 'package:alzeh/core/resources/barallel.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return GestureDetector(
      onTap: () => closeKeyboard(context),
      child: Scaffold(
        body: ContainerStack(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              spacing: 16.h,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Log in Your Account',
                    textAlign: TextAlign.center,
                    style: AppStyles.kTextStyle16Black),

                AppFormField(
                  hintText: '| Enter Your mobile number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  keyboardType: TextInputType.phone,
                ),

                PasswordField(),

                CheckBoxAndForgot(),

                AppButton(
                  hintText: 'Log In',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeNavScreen(),
                      )),
                ),

                SizedBox(height: height * 0.1),

                Text(
                  'Or sign in with',
                  textAlign: TextAlign.center,
                  style: AppStyles.kTextStyle16Grey,
                ),

                SocialChoices(),

                Divider(
                  color: Colors.grey[300],
                  thickness: 1,
                ),
                // Sign Up Link
                NotHaveAccount(
                  text: 'Sign Up',
                  screen: SignUpScreen(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
