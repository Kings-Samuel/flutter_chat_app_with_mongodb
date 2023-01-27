import 'dart:async';
import 'package:chat_app/helpers/utils/sec_storage.dart';
import 'package:chat_app/models/chat_room.dart';
import 'package:chat_app/models/user.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:recase/recase.dart';
import '../consts.dart';
import '../helpers/utils/init_mogodb.dart';

class ChatRoomsProvider extends ChangeNotifier {
  String _errorMessage = '';
  final _collection = database.collection(Consts.chatRooms);
  final _usersCollection = database.collection(Consts.users);
  List<ChatRoom> _rooms = [];

  String get errorMessage => _errorMessage;
  DbCollection get usersCollection => _usersCollection;
  List<ChatRoom> get rooms => _rooms;

  ChatRoomsProvider() {
    init();
  }

  Future<void> init() async {
    String? userId = await secStorage.read(key: "userId");
    startStream(userId!);
  }

  // get chat rroms
  Future<void> startStream(String userId) async {
    Stream.periodic(const Duration(seconds: 60)).listen((event) async {
      Participant participant = Participant(id: userId, isActive: true);

      final res = await _collection.find({
        "participants": {
          "\$in": [participant.toJson()]
        }
      }).toList();
      final rooms = res.map((e) => ChatRoom.fromJson(e)).toList();

      rooms.sort((a, b) {
        String aEpoch = DateTime.parse(a.lastMessage!.timeStamp!).toLocal().millisecondsSinceEpoch.toString();
        String bEpoch = DateTime.parse(b.lastMessage!.timeStamp!).toLocal().millisecondsSinceEpoch.toString();
        return bEpoch.compareTo(aEpoch);
      });

      _rooms.clear();
      _rooms = rooms;
      notifyListeners();
    });
  }

  // get chat rroms
  Future<void> getChatRooms(String userId) async {
    Participant participant = Participant(id: userId, isActive: true);

    final res = await _collection.find({
      "participants": {
        "\$in": [participant.toJson()]
      }
    }).toList();
    final rooms = res.map((e) => ChatRoom.fromJson(e)).toList();

    rooms.sort((a, b) {
      String aEpoch = DateTime.parse(a.lastMessage!.timeStamp!).toLocal().millisecondsSinceEpoch.toString();
      String bEpoch = DateTime.parse(b.lastMessage!.timeStamp!).toLocal().millisecondsSinceEpoch.toString();
      return bEpoch.compareTo(aEpoch);
    });

    _rooms = rooms;
  }

  // get other user
  Future<User> getChatPartner({required String userId, required List<String> participants}) async {
    participants.removeWhere((element) => element == userId);
    String otherUserId = participants.first;

    final res = await _usersCollection.findOne({"id": otherUserId});

    User otherUser = User.fromJson(res!);

    return otherUser;
  }

  // create chat room
  Future<String?> createChatRoom(ChatRoom room) async {
    try {
      // create chat room doc
      final res = await _collection.insertOne(room.toJson());

      // extract id
      ObjectId oid = res.id;
      String id = oid.$oid;

      // update doc
      await _collection.updateOne({
        "_id": oid
      }, {
        "\$set": {"id": id}
      });

      room.id = id;

      List<ChatRoom> temp = [];

      for (var room in _rooms) {
        temp.add(room);
      }

      temp.add(room);

      _rooms.clear();
      _rooms = temp;

      notifyListeners();

      return id;
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return null;
    }
  }

  // update last message
  Future<bool> updateLastMessage(String roomId, LastMessage lastMessage) async {
    try {
      await _collection.updateOne({
        "id": roomId
      }, {
        "\$set": {"lastMessage": lastMessage.toJson()}
      });

      List<ChatRoom> temp = [];

      for (var room in _rooms) {
        temp.add(room);
      }

      _rooms.clear();

      ChatRoom room = temp.where((element) => element.id == roomId).first;
      room.lastMessage = lastMessage;

      temp.removeWhere((element) => element.id == roomId);

      temp.add(room);

      _rooms = temp;

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return false;
    }
  }

  // delete user from chat room
  Future<bool> removeUserFromRoom(String roomId, String userId, List<Participant> participants) async {
    try {
      // delete chat if only 1 user left in it, else just render user inactive
      List<bool> statuses = [];

      for (var participant in participants) {
        statuses.add(participant.isActive!);
      }

      if (statuses.first && statuses.last) {
        await _collection.updateOne(where.eq("id", roomId), modify.pull('participants', userId));

        List<ChatRoom> temp = _rooms;
        temp.removeWhere((element) => element.id == roomId);

        _rooms = temp;

        return true;
      } else {
        await _collection.deleteOne(where.eq('id', roomId));

        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return false;
    }
  }

  // search chats/users
  Future<List<User>?> searchUsers(String query) async {
    List<User> users = [];
    String? userId = await secStorage.read(key: 'userId');

    try {
      final res = await _usersCollection.find({
        "\$text": {"\$search": query}
      }).toList();

      users = res.map((e) => User.fromJson(e)).toList();

      users.removeWhere((user) => user.id == userId);

      return users;
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return null;
    }
  }

  // check if a chat room exists for user on search screen
  Future<String?> doesChatRoomExist(String userId) async {
    String? roomId;

    List<String> ids = [];

    for (var room in _rooms) {
      for (var participant in room.participants!) {
        ids.add(participant.id!);
        if (participant.id == userId) {
          roomId = room.id;
        }
      }
    }

    return roomId;
  }
}
