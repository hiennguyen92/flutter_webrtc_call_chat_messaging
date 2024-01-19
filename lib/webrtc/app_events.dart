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
  Closed("closed"),
  Data("data"),
  Binary("binary");

  const DataConnectionEvent(this.type);
  final String type;
}