import 'package:alzeh/core/resources/barallel.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});
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
              spacing: 20.h,
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
                PasswordField(
                  hint: "| Confirm Your Password",
                ),
                CheckBoxAndForgot(
                  showForget: false,
                  title: AgreeToConditions(),
                ),

                AppButton(
                  hintText: 'Sign In',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomeNavScreen(),
                      )),
                ),

                SizedBox(height: height * 0.025),

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
                  title: 'Already Have an account?',
                  text: 'LogIn',
                  screen: LoginScreen(),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
