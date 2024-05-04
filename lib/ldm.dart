library nexrad_level_ii;

import 'dart:async';
import 'dart:typed_data';
import 'package:archive/archive.dart';

const int CTM_HEADER_SIZE = 12;
const int MESSAGE_SIZE = 2432;

class NexradLDM {
  final int compressedSize;
  final ByteData blob;
  final int offset;

  NexradLDM(ByteData blob, int offset) : compressedSize = blob.getInt32(offset).abs(), blob = blob, offset = offset
  { }

  Future<List<NexradLDMMessage>> getMessages() async {
    var decoder = new BZip2Decoder();
    var bzipped = decoder.decodeBytes(blob.buffer.asUint8List(offset+4, compressedSize), verify: true) as Uint8List;
    var uncompressed = ByteData.sublistView(bzipped);
    var seek = 0;
    var messages = <NexradLDMMessage>[];
    while (seek < bzipped.length) {
      var message = new NexradLDMMessage(uncompressed, seek);
      final hdr = await message.header;
      if (hdr.messageSize == 0) {
        seek += MESSAGE_SIZE;
        continue;
      }
      messages.add(message);
      switch (hdr.type) {
        case 31:
        case 29:
          seek += hdr.messageSize * 2 + CTM_HEADER_SIZE;
          break;
        default:
          seek += MESSAGE_SIZE;
      }
    }
    return messages;
  }

  String toString() {
    return 'NexradLDM{compressedSize: $compressedSize}';
  }
}

class NexradLDMMessage {
  final ByteData blob;
  final int offset;
  
  NexradLDMMessage(ByteData blob, int offset) : blob = blob, offset = offset
  {}

  Future<NexradLDMHeader> get header async {
    return new NexradLDMHeader(blob, offset);
  }

  Future<NexradLDMMessageData> get data async {
    var hdr = await header;
    switch (hdr.type) {
      case 0:
        break;
      case 2:
        return new NexradLDMMessage2(hdr, blob, offset);
      case 3:
        return new NexradLDMMessage3(hdr, blob, offset);
      case 5:
        return new NexradLDMMessage5(hdr, blob, offset);
      case 15:
        return new NexradLDMMessage15(hdr, blob, offset);
      case 18:
        return new NexradLDMMessage18(hdr, blob, offset);
      case 31:
        return new NexradLDMMessage31(hdr, blob, offset);
    }
    throw new Exception('Unknown message type: ${hdr.type}');
  }

  String toString() {
    return 'NexradLDMMessage{header: $header}';
  }
}

base class NexradLDMMessageData {
}

class NexradLDMHeader {
  late int messageSize;
  final int redundantChannel;
  final int type;
  final int seq;
  final int date;
  final int time;
  final int numSegments;
  final int segmentNumber;

  NexradLDMHeader(ByteData blob, int offset) : messageSize = blob.getUint16(offset+12),
                                    redundantChannel = blob.getUint8(offset+14),
                                    type = blob.getUint8(offset+15),
                                    seq = blob.getUint16(offset+16),
                                    date = blob.getUint16(offset+18) - 1,
                                    time = blob.getUint32(offset+20),
                                    numSegments = blob.getUint16(offset+24),
                                    segmentNumber = blob.getUint16(offset+26)
  {
      if (messageSize == 65535) {
        // Special case for long messages
        messageSize = numSegments << 16 | segmentNumber + CTM_HEADER_SIZE;
      }
  }

  DateTime get dateTime {
    var date = new DateTime.utc(1970, 1, 1+this.date);
    return date.add(new Duration(milliseconds: this.time));
  }

  String toString() {
    return 'NexradLDMHeader{messageSize: $messageSize, redundantChannel: $redundantChannel, type: $type, seq: $seq, date: $dateTime, numSegments: $numSegments, segmentNumber: $segmentNumber}';
  }
}

final class NexradLDMMessage31 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;
  final int offset;

  NexradLDMMessage31(NexradLDMHeader header, ByteData blob, int offset) : header = header, blob = blob, offset = offset
  { }

  Future<List<int>> get data async {
    var size = header.messageSize;
    return new List<int>.generate(size, (i) => blob.getUint16(offset+CTM_HEADER_SIZE+i*2));
  }

  String toString() {
    return 'NexradLDMMessage31{}';
  }
}

final class NexradLDMMessage15 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;
  final int offset;

  NexradLDMMessage15(NexradLDMHeader header, ByteData blob, int offset) : header = header, blob = blob, offset = offset
  { }

  Future<List<int>> get data async {
    var size = header.messageSize;
    return new List<int>.generate(size, (i) => blob.getUint16(offset+CTM_HEADER_SIZE+i*2));
  }

  String toString() {
    return 'NexradLDMMessage15{}';
  }
}

final class NexradLDMMessage18 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;
  final int offset;

  NexradLDMMessage18(NexradLDMHeader header, ByteData blob, int offset) : header = header, blob = blob, offset = offset
  { }

  Future<List<int>> get data async {
    var size = header.messageSize;
    return new List<int>.generate(size, (i) => blob.getUint16(offset+CTM_HEADER_SIZE+i*2));
  }

  String toString() {
    return 'NexradLDMMessage18{}';
  }
}

final class NexradLDMMessage2 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;
  final int offset;

  NexradLDMMessage2(NexradLDMHeader header, ByteData blob, int offset) : header = header, blob = blob, offset = offset
  { }

  Future<List<int>> get data async {
    var size = header.messageSize;
    return new List<int>.generate(size, (i) => blob.getUint16(offset+CTM_HEADER_SIZE+i*2));
  }

  String toString() {
    return 'NexradLDMMessage2{}';
  }
}

final class NexradLDMMessage3 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;
  final int offset;

  NexradLDMMessage3(NexradLDMHeader header, ByteData blob, int offset) : header = header, blob = blob, offset = offset
  { }

  Future<List<int>> get data async {
    var size = header.messageSize;
    return new List<int>.generate(size, (i) => blob.getUint16(offset+CTM_HEADER_SIZE+i*2));
  }

  String toString() {
    return 'NexradLDMMessage3{}';
  }
}

final class NexradLDMMessage5 extends NexradLDMMessageData {
  final NexradLDMHeader header;
  final ByteData blob;
  final int offset;

  NexradLDMMessage5(NexradLDMHeader header, ByteData blob, int offset) : header = header, blob = blob, offset = offset
  { }

  Future<List<int>> get data async {
    var size = header.messageSize;
    return new List<int>.generate(size, (i) => blob.getUint16(offset+CTM_HEADER_SIZE+i*2));
  }

  String toString() {
    return 'NexradLDMMessage5{}';
  }
}
