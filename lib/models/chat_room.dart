import 'package:chat_app/models/message.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:mongo_dart/mongo_dart.dart';

class ChatRoom {
  String? id, name, owner, uuid, dateCreated, type;
  int? unreadCount;
  List<String>? admins;
  List<Participant>? participants;
  LastMessage? lastMessage;

  ChatRoom(
      {this.admins, this.id, this.lastMessage, this.name, this.owner, this.participants, this.type, this.dateCreated})
      : uuid = const Uuid().v4();

  @override
  bool operator ==(covariant ChatRoom other) => uuid == other.uuid;

  @override
  int get hashCode => uuid.hashCode;

  ChatRoom.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    owner = json['owner'];
    type = json['type'];
    dateCreated = json['dateCreated'];
    if (json['participants'] != null) {
      List<dynamic> items = json['participants'];

      participants = items.map((e) => Participant.fromJson(e)).toList();
    }
    if (json['admins'] != null) admins = json['admins'].cast<String>();
    lastMessage = LastMessage.fromJson(json['lastMessage']);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    data['id'] = id;
    data['name'] = name;
    data['owner'] = owner;
    data['type'] = type;
    data['dateCreated'] = dateCreated;
    data['participants'] = participants!.map((e) => e.toJson()).toList();
    data['admins'] = admins;
    data['lastMessage'] = lastMessage!.toJson();

    return data;
  }
}

class LastMessage {
  String? message, sender, timeStamp;
  int? noOfFiles;
  MessageType? type;

  LastMessage({this.message, this.sender, this.timeStamp, this.noOfFiles, this.type});

  LastMessage.fromJson(Map<String, dynamic> json) {
    message = json['message'];
    sender = json['sender'];
    type = EnumToString.fromString(MessageType.values, json['type']);
    timeStamp = json['timeStamp'];
    noOfFiles = json['noOfFiles'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    data['message'] = message;
    data['sender'] = sender;
    data['timeStamp'] = timeStamp;
    data['type'] = EnumToString.convertToString(type);
    data['noOfFiles'] = noOfFiles;

    return data;
  }

  String dateTime() {
    DateTime today = DateTime.now().toLocal();
    DateTime messageDateTime = DateTime.parse(timeStamp!).toLocal();

    String todayDate = today.toString().split(' ')[0];
    String messageDate = messageDateTime.toString().split(' ')[0];

    String messageTime = messageDateTime.toString().split(' ')[1];
    String hour = messageTime.split(':')[0];
    String minute = messageTime.split(':')[1].split(':')[0];

    String time = "$hour:$minute";

    if (todayDate == messageDate) {
      return time;
    } else {
      String toReturn = messageDate.replaceAll("-", "/");
      return toReturn;
    }
  }
}

class Participant {
  String? id;
  bool? isActive;

  Participant({
    this.id,
    this.isActive,
  });

  Participant.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    isActive = json['isActive'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    data['id'] = id;
    data['isActive'] = isActive;

    return data;
  }
}
