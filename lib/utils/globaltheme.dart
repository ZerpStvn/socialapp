//
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Primary Text
class PrimaryText extends StatelessWidget {
  final double? fsize;
  final FontWeight? fw;
  final String data;
  final Color? fcolor;
  final TextAlign? falign;

  const PrimaryText({
    super.key,
    this.fsize,
    this.fw,
    required this.data,
    this.fcolor,
    this.falign,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: falign,
      style: GoogleFonts.poppins(
        color: fcolor ?? Colors.black,
        fontWeight: fw,
        fontSize: fsize,
      ),
    );
  }
}

// Color

const maincolor = Color(0xffC96868);

const secondColor = Color(0xff4338CA);

const primarycolor = Color(0xffEBC900);

// Button
class GlobalButton extends StatelessWidget {
  final Function callback;
  final String title;
  const GlobalButton({super.key, required this.callback, required this.title});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: primarycolor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
        onPressed: () {
          callback();
        },
        child: PrimaryText(
          data: title,
          fcolor: Colors.white,
        ));
  }
}

Future<void> upplynotifcation(String useownid, String ownnotif, String type,
    String title, String? postid) async {
  try {
    await FirebaseFirestore.instance
        .collection('notif')
        .doc(useownid)
        .collection('datanot')
        .add({
      "userownid": useownid,
      'whonotif': ownnotif,
      'type': type,
      'created': Timestamp.now(),
      'title': title,
      'postid': postid ?? "",
    });
  } catch (error) {
    debugPrint("$error");
  }
}

String formatTimestamp1(DateTime? timestamp) {
  if (timestamp == null) return 'Unknown'; // Handle null timestamp

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sentDate = DateTime(timestamp.year, timestamp.month, timestamp.day);

  if (sentDate == today) {
    // Sent today
    return DateFormat('h:mm a').format(timestamp); // Format as 3:00 AM
  } else if (now.difference(timestamp).inHours < 24) {
    // Sent within the last 24 hours
    return DateFormat('MMM. d h:mm a')
        .format(timestamp); // Format as Apr. 20 3:00 AM
  } else {
    // Sent more than 24 hours ago
    return DateFormat('MMM. d, yyyy h:mm a')
        .format(timestamp); // Format as Apr. 20, 2023 3:00 AM
  }
}
