import 'package:file_picker/src/api/file_picker_types.dart';
import 'package:dbus/dbus.dart';

typedef FilterInfo = Map<String, List<(int, String)>>;

class Filter {
  FilterInfo info = {};
  Filter(FileType type, List<String>? allowedExtensions) {
    if (type != FileType.custom && (allowedExtensions?.isNotEmpty ?? false)) {
      throw ArgumentError.value(
        allowedExtensions,
        'allowedExtensions',
        'Custom extension filters are only allowed with FileType.custom. '
            'Remove the extension filter or change the FileType to FileType.custom.',
      );
    }
    switch (type) {
      case FileType.any:
        return;
      case FileType.audio:
        final audio = ["*.aac", "*.midi", "*.mp3", "*.ogg", "*.wav"];
        List<(int, String)> audioList = [];
        for (var filter in audio) {
          audioList.add((0, filter));
        }
        info["Audio"] = audioList;
      case FileType.custom:
        final custom = [...?allowedExtensions];
        List<(int, String)> customList = [];
        for (var filter in custom) {
          customList.add((0, "*.$filter"));
        }
        info["Custom"] = customList;
      case FileType.image:
        final image = ["*.bmp", "*.gif", "*.jpeg", "*.jpg", "*.png", "*.webp"];
        List<(int, String)> imageList = [];
        for (var filter in image) {
          imageList.add((0, filter));
        }
        info["Image"] = imageList;
      case FileType.media:
        final media = [
          "*.avi",
          "*.flv",
          "*.m4v",
          "*.mkv",
          "*.mov",
          "*.mp4",
          "*.mpeg",
          "*.webm",
          "*.wmv",
          "*.bmp",
          "*.gif",
          "*.jpeg",
          "*.jpg",
          "*.png"
        ];
        List<(int, String)> mediaList = [];
        for (var filter in media) {
          mediaList.add((0, filter));
        }
        info["Media"] = mediaList;
      case FileType.video:
        final video = [
          "*.avi",
          "*.flv",
          "*.mkv",
          "*.mov",
          "*.mp4",
          "*.m4v",
          "*.mpeg",
          "*.webm",
          "*.wmv"
        ];
        List<(int, String)> videoList = [];
        for (var filter in video) {
          videoList.add((0, filter));
        }
        info["Video"] = videoList;
    }
  }
  DBusArray toDBusArray() {
    List<DBusValue> dataList = [];
    info.forEach((var key, var values) {
      List<DBusStruct> tmpList = [];
      for (var (posO, val) in values) {
        final pos = DBusUint32(posO);
        final value = DBusString(val);
        tmpList.add(DBusStruct([pos, value]));
      }
      DBusValue dataArray = DBusArray(
          DBusSignature.struct([DBusSignature.uint32, DBusSignature.string]),
          tmpList);
      dataList.add(DBusStruct([DBusString(key), dataArray]));
    });

    return DBusArray(
        DBusSignature.struct([
          DBusSignature.string,
          DBusSignature.array(DBusSignature.struct(
              [DBusSignature.uint32, DBusSignature.string]))
        ]),
        dataList);
  }
}
