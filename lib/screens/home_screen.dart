import 'package:chat_app/helpers/utils/color_palette.dart';
import 'package:chat_app/helpers/utils/get_user_initials.dart';
import 'package:chat_app/helpers/utils/navigator.dart';
import 'package:chat_app/helpers/widgets/custom_appbar.dart';
import 'package:chat_app/helpers/widgets/custom_texts.dart';
import 'package:chat_app/helpers/widgets/loading_animation.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/providers/chat_rooms_provider.dart';
import 'package:chat_app/screens/messages_screen.dart';
import 'package:chat_app/screens/profile_screen.dart';
import 'package:chat_app/screens/search_users_screen.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:recase/recase.dart';
import 'package:sticky_headers/sticky_headers.dart';
import '../models/chat_room.dart';
import '../providers/auth_provider.dart';

final bucket = PageStorageBucket();

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  ChatRoomsProvider _roomsProvider = ChatRoomsProvider();
  AuthProvider _authProvider = AuthProvider();
  Future<void>? _future;
  bool _showFAB = false;

  @override
  void initState() {
    super.initState();
    _roomsProvider = context.read<ChatRoomsProvider>();
    _authProvider = context.read<AuthProvider>();
    _future = _roomsProvider.getChatRooms(_authProvider.user.id!).then((value) {
      setState(() {
        _showFAB = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      floatingActionButton: !_showFAB
          ? null
          : FloatingActionButton(
              onPressed: () => pushNavigator(const SearchUsersScreen(), context),
              backgroundColor: Palette.green,
              child: const Icon(
                CupertinoIcons.chat_bubble_text,
                color: Colors.white,
                size: 35,
              ),
            ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: StickyHeader(
          header: customAppBar(context, title: 'Direct Messages', actions: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              margin: const EdgeInsets.only(right: 10),
              child: InkWell(
                  onTap: () => pushNavigator(const ProfileScreen(), context),
                  child: const Icon(
                    CupertinoIcons.person_circle,
                    size: 30,
                    color: Colors.black,
                  )),
            )
          ]),
          content: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: FutureBuilder(
              future: _future,
              // initialData: initialData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 2.5,
                      ),
                      Center(
                        child: loadingAnimation(),
                      ),
                    ],
                  );
                } else if (snapshot.hasError) {
                  return Column(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 2.5,
                      ),
                      Center(
                        child: bodyText(text: snapshot.error.toString()),
                      ),
                    ],
                  );
                } else {
                  return Selector<ChatRoomsProvider, List<ChatRoom>>(
                    selector: (_, provider) => provider.rooms,
                    builder: (context, rooms, child) {
                      if (rooms.isEmpty) {
                        return Column(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height / 2.5,
                            ),
                            Center(
                              child: bodyText(
                                  text:
                                      'You have no chats at the moment. Click on the chat button to chat with other users',
                                  textAlign: TextAlign.center),
                            ),
                          ],
                        );
                      } else {
                        return PageStorage(
                          bucket: bucket,
                          child: ListView.builder(
                            shrinkWrap: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: rooms.length,
                            itemBuilder: (BuildContext context, int index) {
                              ChatRoom room = rooms[index];
                              LastMessage lastMessage = room.lastMessage!;
                              List<String> participantsIds = [];

                              for (var participant in room.participants!) {
                                participantsIds.add(participant.id!);
                              }

                              return Slidable(
                                key: const ValueKey(0),
                                endActionPane: ActionPane(
                                  motion: const ScrollMotion(),
                                  // dismissible: DismissiblePane(onDismissed: () {}),
                                  children: [
                                    SlidableAction(
                                      // An action can be bigger than the others.
                                      flex: 2,
                                      onPressed: (_) => showDialog(
                                          context: context,
                                          builder: (_) {
                                            return AlertDialog(
                                              title: bodyText(text: 'Delete Chat?', bold: true),
                                              content: bodyText(text: 'Are you sure you want to delete this chat?'),
                                              actions: [
                                                TextButton(
                                                    onPressed: () => popNavigator(context, rootNavigator: true),
                                                    child: bodyText(text: 'Cancel')),
                                                TextButton(
                                                    onPressed: () async {
                                                      await _roomsProvider.removeUserFromRoom(
                                                          room.id!, _authProvider.user.id!, room.participants!);
                                                      if (mounted) popNavigator(context, rootNavigator: true);
                                                    },
                                                    child: bodyText(text: 'Continue'))
                                              ],
                                            );
                                          }),
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete_sweep,
                                      label: 'Delete',
                                    ),
                                  ],
                                ),
                                child: FutureBuilder(
                                  future: _roomsProvider.getChatPartner(
                                      userId: _authProvider.user.id!, participants: participantsIds),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Container();
                                    } else {
                                      User user = snapshot.data!;
                                      Uint8List? image = user.image?.byteList;

                                      return InkWell(
                                        onTap: () => pushNavigator(
                                            MessagesScreen(
                                              chatPartner: user,
                                              roomId: room.id!,
                                            ),
                                            context),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            children: [
                                              // image
                                              SizedBox(
                                                height: 60,
                                                width: 60,
                                                child: FittedBox(
                                                  child: Hero(
                                                    tag: user.username!,
                                                    child: Container(
                                                      height: 100,
                                                      width: 100,
                                                      alignment: Alignment.center,
                                                      decoration: image == null
                                                          ? BoxDecoration(
                                                              shape: BoxShape.circle, color: user.listToColor())
                                                          : BoxDecoration(
                                                              shape: BoxShape.circle,
                                                              image: DecorationImage(
                                                                  image: MemoryImage(image), fit: BoxFit.fill)),
                                                      child: image != null
                                                          ? null
                                                          : Center(
                                                              child: headingText(
                                                                  text: getUserInitials(user.name!),
                                                                  color: Colors.white,
                                                                  fontSize: 50)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 8,
                                              ),
                                              // user name and message
                                              SizedBox(
                                                height: 70,
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: bodyText(text: user.name!, fontSize: 16, bold: true)),
                                                    Center(
                                                      child: Row(
                                                        children: [
                                                          Visibility(
                                                            visible: lastMessage.noOfFiles! > 0 &&
                                                                lastMessage.type != MessageType.none,
                                                            child: Icon(
                                                              lastMessage.type == MessageType.image
                                                                  ? Icons.photo
                                                                  : lastMessage.type == MessageType.audio
                                                                      ? Icons.headphones
                                                                      : lastMessage.type == MessageType.video
                                                                          ? Icons.video_camera_back
                                                                          : CupertinoIcons.doc_fill,
                                                              color: Colors.black,
                                                              size: 25,
                                                            ),
                                                          ),
                                                          Visibility(
                                                            visible: lastMessage.noOfFiles! > 0,
                                                            child: const SizedBox(
                                                              width: 5,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              width: lastMessage.noOfFiles! > 0
                                                                  ? MediaQuery.of(context).size.width - 200
                                                                  : MediaQuery.of(context).size.width - 170,
                                                              child: bodyText2(
                                                                  text: lastMessage.message!.isEmpty
                                                                      ? EnumToString.convertToString(lastMessage.type)
                                                                          .sentenceCase
                                                                      : lastMessage.message!))
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // last message time and unread message count
                                              Container(
                                                height: 60,
                                                width: 60,
                                                alignment: Alignment.center,
                                                child: Column(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [FittedBox(child: bodyText(text: lastMessage.dateTime()))],
                                                ),
                                              )
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
