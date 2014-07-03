part of hammock;

@Injectable()
class ResourceStore {
  final Http http;
  final HammockConfig config;
  final List<Resource> scopingResources;

  ResourceStore(this.http, this.config)
      : scopingResources = [];

  ResourceStore.copy(ResourceStore original)
      : this.scopingResources = new List.from(original.scopingResources),
        this.http = original.http,
        this.config = original.config;

  ResourceStore scope(scopingResource) => new ResourceStore.copy(this)..scopingResources.add(scopingResource);


  Future<Resource> one(resourceType, resourceId) {
    final url = _url(resourceType, resourceId);
    return http.get(url).then(_parseResource(resourceType));
  }

  Future<List<Resource>> list(resourceType) {
    final url = _url(resourceType);
    return http.get(url).then(_parseManyResources((resourceType)));
  }

  Future<Resource> customQueryOne(resourceType, {
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

    final r = http(method: method, url: url, data: data, params: params, headers: headers,
      withCredentials: withCredentials, xsrfHeaderName: xsrfHeaderName,
      xsrfCookieName: xsrfCookieName, interceptors: interceptors, cache: cache,
      timeout: timeout);

    return r.then(_parseResource(resourceType));
  }

  Future<List<Resource>> customQueryList(resourceType, {
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
    final r = http(method: method, url: url, data: data, params: params, headers: headers,
      withCredentials: withCredentials, xsrfHeaderName: xsrfHeaderName,
      xsrfCookieName: xsrfCookieName, interceptors: interceptors, cache: cache,
      timeout: timeout);

    return r.then(_parseManyResources((resourceType)));
  }

  Future<CommandResponse> create(Resource resource) {
    final content = _docFormat.resourceToDocument(resource);
    final url = _url(resource.type);
    final p = _parseCommandResponse(resource);
    return http.post(url, content).then(p, onError: _error(p));
  }

  Future<CommandResponse> update(Resource resource) {
    final content = _docFormat.resourceToDocument(resource);
    final url = _url(resource.type, resource.id);
    final p = _parseCommandResponse(resource);
    return http.put(url, content).then(p, onError: _error(p));
  }

  Future<CommandResponse> delete(Resource resource) {
    final url = _url(resource.type, resource.id);
    final p = _parseCommandResponse(resource);
    return http.delete(url).then(p, onError: _error(p));
  }

  Future<CommandResponse> customCommand(resource, {
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
    final r = http(method: method, url: url, data: data, params: params, headers: headers,
      withCredentials: withCredentials, xsrfHeaderName: xsrfHeaderName,
      xsrfCookieName: xsrfCookieName, interceptors: interceptors, cache: cache,
      timeout: timeout);

    final p = _parseCommandResponse(resource);
    return r.then(p, onError: _error(p));
  }


  _parseResource(resourceType) => (resp) => _docFormat.documentToResource(resourceType, resp.data);
  _parseManyResources(resourceType) => (resp) => _docFormat.documentToManyResources(resourceType, resp.data);
  _parseCommandResponse(res) => (resp) => _docFormat.documentToCommandResponse(res, resp.data);
  _error(Function func) => (resp) => new Future.error(func(resp));

  get _docFormat => config.documentFormat;

  _url(type, [id=_u]) {
    final parentFragment = scopingResources.map((r) => "/${config.route(r.type)}/${r.id}").join("");
    final currentFragment = "/${config.route(type)}";
    final idFragment = (id != _u) ? "/$id" :  "";
    return config.urlRewriter("$parentFragment$currentFragment$idFragment");
  }
}
