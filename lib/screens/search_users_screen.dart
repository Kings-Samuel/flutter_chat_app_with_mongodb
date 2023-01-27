import 'package:animated_snack_bar/animated_snack_bar.dart';
import 'package:chat_app/helpers/utils/get_user_initials.dart';
import 'package:chat_app/helpers/utils/navigator.dart';
import 'package:chat_app/helpers/widgets/custom_texts.dart';
import 'package:chat_app/helpers/widgets/loading_animation.dart';
import 'package:chat_app/helpers/widgets/snack_bar_helper.dart';
import 'package:chat_app/models/user.dart';
import 'package:chat_app/providers/chat_rooms_provider.dart';
import 'package:chat_app/screens/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({Key? key}) : super(key: key);

  @override
  SearchUsersScreenState createState() => SearchUsersScreenState();
}

class SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<User>? _users = [];
  bool _isLoading = false;
  bool _isError = false;
  ChatRoomsProvider provider = ChatRoomsProvider();

  @override
  void initState() {
    super.initState();
    provider = context.read<ChatRoomsProvider>();
  }

  Future<void> search() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    _users = await provider.searchUsers(_controller.text);

    setState(() {
      _isLoading = false;
    });

    if (_users == null) {
      setState(() {
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          keyboardType: TextInputType.text,
          autofocus: true,
          textInputAction: TextInputAction.search,
          validator: (value) {
            if (value!.isEmpty) {
              return 'Field cannot be empty';
            } else {
              return null;
            }
          },
          onEditingComplete: () async {
            _focusNode.unfocus();

            if (_controller.text.isEmpty) {
              snackBarHelper(context, message: 'Field cannot be empty', type: AnimatedSnackBarType.error);
            } else {
              await search();
            }
          },
          decoration: const InputDecoration(
            hintText: 'Search',
            border: InputBorder.none,
            focusedBorder: InputBorder.none,
            enabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: body(),
      ),
    );
  }

  Widget body() {
    if (_controller.text.isEmpty) {
      return Container();
    } else if (_isLoading) {
      return Center(
        child: loadingAnimation(),
      );
    } else if (_isError) {
      return Center(
        child: bodyText(text: provider.errorMessage),
      );
    } else if (_users!.isEmpty) {
      return Center(
        child: bodyText(text: 'No user found with matching display name'),
      );
    } else {
      return ListView.separated(
        itemCount: _users!.length,
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(
          height: 10,
        ),
        itemBuilder: (BuildContext context, int index) {
          User user = _users![index];

          return ListTile(
            onTap: () async {
              String? roomId = await provider.doesChatRoomExist(user.id!);

              if (mounted) pushReplacementNavigator(MessagesScreen(chatPartner: user, roomId: roomId), context);
            },
            leading: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: user.image == null ? user.listToColor() : null,
                  image: user.image == null
                      ? null
                      : DecorationImage(image: MemoryImage(user.image!.byteList), fit: BoxFit.fill)),
              child: Visibility(
                  visible: user.image == null,
                  child: Center(child: bodyText(text: getUserInitials(user.name!), bold: true, fontSize: 30))),
            ),
            title: bodyText(text: user.name!, bold: true),
            subtitle: bodyText(text: 'Last seen: ${user.lastSeen!.substring(0, 16)}', fontSize: 12),
          );
        },
      );
    }
  }
}
