part of hammock;

class HammockUrlRewriter implements UrlRewriter {
  String baseUrl = "";
  String suffix = "";
  String call(String url) => "$baseUrl$url$suffix";
}

@Injectable()
class HammockConfig {
  Map config = {};
  DocumentFormat documentFormat = new SimpleDocumentFormat();
  dynamic urlRewriter = new HammockUrlRewriter();

  final Injector injector;
  HammockConfig(this.injector);

  void set(Map config){
    this.config = config;
  }

  String route(resourceType) =>
      _value([resourceType, 'route'], () => resourceType);

  deserializer(resourceType, [List path=const[]]) =>
      _load(_value([resourceType, 'deserializer']..addAll(path)));

  serializer(resourceType) =>
      _load(_value([resourceType, 'serializer'], () => throw "No serializer for `${resourceType}`"));

  resourceType(objectType) =>
      config.keys.firstWhere(
        (e) => _value([e, "type"]) == objectType,
        orElse: () => throw "No resource type found for $objectType");

  _value(List path, [ifAbsent=_null]) {
    path = path.where((_) => _ != null).toList();

    var current = config;
    for(var i = 0; i < path.length; ++i) {
      if( current is! Map ) break;
      if (current.containsKey(path[i])) {
        current = current[path[i]];
      } else {
        current = null;
      }
    }

    return current == null ? ifAbsent() : current;
  }

  _defaultUpdater(resourceType) =>
      (object, resource) => deserializer(resourceType)(resource);

  _load(obj) =>
      (obj is Type) ? injector.get(obj) : obj;
}

_null() => null;