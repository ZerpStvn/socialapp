// ignore_for_file: library_private_types_in_public_api

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:social/controller/videoplayer.dart';
import 'package:social/utils/globaltheme.dart';
import 'package:video_player/video_player.dart';

class MediaPost extends StatefulWidget {
  final String mediaUrl;
  final String posid;
  final String userid;
  final String views;

  const MediaPost(
      {super.key,
      required this.mediaUrl,
      required this.posid,
      required this.userid,
      required this.views});

  @override
  _MediaPostState createState() => _MediaPostState();
}

class _MediaPostState extends State<MediaPost> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isLoading = true;
  bool _isPlaying = false; // Track if video is playing

  @override
  void initState() {
    super.initState();
    _checkMediaType(widget.mediaUrl);
  }

  Future<void> _checkMediaType(String url) async {
    if (url.contains(".mp4") || url.contains("alt=media")) {
      setState(() {
        _isVideo = true;
      });
      _initializeVideoPlayer(url);
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeVideoPlayer(String videoUrl) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isLoading = false;
        });
        _videoController!.setLooping(true);
      });
  }

  void _playPauseVideo() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        if (_videoController!.value.isPlaying) {
          _videoController!.pause();
          _isPlaying = false;
        } else {
          _videoController!.play();
          _isPlaying = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> updateviewcount(String userid, String postid, int count) async {
    try {
      await FirebaseFirestore.instance
          .collection('userpost')
          .doc(userid)
          .collection("posts")
          .doc(postid)
          .update({
        "views": count,
      });
    } catch (error) {
      debugPrint("$error");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        width: MediaQuery.of(context).size.width,
        height: 240,
        color: const Color.fromARGB(96, 158, 158, 158),
      );
    }

    return GestureDetector(
      onTap: () {
        if (_isVideo) {
          _playPauseVideo();
          debugPrint("ds");
          int total = 0;

          if (widget.views.isEmpty) {
            total = 1;
            updateviewcount(widget.userid, widget.posid, total);
          } else if (widget.views.isNotEmpty) {
            // Ensure `views` is treated as an int
            int currentViews = int.parse(widget.views);
            int total = currentViews + 1;
            updateviewcount(widget.userid, widget.posid, total);
          }
        }
      },
      onDoubleTap: () {
        if (_isVideo) {
          debugPrint("ds");
          int total = 0;

          if (widget.views.isEmpty) {
            total = 1;
            updateviewcount(widget.userid, widget.posid, total);
          } else if (widget.views.isNotEmpty) {
            // Ensure `views` is treated as an int
            int currentViews = int.parse(widget.views);
            int total = currentViews + 1;
            updateviewcount(widget.userid, widget.posid, total);
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPlayerPage(mediaUrl: widget.mediaUrl),
            ),
          );
        }
      },
      child: Stack(
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            height: 240,
            decoration: const BoxDecoration(color: secondColor),
            child: _isVideo
                ? _videoController != null &&
                        _videoController!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      )
                    : const Center(child: CircularProgressIndicator())
                : Image.network(
                    widget.mediaUrl,
                    fit: BoxFit.cover,
                  ),
          ),
          Positioned(
            top: 90,
            bottom: 90,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _isPlaying ? 0.0 : 1.0, // Fade out when playing
              duration: const Duration(milliseconds: 300),
              child: Container(
                height: 9,
                width: 9,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: secondColor,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause_outlined : Icons.play_arrow_outlined,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
