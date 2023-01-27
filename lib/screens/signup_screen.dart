import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:chat_app/helpers/utils/color_generator.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../helpers/utils/color_palette.dart';
import '../helpers/utils/navigator.dart';
import '../helpers/widgets/custom_btn.dart';
import '../helpers/widgets/custom_texts.dart';
import '../helpers/widgets/snack_bar_helper.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  SignupScreenState createState() => SignupScreenState();
}

class SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _username = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _usernameFocus = FocusNode();
  bool _hidePword = true;
  bool _isloading = false;

  String _usernameAvailabityStatus = '';

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
            const SizedBox(
              height: 100,
            ),
            // heading texts
            Center(child: headingText(text: 'Demo Chat App')),
            const SizedBox(
              height: 10,
            ),
            Center(child: bodyText(text: 'Please, sign up to continue')),
            const SizedBox(
              height: 50,
            ),
            // name
            Align(
              alignment: Alignment.centerLeft,
              child: bodyText(text: 'Display Name'),
            ),
            SizedBox(
              width: double.infinity,
              child: TextFormField(
                  controller: _name,
                  focusNode: _nameFocus,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'John Doe',
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    prefixIcon: const Icon(
                      Icons.person,
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
                    } else if (val.length < 3) {
                      return 'Name should be more than 3 characters';
                    } else if (val.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_]'))) {
                      return 'Field cannot contain special caharacters';
                    }
                    {
                      return null;
                    }
                  }),
            ),
            const SizedBox(
              height: 10,
            ),
            // username
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: bodyText(text: 'Usename'),
                ),
                Visibility(
                  visible: _username.text.length >= 6,
                  child: Selector<AuthProvider, bool>(
                    selector: (_, provider) => provider.isUserNameExists,
                    builder: (context, isExists, child) {
                      if (!isExists) {
                        _usernameAvailabityStatus = 'Username is Available';
                        return FittedBox(
                          child: bodyText(text: _usernameAvailabityStatus, color: Palette.green),
                        );
                      } else {
                        _usernameAvailabityStatus = 'Username has been taken';
                        return FittedBox(
                          child: bodyText(text: _usernameAvailabityStatus, color: Colors.red),
                        );
                      }
                    },
                  ),
                )
              ],
            ),
            SizedBox(
              width: double.infinity,
              child: TextFormField(
                  controller: _username,
                  focusNode: _usernameFocus,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) async {
                    if (value.length > 1 && value.length < 6) {
                      setState(() {
                        _usernameAvailabityStatus = 'Username should at least 6 characters';
                      });
                    }
                    if (value.length >= 6) {
                      await context.read<AuthProvider>().checkUsernameExists(username: _username.text);
                      setState(() {});
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'johndoe4real (no special characters allowed)',
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                    prefixIcon: const Icon(
                      Icons.person,
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
                    } else if (val.length < 6) {
                      return 'Username should be at least 6 characters';
                    } else if (val.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_]'))) {
                      return 'Field cannot contain special caharacters';
                    } else {
                      return null;
                    }
                  }),
            ),
            const SizedBox(
              height: 10,
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
            // login text
            RichText(
              text: TextSpan(
                style: GoogleFonts.poppins(color: Colors.black),
                children: <TextSpan>[
                  const TextSpan(text: "Already have an account? "),
                  TextSpan(
                    text: "Click here",
                    style: const TextStyle(color: Palette.green),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        pushNavigator(const LoginScreen(), context);
                      },
                  ),
                  const TextSpan(text: " to login now"),
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
                  customButton(context, icon: Icons.login, text: 'Sign up', isLoading: _isloading, onPressed: () async {
                final authProvider = context.read<AuthProvider>();
                _emailFocus.unfocus();
                _passwordFocus.unfocus();
                _nameFocus.unfocus();
                _usernameFocus.unfocus();

                setState(() {
                  _isloading = true;
                });

                // check if email already exists
                bool isExists = await authProvider.checkEmailExists(email: _email.text);

                if (isExists && mounted) {
                  setState(() {
                    _isloading = false;
                  });
                  snackBarHelper(context, message: authProvider.errorMessage, type: AnimatedSnackBarType.error);
                } else {
                  if (_usernameAvailabityStatus == 'Username has been taken') {
                    setState(() {
                      _isloading = false;
                    });
                    snackBarHelper(context,
                        message: 'Username has been taken. Please use another one.', type: AnimatedSnackBarType.error);
                  } else {
                    setState(() {
                      _isloading = false;
                    });
                    if (_formKey.currentState!.validate()) {
                      User user = User(
                          name: _name.text,
                          username: _username.text,
                          email: _email.text,
                          image: null,
                          passwordHash: _password.text,
                          lastSeen: DateTime.now().toUtc().toString(),
                          color: []);

                      Color color = randomColor();
                      List<int> colorToList = user.colorToList(color);
                      user.color = colorToList;

                      // create user
                      final isCreated = await authProvider.registerUser(user);

                      if (isCreated && mounted) {
                        // login user
                        bool user = await authProvider.loginUser(email: _email.text, password: _password.text);

                        setState(() {
                          _isloading = false;
                        });

                        if (user && mounted) {
                          snackBarHelper(context,
                              message: 'Login successful. Welcome', type: AnimatedSnackBarType.success);
                          if (mounted) pushAndRemoveNavigator(const HomeScreen(), context);
                        } else {
                          snackBarHelper(context, message: authProvider.errorMessage, type: AnimatedSnackBarType.error);
                        }
                      } else {
                        setState(() {
                          _isloading = false;
                        });
                        snackBarHelper(context, message: authProvider.errorMessage, type: AnimatedSnackBarType.error);
                      }
                    }
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
