part of hammock;

class CustomRequestParams {
  final String url;
  final String method;
  final data;
  final Map<String, dynamic> params;
  final Map<String, dynamic> headers;
  final bool withCredentials;
  final xsrfHeaderName;
  final xsrfCookieName;
  final interceptors;
  final cache;
  final timeout;

  const CustomRequestParams({
    this.url,
    this.method,
    this.data,
    this.params,
    this.headers,
    this.withCredentials: false,
    this.xsrfHeaderName,
    this.xsrfCookieName,
    this.interceptors,
    this.cache,
    this.timeout
  });

  Future invoke(http) =>
      http(method: method, url: url, data: data, params: params, headers: headers,
        withCredentials: withCredentials, xsrfHeaderName: xsrfHeaderName,
        xsrfCookieName: xsrfCookieName, interceptors: interceptors, cache: cache,
        timeout: timeout);
}