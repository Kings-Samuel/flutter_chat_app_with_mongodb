import 'package:flutter/material.dart';

pushNavigator(Widget screen, BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

popNavigator(BuildContext context, {bool? rootNavigator}) {
  Navigator.of(context, rootNavigator: rootNavigator ?? false).pop();
}

pushReplacementNavigator(Widget screen, BuildContext context) {
  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => screen));
}

pushAndRemoveNavigator(Widget screen, BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => screen), (route) => false);
}