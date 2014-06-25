part of hammock_test;

testIntegration() {
  describe("Custom Document Formats", () {
    it("can support jsonapi.org format", inject((HammockConfig config, MockHttpBackend hb, ResourceStore s){
      config.documentFormat = new JsonApiOrgFormat();

      hb.whenGET("/posts/123").respond({"posts" : [{"id" : 123, "title" : "title"}]});
      wait(s.one("posts", 123), (post) {
        expect(post.content["title"]).toEqual("title");
      });

      hb.expectPUT("/posts/123", '{"posts":[{"id":123,"title":"new"}]}');
      wait(s.save(resource("posts", 123, {"id" : 123, "title" : "new"})));
    }));
  });

  describe("Configuration", () {
    it("example", inject((HammockConfig config, MockHttpBackend hb, ObjectStore s){
      config.documentFormat = new JsonApiOrgFormat();
      config.set({
        "posts" : {
          "type" : Post,
          "route" : "custom_posts",
          "serializer" : serializePost,
          "deserializer" : deserializePost
        }
      });

      hb.whenGET("/custom_posts/123").respond({"posts" : [{"id" : 123, "title" : "title"}]});
      wait(s.one(Post, 123), (post) {
        expect(post.title).toEqual("title");
      });

      hb.expectPUT("/custom_posts/123", '{"posts":[{"id":123,"title":"new"}]}');
      wait(s.save(new Post()..id = 123..title = "new"));
    }));
  });
}

class JsonApiOrgFormat extends JsonDocumentFormat {
  resourceToJson(Resource res) =>
      {res.type.toString(): [res.content]};

  manyResourcesToJson(List<Resource> list) =>
      throw 'not needed';

  Resource jsonToResource(type, json) =>
      resource(type, json[type][0]["id"], json[type][0]);

  List<Resource> jsonToManyResources(type, json) =>
      json[type].map((r) => resource(type, r["id"], r));
}