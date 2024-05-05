import "../lib/nexrad.dart";

void main() async {
  // For tracking timing
  final stopwatch = Stopwatch();
  var times = new Map<String, String>();
  stopwatch.start();

  // Read the file
  final archive = Archive2.fromPath("test/data/KTLX20240418_154156_V06");

  stopwatch.stop();
  times.addAll({'Read file': stopwatch.elapsedMilliseconds.toString() + "ms"});
  stopwatch.reset();
  stopwatch.start();

  // Take the archive header
  var header = archive.header;

  stopwatch.stop();
  times.addAll(
      {'Parse header': stopwatch.elapsedMilliseconds.toString() + "ms"});

  // Print the header
  print(header);

  stopwatch.reset();
  stopwatch.start();

  // Parse the data
  await for (var ldm in archive.data) {
    await for (var msg in ldm.getMessages()) {
      print(msg.header);
      print(msg.data);
    }
  }

  stopwatch.stop();
  times.addAll({'Parse data': stopwatch.elapsedMilliseconds.toString() + "ms"});
  stopwatch.stop();
  print(times);
}
