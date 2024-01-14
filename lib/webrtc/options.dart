import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_call_chat_messaging/webrtc/events.dart';

class PeerConnectOption {
  PeerConnectOption(
      {this.label,
      this.metadata,
      this.reliable,
      this.serialization,
      this.payload,
      this.connectionId,
      this.stream,
      this.sdpTransform,
      this.constraints,
      this.originator,
      this.sdp});

  String? connectionId;
  String? label;
  dynamic metadata;
  SerializationType? serialization;
  bool? reliable;
  PeerConnectOption? payload;
  MediaStream? stream;
  Function? sdpTransform;
  Map<String, dynamic>? constraints;
  bool? originator;
  Map<String, dynamic>? sdp;

  PeerConnectOption copyWith(
      {String? connectionId,
      String? label,
      dynamic metadata,
      SerializationType? serialization,
      bool? reliable,
      PeerConnectOption? payload,
      MediaStream? stream,
      Function? sdpTransform,
      Map<String, dynamic>? constraints,
      bool? originator}) {
    return PeerConnectOption(
      connectionId: connectionId ?? this.connectionId,
      label: label ?? this.label,
      metadata: metadata ?? this.metadata,
      serialization: serialization ?? this.serialization,
      reliable: reliable ?? this.reliable,
      payload: payload ?? this.payload,
      stream: stream ?? this.stream,
      sdpTransform: sdpTransform ?? this.sdpTransform,
      constraints: constraints ?? this.constraints,
      originator: originator ?? this.originator,
    );
  }

  factory PeerConnectOption.fromMap(Map<String, dynamic> json) =>
      PeerConnectOption(
        label: json["label"],
        metadata: json["metadata"],
        serialization: json["serialization"] != null
            ? SerializationType.values
                .singleWhere((element) => element.type == json["serialization"])
            : null,
        reliable: json["reliable"],
        sdp: json["sdp"],
        payload: json["payload"] != null
            ? PeerConnectOption.fromMap(json["payload"])
            : null,
        originator: json["originator"],
      );

  Map<String, dynamic> toMap() => {
        "label": label,
        "metadata": metadata,
        "serialization": serialization,
        "reliable": reliable,
        "payload": payload,
        "stream": stream,
        "constraints": constraints,
        "originator": originator,
        "sdp": sdp
      };
}
