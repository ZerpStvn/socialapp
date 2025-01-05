import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social/utils/globaltheme.dart';
import 'package:social/views/photoview.dart';
import 'package:social/views/profile.dart';
import 'package:social/widgets/hashtag.dart';
import 'package:social/widgets/mediaplayer.dart';
import 'package:social/widgets/morevert.dart';
import 'package:social/widgets/viewcomments.dart';

class UsersPostFeed extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const UsersPostFeed({super.key, this.userData});

  @override
  State<UsersPostFeed> createState() => _UsersPostFeedState();
}

class _UsersPostFeedState extends State<UsersPostFeed> {
  final String currentUserID = FirebaseAuth.instance.currentUser!.uid;
  List<DocumentSnapshot> userPosts = [];
  bool isReposting = false;
  List<Map<String, dynamic>> followedUserData = [];
  Set<String> likedPosts = {};
  bool isCommentOpen = false;
  String isPostComment = "";
  Map<String, int> postLikeCounts = {};

  @override
  void initState() {
    super.initState();
    _fetchLikedPosts(); // Fetch liked posts on init
  }

  Stream<List<DocumentSnapshot>> _fetchFollowedUsersPosts() {
    return FirebaseFirestore.instance
        .collection('follows')
        .doc(currentUserID)
        .collection('following')
        .snapshots()
        .asyncMap((followingSnapshot) async {
      List<String> followedUserIDs =
          followingSnapshot.docs.map((doc) => doc.id).toList();

      List<DocumentSnapshot> allUserPosts = [];
      followedUserData = [];

      for (String followedUserID in followedUserIDs) {
        QuerySnapshot postSnapshot = await FirebaseFirestore.instance
            .collection('userpost')
            .doc(followedUserID)
            .collection('posts')
            .get();

        DocumentSnapshot followedUserDataDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(followedUserID)
            .get();

        allUserPosts.addAll(postSnapshot.docs);
        followedUserData
            .add(followedUserDataDoc.data() as Map<String, dynamic>);
      }

      // Manually sort posts by createdAt timestamp in descending order
      allUserPosts.sort((a, b) {
        Timestamp timestampA = a['createdAt'] ?? Timestamp(0, 0);
        Timestamp timestampB = b['createdAt'] ?? Timestamp(0, 0);
        return timestampB.compareTo(timestampA);
      });

      return allUserPosts;
    });
  }

  Future<void> _fetchLikedPosts() async {
    try {
      QuerySnapshot likedSnapshot =
          await FirebaseFirestore.instance.collectionGroup('userslike').get();
      likedPosts.clear();
      postLikeCounts.clear();

      for (var doc in likedSnapshot.docs) {
        if (doc['userID'] == currentUserID) {
          likedPosts.add(doc['postID'] as String);
        }

        setState(() {
          String postId = doc['postID'];
          postLikeCounts[postId] = (postLikeCounts[postId] ?? 0) + 1;
        });
      }
    } catch (e) {
      debugPrint('Error fetching liked posts: $e');
    }
  }

  Future<void> userPostLiked(String postId) async {
    if (likedPosts.contains(postId)) {
      await FirebaseFirestore.instance
          .collection('liked')
          .doc(postId)
          .collection('userslike')
          .doc(currentUserID)
          .delete();
      likedPosts.remove(postId);
    } else {
      await FirebaseFirestore.instance
          .collection('liked')
          .doc(postId)
          .collection('userslike')
          .doc(currentUserID)
          .set({
        'userID': currentUserID,
        'liked': Timestamp.now(),
        'postID': postId,
      });
      likedPosts.add(postId);
    }

    await _fetchLikedPosts();
    setState(() {});
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

  Future<String> checkcommentcount(String postid) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('comments')
          .doc(postid)
          .collection('comments')
          .get();
      return "${querySnapshot.docs.length + 1}";
    } catch (e) {
      debugPrint('Error checking comment count: $e');
      return "0";
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _fetchFollowedUsersPosts();
        });
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // const GetFollowingStory(),
            StreamBuilder<List<DocumentSnapshot>>(
              stream: _fetchFollowedUsersPosts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: LinearProgressIndicator());
                }

                userPosts = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: userPosts.length,
                  itemBuilder: (context, index) {
                    var postData =
                        userPosts[index].data() as Map<String, dynamic>;
                    var postID = userPosts[index].id;

                    if (postData['type'] != 'story') {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: FutureBuilder(
                                future: FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(postData['userID'])
                                    .get(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) {
                                    return Container();
                                  } else {
                                    var userData = snapshot.data!.data();
                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        UserProfile(
                                                            userID: postData[
                                                                'userID']),
                                                  ),
                                                );
                                              },
                                              child: CircleAvatar(
                                                foregroundImage: NetworkImage(
                                                    '${userData!['profileImage']}'),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Text("${userData['name']}"),
                                          ],
                                        ),
                                        morevertOption(postData['userID'],
                                            context, postData, postID)
                                      ],
                                    );
                                  }
                                }),
                          ),
                          postData['mediaType'] == 'video'
                              ? MediaPost(
                                  mediaUrl: postData['imageUrl'],
                                  posid: postID,
                                  userid: postData['userID'],
                                  views: postData['views'].toString(),
                                )
                              : GestureDetector(
                                  onTap: () {
                                    int total = 0;

                                    if (postData['views'] == null) {
                                      total = 1;
                                      updateviewcount(
                                          postData['userID'], postID, total);
                                    } else if (postData['views'] != null) {
                                      // Ensure `views` is treated as an int
                                      int currentViews =
                                          postData['views'] is int
                                              ? postData['views']
                                              : int.parse(postData['views']);
                                      int total = currentViews + 1;

                                      updateviewcount(
                                          postData['userID'], postID, total);
                                    }
                                    debugPrint(postID);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MyImageView(
                                            imageUrl: postData['imageUrl']),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height: 230,
                                    decoration: BoxDecoration(
                                        image: DecorationImage(
                                            fit: BoxFit.cover,
                                            image: NetworkImage(
                                                postData['imageUrl']))),
                                  ),
                                ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: RichText(
                              text: TextSpan(
                                children: buildDescriptionWithHashtags(
                                    postData['description']),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                  onPressed: () {
                                    userPostLiked(postID);
                                    upplynotifcation(
                                        postData['userID'],
                                        currentUserID,
                                        "like",
                                        "Like your post",
                                        postID);
                                    debugPrint("${postData['userID']}");
                                  },
                                  icon: Icon(
                                    likedPosts.contains(postID)
                                        ? Icons.favorite
                                        : Icons.favorite_outline,
                                    color: likedPosts.contains(postID)
                                        ? Colors.red
                                        : null,
                                  )),
                              const SizedBox(width: 3),
                              Text(
                                '${postLikeCounts[postID] ?? ''}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                      onPressed: () {
                                        setState(() {
                                          isPostComment = postID;
                                        });
                                        if (isPostComment == postID) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ViewCommentSection(
                                                ownpost: postData['userID'],
                                                postID: postID,
                                                userData: widget.userData,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.comment_outlined)),
                                  FutureBuilder<String>(
                                    future: checkcommentcount(
                                        postID), // Call your async function
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Text(
                                            ""); // Show nothing or a placeholder while waiting
                                      } else if (snapshot.hasError) {
                                        return Text(
                                            "Error"); // Handle any error
                                      } else if (snapshot.hasData) {
                                        return Text(snapshot
                                            .data!); // Display the comment count
                                      } else {
                                        return Text(
                                            ""); // Display nothing if the count is 0
                                      }
                                    },
                                  ),
                                ],
                              ),
                              isReposting != true
                                  ? IconButton(
                                      onPressed: () {
                                        repostBtn(
                                            '${postData['description']}',
                                            '${postData['imageUrl']}',
                                            'post',
                                            '${postData['userID']}',
                                            '${postData['mediaType']}',
                                            int.parse(postData['views']));
                                        upplynotifcation(
                                            postData['userID'],
                                            currentUserID,
                                            "rpost",
                                            "User reposted your post",
                                            postID);
                                        debugPrint("${postData['userID']}");
                                      },
                                      icon:
                                          const Icon(Icons.autorenew_outlined))
                                  : const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator()),
                              postData['views'] != null
                                  ? Row(
                                      children: [
                                        const Icon(Icons.visibility_outlined),
                                        const SizedBox(width: 3),
                                        Text("${postData['views'] ?? 0}")
                                      ],
                                    )
                                  : Container(),
                            ],
                          ),
                        ],
                      );
                    } else {
                      return Container();
                    }
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> repostBtn(String des, String imgUrl, String type, String userId,
      String mediatype, int viewscount) async {
    setState(() {
      isReposting = true;
    });
    try {
      await FirebaseFirestore.instance
          .collection('repost')
          .doc(currentUserID)
          .collection('reposted')
          .add({
        'userID': userId,
        'description': des,
        'imageUrl': imgUrl,
        'mediaType': mediatype,
        'type': type,
        'views': viewscount,
        'createdAt': FieldValue.serverTimestamp(),
      });
      setState(() {
        isReposting = false;
      });
    } catch (error) {
      debugPrint("error: $error");
      setState(() {
        isReposting = false;
      });
    }
  }

  // void showBottomSheetComment(String postID) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       return DraggableScrollableSheet(
  //         initialChildSize: 0.75,
  //         minChildSize: 0.5,
  //         maxChildSize: 1.0,
  //         builder: (context, scrollController) {
  //           return Container(
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.only(
  //                 topLeft: Radius.circular(20),
  //                 topRight: Radius.circular(20),
  //               ),
  //             ),
  //             child: ViewCommentSection(
  //               postID: postID,
  //               userData: widget.userData,
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
}
