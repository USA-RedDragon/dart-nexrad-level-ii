library nexrad_level_ii;

import 'dart:async';
import 'dart:typed_data';
import 'package:archive/archive.dart';

const int CTM_HEADER_SIZE = 12;
const int MESSAGE_SIZE = 2432;

class NexradLDM {
  final ByteData blob;
  final int compressedSize;

  NexradLDM(ByteData blob)
      : blob = blob,
        compressedSize = blob.getInt32(0).abs() {}

  Stream<NexradLDMMessage> getMessages() async* {
    var decoder = new BZip2Decoder();
    var bzipped = decoder.decodeBytes(
        blob.buffer.asUint8List(blob.offsetInBytes + 4, compressedSize),
        verify: true) as Uint8List;
    var uncompressed = ByteData.sublistView(bzipped).asUnmodifiableView();
    var seek = 0;
    while (seek < bzipped.length) {
      var message = new NexradLDMMessage(
          ByteData.view(uncompressed.buffer, seek, MESSAGE_SIZE));
      final hdr = await message.header;
      if (hdr.messageSize == 0) {
        seek += MESSAGE_SIZE;
        continue;
      }
      yield message;
      switch (hdr.type) {
        case 31:
        case 29:
          seek += hdr.messageSize * 2 + CTM_HEADER_SIZE;
          break;
        default:
          seek += MESSAGE_SIZE;
      }
    }
  }

  String toString() {
    return 'NexradLDM{compressedSize: $compressedSize}';
  }
}

class NexradLDMMessage {
  final ByteData blob;

  NexradLDMMessage(ByteData blob) : blob = blob {}

  NexradLDMHeader get header {
    return new NexradLDMHeader(blob);
  }

  NexradLDMMessageData get data {
    switch (header.type) {
      case 0:
        break;
      case 2:
        // RDA Status Data
        return new NexradLDMMessage2(header, blob);
      case 3:
        // RDA Performance/Maintenance Data
        return new NexradLDMMessage3(header, blob);
      case 5:
        // RDA Volume Coverage Data
        return new NexradLDMMessage5(header, blob);
      case 15:
        // RDA Clutter Map Data
        return new NexradLDMMessage15(header, blob);
      case 18:
        // RDA Adaptable Parameters
        return new NexradLDMMessage18(header, blob);
      case 31:
        // Digital Radar Data Generic Format
        return new NexradLDMMessage31(header, blob);
    }
    throw new Exception('Unknown message type: ${header.type}');
  }

  String toString() {
    return 'NexradLDMMessage{header: $header}';
  }
}

base class NexradLDMMessageData {}

class NexradLDMHeader {
  late int messageSize;
  final int redundantChannel;
  final int type;
  final int seq;
  final int date;
  final int time;
  final int numSegments;
  final int segmentNumber;

  NexradLDMHeader(ByteData blob)
      : messageSize = blob.getUint16(12),
        redundantChannel = blob.getUint8(14),
        type = blob.getUint8(15),
        seq = blob.getUint16(16),
        date = blob.getUint16(18) - 1,
        time = blob.getUint32(20),
        numSegments = blob.getUint16(24),
        segmentNumber = blob.getUint16(26) {
    if (messageSize == 65535) {
      // Special case for long messages
      messageSize = numSegments << 16 | segmentNumber + CTM_HEADER_SIZE;
    }
  }

  DateTime get dateTime {
    var date = new DateTime.utc(1970, 1, 1 + this.date);
    return date.add(new Duration(milliseconds: this.time));
  }

  String toString() {
    return 'NexradLDMHeader{messageSize: $messageSize, redundantChannel: $redundantChannel, type: $type, seq: $seq, date: $dateTime, numSegments: $numSegments, segmentNumber: $segmentNumber}';
  }
}

final class NexradLDMMessage31 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;

  NexradLDMMessage31(NexradLDMHeader header, ByteData blob)
      : header = header,
        blob = blob {}

  List<int> get data {
    var size = header.messageSize;
    return new List<int>.generate(
        size, (i) => blob.getUint16(CTM_HEADER_SIZE + i * 2));
  }

  String toString() {
    return 'NexradLDMMessage31{}';
  }
}

final class NexradLDMMessage15 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;

  NexradLDMMessage15(NexradLDMHeader header, ByteData blob)
      : header = header,
        blob = blob {}

  List<int> get data {
    var size = header.messageSize;
    return new List<int>.generate(
        size, (i) => blob.getUint16(CTM_HEADER_SIZE + i * 2));
  }

  String toString() {
    return 'NexradLDMMessage15{}';
  }
}

final class NexradLDMMessage18 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;

  NexradLDMMessage18(NexradLDMHeader header, ByteData blob)
      : header = header,
        blob = blob {}

  List<int> get data {
    var size = header.messageSize;
    return new List<int>.generate(
        size, (i) => blob.getUint16(CTM_HEADER_SIZE + i * 2));
  }

  String toString() {
    return 'NexradLDMMessage18{}';
  }
}

final class NexradLDMMessage2 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;

  NexradLDMMessage2(NexradLDMHeader header, ByteData blob)
      : header = header,
        blob = blob {}

  List<int> get data {
    var size = header.messageSize;
    return new List<int>.generate(
        size, (i) => blob.getUint16(CTM_HEADER_SIZE + i * 2));
  }

  String toString() {
    return 'NexradLDMMessage2{}';
  }
}

final class NexradLDMMessage3 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;

  NexradLDMMessage3(NexradLDMHeader header, ByteData blob)
      : header = header,
        blob = blob {}

  List<int> get data {
    var size = header.messageSize;
    return new List<int>.generate(
        size, (i) => blob.getUint16(CTM_HEADER_SIZE + i * 2));
  }

  String toString() {
    return 'NexradLDMMessage3{}';
  }
}

final class NexradLDMMessage5 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;

  NexradLDMMessage5(NexradLDMHeader header, ByteData blob)
      : header = header,
        blob = blob {}

  List<int> get data {
    var size = header.messageSize;
    return new List<int>.generate(
        size, (i) => blob.getUint16(CTM_HEADER_SIZE + i * 2));
  }

  String toString() {
    return 'NexradLDMMessage5{}';
  }
}
