part of hammock;

abstract class DocumentFormat {
  String resourceToDocument(Resource res);
  String manyResourcesToDocument(List<Resource> res);
  Resource documentToResource(resourceType, document);
  List<Resource> documentToManyResources(resourceType, document);
}

abstract class JsonDocumentFormat implements DocumentFormat {
  resourceToJson(Resource resource);
  manyResourcesToJson(List<Resource> list);
  Resource jsonToResource(type, json);
  List<Resource> jsonToManyResources(type, json);

  final _encoder = new JsonEncoder();
  final _decoder = new JsonDecoder();

  String resourceToDocument(Resource res) =>
      _encoder.convert(resourceToJson(res));

  String manyResourcesToDocument(List<Resource> res) =>
      _encoder.convert(manyResourcesToJson(res));

  Resource documentToResource(resourceType, document) =>
      jsonToResource(resourceType, _toJSON(document));

  List<Resource> documentToManyResources(resourceType, document) =>
      jsonToManyResources(resourceType, _toJSON(document));

  _toJSON(document) => (document is String) ? _decoder.convert(document) : document;
}

class SimpleDocumentFormat extends JsonDocumentFormat {
  resourceToJson(Resource res) =>
      res.content;

  manyResourcesToJson(List<Resource> list) =>
      list.map(resourceToJson).toList();

  Resource jsonToResource(type, json) =>
      resource(type, json["id"], json);

  List<Resource> jsonToManyResources(type, json) =>
      json.map((j) => jsonToResource(type, j)).toList();
}