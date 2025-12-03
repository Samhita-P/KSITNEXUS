import 'dart:html' as html;

Future<void> downloadFileWeb(List<int> bytes, String filename, String? mimeType) async {
  final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
  final url = html.Url.createObjectUrlFromBlob(blob);

  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();

  html.Url.revokeObjectUrl(url);
}
