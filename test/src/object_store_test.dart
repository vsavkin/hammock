part of hammock_test;

testObjectStore() {
  describe("ObjectStore", () {
    beforeEach((HammockConfig config) {
      config.set({
          "posts" : {
              "type" : Post,
              "deserializer" : deserializePost,
              "serializer" : serializePost
          },
          "comments" : {
              "type": Comment,
              "deserializer" : deserializeComment,
              "serializer" : serializeComment
          }
      });
    });

    it("returns an object", (MockHttpBackend hb, ObjectStore store) {
      hb.whenGET("/posts/123").respond({"id": 123, "title" : "SampleTitle"});

      wait(store.one(Post, 123), (Post post) {
        expect(post.title).toEqual("SampleTitle");
      });
    });

    it("returns multiple objects", (MockHttpBackend hb, ObjectStore store) {
      hb.whenGET("/posts").respond([{"id": 123, "title" : "SampleTitle"}]);

      wait(store.list(Post), (List<Post> posts) {
        expect(posts.length).toEqual(1);
        expect(posts[0].title).toEqual("SampleTitle");
      });
    });

    it("returns a nested object", (MockHttpBackend hb, ObjectStore store) {
      final post = new Post()..id = 123;
      hb.whenGET("/posts/123/comments/456").respond({"id": 456, "text" : "SampleComment"});

      wait(store.scope(post).one(Comment, 456), (Comment comment) {
        expect(comment.text).toEqual("SampleComment");
      });
    });

    it("creates an object", inject((MockHttpBackend hb, ObjectStore store) {
      hb.expectPOST("/posts", '{"id":null,"title":"New"}').respond({"id":123,"title":"New"});

      final post = new Post()..title = "New";

      wait(store.create(post));
    }));

    it("updates an object", inject((MockHttpBackend hb, ObjectStore store) {
      hb.expectPUT("/posts/123", '{"id":123,"title":"New"}').respond({});

      final post = new Post()..id = 123..title = "New";

      wait(store.save(post));
    }));

    it("updates a nested object", inject((MockHttpBackend hb, ObjectStore store) {
      hb.expectPUT("/posts/123/comments/456", '{"id":456,"text":"New"}').respond({});

      final post = new Post()..id = 123;
      final comment = new Comment()..id = 456..text = "New";

      wait(store.scope(post).save(comment));
    }));

    it("deletes a object", (MockHttpBackend hb, ObjectStore store) {
      hb.expectDELETE("/posts/123").respond({});

      final post = new Post()..id = 123;

      wait(store.delete(post));
    });

    describe("custom update function", () {
      it("returns a deserialized object", inject((MockHttpBackend hb, ObjectStore store, HammockConfig config) {
        config.set({
            "posts" : {
                "type" : Post,
                "serializer" : serializePost,
                "deserializer" : deserializePost
            }
        });

        hb.expectPUT("/posts/123").respond({"id": 123, "title": "Newer"});

        final post = new Post()..id = 123..title = "New";

        wait(store.save(post), (Post returnedPost) {
          expect(returnedPost.id).toEqual(123);
          expect(returnedPost.title).toEqual("Newer");
          expect(post.title).toEqual("New");
        });
      }));

      it("runs custom update function", inject((MockHttpBackend hb, ObjectStore store, HammockConfig config) {
        config.set({
            "posts" : {
                "type" : Post,
                "serializer" : serializePost,
                "updater" : updatePost
            }
        });

        hb.expectPUT("/posts/123").respond({"id": 123, "title": "Newer"});

        final post = new Post()..id = 123..title = "New";
        wait(store.save(post), (bool status) {
          expect(status).toBeTrue();
          expect(post.title).toEqual("Newer");
        });
      }));
    });
  });
}

class Post {
  int id;
  String title;
}

class Comment {
  int id;
  String text;
}

Post deserializePost(Resource r) => new Post()
  ..id = r.id
  ..title = r.content["title"];

Resource serializePost(Post post) =>
    resource("posts", post.id, {"id" : post.id, "title" : post.title});

updatePost(Post post, Resource r) {
  post.title = r.content["title"];
  return true;
}

Comment deserializeComment(Resource r) => new Comment()
  ..id = r.id
  ..text = r.content["text"];

Resource serializeComment(Comment comment) =>
    resource("comments", comment.id, {"id" : comment.id, "text" : comment.text});

