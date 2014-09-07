part of hammock;

class RequestDefaults {
  Map<String, dynamic> params;
  Map<String, dynamic> headers;
  bool withCredentials;
  String xsrfHeaderName;
  String xsrfCookieName;
  var interceptors;
  var cache;
  var timeout;

  RequestDefaults({
    this.params,
    this.headers,
    this.withCredentials: false,
    this.xsrfHeaderName,
    this.xsrfCookieName,
    this.interceptors,
    this.cache,
    this.timeout
  });
}