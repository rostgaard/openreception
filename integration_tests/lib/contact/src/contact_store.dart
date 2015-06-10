part of or_test_fw;

abstract class ContactStore {

  static final Logger log = new Logger ('$libraryName.ContactStore');

  /**
   * Test for the presence of CORS headers.
   */
  static Future isCORSHeadersPresent(HttpClient client) {

    Uri uri = Uri.parse ('${Config.contactStoreUri}/nonexistingpath');

    log.info('Checking CORS headers on a non-existing URL.');
    return client.getUrl(uri)
      .then((HttpClientRequest request) => request.close()
      .then((HttpClientResponse response) {
        if (response.headers['access-control-allow-origin'] == null &&
            response.headers['Access-Control-Allow-Origin'] == null) {
          fail ('No CORS headers on path $uri');
        }
      }))
      .then ((_) {
        log.info('Checking CORS headers on an existing URL.');
        uri = Resource.Reception.single (Config.contactStoreUri, 1);
        return client.getUrl(uri)
          .then((HttpClientRequest request) => request.close()
          .then((HttpClientResponse response) {
          if (response.headers['access-control-allow-origin'] == null &&
              response.headers['Access-Control-Allow-Origin'] == null) {
            fail ('No CORS headers on path $uri');
          }
      }));
    });
  }

  /**
   * Test server behaviour when trying to access a resource not associated with
   * a handler.
   *
   * The expected behaviour is that the server should return a Not Found error.
   */
  static Future nonExistingPath (HttpClient client) {

    Uri uri = Uri.parse ('${Config.contactStoreUri}/nonexistingpath?token=${Config.serverToken}');

    log.info('Checking server behaviour on a non-existing path.');

    return client.getUrl(uri)
      .then((HttpClientRequest request) => request.close()
      .then((HttpClientResponse response) {
        if (response.statusCode != 404) {
          fail ('Expected to received a 404 on path $uri');
        }
      }))
      .then((_) => log.info('Got expected status code 404.'))
      .whenComplete(() => client.close(force : true));
  }

  /**
   * Test server behaviour when trying to aquire a contact object that
   * does not exist.
   *
   * The expected behaviour is that the server should return a Not Found error.
   */
  static void nonExistingContact (Storage.Contact contactStore) {

    log.info('Checking server behaviour on a non-existing contact.');

    return expect(contactStore.get(-1),
            throwsA(new isInstanceOf<Storage.NotFound>()));
  }

  /**
   * Test server behaviour when trying to aquire a list of contact objects from
   * a reception.
   *
   * The expected behaviour is that the server should return a list of
   * contact objects.
   */
  static Future listContactsByExistingReception (Storage.Contact contactStore) {
    const int receptionID = 1;
    log.info('Checking server behaviour on list of contacts in reception $receptionID.');

    return contactStore.listByReception(receptionID)
        .then((Iterable<Model.Contact> contacts) {
      expect(contacts, isNotNull);
      expect(contacts, isNotEmpty);
    });
  }

  /**
   * Test server behaviour when trying to aquire a list of contact objects from
   * a non existing reception.
   *
   * The expected behaviour is that the server should return an empty list.
   */
  static Future listContactsByNonExistingReception (Storage.Contact contactStore) {
    const int receptionID = -1;
    log.info('Checking server behaviour on list of contacts in reception $receptionID.');

    return contactStore.listByReception(receptionID)
      .then((Iterable<Model.Contact> contacts) {
        expect(contacts, isEmpty);
      });
  }

  /**
   * Test server behaviour when trying to list calendar events associated with
   * a given contact.
   *
   * The expected behaviour is that the server should return a list of
   * CalendarEntry objects.
   */
  static void existingContactCalendar (Storage.Contact contactStore) {
    int receptionID = 1;
    int contactID = 4;

    log.info('Looking up calendar list for contact $contactID@$receptionID.');

    return expect(contactStore.calendar (contactID, receptionID), isNotNull);
  }

  /**
   * Test server behaviour when trying to create a new calendar event object.
   *
   * The expected behaviour is that the server should return the created
   * CalendarEntry object.
   */
  static Future calendarEntryCreate (Storage.Contact contactStore) {

    int receptionID = 1;
    int contactID = 4;

    Model.CalendarEntry event =
        new Model.CalendarEntry.contact(contactID, receptionID)
         ..beginsAt    = new DateTime.now()
         ..until       = new DateTime.now().add(new Duration(hours: 2))
         ..content     = Randomizer.randomEvent();

    log.info('Creating a calendar event for contact $contactID@$receptionID.');

    return contactStore.calendarEventCreate(event)
        .then((Model.CalendarEntry createdEvent) {
          expect(event.content, equals(createdEvent.content));

          // We round to the nearest second, and have to compensate for skew.
          expect(event.start.difference(createdEvent.start),
              lessThan(new Duration(seconds : 1)));
          expect(event.stop.difference(createdEvent.stop),
              lessThan(new Duration(seconds : 1)));
          expect(event.receptionID, equals(createdEvent.receptionID));
          expect(event.contactID, equals(createdEvent.contactID));

    });
  }

  /**
   * Test server behaviour when trying to create a new calendar event object.
   *
   * The expected behaviour is that the server should return the created
   * CalendarEntry object and send out a CalendarEvent notification.
   */
  static Future calendarEntryCreateEvent (Storage.Contact contactStore,
                                          Receptionist receptionist) {

    int receptionID = 1;
    int contactID = 4;

    Model.CalendarEntry event =
        new Model.CalendarEntry.contact(contactID, receptionID)
         ..beginsAt    = new DateTime.now()
         ..until       = new DateTime.now().add(new Duration(hours: 2))
         ..content     = Randomizer.randomEvent();

    log.info('Creating a calendar event for contact $contactID@$receptionID.');

    return contactStore.calendarEventCreate(event)
        .then((Model.CalendarEntry createdEvent) {
          expect(event.content, equals(createdEvent.content));

          // We round to the nearest second, and have to compensate for skew.
          expect(event.start.difference(createdEvent.start),
              lessThan(new Duration(seconds : 1)));
          expect(event.stop.difference(createdEvent.stop),
              lessThan(new Duration(seconds : 1)));
          expect(event.receptionID, equals(createdEvent.receptionID));
          expect(event.contactID, equals(createdEvent.contactID));

          return receptionist.waitFor(eventType: Event.Key.calendarChange)
            .then((Event.CalendarChange event) {
              expect (event.contactID, equals(contactID));
              expect (event.receptionID, equals(receptionID));
              expect (event.entryID, greaterThan(Model.CalendarEntry.noID));
              expect (event.state, equals(Event.CalendarEntryState.CREATED));
           });
    });
  }


  /**
   * Test server behaviour when trying to update a calendar event object that
   * exists.
   *
   * The expected behaviour is that the server should return the updated
   * CalendarEntry object.
   */
  static Future calendarEntryUpdate (Storage.Contact contactStore) {

    int receptionID = 1;
    int contactID = 4;

    return contactStore.calendar(contactID, receptionID)
      .then((Iterable <Model.CalendarEntry> events) {

      // Update the last event in list.
      Model.CalendarEntry event = events.last
          ..beginsAt    = new DateTime.now()
          ..until       = new DateTime.now().add(new Duration(hours: 2))
          ..content     = Randomizer.randomEvent();

      log.info
        ('Got event ${event.asMap} - ${event.contactID}@${event.receptionID}');

      log.info
        ('Updating a calendar event for contact $contactID@$receptionID.');

      return contactStore.calendarEventUpdate(event)
          .then((Model.CalendarEntry updatedEvent) {
            expect(event.content, equals(updatedEvent.content));
            expect(event.ID, equals(updatedEvent.ID));

            // We round to the nearest second, and have to compensate for skew.
            expect(event.start.difference(updatedEvent.start),
                lessThan(new Duration(seconds : 1)));
            expect(event.stop.difference(updatedEvent.stop),
                lessThan(new Duration(seconds : 1)));
            expect(event.receptionID, equals(updatedEvent.receptionID));
            expect(event.contactID, equals(updatedEvent.contactID));

      });
    });
  }

  /**
   * Test server behaviour when trying to update a calendar event object that
   * exists.
   *
   * The expected behaviour is that the server should return the updated
   * CalendarEntry object and send out a CalendarEvent notification.
   */
  static Future calendarEntryUpdateEvent (Storage.Contact contactStore,
                                          Receptionist receptionist) {

    int receptionID = 1;
    int contactID = 4;

    return contactStore.calendar(contactID, receptionID)
      .then((Iterable <Model.CalendarEntry> events) {

      // Update the last event in list.
      Model.CalendarEntry event = events.last
          ..beginsAt    = new DateTime.now()
          ..until       = new DateTime.now().add(new Duration(hours: 2))
          ..content     = Randomizer.randomEvent();

      log.info
        ('Got event ${event.asMap} - ${event.contactID}@${event.receptionID}');

      log.info
        ('Updating a calendar event for contact $contactID@$receptionID.');

      return contactStore.calendarEventUpdate(event)
          .then((Model.CalendarEntry updatedEvent) {
            expect(event.content, equals(updatedEvent.content));
            expect(event.ID, equals(updatedEvent.ID));

            // We round to the nearest second, and have to compensate for skew.
            expect(event.start.difference(updatedEvent.start),
                lessThan(new Duration(seconds : 1)));
            expect(event.stop.difference(updatedEvent.stop),
                lessThan(new Duration(seconds : 1)));
            expect(event.receptionID, equals(updatedEvent.receptionID));
            expect(event.contactID, equals(updatedEvent.contactID));

            return receptionist.waitFor(eventType: Event.Key.calendarChange)
              .then((Event.CalendarChange event) {
                expect (event.contactID, equals(contactID));
                expect (event.receptionID, equals(receptionID));
                expect (event.entryID, greaterThan(Model.CalendarEntry.noID));
                expect (event.state, equals(Event.CalendarEntryState.UPDATED));
             });

      });
    });
  }

  /**
   * Test server behaviour when trying to aquire a calendar event object that
   * exists.
   *
   * The expected behaviour is that the server should return the
   * CalendarEntry object.
   */
  static Future calendarEntryExisting (Storage.Contact contactStore) {

    int receptionID = 1;
    int contactID = 4;

    log.info('Checking server behaviour on an existing calendar event.');

    log.info('Listing all events');
    return contactStore.calendar(contactID, receptionID)
        .then ((Iterable<Model.CalendarEntry> events) {
      log.info('Selecting last event in list');
      int eventID = events.last.ID;

      log.info('Selected ${events.last.asMap}, fetching it');

      return contactStore.calendarEvent(receptionID, contactID , eventID)
        .then((Model.CalendarEntry receivedEvent) {
        log.info('Received ${receivedEvent}');
          expect (receivedEvent.ID, equals(eventID));
      });
    });
  }

  /**
   * Test server behaviour when trying to aquire a calendar event object that
   * is not existing - or not referenced by the contact passed by parameter.
   *
   * The expected behaviour is that the server should return "Not Found".
   */
  static void calendarEntryNonExisting (Storage.Contact contactStore) {

    int receptionID = 1;
    int contactID = 4;
    int eventID = 0;

    log.info('Checking server behaviour on a non-existing calendar event.');

    return expect(contactStore.calendarEvent(receptionID, contactID, eventID),
            throwsA(new isInstanceOf<Storage.NotFound>()));
  }

  /**
   * Test server behaviour when trying to delete a calendar event object that
   * exists.
   *
   * The expected behaviour is that the server should succeed.
   */
  static Future calendarEntryDelete (Storage.Contact contactStore) {

    int receptionID = 1;
    int contactID = 4;

    return contactStore.calendar(contactID, receptionID)
      .then((Iterable <Model.CalendarEntry> events) {

      // Update the last event in list.
      Model.CalendarEntry event = events.last;

      log.info
        ('Got event ${event.asMap} - ${event.contactID}@${event.receptionID}');

      log.info
        ('Deleting last calendar event for contact $contactID@$receptionID.');

      return contactStore.calendarEventRemove(event)
        .then((_) {

        return expect(contactStore.calendarEvent(receptionID, contactID, event.ID),
                throwsA(new isInstanceOf<Storage.NotFound>()));
      });
    });
  }

  /**
   * Test server behaviour when trying to delete a calendar event object that
   * exists.
   *
   * The expected behaviour is that the server should succeed and send out a
   * CalendarChange Notification.
   */
  static Future calendarEntryDeleteEvent (Storage.Contact contactStore,
                                          Receptionist receptionist) {

    int receptionID = 1;
    int contactID = 4;

    return contactStore.calendar(contactID, receptionID)
      .then((Iterable <Model.CalendarEntry> events) {

      // Update the last event in list.
      Model.CalendarEntry event = events.last;

      log.info
        ('Got event ${event.asMap} - ${event.contactID}@${event.receptionID}');

      log.info
        ('Deleting last calendar event for contact $contactID@$receptionID.');

      return contactStore.calendarEventRemove(event).then((_) {
        return receptionist.waitFor(eventType: Event.Key.calendarChange)
          .then((Event.CalendarChange event) {
            expect (event.contactID, equals(contactID));
            expect (event.receptionID, equals(receptionID));
            expect (event.entryID, greaterThan(Model.CalendarEntry.noID));
            expect (event.state, equals(Event.CalendarEntryState.DELETED));
         });
      });
    });

  }

  /**
   * Test server behaviour when trying to retrieve an endpoint list of a
   * contact.
   *
   * The expected behaviour is that the server should succeed.
   */
  static Future endpoints (Service.RESTContactStore contactStore) {

    int receptionID = 1;
    int contactID = 4;

    return contactStore.endpoints(contactID, receptionID)
      .then((Iterable <Model.MessageEndpoint> endpoints) {
        expect(endpoints, isNotNull);
    });
  }

  /**
   * Test server behaviour when trying to retrieve an phone list of a
   * contact.
   *
   * The expected behaviour is that the server should succeed.
   */
  static Future phones (Service.RESTContactStore contactStore) {

    int receptionID = 1;
    int contactID = 4;

    return contactStore.phones(contactID, receptionID)
      .then((Iterable <Model.PhoneNumber> endpoints) {
        expect(endpoints, isNotNull);
    });
  }

  /**
   * Test server behaviour with regards to calendar changes.
   * This function creates an entry and asserts that a change is also present.
   */
  static Future calendarEntryChangeCreate
    (Service.RESTContactStore contactStore) {

    int receptionID = 1;
    int contactID = 4;

    Model.CalendarEntry entry =
        new Model.CalendarEntry.contact(contactID, receptionID)
         ..beginsAt    = new DateTime.now()
         ..until       = new DateTime.now().add(new Duration(hours: 2))
         ..content     = Randomizer.randomEvent();

    log.info('Creating a calendar event for $contactID@$receptionID.');

    return contactStore.calendarEventCreate (entry)
      .then((Model.CalendarEntry createdEvent) {
        return contactStore.calendarEntryChanges(createdEvent.ID)
          .then((Iterable<Model.CalendarEntryChange> changes) {
            expect (changes.length, equals(1));
            expect (changes.first.changedAt.millisecondsSinceEpoch,
                    lessThan(new DateTime.now().millisecondsSinceEpoch));
            expect (changes.first.userID, isNot(Model.User.noID));
        });
    });
  }

  /**
   * Test server behaviour with regards to calendar changes.
   * This function update an entry and asserts that another change is present.
   */
  static Future calendarEntryChangeUpdate
    (Service.RESTContactStore contactStore) {

    int receptionID = 1;
    int contactID = 4;

    return contactStore.calendar(contactID, receptionID)
      .then((Iterable <Model.CalendarEntry> entries) {

      // Update the last event in list.
      Model.CalendarEntry entry = entries.last
          ..beginsAt    = new DateTime.now()
          ..until       = new DateTime.now().add(new Duration(hours: 2))
          ..content     = Randomizer.randomEvent();

      int updateCount = -1;



      log.info('Updating a calendar event for reception $receptionID.');

      return contactStore.calendarEntryChanges(entry.ID)
        .then((Iterable<Model.CalendarEntryChange> changes) =>
          updateCount = changes.length)
        .then((_) => contactStore.calendarEventUpdate (entry)
        .then((Model.CalendarEntry updatedEvent) {
          return contactStore.calendarEntryChanges(updatedEvent.ID)
            .then((Iterable<Model.CalendarEntryChange> changes) {
              expect (changes.length, equals(updateCount+1));
              expect (changes.first.changedAt.millisecondsSinceEpoch,
                      lessThan(new DateTime.now().millisecondsSinceEpoch));
              expect (changes.first.userID, isNot(Model.User.noID));
          });

      }));
    });
  }

  /**
   * Test server behaviour with regards to calendar changes.
   * This function removes an entry and asserts that no changes are present.
   */
  static Future calendarEntryChangeDelete
    (Service.RESTContactStore contactStore) {

    int receptionID = 1;
    int contactID = 4;

    return contactStore.calendar(contactID, receptionID)
      .then((Iterable <Model.CalendarEntry> events) {

      // Update the last event in list.
      Model.CalendarEntry event = events.last;

      log.info
        ('Got event ${event.asMap} - ${event.contactID}@${event.receptionID}');

      log.info
        ('Deleting last (in list) calendar event for reception $receptionID.');

      return contactStore.calendarEventRemove(event)
        .then((_) {
        return contactStore.calendarEntryChanges(event.ID)
          .then((Iterable<Model.CalendarEntryChange> changes) {
            expect (changes.length, equals(0));

            return expect(contactStore.calendarEntryLatestChange(event.ID),
                throwsA(new isInstanceOf<Storage.NotFound>()));
          });
        });
    });
  }
}
