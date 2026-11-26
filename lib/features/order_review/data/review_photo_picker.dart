import 'package:image_picker/image_picker.dart';

enum ReviewPhotoSource { camera, gallery }

abstract class ReviewPhotoPicker {
  const ReviewPhotoPicker();
  Future<String?> pick(ReviewPhotoSource source);
}

class DeviceReviewPhotoPicker extends ReviewPhotoPicker {
  const DeviceReviewPhotoPicker();

  @override
  Future<String?> pick(ReviewPhotoSource source) async {
    final photo = await ImagePicker().pickImage(
      source: source == ReviewPhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
    );
    return photo?.path;
  }
}
