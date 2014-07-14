library hammock_core;

import 'dart:convert';

class Resource {
  final Object type, id;
  final Map content;

  Resource(this.type, this.id, this.content);
}

Resource resource(type, id, [content]) => new Resource(type, id, content);

class CommandResponse {
  final Resource resource;
  final content;
  CommandResponse(this.resource, this.content);
}

abstract class DocumentFormat {
  String resourceToDocument(Resource res);
  Resource documentToResource(resourceType, document);
  List<Resource> documentToManyResources(resourceType, document);
  CommandResponse documentToCommandResponse(Resource res, document);
}

abstract class JsonDocumentFormat implements DocumentFormat {
  resourceToJson(Resource resource);
  Resource jsonToResource(resourceType, json);
  List<Resource> jsonToManyResources(resourceType, json);

  final _encoder = new JsonEncoder();
  final _decoder = new JsonDecoder();

  String resourceToDocument(Resource res) =>
      _encoder.convert(resourceToJson(res));

  Resource documentToResource(resourceType, document) =>
      jsonToResource(resourceType, _toJSON(document));

  List<Resource> documentToManyResources(resourceType, document) =>
      jsonToManyResources(resourceType, _toJSON(document));

  CommandResponse documentToCommandResponse(Resource res, document) =>
      new CommandResponse(res, _toJSON(document));

  _toJSON(document) {
    try {
      return (document is String) ? _decoder.convert(document) : document;
    } on FormatException catch(e) {
      return document;
    }
  }
}

class SimpleDocumentFormat extends JsonDocumentFormat {
  resourceToJson(Resource res) =>
  res.content;

  Resource jsonToResource(type, json) =>
  resource(type, json["id"], json);

  List<Resource> jsonToManyResources(type, json) =>
  json.map((j) => jsonToResource(type, j)).toList();
}