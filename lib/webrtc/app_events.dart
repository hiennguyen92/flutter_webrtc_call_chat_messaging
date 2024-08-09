// ignore_for_file: constant_identifier_names

enum SocketEvent {
  Connected("connected"),
  Message("message"),
  Disconnected("disconnected"),
  Error("error");

  const SocketEvent(this.type);
  final String type;
}

enum DataConnectionEvent {
  Connection("connection"),
  Open("open"),
  Connecting("connecting"),
  Closed("closed"),
  Closing("closing"),
  Data("data"),
  Binary("binary");

  const DataConnectionEvent(this.type);
  final String type;
}


enum MediaConnectionEvent {
  Connection("connection"),
  Open("open"),
  Connecting("connecting"),
  Closed("closed"),
  Closing("closing");

  const MediaConnectionEvent(this.type);
  final String type;
}