import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:social/controller/searchuser.dart';
import 'package:social/utils/globaltheme.dart';
import 'package:social/views/profile.dart';
import 'package:social/widgets/chatwidget.dart';
import 'package:social/widgets/homeapp.dart';

class ChatSystem extends StatefulWidget {
  const ChatSystem({super.key});

  @override
  State<ChatSystem> createState() => _ChatSystemState();
}

class _ChatSystemState extends State<ChatSystem> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> userFollowingList = [];

  Future<void> _displayFollowing() async {
    try {
      userFollowingList.clear();
      QuerySnapshot userDocs = await FirebaseFirestore.instance
          .collection('follows')
          .doc(user!.uid)
          .collection('following')
          .get();

      for (var doc in userDocs.docs) {
        String userID = doc.id;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userID)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic>? userData =
              userDoc.data() as Map<String, dynamic>?;
          userData!['id'] = userID;
          userFollowingList.add(userData);
        } else {
          debugPrint("No user data found for $userID");
        }
      }

      // Fetch the latest message for each user and unread count
      await _fetchLatestMessages();
      setState(() {});
    } catch (error) {
      debugPrint("Error fetching data: $error");
    }
  }

  Future<void> _fetchLatestMessages() async {
    for (var ruser in userFollowingList) {
      String recieverID = ruser['id'];
      List<String> ids = [recieverID, user!.uid];
      ids.sort();
      String chatDocId = ids.join("_");

      try {
        // Get the latest message
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatDocId)
            .collection('messages')
            .orderBy("time", descending: true)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          var latestMessage = snapshot.docs.first;
          ruser['latestMessage'] = latestMessage['message'];
          ruser['latestMessageTime'] = latestMessage['time'];
        } else {
          // Assign default values for users without messages
          ruser['latestMessage'] = "No messages yet";
          ruser['latestMessageTime'] = DateTime(1970); // Placeholder date
        }

        // Fetch all messages and manually filter unread messages
        QuerySnapshot unreadSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(chatDocId)
            .collection('messages')
            .get();

        int unreadCount = 0;

        for (var doc in unreadSnapshot.docs) {
          if (doc['isRead'] == false && doc['receiver'] == user!.uid) {
            unreadCount++;
          }
        }

        ruser['unreadCount'] = unreadCount;
      } catch (error) {
        debugPrint("Error fetching latest messages: $error");
        // Ensure users without messages are initialized
        ruser['latestMessage'] ??= "No messages yet";
        ruser['latestMessageTime'] ??= DateTime(1970);
        ruser['unreadCount'] ??= 0;
      }
    }

    // Sort the userFollowingList by latest message time
    userFollowingList.sort((a, b) {
      var timeA = a['latestMessageTime'] ?? DateTime(1970);
      var timeB = b['latestMessageTime'] ?? DateTime(1970);
      return timeB.compareTo(timeA); // Latest messages first
    });

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _displayFollowing();
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
            userData = userDoc.data() as Map<String, dynamic>?;
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
          "Messages",
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
      body: RefreshIndicator(
        onRefresh: _displayFollowing,
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: userFollowingList.length,
          itemBuilder: (context, index) {
            final user = userFollowingList[index];
            final userID = user['id'];
            final unreadCount = user['unreadCount'] ?? 0;

            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfile(userID: userID),
                  ),
                );
              },
              trailing: IconButton(
                onPressed: () async {
                  await markMessagesAsRead(userID);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ChatWidget(
                                recieverID: userID,
                              )));
                },
                icon: const Icon(Icons.chat_bubble_outline),
              ),
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(user['profileImage'] ?? ''),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text(user['name'] ?? 'Unknown'),
              subtitle: Text(
                "message: ${user['latestMessage']}",
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> markMessagesAsRead(String receiverID) async {
    List<String> ids = [receiverID, user!.uid];
    ids.sort();
    String chatDocId = ids.join("_");

    try {
      // Fetch unread messages for the current user
      QuerySnapshot unreadSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatDocId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .where('receiver', isEqualTo: user!.uid)
          .get();

      // Update each message's isRead field to true
      for (var doc in unreadSnapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (error) {
      debugPrint("Error marking messages as read: $error");
    }
  }
}
