import 'package:flutter/material.dart';
import 'custom_texts.dart';

AppBar customAppBar(BuildContext context, {required String title, bool canPop = false, List<Widget> actions = const []}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: canPop ? IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 25)) : null,
    centerTitle: actions.isEmpty,
    toolbarHeight: 50,
    title: headingText(text: title),
    actions: actions,
  );
}