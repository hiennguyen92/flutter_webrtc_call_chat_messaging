class HomeViewState {

  String? displayName;
  String? status;

  List<String> peers = [];
  List<dynamic> users = [];

  HomeViewState();

  String getStatus() {
    return status ?? "None";
  }

  bool hasDisplayName() {
    return displayName != null && displayName!.isNotEmpty;
  }

}
