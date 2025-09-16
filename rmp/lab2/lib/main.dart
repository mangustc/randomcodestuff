import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    title: 'Lab 2',
    home: Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Text("Lab 2"),
      ),
      body: Wrap(
        children: [
          Container(padding: EdgeInsets.all(5), width: 100, height: 100, child: Image.network("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSoRGJMWyWvM60rqwTc5y_GILztwNg-lX7FcA&s")),
          Container(padding: EdgeInsets.all(5), width: 100, height: 100, child: Image.network("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSoRGJMWyWvM60rqwTc5y_GILztwNg-lX7FcA&s")),
          Container(padding: EdgeInsets.all(5), width: 100, height: 100, child: Image.network("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSoRGJMWyWvM60rqwTc5y_GILztwNg-lX7FcA&s")),
          Container(padding: EdgeInsets.all(5), width: 150, height: 150, child: Image.network("https://substackcdn.com/image/fetch/\$s_!Hro2!,f_auto,q_auto:good,fl_progressive:steep/https%3A%2F%2Fsubstack-post-media.s3.amazonaws.com%2Fpublic%2Fimages%2F6b5b6587-6dea-4deb-a703-fd00c63a41ea_1080x1080.jpeg")),
          Container(padding: EdgeInsets.all(5), width: 200, height: 300, child: Image.network("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSoRGJMWyWvM60rqwTc5y_GILztwNg-lX7FcA&s")),
        ],
      )
    ),
  ));
}
