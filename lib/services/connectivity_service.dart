import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity =
      Connectivity();

  Future<bool> hasInternet() async {
    final result =
        await _connectivity.checkConnectivity();

    return !result.contains(
      ConnectivityResult.none,
    );
  }

  Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged
        .map(
      (results) =>
          !results.contains(
        ConnectivityResult.none,
      ),
    );
  }
}
