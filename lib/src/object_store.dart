part of hammock;

typedef CommandDeserializer(obj, resp);

@Injectable()
class ObjectStore {
  ResourceStore resourceStore;
  HammockConfig config;

  ObjectStore(this.resourceStore, this.config);

  ObjectStore scope(obj) =>
      new ObjectStore(resourceStore.scope(_wrapInResource(obj)), config);


  Future one(type, id)  =>
      _resourceQueryOne(type, (rt) => resourceStore.one(rt, id));

  Future<List> list(type, {Map params}) =>
      _resourceQueryList(type, (rt) => resourceStore.list(rt, params: params));

  Future customQueryOne(type, CustomRequestParams params) =>
      _resourceQueryOne(type, (rt) => resourceStore.customQueryOne(rt, params));

  Future<List> customQueryList(type, CustomRequestParams params) =>
      _resourceQueryList(type, (rt) => resourceStore.customQueryList(rt, params));


  Future create(object) =>
      _resourceStoreCommand(object, resourceStore.create);

  Future update(object) =>
      _resourceStoreCommand(object, resourceStore.update);

  Future delete(object) =>
      _resourceStoreCommand(object, resourceStore.delete);

  Future customCommand(object, CustomRequestParams params) =>
      _resourceStoreCommand(object, (res) => resourceStore.customCommand(res, params));


  _resourceQueryOne(type, function) {
    final rt = config.resourceType(type);
    final deserialize = config.deserializer(rt, ['query']);
    return function(rt).then(deserialize);
  }

  _resourceQueryList(type, function) {
    final rt = config.resourceType(type);
    deserialize(list) => _wrappedListIntoFuture(list.map(config.deserializer(rt, ['query'])).toList());
    return function(rt).then(deserialize);
  }

  _resourceStoreCommand(object, function) {
    final res = _wrapInResource(object);
    final p = _parseSuccessCommandResponse(res, object);
    final ep = _parseErrorCommandResponse(res, object);
    return function(res).then(p, onError: ep);
  }

  _wrapInResource(object) =>
      config.serializer(config.resourceType(object.runtimeType))(object);

  _parseSuccessCommandResponse(res, object) =>
      _commandResponse(res, object, ['command', 'success']);

  _parseErrorCommandResponse(res, object) =>
      (resp) => _wrappedIntoErrorFuture(_commandResponse(res, object, ['command', 'error'])(resp));

  _commandResponse(res, object, path) {
    final d = config.deserializer(res.type, path);
    if (d == null) {
      return (resp) => resp;
    } else if (d is CommandDeserializer) {
      return (resp) => d(object, resp);
    } else {
      return (resp) => d(resource(res.type, res.id, resp.content));
    }
  }

}