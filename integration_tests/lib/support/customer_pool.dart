part of ort.support;

class CustomerPool extends Pool<Customer> {
  /// Singleton.
  static CustomerPool instance = null;

  CustomerPool(Iterable<Customer> elements) : super(elements);
}

class PhonePool {
  final pjsuaWrapperBinPath;
  final CircularCounter portCounter;

  PhonePool.empty(this.portCounter,
      {this.pjsuaWrapperBinPath: 'bin/basic_agent'});

  final List<Phonio.SIPPhone> allocated = [];

  Phonio.SIPPhone requestNext() {
    final phone = Phonio.PJSUAProcess(pjsuaWrapperBinPath, portCounter.nextInt);

    allocated.add(phone);
    return phone;
  }

  Future finalize() async {
    await Future.forEach(allocated, (Phonio.SIPPhone phone) async {
      if (phone is Phonio.PJSUAProcess) {
        await phone.finalize();
      } else {
        throw UnimplementedError(
            'Phone type ${phone.runtimeType} is not supported '
            'by $runtimeType class.');
      }
    });
  }
}
