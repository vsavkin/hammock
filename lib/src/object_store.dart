part of hammock;

typedef CommandDeserializer(obj, resp);

@Injectable()
class ObjectStore {
  ResourceStore resourceStore;
  HammockConfig config;

  ObjectStore(this.resourceStore, this.config);

  ObjectStore scope(obj) =>
      new ObjectStore(resourceStore.scope(_wrapInResource(obj)), config);


  Future one(type, id) {
    final rt = config.resourceType(type);
    final deserialize = config.deserializer(rt, ['query']);
    return resourceStore.one(rt, id).then(deserialize);
  }

  Future<List> list(type) {
    final rt = config.resourceType(type);
    final deserialize = (list) => list.map(config.deserializer(rt, ['query'])).toList();
    return resourceStore.list(rt).then(deserialize);
  }

  Future customQueryOne(type, {
    String url,
    String method,
    data,
    Map<String, dynamic> params,
    Map<String, dynamic> headers,
    bool withCredentials: false,
    xsrfHeaderName,
    xsrfCookieName,
    interceptors,
    cache,
    timeout
  }){
    final rt = config.resourceType(type);
    final deserialize = config.deserializer(rt, ['query']);

    final r = resourceStore.customQueryOne(rt, method: method, url: url, data: data, params: params, headers: headers,
      withCredentials: withCredentials, xsrfHeaderName: xsrfHeaderName,
      xsrfCookieName: xsrfCookieName, interceptors: interceptors, cache: cache,
      timeout: timeout);

    return r.then(deserialize);
  }

  Future<List> customQueryList(type, {
    String url,
    String method,
    data,
    Map<String, dynamic> params,
    Map<String, dynamic> headers,
    bool withCredentials: false,
    xsrfHeaderName,
    xsrfCookieName,
    interceptors,
    cache,
    timeout
  }){
    final rt = config.resourceType(type);
    final deserialize = (list) => list.map(config.deserializer(rt, ['query'])).toList();

    final r = resourceStore.customQueryList(rt, method: method, url: url, data: data, params: params, headers: headers,
      withCredentials: withCredentials, xsrfHeaderName: xsrfHeaderName,
      xsrfCookieName: xsrfCookieName, interceptors: interceptors, cache: cache,
      timeout: timeout);

    return r.then(deserialize);
  }

  Future create(object) {
    final res = _wrapInResource(object);
    final p = _parseSuccessCommandResponse(res, object);
    final ep = _parseErrorCommandResponse(res, object);
    return resourceStore.create(res).then(p, onError: ep);
  }

  Future update(object) {
    final res = _wrapInResource(object);
    final p = _parseSuccessCommandResponse(res, object);
    final ep = _parseErrorCommandResponse(res, object);
    return resourceStore.update(res).then(p, onError: ep);
  }

  Future delete(object) {
    final res = _wrapInResource(object);
    final p = _parseSuccessCommandResponse(res, object);
    final ep = _parseErrorCommandResponse(res, object);
    return resourceStore.delete(res).then(p, onError: ep);
  }

  Future<CommandResponse> customCommand(object, {
    String url,
    String method,
    data,
    Map<String, dynamic> params,
    Map<String, dynamic> headers,
    bool withCredentials: false,
    xsrfHeaderName,
    xsrfCookieName,
    interceptors,
    cache,
    timeout
  }) {
    final res = _wrapInResource(object);
    final p = _parseSuccessCommandResponse(res, object);
    final ep = _parseErrorCommandResponse(res, object);

    final r = resourceStore.customCommand(res, method: method, url: url, data: data, params: params, headers: headers,
      withCredentials: withCredentials, xsrfHeaderName: xsrfHeaderName,
      xsrfCookieName: xsrfCookieName, interceptors: interceptors, cache: cache,
      timeout: timeout);

    return r.then(p, onError: ep);
  }

  _wrapInResource(object) =>
      config.serializer(config.resourceType(object.runtimeType))(object);

  _parseSuccessCommandResponse(res, object) =>
      _commandResponse(res, object, ['command', 'success']);

  _parseErrorCommandResponse(res, object) =>
      (resp) => new Future.error(_commandResponse(res, object, ['command', 'error'])(resp));

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