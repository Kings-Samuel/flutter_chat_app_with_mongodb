import 'package:chat_app/providers/auth_provider.dart';
import 'package:chat_app/providers/messages_provider.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'providers/chat_rooms_provider.dart';

List<SingleChildWidget> providers = [
  ChangeNotifierProvider(create: (_) => AuthProvider()),
  ChangeNotifierProvider(create: (_) => ChatRoomsProvider()),
  ChangeNotifierProvider(create: (_) => MesagesProvider()),
];
