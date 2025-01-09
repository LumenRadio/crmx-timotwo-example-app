import 'package:crmx_timotwo_example_app/models/mode_notifier.dart';
import 'package:crmx_timotwo_example_app/repository/bluetooth_repository.dart';

class RepositoryBluetoothSingleton {
  static final RepositoryBluetoothSingleton _singleton =
      RepositoryBluetoothSingleton._internal();

  BluetoothRepository? _bluetoothRepository;

  get getBluetoothRepository => _bluetoothRepository;

  factory RepositoryBluetoothSingleton() {
    _singleton._bluetoothRepository ??= BluetoothRepository(ModeNotifier());

    return _singleton;
  }

  RepositoryBluetoothSingleton._internal();
}
