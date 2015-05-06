library hammock_core;

import 'dart:convert';
import 'dart:collection';

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

class QueryResult<T> extends Object with ListMixin<T>  {
  final List<T> list;
  final Map meta;

  QueryResult(this.list, [this.meta=const {}]);

  T operator[](index) => list[index];
  int get length => list.length;

  operator[]=(index,value) => list[index] = value;
  set length(value) => list.length = value;

  QueryResult map(Function fn) => new QueryResult(list.map(fn).toList(), meta);

  QueryResult toList({ bool growable: true }) => this;
}

abstract class DocumentFormat {
  String resourceToDocument(Resource res);
  Resource documentToResource(resourceType, document);
  QueryResult documentToManyResources(resourceType, document);
  CommandResponse documentToCommandResponse(Resource res, document);
}

abstract class JsonDocumentFormat implements DocumentFormat {
  resourceToJson(Resource resource);
  Resource jsonToResource(resourceType, json);
  QueryResult<Resource> jsonToManyResources(resourceType, json);

  final _encoder = new JsonEncoder();
  final _decoder = new JsonDecoder();

  String resourceToDocument(Resource res) =>
      _encoder.convert(resourceToJson(res));

  Resource documentToResource(resourceType, document) =>
      jsonToResource(resourceType, _toJSON(document));

  QueryResult<Resource> documentToManyResources(resourceType, document) =>
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

  QueryResult<Resource> jsonToManyResources(type, json) {
    if(json is Map){
      var newjson = json;
      newjson.forEach((key, value) => jsonToResource(type, value));
      return new QueryResult(newjson.values.toList());
    } else {
      return new QueryResult(json.map((j) => jsonToResource(type, j)).toList());
    }
  }
}
