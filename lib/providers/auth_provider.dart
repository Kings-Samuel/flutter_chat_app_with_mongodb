import 'dart:async';
import 'dart:convert';
import 'package:chat_app/consts.dart';
import 'package:chat_app/helpers/utils/init_mogodb.dart';
import 'package:chat_app/helpers/utils/sec_storage.dart';
import 'package:chat_app/models/user.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:recase/recase.dart';

class AuthProvider extends ChangeNotifier {
  String _errorMessage = '';
  final _usersCollection = database.collection(Consts.users);
  bool _isUserNameExists = false;
  User _user = User();

  String get errorMessage => _errorMessage;
  bool get isUserNameExists => _isUserNameExists;
  User get user => _user;

  // hash user's password
  Future<String> _hashPassword(String password) async {
    var bytes = utf8.encode(password);
    var hash = sha256.convert(bytes);
    String hashKey = hash.toString();

    return hashKey;
  }

  // check if email already exists
  Future<bool> checkEmailExists({required String email}) async {
    try {
      final res = await _usersCollection.findOne({"email": email});

      if (res == null) {
        return false;
      } else {
        _errorMessage = 'Email address already exists';
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return false;
    }
  }

  // check  if username exists
  Future<void> checkUsernameExists({required String username}) async {
    try {
      final res = await _usersCollection.findOne({"username": username});

      if (res == null) {
        _isUserNameExists = false;
      } else {
        _errorMessage = 'Username has been taken';
        _isUserNameExists = true;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
    }
  }

  // check if password match at login
  Future<bool> _doesPasswordMatch(String email, String password) async {
    try {
      // get user data by email
      final res = await _usersCollection.findOne(where.eq('email', email));
      User user = User.fromJson(res!);

      // hash given password
      String passwordHash = await _hashPassword(password);

      if (passwordHash == user.passwordHash) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return false;
    }
  }

  // get logged in user
  Future<bool> getLoggedInUser() async {
    final userId = await secStorage.read(key: 'userId');

    bool isLoggedIn = false;

    if (userId != null) {
      isLoggedIn = true;

      // get user
      final res = await _usersCollection.findOne({"id": userId});
      _user = User.fromJson(res!);

      // update last seen
      updateUserLastSeen();
    } else {
      isLoggedIn = false;
    }

    return isLoggedIn;
  }

  // create user account
  Future<bool> registerUser(User user) async {
    String passwordHash = await _hashPassword(user.passwordHash!); // the hash is actually the password
    user.passwordHash = passwordHash;

    try {
      final res = await _usersCollection.insertOne(user.toJson());

      if (res.isSuccess) {
        ObjectId oid = res.id;
        String id = oid.$oid;
        // add id to doc
        await _usersCollection.updateOne({
          "_id": oid
        }, {
          "\$set": {"id": id}
        });

        return true;
      } else {
        _errorMessage = 'Unknown error';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return false;
    }
  }

  // log user in
  Future<bool> loginUser({required String email, required String password}) async {
    try {
      // verify email exists
      final bool isExists = await checkEmailExists(email: email);

      if (isExists) {
        // verify password is correct
        bool isCorrrect = await _doesPasswordMatch(email, password);

        if (isCorrrect) {
          // get user id and save to sec storage
          final res = await _usersCollection.findOne({"email": email});
          User user = User.fromJson(res!);
          _user = user;

          await secStorage.write(key: 'userId', value: _user.id);

          // update last seen
          updateUserLastSeen();

          return true;
        } else {
          _errorMessage = 'Password incorrect. Check and try again';
          return false;
        }
      } else {
        _errorMessage = 'Email address not found.';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return false;
    }
  }

  // log out user
  Future<void> logoutUser() async {
    await secStorage.delete(key: 'userId');
  }

  // update user profile
  Future<bool> updateUserProfile({required String username, required BsonBinary image}) async {
    try {
      // update document
      final res = await _usersCollection.updateOne({
        "id": _user.id
      }, {
        "\$set": {"username": username, "image": image}
      });

      if (res.isSuccess) {
        // update user in provider
        _user.name = username;
        _user.image = image;

        notifyListeners();

        return true;
      } else {
        _errorMessage = 'Unknown error occurred';
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().sentenceCase;
      debugPrint(_errorMessage);
      return false;
    }
  }

  // update user's last seen
  Future<void> updateUserLastSeen() async {
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      DateTime now = DateTime.now().toUtc();

      await _usersCollection.updateOne(where.eq("id", _user.id), modify.set("lastSeen", now.toString()));
    });
  }
}
