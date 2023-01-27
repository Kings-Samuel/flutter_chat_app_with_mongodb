import 'dart:async';
import 'dart:io';
// import 'package:byte_converter/byte_converter.dart';
import 'package:chat_app/helpers/utils/init_mogodb.dart';
import 'package:chat_app/models/message.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:recase/recase.dart';
import '../consts.dart';

enum UploadStatus { started, done, none }

class MesagesProvider extends ChangeNotifier {
  String _errorMessage = '';
  String _roomId = '';
  List<Message> _messages = [];
  final _collection = database.collection(Consts.messages);
  // final _gridFS = GridFS(database);
  late StreamSubscription _stream;
  int _progressPercent = 0;
  UploadStatus _uploadStatus = UploadStatus.none;

  List<Message> get messages => _messages;
  int get percentProgress => _progressPercent;
  UploadStatus get uploadStatus => _uploadStatus;
  String get errorMessage => _errorMessage;

  void setRoomId(String id) {
    _roomId = id;
    notifyListeners();
  }

  Future<void> init() async {
    _stream = Stream.periodic(const Duration(seconds: 15)).listen((event) async {
      final res = await _collection.find(where.eq('roomId', _roomId)).toList();
      final mes = res.map((e) => Message.fromJson(e)).toList();

      _messages.sort((a, b) {
        String aEpoch = DateTime.parse(a.dateTime!).toLocal().millisecondsSinceEpoch.toString();
        String bEpoch = DateTime.parse(b.dateTime!).toLocal().millisecondsSinceEpoch.toString();
        return bEpoch.compareTo(aEpoch);
      });

      _messages.clear();
      _messages = mes;
      notifyListeners();
    });
  }

  void stopStream() {
    _stream.cancel();
  }

  // get messgaes
  Future<void> getMessages(String roomId) async {
    // set room id
    _roomId = roomId;

    // start stream
    init();

    // get messages
    final res = await _collection.find(where.eq('roomId', _roomId)).toList();
    _messages = res.map((e) => Message.fromJson(e)).toList();

    _messages.sort((a, b) {
      String aEpoch = DateTime.parse(a.dateTime!).toLocal().millisecondsSinceEpoch.toString();
      String bEpoch = DateTime.parse(b.dateTime!).toLocal().millisecondsSinceEpoch.toString();
      return aEpoch.compareTo(bEpoch);
    });
    notifyListeners();
  }

  Future<bool> sendMessage({required Message message, File? file}) async {
    try {
      final res = await _collection.insertOne(message.toJson());
      ObjectId oid = res.id;
      String id = oid.$oid;

      await _collection.updateOne(where.eq("_id", oid), modify.set("id", id));

      List<Message> temp = [];

      for (var message in _messages) {
        temp.add(message);
      }

      message.id = id;

      temp.add(message);

      _messages.clear();
      _messages = temp;

      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return false;
    }
  }

  Future<bool> updateReadReceipts({required String messageId, required String userId}) async {
    try {
      await _collection.updateOne(where.eq("id", messageId), modify.push('readReceipts', userId));

      await getMessages(_roomId);

      return true;
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return false;
    }
  }

  // Future<String?> uploadFile(File file) async {
  //   try {
  //     // update status listeners
  //     _uploadStatus = UploadStatus.started;
  //     notifyListeners();
  //     // get file size (in bytes)
  //     final bytes = await file.length();
  //     // convert to MB
  //     ByteConverter converter = ByteConverter(bytes.toDouble());
  //     final sizeInMB = converter.megaBytes;
  //     int byteCount = 0;
  //     // stream upload progress
  //     final stream = file.openRead();
  //     stream.listen((event) {
  //       int bytes = event.length;
  //       byteCount += bytes;
  //       ByteConverter converter_ = ByteConverter(byteCount.toDouble());
  //       final sizeInMB_ = converter_.megaBytes;
  //       double percentageProgress = (sizeInMB_ * 100) / sizeInMB;
  //       _progressPercent = percentageProgress.toInt();
  //       if (_progressPercent == 100) {
  //         _uploadStatus = UploadStatus.done;
  //       }
  //       notifyListeners();
  //     });
  //     GridIn createdFile = _gridFS.createFile(stream, file.path);
  //     ObjectId oid = createdFile.id;
  //     String id = oid.$oid;
  //     return id;
  //   } catch (e) {
  //     _errorMessage = e.toString().sentenceCase;
  //     debugPrint(_errorMessage);
  //     return null;
  //   }
  // }

  Stream<UploadStatus> streamUploadStatusChanges() async* {
    UploadStatus status = _uploadStatus;

    yield status;
  }

  void setUploadStatusNone() {
    _progressPercent = 0;
    _uploadStatus = UploadStatus.none;
    notifyListeners();
  }

  void notify() {
    notifyListeners();
  }
}
