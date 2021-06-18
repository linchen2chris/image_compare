import 'algorithms.dart';
import 'dart:io';
import 'package:image/image.dart';

/// Compare images from [src1] and [src2] with a specified [algorithm].
/// If [algorithm] is not specified, the default (PixelMatching()) is supplied.
///
/// Returns a [Future] of double corresponding to the difference between [src1]
/// and [src2]
///
/// [src1] and [src2] may be any combination of the supported types:
/// * [Uri] - parsed URI, such as a URL (dart:core Uri class)
/// * [File] - reference to a file on the file system (dart:io File class)
/// * [List]- list of integers (bytes representing the image)
/// * [Image] - image buffer (Image class)
Future<double> compareImages({
  required var src1,
  required var src2,
  Algorithm? algorithm,
}) async {
  algorithm ??= PixelMatching(); //default algorithm
  src1 = await _getImageFromDynamic(src1);
  src2 = await _getImageFromDynamic(src2);
  return algorithm.compare(src1, src2);
}

Future<Image> _getImageFromDynamic(var src) async {
  if (src is File) {
    src = _getImageFile(src);
  } else if (src is Uri) {
    src = _getImageNetwork(src);
  } else if (src is List<int>) {
    src = decodeImage(src);
  } else if (!(src is Image)) {
    throw UnsupportedError(
        "The source(${src}) of type(${src.runtimeType}) passed in is unsupported");
  }

  return src;
}

Image _getImageFile(File path) {
  var imageFile1 = path.readAsBytesSync();

  return decodeImage(imageFile1)!;
}

/// Compare [targetSrc] to each image present in [srcList] using a
/// specified [algorithm]. If [algorithm] is not specified, the default (PixelMatching())
/// is supplied.
///
/// Returns a [Future] list of doubles corresponding to the difference
/// between [targetSrc] and srcList[i].
/// Output is in the same order as [srcList].
///
/// [targetSrc] and srcList[i] may be any combination of the supported types:
/// * [Uri] - parsed URI, such as a URL (dart:core Uri class)
/// * [File] - reference to a file on the file system (dart:io File class)
/// * [List]- list of integers (bytes representing the image)
/// * [Image] - image buffer (Image class)
Future<List<double>> listCompare({
  required var targetSrc,
  required List<dynamic> srcList,
  Algorithm? algorithm,
}) async {
  algorithm ??= PixelMatching(); //default algorithm

  var results = List<double>.filled(srcList.length, 0);

  await Future.wait(srcList.map((otherSrc) async {
    results[srcList.indexOf(otherSrc)] = await compareImages(
        src1: targetSrc, src2: otherSrc, algorithm: algorithm);
  }));

  return results;
}

Future<Image> _getImageNetwork(Uri src) async {
  var bodyBytes = <int>[];
  HttpClient cl = new HttpClient();
  var req = await cl.getUrl(src);
  var res = await req.close();
  await for (var value in res) {
    value.forEach((element) {
      bodyBytes.add(element);
    });
  }

  return decodeImage(bodyBytes)!;
}
