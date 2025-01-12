import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('XLSX Test')),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom, allowedExtensions: ['xlsx']);
              if (result != null) {
                PlatformFile file = result.files.first;
                if (file.path != null) {
                  try {
                    final workbook = xlsio.Workbook.fromFile(File(file.path!));
                    print('Workbook loaded successfully!');
                    workbook.dispose();
                  } catch (e) {
                    print('Error loading workbook: $e');
                  }
                }
              }
            },
            child: Text('Pick and Load XLSX'),
          ),
        ),
      ),
    );
  }
}