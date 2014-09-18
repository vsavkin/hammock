part of hammock_test;

class IntegrationPost {
  int id;
  String title;
  String errors;
}

testIntegration() {
  setUpAngular();

  deserializePost(r) => new IntegrationPost()
    ..id = r.id
    ..title = r.content["title"]
    ..errors = r.content["errors"];

  serializePost(post) =>
    resource("posts", post.id, {"id" : post.id, "title" : post.title});



  describe("Custom Document Formats", () {
    it("can support jsonapi.org format", (HammockConfig config, MockHttpBackend hb, ResourceStore s){
      config.documentFormat = new JsonApiOrgFormat();

      hb.whenGET("/posts/123").respond({"posts" : [{"id" : 123, "title" : "title"}]});
      wait(s.one("posts", 123), (post) {
        expect(post.content["title"]).toEqual("title");
      });

      hb.expectPUT("/posts/123", '{"posts":[{"id":123,"title":"new"}]}');
      wait(s.update(resource("posts", 123, {"id" : 123, "title" : "new"})));
    });
  });

  describe("Different Types of Responses", () {
    final post = new IntegrationPost()..id = 123..title = "new";

    it("works when when a server returns an updated resource",
      (HammockConfig config, MockHttpBackend hb, ObjectStore s) {

        config.set({
            "posts" : {
                "type" : IntegrationPost,
                "serializer" : serializePost,
                "deserializer" : deserializePost
            }
        });

        hb.expectPUT("/posts/123").respond({"id" : 123, "title" : "updated"});

        wait(s.update(post), (up) {
          expect(up.title).toEqual("updated");
        });

        hb.expectPUT("/posts/123").respond(422, {"id" : 123, "title" : "updated", "errors" : "some errors"}, {});

        waitForError(s.update(post), (up, s) {
          expect(up.title).toEqual("updated");
          expect(up.errors).toEqual("some errors");
        });
    });

    it("works when a server returns a status",
      (HammockConfig config, MockHttpBackend hb, ObjectStore s) {

        config.set({
            "posts" : {
                "type" : IntegrationPost,
                "serializer" : serializePost,
                "deserializer" : {
                  "command" : {
                    "success" : (obj, r) => true,
                    "error" : (obj, r) => r.content["errors"]
                  }
                }
            }
        });


        hb.expectPUT("/posts/123").respond("OK");

        wait(s.update(post), (res) {
          expect(res).toBeTrue();
        });

        hb.expectPUT("/posts/123").respond(422, {"errors" : "some errors"}, {});

        waitForError(s.update(post), (errors) {
          expect(errors).toEqual("some errors");
        });
    });
  });
}

class JsonApiOrgFormat extends JsonDocumentFormat {
  resourceToJson(Resource res) =>
      {res.type.toString(): [res.content]};

  Resource jsonToResource(type, json) =>
      resource(type, json[type][0]["id"], json[type][0]);

  List<Resource> jsonToManyResources(type, json) =>
      json[type].map((r) => resource(type, r["id"], r)).toList();
}