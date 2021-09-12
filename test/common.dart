import 'dart:io';

setUpTestFiles(
  String imageTestFile,
  String pdfTestFile,
  String yamlTestFile,
) {
  File(
    './test/test_files/franz-michael-schneeberger-unsplash.jpg',
  ).copySync(imageTestFile);
  File(
    './test/test_files/test.pdf',
  ).copySync(pdfTestFile);
  File(
    './test/test_files/test.yml',
  ).copySync(yamlTestFile);
}

tearDownTestFiles(
  String imageTestFile,
  String pdfTestFile,
  String yamlTestFile,
) {
  File(imageTestFile).deleteSync();
  File(pdfTestFile).deleteSync();
  File(yamlTestFile).deleteSync();
}
