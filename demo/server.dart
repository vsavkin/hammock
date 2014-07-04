library server;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http_server/http_server.dart' show VirtualDirectory;
import 'dart:convert' show UTF8;

final postsReg = new RegExp(r'/api/sites/(\d+)/posts$');
final siteReg = new RegExp(r'/api/sites/(\d+)$');
final postReg = new RegExp(r'/api/sites/(\d+)/posts/(\d+)$');

var sites = [
    {"id" : 1, "name" : "Site1"},
    {"id" : 2, "name" : "Site2"}
];

var posts = [
    {"siteId" : 1, "id" :  10, "title" : "Post1", "views" : 10},
    {"siteId" : 1, "id" :  20, "title" : "Post2", "views" : 20},
    {"siteId" : 2, "id" :  30, "title" : "Post3", "views" : 30}
];

handleRequest(HttpRequest request) {
  final p = request.uri.path;

  print("PROCESSING REQUEST: ${request.method} $p");

  respond(obj, [status=200]){
    print("RESPONSE: $status $obj");
    request.response.statusCode = status;
    request.response.write(new JsonEncoder().convert(obj));
    request.response.close();
  }
  decode(str) => new JsonDecoder().convert(str);
  siteId(regExp) => int.parse(regExp.firstMatch(p).group(1));
  postId(regExp) => int.parse(regExp.firstMatch(p).group(2));

  handleSitesGet() {
    respond(sites);
  }

  handleSitePut() {
    UTF8.decodeStream(request).then(decode).then((body) {
      print("REQUEST PAYLOAD: $body");

      if (body["name"].isEmpty) {
        respond({
          "errors" : ["Name must be present"]
        }, 422);
      } else {
        sites.removeWhere((s) => s["id"] == siteId(siteReg));
        sites.add(body);
        respond({});
      }
    });
  }

  handlePostsGet() {
    respond(posts.where((p) => p["siteId"] == siteId(postsReg)).toList());
  }

  handlePostDelete() {
    posts.removeWhere((p) => p["id"] == postId(postReg));
    respond({});
  }



  if ('/api/sites' == p) {
    handleSitesGet();

  } else if (siteReg.hasMatch(p)) {
    if (request.method == "PUT") handleSitePut();

  } else if (postsReg.hasMatch(p)) {
    handlePostsGet();

  } else if (postReg.hasMatch(p)) {
    if (request.method == "DELETE") handlePostDelete();
  }
}

main() {
  HttpServer.bind("127.0.0.1", 3001).then((server){
    final vDir = new VirtualDirectory(Platform.script.resolve('./web').toFilePath())
      ..followLinks = true
      ..allowDirectoryListing = true
      ..jailRoot = false;

    server.listen((request) {
      if(request.uri.path.startsWith('/api')) {
        handleRequest(request);
      } else {
        vDir.serveRequest(request);
      }
    });
  });
}