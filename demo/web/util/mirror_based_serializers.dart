library mirror_based_serializers;

import 'dart:mirrors';
import 'package:hammock/hammock.dart';

serializer(type, attrs) {
  return (obj) {
    final m = reflect(obj);

    final id = m.getField(#id).reflectee;
    final content = attrs.fold({}, (res, attr) {
      res[attr] = m.getField(new Symbol(attr)).reflectee;
      return res;
    });

    return resource(type, id, content);
  };
}

deserializer(type, attrs) {
  return (r) {
    final params = attrs.fold([], (res, attr) => res..add(r.content[attr]));
    return reflectClass(type).newInstance(const Symbol(''), params).reflectee;
  };
}