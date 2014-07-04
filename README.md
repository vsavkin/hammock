# Hammock

AngularDart service for working with Rest APIs

[![Build Status](https://travis-ci.org/vsavkin/hammock.svg?branch=master)](https://travis-ci.org/vsavkin/hammock)



## Installation

You can find the Hammock installation instructions [here](http://pub.dartlang.org/packages/hammock#installing).



## Quick Start Guide

To use Hammock you need to install it:

    module.install(new Hammock());


Suppose we have this class defined:

```dart
class Post {
  int id;
  String title;
}
```

We need to configure Hammock to work with this class:

```dart
config.set({
    "posts" : {
        "type" : Post,
        "deserializer" : deserializePost,
        "serializer" : serializePost
    }
});
```

Where the serialization and deserialization functions are responsible for converting domain objects from/into resources.

```dart
Post deserializePost(Resource r) => new Post()
  ..id = r.id
  ..title = r.content["title"];

Resource serializePost(Post post) =>
    resource("posts", post.id, {"id" : post.id, "title" : post.title});
```

You don't have to define all these functions by hand. Any framework converting maps into objects and visa versa can be used here.

Now, having this configuration we can start loading and saving plain old Dart objects.

```dart
Future<Post> p = store.one(Post, 123);
Future<List<Post>> ps = store.list(Post);

final post = new Post()..id=456..title="title";
store.update(post); // PUT '/posts/456'
```






## Detailed Guide

### Main Abstractions

* `Document` is what is sent over the wire, and it can include one or many resources. It is a String.
* `Resource` is an addressable entity. It has a type, an id, and content. The content field is a Map.
* `ResourceStore` sends resources over the wire.
* `ObjectStore` converts objects into resources and sends them over the wire. It is built on top of `ResourceStore`.
* `HammockConfig` configures some aspects of `ResourceStore` and `ObjectStore`.



### Using Hammock

To use Hammock you need to install it:

    module.install(new Hammock());

After that the following services will become injectable:

* `ResourceStore`
* `ObjectStore`
* `HammockConfig`




### Using Resource

You can create a resource like this:

    resource("posts", 1, {"title": "some post"});

Resource has a type, an id, and content.




### Using ResourceStore

The `one` method, which takes a resource type and an id, loads a resource.

```dart
Future<Resource> r = store.one("posts", 123); // GET "/posts/123"
```

The `list` method, which takes a resource type, loads all the resources of the given type.

```dart
Future<List<Resource>> rs = store.list("posts"); // GET "/posts"
```

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

You can scope multiple times:

```dart
store.scope(blog).scope(post);
```

To create a resource call the `create` method:

```dart
final post = resource("posts", null, {"title": "New"}); 
store.create(post); // POST "/posts"
```

Use `update` to change the existing resource:

```dart
final post = resource("posts", 123, {"id": 123, "title": "New"}); 
store.update(post); // PUT "/posts/123"
```

Use `delete` to delete the existing resource:

```dart
final post = resource("posts", 123, {"id": 123, "title": "New"}); 
store.delete(post); // DELETE "/posts/123"
```

Use `scope` to create, update, and delete nested resources.

All the commands return a `CommandResponse`. For instance:

```dart
Future<CommandResponse> createdPost = store.create(post);
```

Use `customQueryOne` and `customQueryList` to make custom queries:

``dart
Future<Resource> r = store.customQueryOne("posts", new CustomRequestParams(method: "GET", url:"/posts/123"));
Future<List<Resource>> rs = store.customQueryList("posts", new CustomRequestParams(method: "GET", url:"/posts"));
``

And `customCommand` to execute custom commands:

``dart
final post = resource("posts", 123);
store.customCommand(post, new CustomRequestParams(method: 'DELETE', url: '/posts/123'));
``

Using custom queries and command is discouraged.


### Configuring ResourceStore

`HammockConfig` allows you to configure some aspects of `ResourceStore`.

### Setting Up Route

```dart
config.set({"posts" : {"route" : "custom"}});
```

`ResourceStore` will use "custom" to build the url when fetching/saving posts. For instance:

```dart
store.one("posts", 123) // GET "/custom/123"
```

#### Setting Up UrlRewriter

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

#### DocumentFormat

`DocumentFormat` defines how resources are serialized into documents. SimpleDocumentFormat is used by default. It can be overwritten as follows:

    config.documentFormat = new CustomDocumentFormat();

Please, see `integration_test.dart` for more details.


#### Configuring the Http Service

Hammock is built on top of the `Http` service provided by Angular. Consequently, you can configure Hammock by configuring `Http`.

```dart
final headers = injector.get(HttpDefaultHeaders);
headers.setHeaders({'Content-Type' : 'custom-type'}, 'GET');
```

### Using ObjectStore

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
}

class Comment {
  int id;
  String text;
}
```

We want to be able to work with `Post`s and `Comment`s, not with `Map`s.  To do that we need to configure our store:

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
Post deserializePost(Resource r) => new Post()
  ..id = r.id
  ..title = r.content["title"];

Resource serializePost(Post post) =>
    resource("posts", post.id, {"id" : post.id, "title" : post.title});

Comment deserializeComment(Resource r) => new Comment()
  ..id = r.id
  ..text = r.content["text"];

Resource serializeComment(Comment comment) =>
    resource("comments", comment.id, {"id" : comment.id, "text" : comment.text});
```

You don't have to define all these functions by hand. Any framework converting maps into objects and visa versa can be used here.

Now, having this configuration we can start loading and saving plain old Dart objects.

```dart
Future<Post> p = store.one(Post, 123);
Future<List<Post>> ps = store.list(Post);
Future<Comment> c = store.scope(post).one(Comment, 123);
Future<List<Comment>> cs = store.scope(post).list(Comment);
```

As you can see it is very similar to `ResourceStore`, but we can use our domain objects instead of `Resource`.

With the current configuration `create`, `update`, `delete` return a new object. For example:

```dart
final post = new Post()..id=123..title="title";
Future<Post> p = store.update(post); // PUT '/posts/123'
```

Let's say the backend returns the updated post object, for instance, serialized like this `{"id":123,"title":"New"}`.

```dart
final post = new Post()..id=123..title="title";
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
final post = new Post()..id=123..title="title";
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

Now, if the backend returns `{"errors" : ["Some Error"]}`.

```dart
final post = new Post()..id=123..title="title";
store.update(post).catchError((errs) {
  expect(errs).toEqual(["Some Error"]);
});
```

#### Async Deserializers

Hammock support deserializers returning `Future`s, which can be useful for a variety of things:

* You can fetch some extra information while deserializing an object.
* You can implement error handling in your success deserializer. Just return a `Future.error`.


#### Injected Serializers and Deserializers

If you pass a type as a serializer or a deserializer, Hammock will use `Injector` to get an instance of that type.

```dart
config.set({
    "posts" : {
      "type" : Post,
      "serializer" : PostSerializer
      }
    }
});

@Injected()
class PostSerializer {}
```




#### Custom Queries and Commands

Similar to `ResourceStore` `ObjectStore` supports custom queries and commands.


## Demo App

Check out a demo app [here](https://github.com/vsavkin/hammock/tree/master/demo).


## Design Principles

### Plain old Dart objects. No active record.

Angular is different from other client-side frameworks. It lets you use simple framework-agnostic objects for your components, controllers, formatters, etc.

In my opinion making users inherit from some class is against the Angular spirit. This is especially true when talking about domain objects. They should not have to know anything about Angular or the backend. Any object, including a simple `Map`, should be possible to load and save, if you wish so.

This means that:

```dart
post.update()
post.delete()
```

are not allowed.

### Convention over Configuration

Everything should work with the minimum amount of configuration, but, if needed, be extensible. It should be possible to configure how data is serialized, deserialized, etc.


