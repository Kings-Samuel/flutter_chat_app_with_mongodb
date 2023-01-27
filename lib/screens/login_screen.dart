import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:chat_app/helpers/utils/color_palette.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/screens/signup_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../helpers/utils/navigator.dart';
import '../helpers/widgets/custom_btn.dart';
import '../helpers/widgets/custom_texts.dart';
import '../helpers/widgets/snack_bar_helper.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _hidePword = true;
  bool _isloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // heading texts
            Center(child: headingText(text: 'Demo Chat App')),
            const SizedBox(
              height: 10,
            ),
            Center(child: bodyText(text: 'Welcome back! Login to continue')),
            const SizedBox(
              height: 50,
            ),
            // email
            Align(
              alignment: Alignment.centerLeft,
              child: bodyText(text: 'Email'),
            ),
            SizedBox(
              width: double.infinity,
              child: TextFormField(
                  controller: _email,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'example@gmail.com',
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    prefixIcon: const Icon(
                      Icons.mail,
                      color: Colors.black,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.black54,
                        width: 1,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.black54,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val!.isEmpty) {
                      return 'Field cannot be empty';
                    } else if (!val.contains('@')) {
                      return 'Invalid email';
                    }
                    {
                      return null;
                    }
                  }),
            ),
            const SizedBox(
              height: 10,
            ),
            // password
            Align(
              alignment: Alignment.centerLeft,
              child: bodyText(text: 'Password'),
            ),
            SizedBox(
              width: double.infinity,
              child: TextFormField(
                  controller: _password,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  obscureText: _hidePword,
                  decoration: InputDecoration(
                    hintText: '*******',
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    prefixIcon: const Icon(
                      Icons.lock,
                      color: Colors.black,
                    ),
                    suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _hidePword = !_hidePword;
                          });
                        },
                        icon: Icon(
                          _hidePword ? Icons.visibility : Icons.visibility_off,
                          color: Colors.black54,
                        )),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.black54,
                        width: 1,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.black54,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.black),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 1,
                      ),
                    ),
                  ),
                  validator: (val) {
                    if (val!.isEmpty) {
                      return 'Field cannot be empty';
                    } else if (val.length < 8) {
                      return 'Password should be at least 8 characters';
                    }
                    {
                      return null;
                    }
                  }),
            ),
            const SizedBox(
              height: 20,
            ),
            // sign up text
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(color: Colors.black),
                children: <TextSpan>[
                  const TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: "Click here",
                    style: const TextStyle(color: Palette.green),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        pushNavigator(const SignupScreen(), context);
                      },
                  ),
                  const TextSpan(text: " to sign up now"),
                ],
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            // button
            SizedBox(
              width: double.infinity,
              child:
                  customButton(context, icon: Icons.login, text: 'Login', isLoading: _isloading, onPressed: () async {
                final authProvider = context.read<AuthProvider>();

                if (_formKey.currentState!.validate()) {
                  _emailFocus.unfocus();
                  _passwordFocus.unfocus();
                  setState(() {
                    _isloading = true;
                  });

                  final user = await authProvider.loginUser(email: _email.text, password: _password.text);

                  setState(() {
                    _isloading = false;
                  });

                  if (user && mounted) {
                    snackBarHelper(context, message: 'Login successful. Welcome', type: AnimatedSnackBarType.success);
                    pushAndRemoveNavigator(const HomeScreen(), context);
                  } else {
                    snackBarHelper(context, message: authProvider.errorMessage, type: AnimatedSnackBarType.error);
                  }
                }
              }),
            )
          ],
        ),
      ),
    ));
  }
}
