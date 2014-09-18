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
    return _invoke("GET", url).then(_parseResource(resourceType));
  }

  Future<QueryResult<Resource>> list(resourceType, {Map params}) {
    final url = _url(resourceType);
    return _invoke("GET", url, params: params).then(_parseManyResources((resourceType)));
  }

  Future<Resource> customQueryOne(resourceType, CustomRequestParams params) =>
      params.invoke(http).then(_parseResource(resourceType));

  Future<QueryResult<Resource>> customQueryList(resourceType, CustomRequestParams params)  =>
      params.invoke(http).then(_parseManyResources(resourceType));


  Future<CommandResponse> create(Resource resource) {
    final content = _docFormat.resourceToDocument(resource);
    final url = _url(resource.type);
    final p = _parseCommandResponse(resource);
    return _invoke("POST", url, data: content).then(p, onError: _error(p));
  }

  Future<CommandResponse> update(Resource resource) {
    final content = _docFormat.resourceToDocument(resource);
    final url = _url(resource.type, resource.id);
    final p = _parseCommandResponse(resource);
    return _invoke("PUT", url, data: content).then(p, onError: _error(p));
  }

  Future<CommandResponse> delete(Resource resource) {
    final url = _url(resource.type, resource.id);
    final p = _parseCommandResponse(resource);
    return _invoke("DELETE", url).then(p, onError: _error(p));
  }

  Future<CommandResponse> customCommand(Resource resource, CustomRequestParams params) {
    final p = _parseCommandResponse(resource);
    return params.invoke(http).then(p, onError: _error(p));
  }

  _invoke(String method, String url, {String data, Map params}) {
    final d = config.requestDefaults;
    return http.call(
        method: method,
        url: url,
        data: data,
        params: _paramsWithDefaults(params),
        headers: d.headers,
        withCredentials: d.withCredentials,
        xsrfCookieName: d.xsrfCookieName,
        xsrfHeaderName: d.xsrfHeaderName,
        interceptors: d.interceptors,
        cache: d.cache,
        timeout: d.timeout
    );
  }

  _paramsWithDefaults(Map rParams) {
    if (config.requestDefaults.params == null && rParams == null) return null;
    final params = config.requestDefaults.params == null ? {} : config.requestDefaults.params;
    if (rParams != null) rParams.forEach((key, value) => params[key] = value);
    return params;
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
