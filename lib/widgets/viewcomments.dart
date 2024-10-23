import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social/controller/searchuser.dart';
import 'package:social/utils/globaltheme.dart';
import 'package:social/utils/logs.dart';
import 'package:social/widgets/homeapp.dart';

class ViewCommentSection extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String postID;
  const ViewCommentSection({super.key, this.userData, required this.postID});

  @override
  State<ViewCommentSection> createState() => _ViewCommentSectionState();
}

class _ViewCommentSectionState extends State<ViewCommentSection> {
  Set<String> likedComments = {};
  Map<String, int> commentLikeCounts = {};
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController usercomment = TextEditingController();
  final String currentUserID = FirebaseAuth.instance.currentUser!.uid;
  Map<String, dynamic>? userData;
  Future<void> _fetchLikedComments(String postID) async {
    try {
      QuerySnapshot likedCommentSnapshot = await FirebaseFirestore.instance
          .collection('comment')
          .doc(postID)
          .collection('comments')
          .get();

      Set<String> tempLikedComments = {};
      Map<String, int> tempCommentLikeCounts = {};

      for (var commentDoc in likedCommentSnapshot.docs) {
        String commentID = commentDoc.id;

        DocumentSnapshot likedDoc = await FirebaseFirestore.instance
            .collection('likedcomment')
            .doc(commentID)
            .collection('likecomemntcount')
            .doc(currentUserID)
            .get();

        if (likedDoc.exists) {
          tempLikedComments.add(commentID);
        }

        QuerySnapshot likeCountSnapshot = await FirebaseFirestore.instance
            .collection('likedcomment')
            .doc(commentID)
            .collection('likecomemntcount')
            .get();

        tempCommentLikeCounts[commentID] = likeCountSnapshot.docs.length;
      }

      setState(() {
        likedComments = tempLikedComments;
        commentLikeCounts = tempCommentLikeCounts;
      });
    } catch (e) {
      debugPrint('Error fetching liked comments: $e');
    }
  }

  Future<void> submitcomment(String postId) async {
    await FirebaseFirestore.instance
        .collection('comment')
        .doc(postId)
        .collection('comments')
        .add({
      'username': userData!['name'],
      'userprofile': userData!['profileImage'],
      'userid': userData!['userid'],
      'postid': postId,
      'comment': usercomment.text,
      'created': Timestamp.now(),
    });
    setState(() {
      usercomment.clear();
    });
    recordlogs(postId, "User comment to a post");
  }

  Future<void> addlikecomment(String commentID, String postID) async {
    if (likedComments.contains(commentID)) {
      await FirebaseFirestore.instance
          .collection('likedcomment')
          .doc(commentID)
          .collection('likecomemntcount')
          .doc(currentUserID)
          .delete();
      likedComments.remove(commentID);
    } else {
      // Like the comment
      await FirebaseFirestore.instance
          .collection('likedcomment')
          .doc(commentID)
          .collection('likecomemntcount')
          .doc(currentUserID)
          .set({
        'likes': 1,
        'userid': currentUserID,
      });
      likedComments.add(commentID);
    }

    await _fetchLikedComments(postID);

    setState(() {});
  }

  Future<void> _fetchUserData() async {
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>;
            userData!['id'] = userDoc.id;
          });
        } else {
          debugPrint('No such user data in Firestore');
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 2,
        title: Text(
          "Socials",
          style: GoogleFonts.dancingScript(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 35),
        ),
        actions: [
          HomeAppBar(userData: userData),
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SearchuserForm()));
              },
              icon: const Icon(Icons.search)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(0.0),
                    child: Column(
                      children: [
                        StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('comment')
                                .doc(widget.postID)
                                .collection('comments')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const LinearProgressIndicator();
                              } else if (!snapshot.hasData) {
                                return Container();
                              } else {
                                return ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: snapshot.data!.docs.length,
                                    itemBuilder: (context, index) {
                                      var getcommentdata =
                                          snapshot.data!.docs[index].data();
                                      var commentdataID =
                                          snapshot.data!.docs[index].id;

                                      bool isLiked =
                                          likedComments.contains(commentdataID);
                                      int likeCount =
                                          commentLikeCounts[commentdataID] ?? 0;

                                      return ListTile(
                                        leading: CircleAvatar(
                                          maxRadius: 15,
                                          backgroundImage: NetworkImage(
                                              getcommentdata['userprofile']),
                                        ),
                                        title: Text(
                                          "${getcommentdata['username']}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        subtitle: Text(
                                          "${getcommentdata['comment']}",
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              '$likeCount', // Display like count
                                              style:
                                                  const TextStyle(fontSize: 12),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                addlikecomment(commentdataID,
                                                    widget.postID);
                                                setState(() {});
                                              },
                                              icon: Icon(
                                                isLiked
                                                    ? Icons.favorite
                                                    : Icons.favorite_outline,
                                                size: 14,
                                                color:
                                                    isLiked ? Colors.red : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    });
                              }
                            }),
                      ],
                    ),
                  ),
                ),
                userData != null
                    ? userData!['ismute'] != 1
                        ? Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: TextFormField(
                              controller: usercomment,
                              decoration: InputDecoration(
                                labelText: 'Write a comment...',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    Icons.send,
                                    color: usercomment.text.isNotEmpty
                                        ? secondColor
                                        : Colors.grey,
                                  ),
                                  onPressed: () {
                                    if (usercomment.text.isNotEmpty) {
                                      submitcomment(widget.postID);
                                    }
                                  },
                                ),
                              ),
                            ),
                          )
                        : Container()
                    : const Center(
                        child: CircularProgressIndicator(),
                      ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchLikedComments(widget.postID);
    _fetchUserData();
  }

  @override
  void dispose() {
    super.dispose();
    usercomment.dispose();
  }
}
