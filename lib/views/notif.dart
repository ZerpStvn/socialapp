import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social/utils/globaltheme.dart';
import 'package:social/views/profile.dart';

class ShowNotification extends StatefulWidget {
  const ShowNotification({super.key});

  @override
  State<ShowNotification> createState() => _ShowNotificationState();
}

class _ShowNotificationState extends State<ShowNotification> {
  final User? user = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> usersNotifData = [];

  Future<void> _displayNotif() async {
    try {
      QuerySnapshot userDocs = await FirebaseFirestore.instance
          .collection('notif')
          .doc(user!.uid)
          .collection('datanot')
          .get();
      debugPrint("User notifications found: ${userDocs.docs.length}");

      for (var doc in userDocs.docs) {
        String userID = doc['whonotif'];
        String type = doc['type'];
        String title = doc['title'] ?? "No title available"; // Default value
        debugPrint("User notifications found for: $userID");

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userID)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic>? userData =
              userDoc.data() as Map<String, dynamic>?;
          userData!['id'] = userID; // Add userID to the user data
          userData['title'] = title; // Add the notification title to user data
          usersNotifData.add(userData);
          debugPrint("User data added: $userData");
        } else {
          debugPrint("No user data found for $userID");
        }
      }

      setState(() {});
    } catch (error) {
      debugPrint("Error fetching data: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    _displayNotif();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
      ),
      body: usersNotifData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: usersNotifData.length,
              itemBuilder: (context, index) {
                final notification =
                    usersNotifData[index]; // Get notification data
                if (notification['type'] != 'chat') {
                  return ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              UserProfile(userID: notification['id']),
                        ),
                      );
                    },
                    leading: CircleAvatar(
                      foregroundColor: secondColor,
                      foregroundImage:
                          NetworkImage(notification['profileImage'] ?? ''),
                    ),
                    title: Text("${notification['name']}"),
                    subtitle: Text("${notification['title']}"),
                    trailing: const Icon(Icons.arrow_right_outlined),
                  );
                } else {
                  return Container();
                }
              },
            ),
    );
  }
}
