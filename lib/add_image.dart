import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:path/path.dart' as Path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class AddImage extends StatefulWidget {
  AddImage({Key key}) : super(key: key);

  @override
  _AddImageState createState() => _AddImageState();
}

class _AddImageState extends State<AddImage> {
  CollectionReference imgRef;
  firebase_storage.Reference ref;

  List<File> _image = [];
  final picker = ImagePicker();

  bool uploading = false;
  double progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Image'),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file), 
            onPressed: () {
              setState(() => uploading = true);
              uploadFile().whenComplete(() => Navigator.of(context).pop());
            }
          )
        ],
      ),
      body: Stack(
        children: [
          GridView.builder(
            itemCount: _image.length + 1,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3), 
            itemBuilder: (context, index) {
              return index == 0
                ? Center(
                  child: IconButton(
                    icon: Icon(Icons.add), 
                    onPressed: () {
                      if(!uploading) chooseImage();
                    }
                  ),
                )
                : Container(
                  margin: EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    image: DecorationImage(image: FileImage(_image[index-1]), fit: BoxFit.cover),
                  ),
                );
            }
          ),
          uploading 
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    child: Text('uploading...', style: TextStyle(fontSize: 20)),
                  ),
                  SizedBox(height: 10),
                  CircularProgressIndicator(
                    value: progress,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  )
                ],
              ),
            )
            : Container()
        ]
      ),
    );
  }

  chooseImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    setState(() {
      _image.add(File(pickedFile?.path));
    });
    if (pickedFile.path == null) retriveLostData();
  }

  Future<void> retriveLostData() async {
    final LostData response = await picker.getLostData();
    if (response.isEmpty) {
      return;
    }
    if (response.file != null) {
      setState(() {
        _image.add(File(response.file.path));
      });
    } else {
      print(response.file);
    }
  }

  Future uploadFile() async {
    int i = 1;
    for (var img in _image) {
      setState(() {
        progress = i / _image.length;
      });
      ref = firebase_storage.FirebaseStorage.instance.ref()
              .child('images/${Path.basename(img.path)}');
      await ref.putFile(img).whenComplete(() async {
        await ref.getDownloadURL().then((value) => imgRef.add({ 'ref': value }));
        i++;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    imgRef = FirebaseFirestore.instance.collection('imageURLs');
  }
}