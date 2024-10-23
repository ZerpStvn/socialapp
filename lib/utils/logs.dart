import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social/utils/globaltheme.dart';
import 'package:social/views/pap.dart';

Future<void> recordlogs(String userID, String logs) async {
  final currentuserid = FirebaseAuth.instance.currentUser!.uid;
  try {
    await FirebaseFirestore.instance
        .collection('userlogs')
        .doc(currentuserid)
        .collection('logs')
        .add({
      'userid': userID,
      'created': Timestamp.now(),
      'logs': logs,
    });
  } catch (error) {
    debugPrint("$error");
  }
}

class MutedPost extends StatelessWidget {
  const MutedPost({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: secondColor,
        automaticallyImplyLeading: true,
        title: const PrimaryText(
          data: "Create Post",
          fcolor: Colors.white,
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Center(
            child: Text(
                textAlign: TextAlign.center,
                "You are currently restricted from posting due to violating our"),
          ),
          Center(
              child: TextButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen()));
            },
            child: const Text(
                textAlign: TextAlign.center, "Privacy and Policy Guidelines"),
          ))
        ],
      ),
    );
  }
}
