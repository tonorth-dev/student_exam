import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';

import '../../sidebar/logic.dart';

class CourseManagerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '讲义管理',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: EcourseManagementPage(),
    );
  }

  static SidebarTree newThis() {
    return SidebarTree(
      name: "讲义管理",
      icon: Icons.app_registration_outlined,
      page: CourseManagerPage(),
    );
  }
}

class EcourseManagementPage extends StatefulWidget {
  @override
  _EcourseManagementPageState createState() => _EcourseManagementPageState();
}

class _EcourseManagementPageState extends State<EcourseManagementPage> {
  List<File>? previewImages = [];
  String? selectedEcourse;
  String? selectedChapter;
  String? selectedPage;
  List<String> ecourses = ['E-course 1', 'E-course 2', 'E-course 3'];
  Map<String, List<String>> ecourseStructure = {
    'E-course 1': ['Chapter 1', 'Chapter 2'],
    'E-course 2': ['Chapter 1', 'Chapter 2'],
    'E-course 3': ['Chapter 1', 'Chapter 2'],
  };
  Map<String, List<String>> chaptersAndPages = {
    'Chapter 1': ['Page 1', 'Page 2'],
    'Chapter 2': ['Page 3', 'Page 4'],
  };
  Map<String, List<String>> pagesAndChild = {
    'Page 1': ['Child 1', 'Child 2'],
    'Page 2': ['Child 3', 'Child 4'],
    'Page 3': ['Child 5', 'Child 6'],
    'Page 4': ['Child 7', 'Child 8'],
  };
  String? previewImagePath;

  void onSelectEcourse(String ecourse) {
    setState(() {
      selectedEcourse = ecourse;
      selectedChapter = null;
      selectedPage = null;
      previewImagePath = null;
    });
  }

  void onSelectChapter(String chapter) {
    setState(() {
      selectedChapter = chapter;
      selectedPage = null;
      previewImagePath = null;
    });
  }

  void onSelectPage(String page) {
    setState(() {
      selectedPage = page;
      previewImagePath = null;
    });
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        previewImagePath = result.files.first.path;
      });
    }
  }

  Future<void> pickFileAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.single.path!);
      await uploadAndConvertFile(file);
    }
  }

  Future<void> uploadAndConvertFile(File file) async {
    final dio = Dio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    try {
      final response = await dio.post('https://your-backend.com/convert', data: formData);
      if (response.statusCode == 200) {
        List<String> imageUrls = List<String>.from(response.data['imageUrls']);
        setState(() {
          previewImages = imageUrls.map((url) => File(url)).toList();
        });
      }
    } catch (e) {
      print("Error uploading file: $e");
    }
  }

  void addChapter(String chapter) {
    setState(() {
      ecourseStructure[selectedEcourse]!.add(chapter);
    });
  }

  void addPage(String page) {
    setState(() {
      chaptersAndPages[selectedChapter]!.add(page);
    });
  }

  void addChild(String child) {
    setState(() {
      pagesAndChild[selectedPage]!.add(child);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('E-course Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left Panel: E-course Table
            Expanded(
              flex: 1,
              child: Card(
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('E-course Name')),
                      DataColumn(label: Text('Major')),
                      DataColumn(label: Text('Author')),
                      DataColumn(label: Text('View')),
                    ],
                    rows: ecourses.map((ecourse) {
                      return DataRow(
                        cells: [
                          DataCell(Text(ecourse)),
                          DataCell(Text('Major 1')), // Placeholder for Major
                          DataCell(Text('Author A')), // Placeholder for Author
                          DataCell(IconButton(
                            icon: Icon(Icons.visibility),
                            onPressed: () => onSelectEcourse(ecourse),
                          )),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.0),

            // Middle Panel: E-course Structure (Chapters and Pages)
            Expanded(
              flex: 1,
              child: Card(
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: selectedEcourse == null
                      ? Center(child: Text('Select an e-course to view structure'))
                      : Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: ecourseStructure[selectedEcourse]?.length ?? 0,
                          itemBuilder: (context, chapterIndex) {
                            String chapter = ecourseStructure[selectedEcourse]![chapterIndex];
                            return ExpansionTile(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(chapter),
                                  IconButton(
                                    icon: Icon(Icons.add),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          String newChapter = '';
                                          return AlertDialog(
                                            title: Text('Add Chapter'),
                                            content: TextField(
                                              onChanged: (value) {
                                                newChapter = value;
                                              },
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  addChapter(newChapter);
                                                  Navigator.of(context).pop();
                                                },
                                                child: Text('Add'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              children: [
                                ...chaptersAndPages[chapter]!.map((page) {
                                  return ExpansionTile(
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(page),
                                        IconButton(
                                          icon: Icon(Icons.add),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                String newPage = '';
                                                return AlertDialog(
                                                  title: Text('Add Page'),
                                                  content: TextField(
                                                    onChanged: (value) {
                                                      newPage = value;
                                                    },
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: Text('Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        addPage(newPage);
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: Text('Add'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    children: [
                                      ...pagesAndChild[page]!.map((child) {
                                        return ListTile(
                                          title: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(child),
                                              IconButton(
                                                icon: Icon(Icons.add),
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      String newChild = '';
                                                      return AlertDialog(
                                                        title: Text('Add Child'),
                                                        content: TextField(
                                                          onChanged: (value) {
                                                            newChild = value;
                                                          },
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: Text('Cancel'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              addChild(newChild);
                                                              Navigator.of(context).pop();
                                                            },
                                                            child: Text('Add'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          onTap: () => onSelectPage(child),
                                        );
                                      }).toList(),
                                    ],
                                  );
                                }).toList(),
                              ],
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              String newChapter = '';
                              return AlertDialog(
                                title: Text('Add Chapter'),
                                content: TextField(
                                  onChanged: (value) {
                                    newChapter = value;
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      addChapter(newChapter);
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('Add'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: Text('Add Chapter'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.0),

            // Right Panel: Page Preview and Image Upload
            Expanded(
              flex: 1,
              child: Card(
                elevation: 4.0,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      previewImages == null || previewImages!.isEmpty
                          ? Text('No preview available. Please upload a Word or PDF file.')
                          : Expanded(
                        child: ListView.builder(
                          itemCount: previewImages!.length,
                          itemBuilder: (context, index) {
                            return Image.file(previewImages![index]);
                          },
                        ),
                      ),
                      SizedBox(height: 16.0),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          elevation: 4.0,
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                        ),
                        onPressed: pickFileAndUpload,
                        child: Text('Upload Word or PDF'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
