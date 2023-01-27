import 'dart:async';
import 'package:after_layout/after_layout.dart';
import 'package:chat_app/helpers/utils/color_palette.dart';
import 'package:chat_app/helpers/utils/init_mogodb.dart';
import 'package:chat_app/helpers/widgets/loading_animation.dart';
import 'package:chat_app/providers.dart';
import 'package:chat_app/providers/auth_provider.dart';
import 'package:chat_app/screens/home_screen.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ms_material_color/ms_material_color.dart';
import 'package:provider/provider.dart';
import 'helpers/utils/navigator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initMongoDb();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: providers,
      child: MaterialApp(
          title: 'Demo Chat App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            primarySwatch: MsMaterialColor(Palette.green.value),
            primaryColor: Colors.white,
            appBarTheme: const AppBarTheme(
              iconTheme: IconThemeData(color: Colors.black),
            ),
            visualDensity: VisualDensity.adaptivePlatformDensity,
            scaffoldBackgroundColor: Colors.white,
            scrollbarTheme: ScrollbarThemeData(
              thumbColor: MaterialStateProperty.all(Colors.grey),
            ),
            textTheme: GoogleFonts.poppinsTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          home: const CheckAuth()),
    );
  }
}

class CheckAuth extends StatefulWidget {
  const CheckAuth({super.key});

  @override
  State<CheckAuth> createState() => _CheckAuthState();
}

class _CheckAuthState extends State<CheckAuth> with AfterLayoutMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: loadingAnimation()),
    );
  }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) async {
    bool isLoggedIn = await context.read<AuthProvider>().getLoggedInUser();

    if (isLoggedIn && mounted) {
      pushAndRemoveNavigator(const HomeScreen(), context);
    } else {
      pushAndRemoveNavigator(const LoginScreen(), context);
    }
  }
}
