part of ort.service;

abstract class MessageQueueStore {
  static final Logger log = Logger('$_namespace.MessageStore');

  /**
   *
   */
  static Future list(storage.MessageQueue messageStore) {
    log.info('Listing messages non-filtered.');

    return messageStore
        .list()
        .then((Iterable<model.MessageQueueEntry> entries) {
      expect(entries.every((msg) => msg is model.MessageQueueEntry), isTrue);
    });
  }
}
