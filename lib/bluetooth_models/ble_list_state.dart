import 'package:crmx_timotwo_example_app/models/device.dart';
import 'package:equatable/equatable.dart';

enum ListStatus { loading, success, failure, deviceAlreadyConnected }

class BleListState extends Equatable {
  const BleListState._({
    this.status = ListStatus.loading,
    this.item,
  });
  const BleListState.loading() : this._();

  const BleListState.success(Device item)
      : this._(status: ListStatus.success, item: item);

  const BleListState.failure() : this._(status: ListStatus.failure);
  const BleListState.deviceAlreadyConnected(Device item)
      : this._(status: ListStatus.deviceAlreadyConnected, item: item);

  final ListStatus status;
  final Device? item;

  @override
  List<Object?> get props => [status, item];
}
