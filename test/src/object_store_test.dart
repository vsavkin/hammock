part of hammock_test;

testObjectStore() {
  describe("ObjectStore", () {
    describe("Queries", () {
      beforeEach((HammockConfig config) {
        config.set({
            "posts" : {
                "type" : Post,
                "serializer" : serializePost,
                "deserializer" : deserializePost
            },
            "comments" : {
                "type": Comment,
                "deserializer" : deserializeComment
            }
        });
      });

      it("returns an object", (MockHttpBackend hb, ObjectStore store) {
        hb.whenGET("/posts/123").respond({"title" : "SampleTitle"});

        wait(store.one(Post, 123), (Post post) {
          expect(post.title).toEqual("SampleTitle");
        });
      });

      it("returns multiple objects", (MockHttpBackend hb, ObjectStore store) {
        hb.whenGET("/posts").respond([{"title" : "SampleTitle"}]);

        wait(store.list(Post), (List<Post> posts) {
          expect(posts.length).toEqual(1);
          expect(posts[0].title).toEqual("SampleTitle");
        });
      });

      it("returns a nested object", (MockHttpBackend hb, ObjectStore store) {
        final post = new Post()..id = 123;
        hb.whenGET("/posts/123/comments/456").respond({"text" : "SampleComment"});

        wait(store.scope(post).one(Comment, 456), (Comment comment) {
          expect(comment.text).toEqual("SampleComment");
        });
      });

      it("handles errors", (MockHttpBackend hb, ObjectStore store) {
        hb.whenGET("/posts/123").respond(500, "BOOM");

        waitForError(store.one(Post, 123), (resp) {
          expect(resp.data).toEqual("BOOM");
        });
      });

      it("uses a separate deserializer for queries",
          (HammockConfig config, MockHttpBackend hb, ObjectStore store) {

        config.set({
            "posts" : {
              "type" : Post,
              "deserializer" : {
                "query" : deserializePost
              }
            }
        });

        hb.whenGET("/posts/123").respond({"title" : "SampleTitle"});

        wait(store.one(Post, 123), (Post post) {
          expect(post.title).toEqual("SampleTitle");
        });
      });
    });


    describe("Commands", () {
      describe("Without Deserializers", () {
        beforeEach((HammockConfig config) {
          config.set({
              "posts" : {
                  "type" : Post,
                  "serializer" : serializePost
              },
              "comments" : {
                  "type" : Comment,
                  "serializer" : serializeComment
              }
          });
        });

        it("creates an object", (MockHttpBackend hb, ObjectStore store) {
          hb.expectPOST("/posts", '{"id":null,"title":"New"}').respond({"id":123,"title":"New"});

          final post = new Post()..title = "New";

          wait(store.create(post));
        });

        it("updates an object", (MockHttpBackend hb, ObjectStore store) {
          hb.expectPUT("/posts/123", '{"id":123,"title":"New"}').respond({});

          final post = new Post()..id = 123..title = "New";

          wait(store.save(post));
        });

        it("deletes a object", (MockHttpBackend hb, ObjectStore store) {
          hb.expectDELETE("/posts/123").respond({});

          final post = new Post()..id = 123;

          wait(store.delete(post));
        });

        it("updates a nested object", (MockHttpBackend hb, ObjectStore store) {
          hb.expectPUT("/posts/123/comments/456", '{"id":456,"text":"New"}').respond({});

          final post = new Post()..id = 123;
          final comment = new Comment()..id = 456..text = "New";

          wait(store.scope(post).save(comment));
        });

        it("handles errors", (MockHttpBackend hb, ObjectStore store) {
          hb.expectPOST("/posts", '{"id":null,"title":"New"}').respond(500, "BOOM", {});

          final post = new Post()..title = "New";

          waitForError(store.create(post));
        });
      });

      describe("With Deserializers", () {
        var post;

        beforeEach(() {
          post = new Post()..id = 123..title = "New";
        });

        it("uses the same deserializer for queries and commands",
            (MockHttpBackend hb, ObjectStore store, HammockConfig config) {

          config.set({
              "posts" : {
                  "type" : Post,
                  "serializer" : serializePost,
                  "deserializer" : deserializePost
              }
          });

          hb.expectPUT("/posts/123").respond({"id": 123, "title": "Newer"});

          wait(store.save(post), (Post returnedPost) {
            expect(returnedPost.id).toEqual(123);
            expect(returnedPost.title).toEqual("Newer");
          });
        });

        it("uses a separate serializer for commands",
            (MockHttpBackend hb, ObjectStore store, HammockConfig config) {

          config.set({
              "posts" : {
                  "type" : Post,
                  "serializer" : serializePost,
                  "deserializer" : {
                    "command" : updatePost
                  }
              }
          });

          hb.expectPUT("/posts/123").respond({"title": "Newer"});

          wait(store.save(post), (Post returnedPost) {
            expect(returnedPost.title).toEqual("Newer");
            expect(post.title).toEqual("Newer");
          });
        });

        it("uses a separate serializer when a command fails",
            (MockHttpBackend hb, ObjectStore store, HammockConfig config) {

          config.set({
              "posts" : {
                  "type" : Post,
                  "serializer" : serializePost,
                  "deserializer" : {
                    "command" : {
                      "success" : deserializePost,
                      "error" : parseErrors
                    }
                  }
              }
          });

          hb.expectPUT("/posts/123").respond(500, "BOOM");

          waitForError(store.save(post), (resp) {
            expect(resp).toEqual("BOOM");
          });
        });
      });
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

Post updatePost(Post post, CommandResponse resp) {
  post.title = resp.content["title"];
  return post;
}

parseErrors(Post post, CommandResponse resp) =>
    resp.content;

Resource serializePost(Post post) =>
    resource("posts", post.id, {"id" : post.id, "title" : post.title});

Comment deserializeComment(Resource r) => new Comment()
  ..id = r.id
  ..text = r.content["text"];

Resource serializeComment(Comment comment) =>
    resource("comments", comment.id, {"id" : comment.id, "text" : comment.text});

