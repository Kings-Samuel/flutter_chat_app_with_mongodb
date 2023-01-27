import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart';

class User {
  String? id, name, username, email, passwordHash, lastSeen;
  BsonBinary? image;
  List<int>? color;

  User({this.id, this.name, this.username, this.email, this.image, this.passwordHash, this.lastSeen, this.color});

  User.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    username = json['username'];
    email = json['email'];
    image = json['image'];
    passwordHash = json['passwordHash'];
    lastSeen = json['lastSeen'];
    color = json['color'].cast<int>();
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> data = {};

    data['id'] = id;
    data['name'] = name;
    data['username'] = username;
    data['email'] = email;
    data['image'] = image;
    data['passwordHash'] = passwordHash;
    data['lastSeen'] = lastSeen;
    data['color'] = color;

    return data;
  }

  List<int> colorToList(Color color_) {
    int alpha = color_.alpha;
    int red = color_.red;
    int green = color_.green;
    int blue = color_.blue;

    List<int> value = [alpha, red, green, blue];

    return value;
  }

  Color listToColor() {
    Color color_ = Color.fromARGB(color![0], color![1], color![2], color![3]);

    return color_;
  }
}
