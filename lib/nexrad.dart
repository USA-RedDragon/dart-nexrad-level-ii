library nexrad_level_ii;

import 'dart:io';
import 'dart:typed_data';

import './ldm.dart';

class Archive2 {
  final ByteData blob;

  Archive2(ByteData blob) : blob = blob.asUnmodifiableView() {}
  Archive2.fromFile(File file)
      : blob =
            ByteData.sublistView(file.readAsBytesSync()).asUnmodifiableView() {}
  Archive2.fromBytes(Uint8List bytes)
      : blob = ByteData.sublistView(bytes).asUnmodifiableView() {}
  Archive2.fromPath(String path)
      : blob = ByteData.sublistView(File(path).readAsBytesSync())
            .asUnmodifiableView() {}

  NexradVolumeHeader get header {
    return new NexradVolumeHeader(
        ByteData.view(blob.buffer, 0, NexradVolumeHeader.HEADER_SIZE)
            .asUnmodifiableView());
  }

  Stream<NexradLDM> get data async* {
    var seek = NexradVolumeHeader.HEADER_SIZE;
    while (seek < blob.lengthInBytes) {
      final ldm = new NexradLDM(
          ByteData.view(blob.buffer, seek, blob.getInt32(seek).abs())
              .asUnmodifiableView());
      yield ldm;
      seek += 4 + ldm.compressedSize;
    }
  }
}

// NEXRAD Level II file header
// Format:
// 3 bytes: header: 'AR2' (ASCII)
// 6 bytes: version: 'V00xx.' (ASCII) where xx is the version number
// 3 bytes: extension number: 'xxx' (ASCII) where xxx is the extension number
// 4 bytes: modified Julian date of days since January 1, 1970 where 1/1/1970 = 1
// 4 bytes: milliseconds since midnight
// 4 bytes: ICAO radar station identifier
class NexradVolumeHeader {
  final String header;
  final int version;
  final int extension;
  final int date;
  final int time;
  final String station;

  static const HEADER_SIZE = 24;

  NexradVolumeHeader(ByteData blob)
      : header = new String.fromCharCodes(blob.buffer.asUint8List(0, 3)),
        version =
            int.parse(new String.fromCharCodes(blob.buffer.asUint8List(4, 4))),
        extension =
            int.parse(new String.fromCharCodes(blob.buffer.asUint8List(9, 3))),
        date = blob.getUint32(12) - 1,
        time = blob.getUint32(16),
        station = new String.fromCharCodes(blob.buffer.asUint8List(20, 4)) {}

  DateTime get dateTime {
    var date = new DateTime.utc(1970, 1, 1 + this.date);
    return date.add(new Duration(milliseconds: this.time));
  }

  String toString() {
    return 'NexradHeader{header: $header, version: $version, extension: $extension, date: $dateTime, station: $station}';
  }
}
