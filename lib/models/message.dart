import 'package:chat_app/models/user.dart';
import 'package:enum_to_string/enum_to_string.dart';
import 'package:mongo_dart/mongo_dart.dart';

enum MessageType { text, image, audio, video, document, none }

class Message {
  String? id, parentId, dateTime, roomId;
  User? sender;
  List<String>? readReceipts;
  dynamic content;
  MessageType? type;

  Message(
      {required this.id,
      required this.parentId,
      required this.roomId,
      required this.dateTime,
      required this.sender,
      required this.readReceipts,
      required this.content,
      required this.type});

  Message.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    parentId = json['parentId'];
    roomId = json['roomId'];
    dateTime = json['dateTime'];
    readReceipts = json['readReceipts'].cast<String>();
    sender = User.fromJson(json['sender']);
    type = EnumToString.fromString(MessageType.values, json['type']);
    if (type == MessageType.text) {
      content = json['content'].toString();
    } else if (type == MessageType.audio) {
      content = AudioMessage.fromJson(json['content']);
    } else if (type == MessageType.image) {
      content = PictureMessage.fromJson(json['content']);
    } else if (type == MessageType.video) {
      content = VideoMessage.fromJson(json['content']);
    } else {
      content = DocumentMessage.fromJson(json['content']);
    }
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    data['id'] = id;
    data['parentId'] = parentId;
    data['roomId'] = roomId;
    data['dateTime'] = dateTime;
    data['readReceipts'] = readReceipts;
    data['type'] = EnumToString.convertToString(type);
    data['sender'] = sender!.toJson();
    if (type == MessageType.text) {
      String text = content as String;
      data['content'] = text;
    } else if (type == MessageType.image) {
      PictureMessage image = content as PictureMessage;
      data['content'] = image.toJson();
    } else if (type == MessageType.audio) {
      AudioMessage audio = content as AudioMessage;
      data['content'] = audio.toJson();
    } else if (type == MessageType.video) {
      VideoMessage video = content as VideoMessage;
      data['content'] = video.toJson();
    } else {
      DocumentMessage doc = content as DocumentMessage;
      data['content'] = doc.toJson();
    }

    return data;
  }

  String getTime() {
    DateTime today = DateTime.now().toLocal();
    DateTime messageDateTime = DateTime.parse(dateTime!).toLocal();

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

class PictureMessage {
  String? caption;
  BsonBinary? image;

  PictureMessage({required this.caption, required this.image});

  PictureMessage.fromJson(Map<String, dynamic> json) {
    image = json['image'];
    caption = json['caption'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    data['image'] = image;
    data['caption'] = caption;

    return data;
  }
}

class VideoMessage {
  String? caption, duration;
  BsonBinary? thumbnail, video;
  int? sizeInMB;

  VideoMessage(
      {required this.caption,
      required this.duration,
      required this.thumbnail,
      required this.sizeInMB,
      required this.video});

  VideoMessage.fromJson(Map<String, dynamic> json) {
    caption = json['caption'];
    duration = json['duration'];
    thumbnail = json['thumbnail'];
    sizeInMB = json['sizeInMB'];
    video = json['video'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    data['caption'] = caption;
    data['duration'] = duration;
    data['thumbnail'] = thumbnail;
    data['sizeInMB'] = sizeInMB;
    data['video'] = video;

    return data;
  }
}

class AudioMessage {
  String? caption, duration, title;
  int? sizeInMB;
  BsonBinary? audio;

  AudioMessage(
      {required this.audio,
      required this.caption,
      required this.duration,
      required this.sizeInMB,
      required this.title});

  AudioMessage.fromJson(Map<String, dynamic> json) {
    audio = json['audio'];
    caption = json['caption'];
    duration = json['duration'];
    sizeInMB = json['sizeInMB'];
    title = json['title'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    data['audio'] = audio;
    data['caption'] = caption;
    data['duration'] = duration;
    data['sizeInMB'] = sizeInMB;
    data['title'] = title;

    return data;
  }
}

class DocumentMessage {
  String? caption, title;
  int? sizeInMB;
  BsonBinary? doc;

  DocumentMessage({required this.doc, required this.caption, required this.sizeInMB, required this.title});

  DocumentMessage.fromJson(Map<String, dynamic> json) {
    doc = json['doc'];
    caption = json['caption'];
    sizeInMB = json['sizeInMB'];
    title = json['title'];
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    data['doc'] = doc;
    data['caption'] = caption;
    data['sizeInMB'] = sizeInMB;
    data['title'] = title;

    return data;
  }
}
