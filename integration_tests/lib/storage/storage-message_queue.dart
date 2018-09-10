part of ort.storage;

abstract class MessageQueue {
  static final Logger log = Logger('$_libraryName.MessageQueue');

  /**
   *
   */
  static Future list(ServiceAgent sa) async {
    log.info('Listing message queue entries non-filtered.');

    final org = await sa.createsOrganization();
    final rec = await sa.createsReception(org);
    final con = await sa.createsContact();
    await sa.addsContactToReception(con, rec);

    final context = model.MessageContext.empty()
      ..cid = con.id
      ..rid = rec.id
      ..contactName = con.name
      ..receptionName = rec.name;

    final msg1 = await sa.createsMessage(context);
    await sa.messageQueue.enqueue(msg1);

    {
      final listing = await sa.messageQueue.list();

      expect(listing.length, equals(1));
      expect(listing.any((mqe) => mqe.message.id == msg1.id), isTrue);
    }
    final msg2 = await sa.createsMessage(context);
    await sa.messageQueue.enqueue(msg2);

    {
      final listing = await sa.messageQueue.list();

      expect(listing.length, equals(2));
      expect(listing.any((mqe) => mqe.message.id == msg2.id), isTrue);
    }
  }

  /**
   *
   */
  static Future enqueue(ServiceAgent sa) async {
    final org = await sa.createsOrganization();
    final rec = await sa.createsReception(org);
    final con = await sa.createsContact();
    final attr = await sa.addsContactToReception(con, rec);

    final context = model.MessageContext.empty()
      ..cid = con.id
      ..rid = rec.id
      ..contactName = con.name
      ..receptionName = rec.name;

    final msg1 = await sa.createsMessage(context);
    await sa.messageQueue.enqueue(msg1);

    {
      final listing = await sa.messageQueue.list();
      expect(listing.length, equals(1));

      final queueEntry = listing.first;
      expect(queueEntry.id, greaterThan(model.MessageQueueEntry.noId));
      expect(queueEntry.handledRecipients, isEmpty);
      expect(queueEntry.unhandledRecipients, equals(attr.endpoints));
      expect(queueEntry.tries, equals(0));
      expect(queueEntry.createdAt.isBefore(DateTime.now()), isTrue);
      expect(queueEntry.createdAt.difference(DateTime.now()),
          greaterThan(Duration(seconds: -1)));
    }
  }

  /**
   *
   */
  static Future remove(ServiceAgent sa) async {
    final org = await sa.createsOrganization();
    final rec = await sa.createsReception(org);
    final con = await sa.createsContact();
    await sa.addsContactToReception(con, rec);

    final context = model.MessageContext.empty()
      ..cid = con.id
      ..rid = rec.id
      ..contactName = con.name
      ..receptionName = rec.name;

    final msg1 = await sa.createsMessage(context);
    await sa.messageQueue.enqueue(msg1);
    int mqid;
    {
      final listing = await sa.messageQueue.list();
      expect(listing.length, equals(1));
      mqid = listing.first.id;
    }

    await sa.messageQueue.remove(mqid);
    {
      final listing = await sa.messageQueue.list();
      expect(listing.length, equals(0));
    }
  }

  /**
   *
   */
  static Future update(ServiceAgent sa) async {
    final org = await sa.createsOrganization();
    final rec = await sa.createsReception(org);
    final con = await sa.createsContact();
    final attr = await sa.addsContactToReception(con, rec);

    final context = model.MessageContext.empty()
      ..cid = con.id
      ..rid = rec.id
      ..contactName = con.name
      ..receptionName = rec.name;

    final msg1 = await sa.createsMessage(context);
    await sa.messageQueue.enqueue(msg1);

    {
      final listing = await sa.messageQueue.list();
      expect(listing.length, equals(1));

      final queueEntry = listing.first;

      /// Handle all recipients
      queueEntry.handledRecipients = queueEntry.unhandledRecipients;
      queueEntry.tries++;

      log.info('Updating queue entry');
      await sa.messageQueue.update(queueEntry);
    }

    {
      final listing = await sa.messageQueue.list();
      expect(listing.length, equals(1));

      final queueEntry = listing.first;
      expect(queueEntry.id, greaterThan(model.MessageQueueEntry.noId));
      expect(queueEntry.unhandledRecipients, isEmpty);
      expect(queueEntry.handledRecipients, equals(attr.endpoints.toSet()));
      expect(queueEntry.tries, equals(1));
      expect(queueEntry.createdAt.isBefore(DateTime.now()), isTrue);
      expect(queueEntry.createdAt.difference(DateTime.now()),
          greaterThan(Duration(seconds: -1)));
    }
  }
}
