 import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';


 
 Future<void> takePicture() async {
  // Ensure the storage permission is granted
  if (!await _requestStoragePermission()) {
    // Handle the case where the user does not grant permission
    // ignore: avoid_print
    print('Storage permission not granted');
    return;
  }

  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.camera);


  if (image != null) {
    final File imageFile = File(image.path);

    // Get the external storage directory
    final Directory? externalDir = (await getExternalStorageDirectory());

    // Create a specific folder inside the external storage directory
    final String customDirPath = path.join(externalDir!.path, 'lib/services/cache_photo');
    final Directory customDir = Directory(customDirPath);

    // If the directory does not exist, create it
    if (!await customDir.exists()) {
      await customDir.create(recursive: true);
    }

    // Copy the file from the temporary location to the new directory
    final String fileName = path.basename(imageFile.path);
    final String savedImagePath = path.join(customDir.path, fileName);
    final File savedImage = await imageFile.copy(savedImagePath);

    // Save the image to the gallery
    await saveImageToGallery(savedImage);
    
    // ignore: avoid_print
    print('Image saved at: ${savedImage.path}');
  }

}

Future<void> saveImageToGallery(File file) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    final File imageFile = File(image.path);

    if (await _requestStoragePermission()) {
      final String fileName = path.basename(imageFile.path);
      final Uint8List bytes = await imageFile.readAsBytes();
      final result = await ImageGallerySaver.saveImage(bytes, name: fileName);
      // ignore: avoid_print
      print('Image saved to Gallery: $result');
    }
  }
}

Future<bool> _requestStoragePermission() async {

  if (await Permission.manageExternalStorage.status.isDenied) {
    await Permission.manageExternalStorage.request();
  }
  var status = await Permission.manageExternalStorage.status;

  return status.isGranted;
}
