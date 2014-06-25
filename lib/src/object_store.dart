part of hammock;

@Injectable()
class ObjectStore {
  ResourceStore resourceStore;
  HammockConfig config;

  ObjectStore(this.resourceStore, this.config);

  ObjectStore scope(obj) =>
      new ObjectStore(resourceStore.scope(_wrapInResource(obj)), config);

  Future one(type, id) {
    final rt = config.resourceType(type);
    final deserialize = config.deserializer(rt);
    return resourceStore.one(rt, id).then(deserialize);
  }

  Future<List> list(type) {
    final rt = config.resourceType(type);
    final deserialize = (list) => list.map(config.deserializer(rt)).toList();
    return resourceStore.list(rt).then(deserialize);
  }

  Future create(object) {
    final res = _wrapInResource(object);
    final deserialize = _deserialize(object);
    return resourceStore.create(res).then(deserialize);
  }

  Future save(object) {
    final res = _wrapInResource(object);
    final deserialize = _deserialize(object);
    return resourceStore.save(res).then(deserialize);
  }

  Future delete(object) {
    final res = _wrapInResource(object);
    final deserialize = _deserialize(object);
    return resourceStore.delete(res).then(deserialize);
  }

  _wrapInResource(object) =>
      config.serializer(config.resourceType(object.runtimeType))(object);

  _deserialize(object) =>
      (resource) => config.updater(resource.type)(object, resource);
}