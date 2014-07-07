# Hammock

AngularDart service for working with Rest APIs

[![Build Status](https://travis-ci.org/vsavkin/hammock.svg?branch=master)](https://travis-ci.org/vsavkin/hammock)



## Installation

You can find the Hammock installation instructions [here](http://pub.dartlang.org/packages/hammock#installing).

After you have installed the dependency, you need to install the Hammock module:

```dart
module.install(new Hammock());
```

This makes the following services injectable:

* `ResourceStore`
* `ObjectStore`
* `HammockConfig`




## Overview

This is how Hammock works:

![Overview](https://31.media.tumblr.com/34f3f94ac5b23a0c214ee63c129848b9/tumblr_n8atj11xtE1qc0howo2_500.png)

### Objects

`ObjectStore` converts domain objects into resources and sends them over the wire. It uses serialization and deserialization functions to do that. It is built on top of `ResourceStore`.

### Resources

`Resource` is an addressable entity that has a type, an id, and content. `Resource` is data, and it is immutable. `ResourceStore` sends resources over the wire.

### Documents

Document is what you send and receive from the server, and it is a String. It can include one or many resources. `DocumentFormat` specifies how to convert resources into documents and vice versa. By default, Hammock uses a very simple json-based document format, but you can provide your own, and it does not even have to be json-based.


Though at some point you may have to provision a new document format or deal with resources  directly, most of the time, you will use `ObjectStore`. That's why I will mostly talk about configuring and using `ObjectStore`.



## Queries and Commands

There are two types of operations in Hammock: queries and commands.

Queries:

```dart
Future one(type, id);
Future<List> list(type, {Map params});
Future customQueryOne(type, CustomRequestParams params);
Future<List> customQueryList(type, CustomRequestParams params);
```

Commands:

```dart
Future create(object);
Future update(object);
Future delete(object);
Future customCommand(object, CustomRequestParams params);
```

## Queries

![Queries](https://31.media.tumblr.com/a5623c9e88a2180358e3eae6e1dc51e1/tumblr_n8atj11xtE1qc0howo1_1280.png)


Hammock supports four types of queries: `one`, `list`, `customQueryOne`, and `customQueryList`.  All of them return either an object or a list of objects. You can think about queries as retrieving objects from a collection.

Let's say we have the following model defined:

```dart
class Post {
  int id;
  String title;
  Post(this.id, this.title);
}
```

And we want to use Hammock to fetch some posts from the backend. The first thing we need to do is provide this configuration:

```dart
config.set({
	"posts" : {
		"type" : Post,
		"deserializer": {"query" : deserializePost}
  }
})
```

Where `deserializePost` is defined as follows:

```dart
deserializePost(Resource r) => new Post(r.id, r.content["title"]);
```

This configuration tells Hammock that we have the resource type "posts", which is mapped to the class `Post`, and when querying we should use `deserializePost` to convert resources into `Post` objects. Pretty straightforward.

Let's try some queries:

```dart
Future<Post> p = store.one(Post, 123); 	   // GET /posts/123
Future<List<Post>> ps = store.list(Post);  // GET /posts
Future<List<Post>> ps = store.list(Post, params: {"createdAfter": "2014"}); // GET /posts?createdAfter=2014
```



## Commands

![Commands](https://31.media.tumblr.com/e7c5c9af9804eae0ec3af8ff72d3f93a/tumblr_n8atj11xtE1qc0howo3_1280.png)

Hammock has four types of commands: `create`, `update`, `delete`, and `customCommand`.

Let's start with something very simple - deleting a post.

Having the following configuration:

```dart
config.set({
	"posts" : {
		"type" : Post
   }
});
```

we can delete a post:

		Future c = store.delete(post); // DELETE /posts/123

### Defining Serializers

Now, something a bit more complicated. Let's create a new post.

		store.create(new Post(null, "some title")); // POST /posts

If we execute this command, we will see the following error message: `No serializer for posts`. This makes sense if you think about it. The creation of a new resource involves submitting a document with that resource.

To fix this problem we need to define a serializer.

```dart
config.set({
	"posts" : {
		"type" : Post,
		"serializer" : serializePost
  }
});

Resource serializePost(Post post) =>
	  resource("posts", post.id, {"id" : post.id, "title" : post.title});
```

The error message is gone, and the resource has been successfully created. There is an issue however; we do not know the id of the created post.

To fix it we need to look at the response that we got after submitting our post. Let's say it looked something like this:

```dart
{"id" : 8989, "title" : "some title"}
```

### Defining Deserializers

How do we use this response to update our `Post` object? We need to define a special deserializer.

```dart
config.set({
	"posts" : {
		"type" : Post,
		"serializer" : serializePost,
		"deserializer" : {"command" : updatePost}
  }
});

Post updatePost(Post post, CommandResponse resp) {
  post.id = resp.content["id"];
  return post;
}
```

As you have probably noticed, command deserializers are slightly different from query deserializers. Whereas query deserializers always create a new object, command deserializers are more generic, and can, for instance, update an existing object.

Having all this in place, we have finally gotten the behaviour we wanted:

```dart
final post = new Post(null, "some title");
store.create(post).then((_) {
  //post.id == 8989; when the callback is called, the id field has been already set.
});
```

### FP

If you are a fan of functional programming, you do not want to have all these side effects in your deserializer. Instead, you want to create a new `Post` object with the id field set. Hammock supports this use case:

```dart
Post updatePost(Post post, CommandResponse resp) =>
    new Post(resp.content["id"], resp.content["title"]);
```

And since it is so common, you can use query deserializers for this purpose.

```dart
config.set({
  "posts" : {
  	"type" : Post,
  	"serializer" : serializePost,
  	"deserializer" : {"command" : deserializePost}
  }
});

deserializePost(Resource r) => new Post(r.id, r.content["title"]);
```

### Error Handling

Let's say we are trying to save a post with a blank title.

```dart
store.create(new Post(null, ""));
```

This server does not like it and responds with an error.

```dart
{"errors" : {"title" : ["cannot be blank"]}}
```

How can we handle this error?

The first approach is to modify `updatePost`, as follows:

```dart
Post updatePost(Post post, CommandResponse resp) {
  if (resp.content["errors"] != null) throw resp.content["errors"];
  return new Post(resp.content["id"], resp.content["title"]);
}
```

After that:

```dart
store.create(new Post(null, "")).catchError((errors) => showErrors(errors));
```

The downside is that we have to do this check in all your deserializers. This is not DRY. What we can do instead is to define a special deserializer for errors.

```dart
parseErrors(obj, CommandResponse resp) => resp.content["errors"];

config.set({
	"posts" : {
		"type" : Post,
		"serializer" : serializePost,
		"deserializer" :
		  {"command" : {
	        "success" : deserializePost,
	        "error" : parseErrors}
	  }
  }
});
```

It achieves the same affect but keeps error handling separate.

Finally, if we choose to store errors on the domain object itself, it is easily configurable.

```dart
class Post {
  int id;
  String title;
  Map errors = {};
  Post(this.id, this.title);
}
parseErrors(obj, CommandResponse resp) {
  obj.errors = resp.content["errors"];
  return obj;
}
```



## Nested Resources

Hammock supports nested resources.

```dart
class Comment {
  int id;
  String text;
  Comment(this.id, this.text);
}
store.scope(post).list(Comment); // GET /posts/123/comments
store.scope(post).update(comment); // POUT /posts/123/comments/456
```


## Async Deserializers and Handling Associations

Hammock does not have the notion of an association. But since the library is flexible enough, we can implement it ourselves.

Let's add comments to `Post`.

```dart
class Post {
  int id;
  String title;
  List comments = [];
  Post(this.id, this.title);
}
```

And change our deserializer to fetch all the comments of the given post:

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

config.set({
	"posts" : {
		"type" : Post,
		"serializer" : serializePost,
		"deserializer" : DeserializePost
  },
	"comments" : {
		"type" : Comment,
		"deserializer" : deserializeComment
  }
});
```

There are a few interesting things shown here. First, Hammock supports async deserializers, which, as you can see, is very handy for loading additional resources during deserialization. Second, when given a type, Hammock will use `Injector` to get an instance of that type. This allows us to pass `ObjectStore` into our deserializer.

Now, having all of this defined, we can run:

```dart
store.one(Post, 123).then((post) {
  //post.comments are present
});
```



## No Active Record

Angular is different from other client-side frameworks. It lets us use simple framework-agnostic objects for our components, controllers, formatters, etc. Making users inherit from some class is against the Angular spirit. This is especially true when talking about domain objects. They should not have to know anything about Angular or the backend. Any object, including a simple 'Map', should be possible to load and save, if we wish so. That's why Hammock does not use the active record pattern. The library makes NO assumptions about the objects it works with. This is good news for FP and DDD fans.




## Detailed Guide

You can find a more detailed guide to Hammock [here](https://github.com/vsavkin/hammock/blob/master/DETAILED_GUIDE.md).

