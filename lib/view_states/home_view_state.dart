class HomeViewState {

  bool isLoading = false;

  String? status;
  List<String> peers = [];

  HomeViewState();

  String getStatus() {
    return status ?? "";
  }
}
