import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class StoryView extends StatefulWidget {
  final String imageUrl;
  final String postID;

  const StoryView({
    super.key,
    required this.imageUrl,
    required this.postID,
  });

  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        titleTextStyle: const TextStyle(color: Colors.white),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.black,
        title: Text("Story"),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(widget.imageUrl),
        minScale: PhotoViewComputedScale.contained,
        maxScale: PhotoViewComputedScale.covered * 2,
        heroAttributes: const PhotoViewHeroAttributes(tag: "imageHero"),
      ),
    );
  }
}
