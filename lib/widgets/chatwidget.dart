import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:social/utils/globaltheme.dart';

class Message {
  final String senderId;
  final String message;
  final bool isSending;

  Message({
    required this.senderId,
    required this.message,
    this.isSending = false,
  });
}

class ChatWidget extends StatefulWidget {
  final String recieverID;
  const ChatWidget({
    super.key,
    required this.recieverID,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _messageController = TextEditingController();
  final List<Message> _messages = [];
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    fetchMessages();
    _fetchUserData();
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

  Future<void> fetchchatsavailable() async {}

  Future<void> fetchMessages() async {
    List<String> ids = [widget.recieverID, user!.uid];
    ids.sort();
    String chatDocId = ids.join("_");

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatDocId)
          .collection('messages')
          .orderBy("time")
          .get();

      final messages = snapshot.docs.map((doc) {
        return Message(
          senderId: doc["sender"],
          message: doc["message"],
          isSending: false,
        );
      }).toList();

      setState(() {
        _messages.addAll(messages);
      });
    } catch (error) {
      debugPrint("Error fetching messages: $error");
    }
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final message = Message(
        senderId: user!.uid,
        message: _messageController.text,
        isSending: true,
      );

      setState(() {
        _messages.add(message);
        _messageController.clear();
      });

      await sendMessage(message);
    }
  }

  Future<void> sendMessage(Message message) async {
    try {
      List<String> ids = [user!.uid, widget.recieverID];
      ids.sort();
      String chatDocId = ids.join("_");
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatDocId)
          .collection('messages')
          .add({
        "sender": message.senderId,
        "receiver": widget.recieverID,
        "message": message.message,
        "time": Timestamp.now(),
      });

      setState(() {
        _messages[_messages.length - 1] = Message(
          senderId: message.senderId,
          message: message.message,
          isSending: false,
        );
      });
    } catch (error) {
      debugPrint("Error sending message: $error");
    }
  }

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isSender = message.senderId == user!.uid;

                return Align(
                  alignment:
                      isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSender ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.message,
                          style: const TextStyle(fontSize: 16),
                        ),
                        // Show a loading indicator if the message is sending
                        if (message.isSending)
                          const Padding(
                            padding: EdgeInsets.only(top: 5),
                            child: Text(
                              "sending",
                              style: TextStyle(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          userData != null
              ? userData!['ismute'] == 0
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 4.0),
                      child: Row(
                        children: [
                          // Text Input Field
                          Expanded(
                            child: TextFormField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Type a message...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: _sendMessage,
                          ),
                        ],
                      ),
                    )
                  : Container(
                      width: MediaQuery.of(context).size.width,
                      height: 40,
                      color: secondColor,
                      child: const Center(
                          child: Text(
                        "You're currently muted",
                        style: TextStyle(color: Colors.white),
                      )),
                    )
              : Container(),
        ],
      ),
    );
  }
}
