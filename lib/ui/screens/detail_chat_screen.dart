import 'package:chat_app/config/custom_color.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/chat_services.dart';
import 'package:chat_app/ui/widgets/custom_app_bar.dart';
import 'package:chat_app/ui/widgets/custom_message_card_item.dart';
import 'package:chat_app/ui/widgets/custom_text_field.dart';
import 'package:chat_app/ui/widgets/custom_toast.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/models/api_return_value.dart';

class DetailChatScreen extends StatefulWidget {
  const DetailChatScreen({
    Key? key,
    required this.userMe,
    required this.userReceiver,
  }) : super(key: key);

  final UserModel userMe, userReceiver;

  @override
  _DetailChatScreenState createState() => _DetailChatScreenState();
}

class _DetailChatScreenState extends State<DetailChatScreen> {
  TextEditingController messageController = TextEditingController();

  int myId = 1;

  void hideKeyboard() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        label: widget.userReceiver.fullName,
      ),
      backgroundColor: NeutralColor().offWhite,
      body: buildBody(),
    );
  }

  SafeArea buildBody() {
    return SafeArea(
      top: false,
      child: GestureDetector(
          onTap: () => hideKeyboard(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildListMessage(),
              buildButtonSendMessage(),
            ],
          )),
    );
  }

  Flexible buildListMessage() {
    return Flexible(
        child: StreamBuilder<QuerySnapshot>(
            stream: ChatServices.getListMessages(
                userMe: widget.userMe, userReceiver: widget.userReceiver),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                    itemCount: snapshot.data?.docs.length,
                    physics: BouncingScrollPhysics(),
                    reverse: true,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      print(snapshot.data?.docs[index].data());
                      print(widget.userMe.uid);
                      return Padding(
                          padding: EdgeInsets.only(
                              top: 12, bottom: (index == 0) ? 20 : 0),
                          child: CustomMessageCardItem(
                            chat: ChatModel.fromJson(snapshot.data?.docs[index]
                                .data() as Map<String, dynamic>),
                            isMyMessage: ChatModel.fromJson(
                                        snapshot.data?.docs[index].data()
                                            as Map<String, dynamic>)
                                    .uidSender ==
                                widget.userMe.uid,
                          ));
                    });
              } else if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                // TODO: Handle this error
                return Container();
              }
            }));
  }

  Container buildButtonSendMessage() {
    return Container(
      color: NeutralColor().white,
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {},
            child: Icon(
              Icons.add,
              color: NeutralColor().disabled,
              size: 20,
            ),
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child: CustomTextField(controller: messageController, hintText: ""),
          ),
          SizedBox(
            width: 12,
          ),
          GestureDetector(
            onTap: () async {
              if (messageController.text.trim() != "") {
                DateTime date = DateTime.now();
                // write message for me as sender
                ApiReturnValue<bool> result = await ChatServices.sendMessage(
                    userMe: widget.userMe,
                    userReceiver: widget.userReceiver,
                    chat: ChatModel(
                        message: messageController.text,
                        timestamp: date.millisecondsSinceEpoch.toString(),
                        messageReply: null,
                        uidSender: widget.userMe.uid,
                        uidReceiver: widget.userReceiver.uid));

                // write for receiver
                ChatServices.sendMessage(
                    userMe: widget.userReceiver,
                    userReceiver: widget.userMe,
                    chat: ChatModel(
                        message: messageController.text,
                        timestamp: date.millisecondsSinceEpoch.toString(),
                        messageReply: null,
                        uidSender: widget.userMe.uid,
                        uidReceiver: widget.userReceiver.uid));

                if (result.value!) {
                  // write for me as sender
                  ChatServices.updateLastMessage(
                      userMe: widget.userMe,
                      userReceiver: widget.userReceiver,
                      chat: ChatModel(
                          message: messageController.text,
                          timestamp: date.millisecondsSinceEpoch.toString()));

                  // write for receiver
                  ChatServices.updateLastMessage(
                      userMe: widget.userReceiver,
                      userReceiver: widget.userMe,
                      chat: ChatModel(
                          message: messageController.text,
                          timestamp: date.millisecondsSinceEpoch.toString()));

                  messageController.clear();
                } else {
                  CustomToast.showToast(message: result.message);
                }
              }
            },
            child: ImageIcon(
              AssetImage("assets/icons/icon_send_message.png"),
              color: BrandColor().defaultColor,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}
