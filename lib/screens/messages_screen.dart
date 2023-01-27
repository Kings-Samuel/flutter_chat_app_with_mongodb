import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:badges/badges.dart' as b;
import 'package:better_player/better_player.dart';
import 'package:byte_converter/byte_converter.dart';
import 'package:chat_app/helpers/utils/color_palette.dart';
import 'package:chat_app/helpers/utils/file_selector.dart';
import 'package:chat_app/helpers/utils/get_video_info.dart';
import 'package:chat_app/helpers/utils/get_video_thumbnail.dart';
import 'package:chat_app/helpers/utils/navigator.dart';
import 'package:chat_app/helpers/widgets/loading_animation.dart';
import 'package:chat_app/helpers/widgets/snack_bar_helper.dart';
import 'package:chat_app/models/chat_room.dart';
import 'package:chat_app/models/message.dart';
import 'package:chat_app/providers/auth_provider.dart';
import 'package:chat_app/providers/messages_provider.dart';
import 'package:chat_app/screens/audio_player_screen.dart';
import 'package:chat_app/screens/other_user_profile_screen.dart';
import 'package:easy_image_viewer/easy_image_viewer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mongo_dart/mongo_dart.dart' as m;
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../helpers/utils/get_user_initials.dart';
import '../helpers/widgets/custom_texts.dart';
import '../models/user.dart';
import '../providers/chat_rooms_provider.dart';
import 'dart:math' as math;
import 'package:path/path.dart' as path;

final msBucket = PageStorageBucket(); // messages screen bucket

enum OnlineStatus { online, away, offline }

class MessagesScreen extends StatefulWidget {
  final User chatPartner;
  final String? roomId;
  const MessagesScreen({Key? key, required this.chatPartner, required this.roomId}) : super(key: key);

  @override
  MessagesScreenState createState() => MessagesScreenState();
}

class MessagesScreenState extends State<MessagesScreen> {
  User _chatPartner = User();
  String? _roomId;
  OnlineStatus _onlineStatus = OnlineStatus.offline;
  late Timer _getOnlineStatusTimer;
  MesagesProvider _mesagesProvider = MesagesProvider();
  AuthProvider _authProvider = AuthProvider();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  Future<void>? _future; // initial get messages future
  final TextEditingController _text = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  MessageType _type = MessageType.none;
  bool _isFileSelected = false;
  XFile? _image;
  XFile? _camVideo;
  File? _audio;
  File? _video;
  File? _doc;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _mesagesProvider = context.read<MesagesProvider>();
    _authProvider = context.read<AuthProvider>();
    _mesagesProvider.init();
    _chatPartner = widget.chatPartner;
    _roomId = widget.roomId;
    _getOnlineStatusTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _getLastSeen();
    });
    _text.addListener(() {
      if (_text.text.isNotEmpty && !_isFileSelected) {
        setState(() {
          _type = MessageType.text;
        });
      }
    });
    _future = _mesagesProvider.getMessages(_roomId ?? '');
    _itemPositionsListener.itemPositions.addListener(() async {
      var positions = _itemPositionsListener.itemPositions.value;

      for (ItemPosition position in positions) {
        // get index
        int index = position.index;

        // get the message at index
        Message message = _mesagesProvider.messages[index];

        bool isSeen = message.readReceipts!.contains(_authProvider.user.id);

        // update read receipt if not seen
        if (!isSeen) {
          await _mesagesProvider.updateReadReceipts(messageId: message.id!, userId: _authProvider.user.id!);
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _getOnlineStatusTimer.cancel();
    _mesagesProvider.stopStream();
  }

  Future<void> _getLastSeen() async {
    if (mounted) {
      await context.read<ChatRoomsProvider>().usersCollection.findOne(m.where.eq("id", _chatPartner.id)).then((value) {
        if (mounted) {
          setState(() {
            _chatPartner = User.fromJson(value!);
          });
        }
      });
    }

    DateTime now = DateTime.now().toLocal();
    DateTime lastSeenDateTime = DateTime.parse(_chatPartner.lastSeen!).toLocal();

    int nowEpoch = now.millisecondsSinceEpoch;
    int lastSeenEpoch = lastSeenDateTime.millisecondsSinceEpoch;

    int diff = nowEpoch - lastSeenEpoch;

    if (diff <= 60000) {
      _onlineStatus = OnlineStatus.online;
    } else if (diff > 60000 && diff <= 300000) {
      _onlineStatus = OnlineStatus.away;
    } else {
      _onlineStatus = OnlineStatus.offline;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(top: 15, left: 10, right: 15, bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: const BoxDecoration(
            color: Colors.white, border: Border(top: BorderSide(color: Palette.transPurple, width: 2.5))),
        child: Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Palette.transPurple, borderRadius: BorderRadius.circular(10)),
          child: Row(
            children: [
              // add file btn
              InkWell(
                onTap: () {
                  _scaffoldKey.currentState!.showBottomSheet((context) {
                    return Container(
                      height: 300,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Palette.transPurple, borderRadius: BorderRadius.circular(20)),
                      child: GridView.count(
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        crossAxisCount: 3,
                        children: <Widget>[
                          mediaOption(
                              name: 'Camera Image',
                              icon: Icons.camera,
                              color: Colors.blue,
                              onTap: () async {
                                _image = await pickImageFromCamera();
                                if (_image != null) {
                                  setState(() {
                                    _isFileSelected = true;
                                    _type = MessageType.image;
                                  });
                                }
                              }),
                          mediaOption(
                              name: 'Gallery Image',
                              icon: Icons.image,
                              color: Colors.pink[600]!,
                              onTap: () async {
                                _image = await pickImageFromGallery();
                                if (_image != null) {
                                  setState(() {
                                    _isFileSelected = true;
                                    _type = MessageType.image;
                                  });
                                }
                              }),
                          mediaOption(
                              name: 'Camera Video',
                              icon: Icons.video_camera_back,
                              color: Colors.purple,
                              onTap: () async {
                                _camVideo = await pickVideoFromCamera();
                                if (_camVideo != null) {
                                  setState(() {
                                    _isFileSelected = true;
                                    _type = MessageType.video;
                                  });
                                }
                              }),
                          mediaOption(
                              name: 'Gallery Video',
                              icon: Icons.video_file,
                              color: Colors.orange,
                              onTap: () async {
                                _video = await pickVideoFromGallery();
                                if (_video != null) {
                                  setState(() {
                                    _isFileSelected = true;
                                    _type = MessageType.video;
                                  });
                                }
                              }),
                          mediaOption(
                              name: 'Audio',
                              icon: CupertinoIcons.headphones,
                              color: Colors.green,
                              onTap: () async {
                                _audio = await pickAudio();
                                if (_audio != null) {
                                  setState(() {
                                    _isFileSelected = true;
                                    _type = MessageType.audio;
                                  });
                                }
                              }),
                          mediaOption(
                              name: 'Document',
                              icon: Icons.file_copy,
                              color: Colors.grey,
                              onTap: () async {
                                _doc = await picDocFile();
                                if (_doc != null) {
                                  setState(() {
                                    _isFileSelected = true;
                                    _type = MessageType.document;
                                  });
                                }
                              }),
                        ],
                      ),
                    );
                  }, backgroundColor: Colors.transparent);
                },
                child: Container(
                  height: 30,
                  width: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(
                    Icons.add,
                    color: Palette.purple,
                    size: 20,
                  ),
                ),
              ),
              // text field
              Expanded(
                child: TextFormField(
                  controller: _text,
                  focusNode: _focusNode,
                  textCapitalization: TextCapitalization.sentences,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Type your message here',
                    contentPadding: EdgeInsets.all(10),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
              // send btn
              InkWell(
                onTap: () async {
                  // send message if text field is not empty
                  if (_type != MessageType.none) {
                    _focusNode.unfocus();
                    setState(() {
                      _isLoading = true;
                    });

                    // create chat room if not exist
                    if (_roomId == null) {
                      // create participants
                      Participant participant1 = Participant(id: _authProvider.user.id, isActive: true);
                      Participant participant2 = Participant(id: _chatPartner.id, isActive: true);

                      // create chat room
                      ChatRoom chatRoom = ChatRoom(
                          admins: null,
                          id: null,
                          lastMessage: LastMessage(
                              type: _type,
                              message: '',
                              sender: '',
                              timeStamp: DateTime.now().toUtc().toString(),
                              noOfFiles: 0),
                          name: null,
                          owner: null,
                          participants: [participant1, participant2],
                          type: 'private',
                          dateCreated: DateTime.now().toUtc().toString());

                      final roomId = await context.read<ChatRoomsProvider>().createChatRoom(chatRoom);

                      if (roomId != null) {
                        _mesagesProvider.setRoomId(roomId);
                        setState(() {
                          _roomId = roomId;
                        });
                      }
                    }

                    if (_type == MessageType.text) {
                      Message message = Message(
                          id: '',
                          parentId: '',
                          roomId: _roomId,
                          dateTime: DateTime.now().toUtc().toString(),
                          sender: _authProvider.user,
                          readReceipts: [_authProvider.user.id!],
                          content: _text.text,
                          type: _type);

                      await send(message);
                    } else if (_type == MessageType.document) {
                      // // upload doc
                      // final res = _mesagesProvider.uploadFile(_doc!);
                      // // timer to check for upload status
                      // Timer.periodic(const Duration(seconds: 1), (timer) async {
                      //   UploadStatus status = _mesagesProvider.uploadStatus;
                      //   if (status == UploadStatus.done) {
                      //     timer.cancel();
                      //     // extract doc id
                      //     String? id = await res;
                      //     // create doc
                      //     DocumentMessage doc =
                      //         DocumentMessage(id: id, caption: _text.text, size: await getFileSize(_doc!));
                      //     // upload message
                      //     Message message = Message(
                      //         id: '',
                      //         parentId: '',
                      //         roomId: _roomId,
                      //         dateTime: DateTime.now().toUtc().toString(),
                      //         sender: _authProvider.user,
                      //         readReceipts: [_authProvider.user.id!],
                      //         content: doc,
                      //         type: _type);
                      //     await send(message);
                      //   }
                      // });

                      // convert file to bson binary
                      File file = _doc!;
                      Uint8List bytes = await file.readAsBytes();
                      m.BsonBinary bsonBinary = m.BsonBinary.from(bytes);
                      DocumentMessage doc = DocumentMessage(
                          caption: _text.text,
                          doc: bsonBinary,
                          sizeInMB: await getFileSize(file),
                          title: getFileName());

                      Message message = Message(
                          id: '',
                          parentId: '',
                          roomId: _roomId,
                          dateTime: DateTime.now().toUtc().toString(),
                          sender: _authProvider.user,
                          readReceipts: [_authProvider.user.id!],
                          content: doc,
                          type: _type);

                      int size = await getFileSize(file);

                      if (size > 16 && mounted) {
                        snackBarHelper(context,
                            message: 'Size should not be more than 16MB', type: AnimatedSnackBarType.error);
                        setState(() {
                          _isLoading = false;
                        });
                      } else {
                        await send(message);
                      }
                    } else if (_type == MessageType.audio) {
                      // convert file to bson binary
                      File file = _audio!;
                      Uint8List bytes = await file.readAsBytes();
                      m.BsonBinary bsonBinary = m.BsonBinary.from(bytes);
                      AudioMessage audio = AudioMessage(
                          caption: _text.text,
                          audio: bsonBinary,
                          sizeInMB: await getFileSize(file),
                          duration: '',
                          title: getFileName());

                      Message message = Message(
                          id: '',
                          parentId: '',
                          roomId: _roomId,
                          dateTime: DateTime.now().toUtc().toString(),
                          sender: _authProvider.user,
                          readReceipts: [_authProvider.user.id!],
                          content: audio,
                          type: _type);

                      int size = await getFileSize(file);

                      if (size > 16 && mounted) {
                        snackBarHelper(context,
                            message: 'Size should not be more than 16MB', type: AnimatedSnackBarType.error);
                        setState(() {
                          _isLoading = false;
                        });
                      } else {
                        await send(message);
                      }
                    } else if (_type == MessageType.image) {
                      // convert file to bson binary
                      File file = File(_image!.path);
                      Uint8List imageBytes = await file.readAsBytes();
                      m.BsonBinary imageBson = m.BsonBinary.from(imageBytes);
                      PictureMessage image = PictureMessage(caption: _text.text, image: imageBson);

                      Message message = Message(
                          id: '',
                          parentId: '',
                          roomId: _roomId,
                          dateTime: DateTime.now().toUtc().toString(),
                          sender: _authProvider.user,
                          readReceipts: [_authProvider.user.id!],
                          content: image,
                          type: _type);

                      int size = await getFileSize(file);

                      if (size > 16 && mounted) {
                        snackBarHelper(context,
                            message: 'Size should not be more than 16MB', type: AnimatedSnackBarType.error);
                        setState(() {
                          _isLoading = false;
                        });
                      } else {
                        await send(message);
                      }
                    } else if (_type == MessageType.video) {
                      // convert file to bson binary
                      File file = _video ?? File(_camVideo!.path);
                      Uint8List bytes = await file.readAsBytes();
                      m.BsonBinary bsonBinary = m.BsonBinary.from(bytes);

                      // get video thumbnail
                      Uint8List thumbnailBytes = await getVidfeoThumbnail(file.path);
                      m.BsonBinary thumbnailbinary = m.BsonBinary.from(thumbnailBytes);

                      VideoMessage video = VideoMessage(
                          caption: _text.text,
                          video: bsonBinary,
                          sizeInMB: await getFileSize(file),
                          duration: '',
                          thumbnail: thumbnailbinary);

                      Message message = Message(
                          id: '',
                          parentId: '',
                          roomId: _roomId,
                          dateTime: DateTime.now().toUtc().toString(),
                          sender: _authProvider.user,
                          readReceipts: [_authProvider.user.id!],
                          content: video,
                          type: _type);

                      int size = await getFileSize(file);

                      if (size > 16 && mounted) {
                        snackBarHelper(context,
                            message: 'Size should not be more than 16MB', type: AnimatedSnackBarType.error);
                        setState(() {
                          _isLoading = false;
                        });
                      } else {
                        await send(message);
                      }
                    } else {}
                  }
                },
                child: Container(
                    height: 40,
                    width: 40,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(left: 5, bottom: 5),
                    decoration: BoxDecoration(color: Palette.purple, borderRadius: BorderRadius.circular(10)),
                    child: _isLoading
                        ? loadingAnimation()
                        : Transform.rotate(
                            angle: -math.pi / 4.5,
                            child: const Icon(
                              Icons.send_outlined,
                              color: Colors.white,
                            ),
                          )),
              ),
            ],
          ),
        ),
      ),
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 50,
          automaticallyImplyLeading: !_isFileSelected,
          title: _isFileSelected
              ? Row(
                  children: [
                    IconButton(
                        onPressed: () {
                          setState(() {
                            _image = null;
                            _audio = null;
                            _camVideo = null;
                            _video = null;
                            _doc = null;
                            _isFileSelected = false;
                            _type = MessageType.none;
                            _text.clear();
                            _focusNode.unfocus();
                          });
                        },
                        icon: const Icon(
                          Icons.cancel,
                          size: 40,
                        )),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(child: Center(child: bodyText2(text: getFileName())))
                  ],
                )
              : InkWell(
                  onTap: () =>
                      pushNavigator(OtherUserProfileScreen(user: _chatPartner, onlineStatus: _onlineStatus), context),
                  child: Row(
                    children: [
                      // image
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: FittedBox(
                          child: Hero(
                            tag: _chatPartner.username!,
                            child: Container(
                              height: 100,
                              width: 100,
                              alignment: Alignment.center,
                              decoration: _chatPartner.image == null
                                  ? BoxDecoration(shape: BoxShape.circle, color: _chatPartner.listToColor())
                                  : BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                          image: MemoryImage(_chatPartner.image!.byteList), fit: BoxFit.fill)),
                              child: _chatPartner.image != null
                                  ? null
                                  : Center(
                                      child: headingText(
                                          text: getUserInitials(_chatPartner.name!),
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
                        height: 50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                                alignment: Alignment.centerLeft,
                                child: bodyText(text: _chatPartner.name!, fontSize: 16, bold: true)),
                            Row(
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
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
      body: _isFileSelected
          ? filePreviewPane()
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: FutureBuilder(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: loadingAnimation(),
                    );
                  } else if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(10),
                      child: Center(
                        child: bodyText(text: snapshot.error.toString()),
                      ),
                    );
                  } else {
                    return Selector<MesagesProvider, List<Message>>(
                      selector: (_, provider) {
                        final messages = provider.messages;
                        return messages;
                      },
                      builder: (context, messages, child) {
                        if (messages.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(10),
                            child: Center(
                              child: bodyText(
                                  text:
                                      'This is the beginning of your chat with ${_chatPartner.name}. Send them a message to start a coneversation',
                                  textAlign: TextAlign.center),
                            ),
                          );
                        } else {
                          return ScrollablePositionedList.builder(
                            itemCount: messages.length,
                            physics: const BouncingScrollPhysics(),
                            shrinkWrap: true,
                            itemBuilder: (BuildContext context, int index) {
                              Message message = messages[index];
                              bool isSenderMe = message.sender!.id == _authProvider.user.id;

                              int previousMessageIndex = index - 1;
                              User? previousMessageSender =
                                  previousMessageIndex < 0 ? null : messages[previousMessageIndex].sender;
                              bool isPreviousSenderMe = previousMessageSender?.id == _authProvider.user.id;

                              Message last = messages.last;

                              if (message.type == MessageType.text) {
                                String text = message.content as String;
                                bool isSeen = message.readReceipts!.contains(_chatPartner.id);

                                return Container(
                                  margin: EdgeInsets.only(bottom: last.id == message.id ? 120 : 0),
                                  child: Row(
                                    mainAxisAlignment: isSenderMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    children: [
                                      // avatar if message is from chat partner
                                      Visibility(
                                          visible: !isSenderMe && isPreviousSenderMe,
                                          child: Container(
                                            height: 45,
                                            width: 45,
                                            decoration: BoxDecoration(
                                                color: message.sender!.image != null
                                                    ? null
                                                    : message.sender!.listToColor(),
                                                shape: BoxShape.circle,
                                                image: message.sender!.image == null
                                                    ? null
                                                    : DecorationImage(
                                                        image: MemoryImage(message.sender!.image!.byteList))),
                                            child: Visibility(
                                                visible: message.sender!.image == null,
                                                child: bodyText(
                                                    text: getUserInitials(message.sender!.name!), fontSize: 25)),
                                          )),
                                      // chat bubble && time
                                      Column(
                                        crossAxisAlignment:
                                            isSenderMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          b.Badge(
                                            showBadge: isSenderMe,
                                            badgeStyle: const b.BadgeStyle(
                                                shape: b.BadgeShape.circle, badgeColor: Colors.white),
                                            position: b.BadgePosition.bottomEnd(end: 10),
                                            badgeContent: ImageIcon(
                                              const AssetImage('assets/double_check.png'),
                                              color: isSeen ? Palette.purple : Colors.black,
                                              size: 15,
                                            ),
                                            child: ChatBubble(
                                              clipper: isSenderMe
                                                  ? ChatBubbleClipper1(
                                                      type: BubbleType.sendBubble,
                                                      nipHeight: isPreviousSenderMe ? 0 : 10,
                                                      nipWidth: isPreviousSenderMe ? 0 : 15)
                                                  : ChatBubbleClipper1(
                                                      type: BubbleType.receiverBubble,
                                                      nipHeight: !isPreviousSenderMe ? 0 : 10,
                                                      nipWidth: !isPreviousSenderMe ? 0 : 15),
                                              alignment: isSenderMe ? Alignment.topRight : Alignment.topLeft,
                                              margin: const EdgeInsets.all(5),
                                              backGroundColor: isSenderMe ? Palette.green : Palette.transPurple,
                                              child: Container(
                                                  constraints: BoxConstraints(
                                                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                                                  ),
                                                  child: bodyText(
                                                      text: text,
                                                      fontSize: 13,
                                                      color: isSenderMe ? Colors.white : Colors.black)),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 10, left: 10, top: 5),
                                            child: bodyText(text: message.getTime(), fontSize: 11),
                                          )
                                        ],
                                      ),
                                      // avatar if message is from user
                                      Visibility(
                                          visible: isSenderMe && !isPreviousSenderMe,
                                          child: Container(
                                            height: 45,
                                            width: 45,
                                            decoration: BoxDecoration(
                                                color: message.sender!.image != null
                                                    ? null
                                                    : message.sender!.listToColor(),
                                                shape: BoxShape.circle,
                                                image: message.sender!.image == null
                                                    ? null
                                                    : DecorationImage(
                                                        image: MemoryImage(message.sender!.image!.byteList))),
                                            child: Visibility(
                                                visible: message.sender!.image == null,
                                                child: bodyText(
                                                    text: getUserInitials(message.sender!.name!), fontSize: 25)),
                                          )),
                                    ],
                                  ),
                                );
                              } else if (message.type == MessageType.image) {
                                PictureMessage pictureMessage = message.content as PictureMessage;
                                bool isSeen = message.readReceipts!.contains(_chatPartner.id);

                                return Container(
                                  margin: EdgeInsets.only(bottom: last.id == message.id ? 120 : 0),
                                  child: Row(
                                    mainAxisAlignment: isSenderMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    children: [
                                      // avatar if message is from chat partner
                                      Visibility(
                                          visible: !isSenderMe && isPreviousSenderMe,
                                          child: Container(
                                            height: 45,
                                            width: 45,
                                            decoration: BoxDecoration(
                                                color: message.sender!.image != null
                                                    ? null
                                                    : message.sender!.listToColor(),
                                                shape: BoxShape.circle,
                                                image: message.sender!.image == null
                                                    ? null
                                                    : DecorationImage(
                                                        image: MemoryImage(message.sender!.image!.byteList))),
                                            child: Visibility(
                                                visible: message.sender!.image == null,
                                                child: bodyText(
                                                    text: getUserInitials(message.sender!.name!), fontSize: 25)),
                                          )),
                                      // chat bubble && time
                                      Column(
                                        crossAxisAlignment:
                                            isSenderMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          b.Badge(
                                            showBadge: isSenderMe,
                                            badgeStyle: const b.BadgeStyle(
                                                shape: b.BadgeShape.circle, badgeColor: Colors.white),
                                            position: b.BadgePosition.bottomEnd(end: 10),
                                            badgeContent: ImageIcon(
                                              const AssetImage('assets/double_check.png'),
                                              color: isSeen ? Palette.purple : Colors.black,
                                              size: 15,
                                            ),
                                            child: ChatBubble(
                                              clipper: isSenderMe
                                                  ? ChatBubbleClipper1(
                                                      type: BubbleType.sendBubble,
                                                      nipHeight: isPreviousSenderMe ? 0 : 10,
                                                      nipWidth: isPreviousSenderMe ? 0 : 15)
                                                  : ChatBubbleClipper1(
                                                      type: BubbleType.receiverBubble,
                                                      nipHeight: !isPreviousSenderMe ? 0 : 10,
                                                      nipWidth: !isPreviousSenderMe ? 0 : 15),
                                              alignment: isSenderMe ? Alignment.topRight : Alignment.topLeft,
                                              margin: const EdgeInsets.all(5),
                                              backGroundColor: isSenderMe ? Palette.green : Palette.transPurple,
                                              child: Container(
                                                  constraints: BoxConstraints(
                                                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      InkWell(
                                                          onTap: () {
                                                            final imageProvider =
                                                                Image.memory(pictureMessage.image!.byteList).image;
                                                            showImageViewer(context, imageProvider,
                                                                onViewerDismissed: () {});
                                                          },
                                                          child: Image.memory(pictureMessage.image!.byteList)),
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: bodyText(
                                                            text: pictureMessage.caption!,
                                                            fontSize: 13,
                                                            color: isSenderMe ? Colors.white : Colors.black),
                                                      ),
                                                    ],
                                                  )),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 10, left: 10, top: 5),
                                            child: bodyText(text: message.getTime(), fontSize: 11),
                                          )
                                        ],
                                      ),
                                      // avatar if message is from user
                                      Visibility(
                                          visible: isSenderMe && !isPreviousSenderMe,
                                          child: Container(
                                            height: 45,
                                            width: 45,
                                            decoration: BoxDecoration(
                                                color: message.sender!.image != null
                                                    ? null
                                                    : message.sender!.listToColor(),
                                                shape: BoxShape.circle,
                                                image: message.sender!.image == null
                                                    ? null
                                                    : DecorationImage(
                                                        image: MemoryImage(message.sender!.image!.byteList))),
                                            child: Visibility(
                                                visible: message.sender!.image == null,
                                                child: bodyText(
                                                    text: getUserInitials(message.sender!.name!), fontSize: 25)),
                                          )),
                                    ],
                                  ),
                                );
                              } else if (message.type == MessageType.audio) {
                                AudioMessage audioMessage = message.content as AudioMessage;
                                bool isSeen = message.readReceipts!.contains(_chatPartner.id);

                                return Container(
                                  margin: EdgeInsets.only(bottom: last.id == message.id ? 120 : 0),
                                  child: Row(
                                    mainAxisAlignment: isSenderMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    children: [
                                      // avatar if message is from chat partner
                                      Visibility(
                                          visible: !isSenderMe && isPreviousSenderMe,
                                          child: Container(
                                            height: 45,
                                            width: 45,
                                            decoration: BoxDecoration(
                                                color: message.sender!.image != null
                                                    ? null
                                                    : message.sender!.listToColor(),
                                                shape: BoxShape.circle,
                                                image: message.sender!.image == null
                                                    ? null
                                                    : DecorationImage(
                                                        image: MemoryImage(message.sender!.image!.byteList))),
                                            child: Visibility(
                                                visible: message.sender!.image == null,
                                                child: bodyText(
                                                    text: getUserInitials(message.sender!.name!), fontSize: 25)),
                                          )),
                                      // chat bubble && time
                                      Column(
                                        crossAxisAlignment:
                                            isSenderMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                        children: [
                                          b.Badge(
                                            showBadge: isSenderMe,
                                            badgeStyle: const b.BadgeStyle(
                                                shape: b.BadgeShape.circle, badgeColor: Colors.white),
                                            position: b.BadgePosition.bottomEnd(end: 10),
                                            badgeContent: ImageIcon(
                                              const AssetImage('assets/double_check.png'),
                                              color: isSeen ? Palette.purple : Colors.black,
                                              size: 15,
                                            ),
                                            child: ChatBubble(
                                              clipper: isSenderMe
                                                  ? ChatBubbleClipper1(
                                                      type: BubbleType.sendBubble,
                                                      nipHeight: isPreviousSenderMe ? 0 : 10,
                                                      nipWidth: isPreviousSenderMe ? 0 : 15)
                                                  : ChatBubbleClipper1(
                                                      type: BubbleType.receiverBubble,
                                                      nipHeight: !isPreviousSenderMe ? 0 : 10,
                                                      nipWidth: !isPreviousSenderMe ? 0 : 15),
                                              alignment: isSenderMe ? Alignment.topRight : Alignment.topLeft,
                                              margin: const EdgeInsets.all(5),
                                              backGroundColor: isSenderMe ? Palette.green : Palette.transPurple,
                                              child: Container(
                                                  constraints: BoxConstraints(
                                                    maxWidth: MediaQuery.of(context).size.width * 0.6,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      bodyText(text: audioMessage.title!),
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      Container(
                                                        height: 100,
                                                        alignment: Alignment.center,
                                                        decoration: BoxDecoration(
                                                            borderRadius: BorderRadius.circular(12),
                                                            image: const DecorationImage(
                                                                image: AssetImage('assets/music.jpg'),
                                                                fit: BoxFit.cover)),
                                                        child: InkWell(
                                                            onTap: () => pushNavigator(
                                                                AudioPlayerScreen(
                                                                    audioBytes: audioMessage.audio!.byteList,
                                                                    title: audioMessage.title),
                                                                context),
                                                            child: const CircleAvatar(
                                                              radius: 35,
                                                              backgroundColor: Palette.purple,
                                                              child: Icon(
                                                                Icons.play_arrow,
                                                                color: Colors.white,
                                                                size: 50,
                                                              ),
                                                            )),
                                                      ),
                                                      const SizedBox(
                                                        height: 5,
                                                      ),
                                                      Align(
                                                        alignment: Alignment.centerLeft,
                                                        child: bodyText(
                                                            text: audioMessage.caption!,
                                                            fontSize: 13,
                                                            color: isSenderMe ? Colors.white : Colors.black),
                                                      ),
                                                    ],
                                                  )),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(right: 10, left: 10, top: 5),
                                            child: bodyText(text: message.getTime(), fontSize: 11),
                                          )
                                        ],
                                      ),
                                      // avatar if message is from user
                                      Visibility(
                                          visible: isSenderMe && !isPreviousSenderMe,
                                          child: Container(
                                            height: 45,
                                            width: 45,
                                            decoration: BoxDecoration(
                                                color: message.sender!.image != null
                                                    ? null
                                                    : message.sender!.listToColor(),
                                                shape: BoxShape.circle,
                                                image: message.sender!.image == null
                                                    ? null
                                                    : DecorationImage(
                                                        image: MemoryImage(message.sender!.image!.byteList))),
                                            child: Visibility(
                                                visible: message.sender!.image == null,
                                                child: bodyText(
                                                    text: getUserInitials(message.sender!.name!), fontSize: 25)),
                                          )),
                                    ],
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            },
                          );
                        }
                      },
                    );
                  }
                },
              ),
            ),
    );
  }

  Widget mediaOption({required String name, required IconData icon, required Color color, required Function onTap}) {
    return InkWell(
      onTap: () {
        _image = null;
        _video = null;
        _audio = null;
        _doc = null;
        onTap();
        popNavigator(context, rootNavigator: true);
      },
      child: SizedBox(
        width: 150,
        child: Column(
          children: [
            Container(
              height: 65,
              width: 65,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 40,
              ),
            ),
            Center(
              child: bodyText(text: name, fontSize: 12),
            )
          ],
        ),
      ),
    );
  }

  Widget filePreviewPane() {
    if (_type == MessageType.image) {
      File file = File(_image!.path);
      return Center(child: Image.file(file));
    } else if (_type == MessageType.video) {
      return Column(
        children: [
          // video player
          FutureBuilder(
            future: getVideoInfo(_camVideo != null ? _camVideo!.path : _video!.path),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              } else {
                int height = snapshot.data!.height!;
                int width = snapshot.data!.width!;

                double ratio = width / height;

                return Expanded(
                  child: BetterPlayer.file(
                    _camVideo != null ? _camVideo!.path : _video!.path,
                    betterPlayerConfiguration: BetterPlayerConfiguration(
                      aspectRatio: ratio,
                    ),
                  ),
                );
              }
            },
          ),
          const SizedBox(
            height: 10,
          ),
          // upload progress indicator
          Selector<MesagesProvider, UploadStatus>(
            selector: (_, mProvider) => mProvider.uploadStatus,
            builder: (context, status, child) {
              if (status == UploadStatus.done) {
                return Center(
                  child: bodyText(text: 'Upload complete'),
                );
              } else if (status == UploadStatus.started) {
                return Selector<MesagesProvider, int>(
                  selector: (_, mProvider) => mProvider.percentProgress,
                  builder: (context, percent, child) {
                    if (percent == 0) {
                      return Container();
                    } else {
                      return Center(
                        child: bodyText(text: 'Uploading $percent%'),
                      );
                    }
                  },
                );
              } else {
                return Container();
              }
            },
          )
        ],
      );
    } else if (_type == MessageType.audio) {
      return AudioPlayerScreen(audioFile: _audio);
    } else {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // video player
            InkWell(
              onTap: () => OpenFilex.open(_doc!.path),
              child: const Center(
                  child: Icon(
                CupertinoIcons.doc_circle,
                color: Palette.transPurple,
                size: 150,
                shadows: [Shadow(color: Colors.grey, offset: Offset(5, 5), blurRadius: 5)],
              )),
            ),
            const SizedBox(
              height: 10,
            ),
            Center(child: bodyText(text: getFileName(), textAlign: TextAlign.center)),
            const SizedBox(
              height: 10,
            ),
            // upload progress indicator
            Selector<MesagesProvider, UploadStatus>(
              selector: (_, mProvider) => mProvider.uploadStatus,
              builder: (context, status, child) {
                if (status == UploadStatus.done) {
                  return Center(
                    child: bodyText(text: 'Upload complete'),
                  );
                } else if (status == UploadStatus.started) {
                  return Selector<MesagesProvider, int>(
                    selector: (_, mProvider) => mProvider.percentProgress,
                    builder: (context, percent, child) {
                      if (percent == 0) {
                        return Container();
                      } else {
                        return Center(
                          child: bodyText(text: 'Uploading $percent%'),
                        );
                      }
                    },
                  );
                } else {
                  return Container();
                }
              },
            )
          ],
        ),
      );
    }
  }

  String getFileName() {
    if (_type == MessageType.image) {
      return _image!.name;
    } else if (_type == MessageType.audio) {
      return path.basename(_audio!.path);
    } else if (_type == MessageType.video && _camVideo != null) {
      return _camVideo!.name;
    } else if (_type == MessageType.video && _video != null) {
      return path.basename(_video!.path);
    } else if (_type == MessageType.document) {
      return path.basename(_doc!.path);
    } else {
      return '';
    }
  }

  Future<void> send(Message message) async {
    final success = await _mesagesProvider.sendMessage(message: message);

    if (!success && mounted) {
      snackBarHelper(context, message: _mesagesProvider.errorMessage, type: AnimatedSnackBarType.error);
    } else {
      // update last message
      LastMessage lastMessage = LastMessage(
          message: _text.text,
          sender: _authProvider.user.name,
          timeStamp: DateTime.now().toUtc().toString(),
          noOfFiles: _type == MessageType.text ? 0 : 1,
          type: _type);

      await context.read<ChatRoomsProvider>().updateLastMessage(_roomId!, lastMessage);
    }

    setState(() {
      _isLoading = false;
      _type = MessageType.none;
      _text.clear();
      _isFileSelected = false;
      _image = null;
      _doc = null;
      _audio = null;
      _video = null;
      _camVideo = null;
    });

    _mesagesProvider.setUploadStatusNone();

    if (_image != null) File(_image!.path).delete();
    if (_camVideo != null) File(_camVideo!.path).delete();
    if (_audio != null) _audio!.delete();
    if (_video != null) _video!.delete();
    if (_doc != null) _doc!.delete();
  }

  Future<int> getFileSize(File file) async {
    // get file size (in bytes)
    final bytes = await file.length();
    // convert to MB
    ByteConverter converter = ByteConverter(bytes.toDouble());
    final sizeInMB = converter.megaBytes;

    return sizeInMB.toInt();
  }
}
