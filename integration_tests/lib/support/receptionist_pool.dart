part of ort.support;

class ReceptionistPool extends Pool<Receptionist> {
  static ReceptionistPool instance = null;

  ReceptionistPool(Iterable<Receptionist> elements) : super(elements);

  Future initialized() async {
    for (final Receptionist r in elements) {
      await r.ready();
    }
  }
}
