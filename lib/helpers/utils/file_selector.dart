import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

final ImagePicker _picker = ImagePicker();

Future<XFile?> pickImageFromCamera() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.camera);
  return image;
}

Future<XFile?> pickImageFromGallery() async {
  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  return image;
}

Future<XFile?> pickVideoFromCamera() async {
  final XFile? video = await _picker.pickVideo(source: ImageSource.camera);
  return video;
}

Future<File?> pickVideoFromGallery() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);
  File? file;

  if (result != null) {
    file = File(result.files.single.path!);
    return file;
  } else {
    return file;
  }
}

// Future<List<XFile>> pickImagesFromGallery() async {
//   final List<XFile> images = await _picker.pickMultiImage();
//   return images;
// }

Future<File?> pickAudio() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);
  File? file;

  if (result != null) {
    file = File(result.files.single.path!);
    return file;
  } else {
    return file;
  }
}

Future<File?> picDocFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: [
    'pdf',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'txt',
    'ppt',
  ]);
  File? file;

  if (result != null) {
    file = File(result.files.single.path!);
    return file;
  } else {
    return file;
  }
}
