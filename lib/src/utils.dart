part of hammock;

class _Undefined {
  const _Undefined();
}
const _u = const _Undefined();

_wrappedIntoErrorFuture(res) {
  if (res is Future) {
    return res.then((r) => new Future.error(r));
  } else {
    return new Future.error(res);
  }
}

_wrappedListIntoFuture(List list) {
  if (list.any((v) => v is Future)) {
    final wrappedInFutures = list.map((v) => new Future.value(v));
    return Future.wait(wrappedInFutures);
  } else {
    return list;
  }
}