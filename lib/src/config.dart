part of hammock;

class UrlRewriter implements Function {
  String baseUrl = "";
  String suffix = "";

  String call(String url) => "$baseUrl$url$suffix";
}

@Injectable()
class HammockConfig {
  Map config = {};
  DocumentFormat documentFormat = new SimpleDocumentFormat();
  dynamic urlRewriter = new UrlRewriter();


  void set(Map config){
    this.config = config;
  }

  String route(resourceType) =>
      _value(resourceType, 'route', () => resourceType);

  deserializer(resourceType) =>
      _value(resourceType, 'deserializer', () => throw "No deserializer for `${resourceType}`");

  serializer(resourceType) =>
      _value(resourceType, 'serializer', () => throw "No serializer for `${resourceType}`");

  updater(resourceType) =>
      _value(resourceType, 'updater', () => _defaultUpdater(resourceType));

  resourceType(objectType) =>
      config.keys.firstWhere(
        (e) => _value(e, "type") == objectType,
        orElse: () => throw "No resource type found for $objectType");

  _value(resourceType, key, [ifAbsent]) {
    if (config.containsKey(resourceType) && config[resourceType].containsKey(key)) {
      return config[resourceType][key];
    } else if (ifAbsent != null) {
      return ifAbsent();
    } else {
      return null;
    }
  }

  _defaultUpdater(resourceType) =>
      (object, resource) => deserializer(resourceType)(resource);
}