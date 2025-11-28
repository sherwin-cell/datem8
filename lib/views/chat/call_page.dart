import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:datem8/services/cloudinary_service.dart';

class CallPage extends StatefulWidget {
  final String callID;
  final String currentUserID;
  final String otherUserID;
  final String otherUserName;
  final bool isVideoCall;
  final CloudinaryService cloudinaryService;

  const CallPage({
    super.key,
    required this.callID,
    required this.currentUserID,
    required this.otherUserID,
    required this.otherUserName,
    required this.isVideoCall,
    required this.cloudinaryService,
  });

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late Stopwatch _stopwatch;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.isVideoCall
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    return SafeArea(
      child: ZegoUIKitPrebuiltCall(
        appID: 624522157,
        appSign:
            "9e0e20a7f50c97b7487134a23ad3c79b9febe175190e5e4269465ac4f667edc2",
        userID: widget.currentUserID,
        userName: widget.otherUserName,
        callID: widget.callID,
        config: config,
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
            // Don't call defaultAction() here — Zego handles ending the call
            // Just return the duration to the previous screen
            if (mounted) {
              Navigator.pop(context, _stopwatch.elapsed.inSeconds);
            }
          },
        ),
      ),
    );
  }
}
