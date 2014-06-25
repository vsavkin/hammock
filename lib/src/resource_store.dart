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
    return http.get(url).then(_parse(resourceType));
  }

  Future<List<Resource>> list(resourceType) {
    final url = _url(resourceType);
    final parse = (resp) => _docFormat.documentToManyResources(resourceType, resp.data);
    return http.get(url).then(parse);
  }

  Future save(Resource resource) {
    final content = _docFormat.resourceToDocument(resource);
    final url = _url(resource.type, resource.id);
    return http.put(url, content).then(_parse(resource.type));
  }

  Future create(Resource resource) {
    final content = _docFormat.resourceToDocument(resource);
    final url = _url(resource.type);
    return http.post(url, content).then(_parse(resource.type));
  }

  Future delete(Resource resource) {
    final url = _url(resource.type, resource.id);
    return http.delete(url).then(_parse(resource.type));
  }

  _parse(resourceType) => (resp) => _docFormat.documentToResource(resourceType, resp.data);

  get _docFormat => config.documentFormat;

  _url(type, [id=_u]) {
    final parentFragment = scopingResources.map((r) => "/${config.route(r.type)}/${r.id}").join("");
    final currentFragment = "/${config.route(type)}";
    final idFragment = (id != _u) ? "/$id" :  "";
    return config.urlRewriter("$parentFragment$currentFragment$idFragment");
  }
}
