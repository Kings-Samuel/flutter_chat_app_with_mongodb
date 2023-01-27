import 'package:badges/badges.dart' as b;
import 'package:chat_app/helpers/widgets/custom_appbar.dart';
import 'package:chat_app/helpers/widgets/custom_texts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../helpers/utils/get_user_initials.dart';
import '../models/user.dart';
import 'messages_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final User user;
  final OnlineStatus onlineStatus;
  const OtherUserProfileScreen({Key? key, required this.user, required this.onlineStatus}) : super(key: key);

  @override
  OtherUserProfileScreenState createState() => OtherUserProfileScreenState();
}

class OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  User _user = User();
  OnlineStatus _onlineStatus = OnlineStatus.offline;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _onlineStatus = widget.onlineStatus;
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? image = _user.image?.byteList;

    return Scaffold(
      appBar: customAppBar(context, title: _user.name!, canPop: true),
      body: SingleChildScrollView(
          child: Column(
        children: [
          // avatar
          Hero(
            tag: _user.username!,
            child: b.Badge(
              badgeStyle: const b.BadgeStyle(
                  badgeColor: Colors.transparent, elevation: 0, padding: EdgeInsets.all(5), shape: b.BadgeShape.circle),
              position: b.BadgePosition.bottomEnd(end: -3),
              badgeContent: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 10,
                      width: 10,
                      margin: const EdgeInsets.only(right: 5),
                      decoration: BoxDecoration(
                          color: _onlineStatus == OnlineStatus.online
                              ? Colors.green
                              : _onlineStatus == OnlineStatus.away
                                  ? Colors.amber
                                  : Colors.grey,
                          shape: BoxShape.circle),
                    ),
                    bodyText(
                        text: _onlineStatus == OnlineStatus.online
                            ? 'Online'
                            : _onlineStatus == OnlineStatus.away
                                ? 'Away'
                                : 'Offline')
                  ],
                ),
              ),
              child: Container(
                height: MediaQuery.of(context).size.width,
                width: MediaQuery.of(context).size.width,
                decoration: image != null
                    ? BoxDecoration(image: DecorationImage(image: MemoryImage(image), fit: BoxFit.fill))
                    : BoxDecoration(color: _user.listToColor()),
                child: Visibility(
                    visible: _user.image == null,
                    child: bodyText(text: getUserInitials(_user.name!), bold: true, fontSize: 200)),
              ),
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
      )),
    );
  }

  Widget infoTile(String info, String infoName) {
    return ListTile(
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
}
