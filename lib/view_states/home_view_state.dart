class HomeViewState {

  String? status;
  List<String> peers = [];

  HomeViewState();

  String getStatus() {
    return status ?? "";
  }
}
