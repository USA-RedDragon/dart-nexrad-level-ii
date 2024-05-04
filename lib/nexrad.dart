library nexrad_level_ii;

import 'dart:io';
import 'dart:typed_data';

import './ldm.dart';

void main() async {
  final stopwatch = Stopwatch();
  var times = new Map<String, int>();
  var file = new File('test/data/KTLX20240418_154156_V06');
  stopwatch.start();
  var blob = ByteData.sublistView(file.readAsBytesSync());
  stopwatch.stop();
  times.addAll({'Read file': stopwatch.elapsedMilliseconds});
  stopwatch.reset();
  stopwatch.start();
  var header = new NexradVolumeHeader(blob);
  stopwatch.stop();
  times.addAll({'Parse header': stopwatch.elapsedMilliseconds});
  print(header);
  stopwatch.reset();
  stopwatch.start();
  var seek = header.size;
  var ldms = <NexradLDM>[];
  while (seek < blob.lengthInBytes) {
    var ldm = new NexradLDM(blob, seek);
    ldms.add(ldm);
    seek += ldm.compressedSize + 4;
  }
  times.addAll({'Parse LDMs': stopwatch.elapsedMilliseconds});
  stopwatch.reset();
  stopwatch.start();
  var datas = List<List<NexradLDMMessage>>.empty(growable: true);
  for (var i = 0; i < ldms.length; i++) {
    final messages = await ldms[i].getMessages();
    datas.add(messages);
  }
  times.addAll({'Parse all messages': stopwatch.elapsedMilliseconds});
  stopwatch.reset();
  for (var data in datas) {
    for (var message in data) {
      var hdr = await message.header;
      var data = await message.data;
      stopwatch.stop();
      print(hdr);
      print(data);
      stopwatch.start();
    }
  }
  stopwatch.stop();
  times.addAll({'Print all messages': stopwatch.elapsedMilliseconds});
  print(times);
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
  final int size;

  NexradVolumeHeader(ByteData blob)
      : header = new String.fromCharCodes(blob.buffer.asUint8List(0, 3)),
        version =
            int.parse(new String.fromCharCodes(blob.buffer.asUint8List(4, 4))),
        extension =
            int.parse(new String.fromCharCodes(blob.buffer.asUint8List(9, 3))),
        date = blob.getUint32(12) - 1,
        time = blob.getUint32(16),
        station = new String.fromCharCodes(blob.buffer.asUint8List(20, 4)),
        size = 24 {}

  DateTime get dateTime {
    var date = new DateTime.utc(1970, 1, 1 + this.date);
    return date.add(new Duration(milliseconds: this.time));
  }

  String toString() {
    return 'NexradHeader{header: $header, version: $version, extension: $extension, date: $dateTime, station: $station}';
  }
}
