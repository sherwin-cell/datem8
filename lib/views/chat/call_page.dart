import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallPage extends StatefulWidget {
  final String callID;
  final String userID;
  final String userName;
  final bool isVideoCall;

  const CallPage({
    super.key,
    required this.callID,
    required this.userID,
    required this.userName,
    required this.isVideoCall,
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
    // When page is disposed, pop with elapsed time
    Navigator.pop(context, _stopwatch.elapsed.inSeconds);
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
        userID: widget.userID,
        userName: widget.userName,
        callID: widget.callID,
        config: config,
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
            defaultAction(); // execute default behaviour (pop by default)
            // We already have elapsed time via stopwatch
          },
        ),
      ),
    );
  }
}
