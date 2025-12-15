import 'package:alzeh/core/resources/barallel.dart';

class ManualChange extends StatelessWidget {
  const ManualChange({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => closeKeyboard(context),
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        appBar: CustomAppBar(appBarTiltle: "LCD"),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20.h,
              children: [
                Text("Type your message here"),
                TextField(
                  maxLines: 6,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                HeightSpace(MediaQuery.of(context).size.height * 0.5),
                AppButton(
                  hintText: 'Send',
                  onPressed: () =>
                      showSuccessDialog(context, "Message sent successfully"),
                )
              ]),
        ),
      ),
    );
  }
}
