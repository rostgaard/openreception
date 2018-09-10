part of ort.support;

class NoAvailable implements Exception {}

class NotAquired implements Exception {}

abstract class Pool<T> {
  static final Logger log = Logger('support.Pool');

  Queue<T> available = Queue();
  Set<T> busy = Set();

  Iterable get elements =>
      (Set()..addAll(this.available.toSet())..addAll(this.busy.toSet()));

  dynamic onAquire = (T element) => null;
  dynamic onRelease = (T element) => null;

  Pool(Iterable<T> element) {
    this.available.addAll(element);
  }

  T aquire() {
    if (this.available.isEmpty) {
      log.shout('No objects available');
      throw NoAvailable();
    }

    T aquired = this.available.removeFirst();
    this.busy.add(aquired);

    log.finest('Aquired pool object $aquired');

    onAquire(aquired);
    return aquired;
  }

  void release(T element) {
    if (!this.busy.contains(element)) {
      log.shout('Object is not aquired');
      throw NotAquired();
    }

    log.finest('Released pool object $element');

    this.busy.remove(element);
    this.available.add(element);
    onRelease(element);
  }
}
