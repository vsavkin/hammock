part of hammock_test;

testResourceStore() {
  describe("ResourceStore", () {
    it("returns a resource", (MockHttpBackend hb, ResourceStore store) {
      hb.whenGET("/posts/123").respond({"id": 123, "title" : "SampleTitle"});

      wait(store.one("posts", 123), (resource) {
        expect(resource.id).toEqual(123);
        expect(resource.content["title"]).toEqual("SampleTitle");
      });
    });

    it("returns multiple resources", (MockHttpBackend hb, ResourceStore store) {
      hb.whenGET("/posts").respond([{"id": 123, "title" : "SampleTitle"}]);

      wait(store.list("posts"), (resources) {
        expect(resources.length).toEqual(1);
        expect(resources[0].content["title"]).toEqual("SampleTitle");
      });
    });

    it("returns a nested resource", (MockHttpBackend hb, ResourceStore store) {
      hb.whenGET("/posts/123/comments/456").respond({"id": 456, "text" : "SampleComment"});

      final post = resource("posts", 123);
      wait(store.scope(post).one("comments", 456), (resource) {
        expect(resource.id).toEqual(456);
        expect(resource.content["text"]).toEqual("SampleComment");
      });
    });

    it("create a resource", (MockHttpBackend hb, ResourceStore store) {
      hb.expectPOST("/posts", '{"title":"New"}').respond({"id" : 123, "title" : "New"});

      final post = resource("posts", null, {"title": "New"});

      wait(store.create(post), (resource) {
        expect(resource.id).toEqual(123);
        expect(resource.content["title"]).toEqual("New");
      });
    });

    it("updates a resource", (MockHttpBackend hb, ResourceStore store) {
      hb.expectPUT("/posts/123", '{"id":123,"title":"New"}').respond({"id": 123, "title": "Newer"});

      final post = resource("posts", 123, {"id": 123, "title": "New"});

      wait(store.save(post), (resource) {
        expect(resource.id).toEqual(123);
        expect(resource.content["title"]).toEqual("Newer");
      });
    });

    it("updates a nested resource", (MockHttpBackend hb, ResourceStore store) {
      hb.expectPUT("/posts/123/comments/456", '{"id":456,"text":"New"}').respond({});

      final post = resource("posts", 123);
      final comment = resource("comments", 456, {"id": 456, "text" : "New"});

      wait(store.scope(post).save(comment));
    });

    it("deletes a resource", (MockHttpBackend hb, ResourceStore store) {
      hb.expectDELETE("/posts/123").respond({"status" : "OK"});

      final post = resource("posts", 123);

      wait(store.delete(post), (resource) {
        expect(resource.content["status"]).toEqual("OK");
      });
    });

    describe("Custom Configuration", () {
      it("uses route", (HammockConfig config, MockHttpBackend hb, ResourceStore store) {
        config.set({
            "posts" : {"route": 'custom'}
        });

        hb.whenGET("/custom/123").respond({});

        wait(store.one("posts", 123));
      });

      it("uses urlRewriter", (HammockConfig config, MockHttpBackend hb, ResourceStore store) {
        config.urlRewriter.baseUrl = "/base";
        config.urlRewriter.suffix = ".json";

        hb.whenGET("/base/posts/123.json").respond({});

        wait(store.one("posts", 123));

        config.urlRewriter = (url) => "$url.custom";

        hb.whenGET("/posts/123.custom").respond({});

        wait(store.one("posts", 123));
      });
    });
  });
}