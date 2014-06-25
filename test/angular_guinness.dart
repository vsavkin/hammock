library angular_guinness;

import 'package:angular/angular.dart';
import 'package:angular/mock/module.dart';
import 'package:hammock/hammock.dart';
import 'package:guinness/guinness.dart' as gns;

export 'package:guinness/guinness.dart';
export 'package:unittest/unittest.dart' hide expect;
export 'package:hammock/hammock.dart';
export 'package:angular/angular.dart';
export 'package:angular/mock/module.dart';


void describe(String name, Function fn) {
  gns.describe(name, () {
    describeBody(fn);
  });
}

void ddescribe(String name, Function fn) {
  gns.ddescribe(name, () {
    describeBody(fn);
  });
}

void beforeEach(Function fn) {
  gns.beforeEach(_injectify(fn));
}

void afterEach(Function fn) {
  gns.afterEach(_injectify(fn));
}

void it(String name, Function fn) {
  gns.it(name, _injectify(fn));
}

void iit(String name, Function fn) {
  gns.iit(name, _injectify(fn));
}

void xit(String name, Function fn) {
  gns.xit(name, _injectify(fn));
}

describeBody(fn) {
  gns.beforeEach(setUpInjector);
  gns.afterEach(tearDownInjector);
  gns.beforeEach(module((Module m) => m.install(new Hammock())));

  fn();
}
_injectify(Function fn) => async(inject(fn));