// ignore_for_file: constant_identifier_names

enum AppEvent {
  Connected("connected"),
  Disconnected("disconnected"),
  Error("error");

  const AppEvent(this.type);
  final String type;
}