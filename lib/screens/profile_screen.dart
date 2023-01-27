import 'dart:io';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:badges/badges.dart' as b;
import 'package:chat_app/helpers/utils/color_palette.dart';
import 'package:chat_app/helpers/utils/get_user_initials.dart';
import 'package:chat_app/helpers/utils/file_selector.dart';
import 'package:chat_app/helpers/utils/navigator.dart';
import 'package:chat_app/helpers/widgets/custom_appbar.dart';
import 'package:chat_app/helpers/widgets/custom_btn.dart';
import 'package:chat_app/helpers/widgets/custom_texts.dart';
import 'package:chat_app/helpers/widgets/snack_bar_helper.dart';
import 'package:chat_app/screens/login_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mongo_dart/mongo_dart.dart' as m;
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  AuthProvider _authProvider = AuthProvider();
  XFile? _xFile;
  bool _isUpdated = false;
  bool _isLoading = false;
  User _user = User();

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: !_isUpdated
          ? null
          : Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              child: customButton(context, icon: Icons.save, text: 'Save Changes', isLoading: _isLoading,
                  onPressed: () async {
                setState(() {
                  _isLoading = true;
                });

                // convert file to bson binary
                File file = File(_xFile!.path);
                Uint8List imageBytes = await file.readAsBytes();
                m.BsonBinary imageBson = m.BsonBinary.from(imageBytes);

                final success = await _authProvider.updateUserProfile(username: _user.username!, image: imageBson);

                if (success) {
                  setState(() {
                    _isLoading = false;
                    _isUpdated = false;
                    _xFile = null;
                    snackBarHelper(context, message: 'Profile updated');
                  });
                } else {
                  setState(() {
                    _isLoading = false;
                    snackBarHelper(context, message: _authProvider.errorMessage, type: AnimatedSnackBarType.error);
                  });
                }
              }),
            ),
      appBar: customAppBar(context, title: 'My Profile', canPop: true, actions: [
        InkWell(
          onTap: () async {
            showDialog(
                context: context,
                builder: (_) {
                  return AlertDialog(
                    title: headingText(text: 'Logout', fontSize: 16),
                    content: bodyText(text: 'You are about to logout. Continue?'),
                    actions: [
                      TextButton(
                          onPressed: () async {
                            await _authProvider
                                .logoutUser()
                                .then((value) => pushAndRemoveNavigator(const LoginScreen(), context));
                          },
                          child: bodyText(text: 'Yes')),
                      TextButton(
                          onPressed: () => popNavigator(context, rootNavigator: true), child: bodyText(text: 'No')),
                    ],
                  );
                });
          },
          child: const Icon(
            Icons.exit_to_app,
            color: Colors.black,
          ),
        ),
        const SizedBox(
          width: 12,
        )
      ]),
      body: SingleChildScrollView(
        child: Selector<AuthProvider, User>(
          selector: (_, provider) => provider.user,
          builder: (context, user, child) {
            _user = user;
            Uint8List? bytes = user.image?.byteList;

            return Column(
              children: [
                // avatar
                b.Badge(
                  badgeStyle: const b.BadgeStyle(
                      badgeColor: Palette.green, elevation: 0, padding: EdgeInsets.all(15), shape: b.BadgeShape.circle),
                  position: b.BadgePosition.bottomEnd(bottom: -15, end: 10),
                  badgeContent: InkWell(
                    onTap: () {
                      showBottomSheet(
                          context: context,
                          backgroundColor: Colors.grey,
                          builder: (_) {
                            return Container(
                              height: 150,
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                  borderRadius:
                                      BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))),
                              child: Column(
                                children: [
                                  Center(
                                      child: headingText(text: 'Select image from', fontSize: 16, color: Colors.white)),
                                  const Divider(color: Colors.white),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  selectImageOption(
                                      icon: Icons.camera,
                                      option: 'Camera',
                                      onTap: () async {
                                        await pickImageFromCamera().then((file) {
                                          setState(() {
                                            _xFile = file;
                                            _isUpdated = file != null;
                                          });
                                        });
                                      }),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                  selectImageOption(
                                      icon: Icons.photo_library,
                                      option: 'Gallery',
                                      onTap: () async {
                                        await pickImageFromGallery().then((file) {
                                          setState(() {
                                            _xFile = file;
                                            _isUpdated = file != null;
                                          });
                                        });
                                      })
                                ],
                              ),
                            );
                          });
                    },
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.width,
                    width: MediaQuery.of(context).size.width,
                    alignment: Alignment.center,
                    decoration: _xFile != null
                        ? BoxDecoration(image: DecorationImage(image: FileImage(File(_xFile!.path)), fit: BoxFit.fill))
                        : bytes != null
                            ? BoxDecoration(image: DecorationImage(image: MemoryImage(bytes), fit: BoxFit.fill))
                            : BoxDecoration(color: _user.listToColor()),
                    child: Visibility(
                        visible: user.image == null && _xFile == null,
                        child: bodyText(text: getUserInitials(user.name!), bold: true, fontSize: 200)),
                  ),
                ),
                // others
                const SizedBox(
                  height: 10,
                ),
                infoTile(_user.name!, 'Display Name'),
                infoTile(_user.username!, 'Username'),
                infoTile(_user.email!, 'Email Address'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget selectImageOption({required IconData icon, required String option, required Function onTap}) {
    return InkWell(
      onTap: () {
        popNavigator(context, rootNavigator: true);
        onTap();
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white,
          ),
          const SizedBox(
            width: 10,
          ),
          bodyText(text: option, color: Colors.white)
        ],
      ),
    );
  }

  Widget infoTile(String info, String infoName) {
    return ListTile(
        onTap: () {
          if (infoName == 'Display Name') {
            editDisplayNameDialog(displayName: info);
          }
        },
        title: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: bodyText(text: info),
        ),
        subtitle: Column(
          children: [
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(bottom: 5),
              child: bodyText(text: infoName, color: Colors.black54, fontSize: 14),
            ),
            const Divider(
              color: Colors.black,
            )
          ],
        ));
  }

  editDisplayNameDialog({required String displayName}) {
    final formKey = GlobalKey<FormState>();
    final TextEditingController name = TextEditingController(text: displayName);
    final FocusNode nameFocus = FocusNode();

    showDialog(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (BuildContext context, setState_) {
              return AlertDialog(
                title: Center(
                  child: headingText(text: 'Edit your display name'),
                ),
                contentPadding: const EdgeInsets.all(20),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Form(
                      key: formKey,
                      child: SizedBox(
                        width: 300,
                        child: TextFormField(
                            controller: name,
                            focusNode: nameFocus,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
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
                    )
                  ],
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        popNavigator(context, rootNavigator: true);
                      },
                      child: bodyText(text: 'Cancel')),
                  TextButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          setState(
                            () {
                              _isUpdated = true;
                              _user.name = name.text;
                            },
                          );
                          popNavigator(context, rootNavigator: true);
                        }
                      },
                      child: bodyText(text: 'Done')),
                ],
              );
            },
          );
        });
  }
}
