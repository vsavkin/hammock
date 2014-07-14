library hammock;

import 'package:angular/angular.dart';
import 'dart:async';
import 'hammock_core.dart';
export 'hammock_core.dart';

part 'src/resource_store.dart';
part 'src/config.dart';
part 'src/custom_request_params.dart';
part 'src/object_store.dart';
part 'src/utils.dart';

class Hammock extends Module {
  Hammock() {
    bind(HammockConfig);
    bind(ResourceStore);
    bind(ObjectStore);
  }
}