import 'dart:async';
import 'dart:io';
import 'dart:math' show Random;

import 'package:logging/logging.dart';
import 'package:ort/support.dart' as support;
import 'package:phonio/phonio.dart' as Phonio;

Logger log = Logger('Call-Spawner');
Logger _statusLog = Logger('Status');

const List<String> _receptionNumbers = const [
  '12340001',
  '12340002',
  '12340003',
  '12340004',
  '12340005',
  '12340006'
];
final Random rand = Random(DateTime.now().millisecondsSinceEpoch);

enum CallDirection { inbound, outbound }

Map<String, CallDirection> _calls = {};
Set<support.Customer> customers = Set();

Iterable _outboundCalls() =>
    _calls.values.where((CallDirection dir) => dir == CallDirection.outbound);

Iterable _inboundCalls() =>
    _calls.values.where((CallDirection dir) => dir == CallDirection.inbound);

String status() =>
    'Outbound calls: ${_outboundCalls().length}, inbound calls: ${_inboundCalls().length}';

void updateStatus() {
//  stdout.writeCharCode(27);
//  stdout.write('[2J');
//  stdout.writeCharCode(27);
//  stdout.write('[H');

//  stdout.write(status());
  _statusLog.info(status());
}

dynamic _randomChoice(List pool) {
  if (pool.isEmpty) {
    throw ArgumentError('Cannot find a random value in an empty list');
  }

  final int index = rand.nextInt(pool.length);

  return pool[index];
}

bool _stopping = false;

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen(print);

  //support.SupportTools st;

  ProcessSignal.sigint.watch().listen((_) {
    log.info('SIGINT caught, hanging up all calls.');
    _stopping = true;

    //st.tearDownCustomers();

    return Future.delayed(Duration(seconds: 3))
        .then((_) => updateStatus())
        .then((_) => exit(0));
  });

  ProcessSignal.sigterm.watch().listen((_) {
    log.info('SIGTERM caught, hanging up all calls.');
    _stopping = true;

    customers.forEach((support.Customer customer) => customer.hangupAll());

    return Future.wait(
            customers.map((support.Customer customer) => customer.hangupAll()))
        .then((_) => log.info('Hung up all calls.'))
        .then((_) => Future.delayed(Duration(seconds: 3)))
//        .then((_) => st.tearDown())
        .then((_) => Future.delayed(Duration(seconds: 3)).then((_) => exit(0)));
  });

//   support.SupportTools.instance
//       .then((support.SupportTools init) => st = init)
//       .then((_) => print(st))
//       .then((_) => start_spawning());
}

Future start_spawning() async {
  support.CustomerPool.instance.available;

  Set<support.Customer> customers = await getCustomers();
  customers.forEach((support.Customer c) {
    print(c.extension);
  });

  // Each customer spawns a call
  return Future.forEach(customers, (support.Customer customer) {
    customerAutoDialing(customer);
  });
}

Duration _randomWait() => Duration(milliseconds: rand.nextInt(3000) + 500);

String _id(support.Customer customer, String id) => '${customer.hashCode}_$id';

Future customerAutoDialing(support.Customer customer) {
  StreamSubscription subscription;
  subscription = customer.phoneEvents.listen((Phonio.Event event) {
    // Spawn a call as soon as the old call is disconnected.
    if (event is Phonio.CallDisconnected) {
      bool outbound =
          _calls[_id(customer, event.callId)] == CallDirection.outbound;

      _calls.remove(_id(customer, event.callId));

      updateStatus();

      if (_stopping) {
        subscription.cancel();
        return;
      }

      if (outbound) {
        Future.delayed(Duration(milliseconds: 100))
            .then((_) => customer.dial(_randomChoice(_receptionNumbers)));
      }
    } else if (event is Phonio.CallIncoming) {
      _scheduleHangup(customer, event.callId);

      final List<int> actions = List.generate(10, (int i) => i);
      final chosenAction = _randomChoice(actions);

      log.info('Got incoming call to ${event.callee}');

      _calls[_id(customer, event.callId)] = CallDirection.inbound;
      updateStatus();

      if (chosenAction < 2) {
        Phonio.Call call = customer.call.firstWhere(
            (Phonio.Call call) => call.id == event.callId,
            orElse: () => null);

        if (call != null) {
          Duration randomWait = _randomWait();
          log.info(
              'Declining call to ${event.callee} in ${randomWait.inMilliseconds}ms');
          Future.delayed(randomWait).then((_) => customer.hangup(call));
        } else {
          log.warning('Failed to hangup call with ID ${call.id}');
        }
      } else if (chosenAction < 4) {
        log.info('Ignoring call to ${event.callee}');
        //Perform no actions, just let it ring.
      } else {
        Duration randomWait = _randomWait();

        log.info('Waiting ${randomWait.inMilliseconds}ms to answer call '
            'to ${event.callee}');

        Phonio.Call call = customer.phone.activeCalls
            .firstWhere((Phonio.Call call) => call.id == event.callId);

        Future.delayed(randomWait).then((_) => customer.pickup(call));
      }
    } else if (event is Phonio.CallOutgoing) {
      _scheduleHangup(customer, event.callId);
      _calls[_id(customer, event.callId)] = CallDirection.outbound;
      updateStatus();
    }
  });

  int outboundCallsPerAgent = 1;
  return Future.doWhile(() {
    outboundCallsPerAgent = outboundCallsPerAgent - 1;
    return Future.delayed(Duration(milliseconds: 50))
        .then((_) => customer.dial(_randomChoice(_receptionNumbers)).then((_) {
              return outboundCallsPerAgent != 0 && !_stopping;
            }));
  });
}

Future getCustomers() async {
  while (support.CustomerPool.instance.available.length > 0) {
    customers.add(support.CustomerPool.instance.aquire());
  }

  return Future.wait(
          customers.map((support.Customer customer) => customer.initialize()))
      .then((_) => customers);
}

Future _scheduleHangup(support.Customer customer, String callId) {
  log.info('Scheduling hangup of call with id ${callId} '
      'for agent ${customer.phone.defaultAccount.username}');

  return Future.delayed(Duration(seconds: 60)).then((_) {
    Phonio.Call call = customer.phone.activeCalls.firstWhere(
        (Phonio.Call call) => call.id == callId,
        orElse: () => null);

    return call != null ? customer.hangup(call) : null;
  });
}
