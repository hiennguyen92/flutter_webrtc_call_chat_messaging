// ignore_for_file: constant_identifier_names

enum ConnectionType {
  Data("data"),
  Media("media");

  const ConnectionType(this.type);
  final String type;
}

enum SocketEventType {
  Message("message"),
  Disconnected("disconnected"),
  Error("error");

  const SocketEventType(this.type);
  final String type;
}

enum MessageType {
  Heartbeat("HEARTBEAT"),
  Candidate("CANDIDATE"),
  Offer("OFFER"),
  Answer("ANSWER"),
  Open("OPEN"), // The connection to the server is open.
  Error("ERROR"), // Server error.
  IdTaken("ID-TAKEN"), // The selected ID is taken.
  InvalidKey("INVALID-KEY"), // The given API key cannot be found.
  Leave("LEAVE"), // Another peer has closed its connection to this peer.
  Expire("EXPIRE"); // The offer sent to a peer has expired without response.

  const MessageType(this.type);
  final String type;
}

enum APIType {
  Error("error");

  const APIType(this.type);
  final String type;
}

enum SerializationType {
  Binary("binary"),
  JSON("json");

  const SerializationType(this.type);
  final String type;
}

enum DataChannels { binary, data }
