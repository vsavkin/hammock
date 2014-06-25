part of hammock;

class Resource {
  final Object type, id;
  final Map content;

  Resource(this.type, this.id, this.content);
}

Resource resource(type, id, [Map content]) => new Resource(type, id, content);
