# Hammock

AngularDart service for working with Rest APIs



## Introduction to Hammock

You can find a quick start guide [here](https://github.com/vsavkin/hammock). Look at it first before reading this guide.



## Resources

Though most of the time you are going to work with `ObjectStore`, sometimes it is valuable to go lower-level and work with resources directly.


You can create a resource like this:

    resource("posts", 1, {"title": "some post"});

Resource has a type, an id, and content.




## Using ResourceStore



### One

The `one` method, which takes a resource type and an id, loads a resource.

```dart
Future<Resource> r = store.one("posts", 123); // GET "/posts/123"
```



### List

The `list` method, which takes a resource type, loads all the resources of the given type.

```dart
Future<List<Resource>> rs = store.list("posts"); // GET "/posts"
Future<List<Resource>> rs = store.list("posts", params: {"createdAfter": '2014'}); // GET "/posts?createdAfter=2014"
```



### Nested Resources

The `scope` method, which takes a resource, allows fetching nested resources.

```dart
final post = resource("posts", 123);
Future<Resource> r = store.scope(post).one("comments", 456); // GET "/posts/123/comments/456"
Future<List<Resource>> rs = store.scope(post).list("comments"); // GET "/posts/123/comments"
```

`scope` returns a new store:

```dart
ResourceStore scopeStore = store.scope(post);
```

You can scope an already scoped store:

```dart
store.scope(blog).scope(post);
```



### Create

To create a resource call the `create` method:

```dart
final post = resource("posts", null, {"title": "New"}); 
store.create(post); // POST "/posts"
```



### Update

Use `update` to change the existing resource:

```dart
final post = resource("posts", 123, {"id": 123, "title": "New"}); 
store.update(post); // PUT "/posts/123"
```



### Delete

Use `delete` to delete the existing resource:

```dart
final post = resource("posts", 123, {"id": 123, "title": "New"}); 
store.delete(post); // DELETE "/posts/123"
```

Use `scope` to create, update, and delete nested resources.



### CommandResponse

All the commands return a `CommandResponse`. For instance:

```dart
Future<CommandResponse> createdPost = store.create(post);
```



### Custom Queries


Use `customQueryOne` and `customQueryList` to make custom queries:

``dart
Future<Resource> r = store.customQueryOne("posts", new CustomRequestParams(method: "GET", url:"/posts/123"));
Future<List<Resource>> rs = store.customQueryList("posts", new CustomRequestParams(method: "GET", url:"/posts"));
``



### Custom Commands

And `customCommand` to execute custom commands:

``dart
final post = resource("posts", 123);
store.customCommand(post, new CustomRequestParams(method: 'DELETE', url: '/posts/123'));
``

Using custom queries and command is discouraged.




## Configuring ResourceStore

`HammockConfig` allows you to configure some aspects of `ResourceStore`.



### Setting Up Route

```dart
config.set({"posts" : {"route" : "custom"}});
```

`ResourceStore` will use "custom" to build the url when fetching/saving posts. For instance:

```dart
store.one("posts", 123) // GET "/custom/123"
```



### Setting Up UrlRewriter

```dart
config.urlRewriter.baseUrl = "/base";
config.urlRewriter.suffix = ".json";

store.one("posts", 123); // GET "/base/posts/123.json"
```

Or even like this:

```dart
config.urlRewriter = (url) => "$url.custom";

store.one("posts", 123); // GET "/posts/123.custom"
```



### DocumentFormat

`DocumentFormat` defines how resources are serialized into documents. `SimpleDocumentFormat` is used by default. It can be overwritten as follows:

    config.documentFormat = new CustomDocumentFormat();

Please see `integration_test.dart` for more details.




## Configuring the Http Service

Hammock is built on top of the `Http` service provided by Angular. Consequently, you can configure Hammock by configuring `Http`.

```dart
final headers = injector.get(HttpDefaultHeaders);
headers.setHeaders({'Content-Type' : 'custom-type'}, 'GET');
```




## Using ObjectStore

`ObjectStore` is responsible for:

* Converting object into resources
* Converting resources into objects
* Updating objects
* Using `ResourceStore` to send objects to the server

Suppose we have these classed defined:

```dart
class Post {
  int id;
  String title;
  dynamic errors;
  Post(this.id, this.title);
}

class Comment {
  int id;
  String text;
  Comment(this.id, this.text);
}
```

Plus this configuration:


```dart
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
```

Where the serialization and deserialization functions are responsible for converting domain objects from/into resources.

```dart
Post deserializePost(Resource r) => new Post(id, r.content["title"));
Resource serializePost(Post post) => resource("posts", post.id, {"id" : post.id, "title" : post.title});
Comment deserializeComment(Resource r) => new Comment(id, content["text"]);
Resource serializeComment(Comment comment) => resource("comments", comment.id, {"id" : comment.id, "text" : comment.text});
```



### One

The `one` method, which takes a type and an id, loads an object.

```dart
Future<Post> p = store.one(Post, 123); // GET "/posts/123"
Future<Comment> c = store.scope(post).one(Comment, 456); //GET "posts/123/comments/456"
```



### List

The `list` method, which takes a type, loads all the objects of the given type.

```dart
Future<List<Post>> ps = store.list(Post); // GET "/posts"
Future<List<Post>> ps = store.list(Post, params: {"createdAfter": "2014"}); // GET "/posts?createdAfter=2014"
Future<List<Comment>> cs = store.scope(post).list(Comment); //GET "/posts/123/comments"
```

As you can see it is very similar to `ResourceStore`, but we can use our domain objects instead of `Resource`.



### Commands

With the current configuration `create`, `update`, `delete`, `customCommand` return a new object. For example:

```dart
final post = new Post(123, "title");
Future<Post> p = store.update(post); // PUT '/posts/123'
```

Let's say the backend returns the updated post object, for instance, serialized like this `{"id":123,"title":"New"}`.

```dart
final post = new Post(123, "title");
store.update(post).then((updatedPost) {
  expect(updatedPost.title).toEqual("New");
  expect(post.title).toEqual("title");
});
```

`post` was not updated, and instead a new post object was created. This is great cause it allows you to keep you objects immutable. Sometimes, however, we would like to treat our objects as entities and update them instead. To do that, we need configure our store differently:

```dart
config.set({
    "posts" : {
      "type" : Post,
      "serializer" : serializePost,
      "deserializer" : {
        "query" : deserializePost,
        "command" : updatePost
      }
    }
});
```

Where `updatePost`:

```dart
updatePost(Post post, CommandResponse r) {
  post.title = r.content["title"];
  return post;
}
```

In this case:

```dart
final post = new Post(123, "title");
store.update(post).then((updatedPost) {
  expect(updatedPost.title).toEqual("New");
  expect(post.title).toEqual("New");
  expect(post).toBe(updatedPost);
});
```

Finally, let's configure our store to handle errors differently:

```dart
config.set({
    "posts" : {
      "type" : Post,
      "serializer" : serializePost,
      "deserializer" : {
        "query" : deserializePost,
        "command" : {
          "success" : updatePost,
          "error" : parseErrors
        }
      }
    }
});
```

Where `parseErrors`:

```dart
parseErrors(Post post, CommandResponse r) {
  return r.content["errors"];
}
```

Now, if the backend returns `{"errors" : {"title": ["some error"]}}`.

```dart
final post = new Post(123, "title");
store.update(post).catchError((errs) {
  expect(errs["title"]).toEqual(["some error"]);
});
```

### Custom Queries and Commands

Similar to `ResourceStore`, `ObjectStore` supports custom queries and commands.




## Async Deserializers

Hammock support deserializers returning `Future`s, which can be useful for a variety of things:

* You can fetch some extra information while deserializing an object.
* You can implement error handling in your success deserializer. Just return a `Future.error`.


```dart
class DeserializePost {
  ObjectStore store;
  DeserializePost(this.store);

  call(Resource r) {
    final post = new Post(r.id, r.content["title"]);
    return store.scope(post).list(Comment).then((comments) {
      post.comments = comments;
      return post;
    });
  }
}
```


## Injectable Serializers and Deserializers

If you pass a type as a serializer or a deserializer, Hammock will use `Injector` to get an instance of that type.

```dart
config.set({
    "posts" : {
      "type" : Post,
      "deserializer" : DeserializePost
      }
    }
});
```