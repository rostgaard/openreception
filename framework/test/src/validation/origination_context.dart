/*                  This file is part of OpenReception
                   Copyright (C) 2016-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.test.validation;

void _originationContextTests() {
  group('validation.originationContext', () {
    test('no errors', () {
      final model.OriginationContext context = new model.OriginationContext()
        ..contactId = 1
        ..receptionId = 2
        ..dialplan = 'test-dialplan'
        ..callId = 'test-call';

      Iterable<ValidationException> errors =
          validateOriginationContext(context);

      expect(errors.length, equals(0));
    });

    test('cid is noId', () {
      final model.OriginationContext context = new model.OriginationContext()
        ..contactId = model.BaseContact.noId
        ..receptionId = 2
        ..dialplan = 'test-dialplan'
        ..callId = 'test-call';

      Iterable<ValidationException> errors =
          validateOriginationContext(context);

      expect(errors.length, equals(1));

      expect(errors.first, const TypeMatcher<InvalidId>());
    });

    test('rid is noId', () {
      final model.OriginationContext context = new model.OriginationContext()
        ..contactId = 1
        ..receptionId = model.Reception.noId
        ..dialplan = 'test-dialplan'
        ..callId = 'test-call';

      Iterable<ValidationException> errors =
          validateOriginationContext(context);

      expect(errors.length, equals(1));

      expect(errors.first, const TypeMatcher<InvalidId>());
    });

    test('dialplan is empty', () {
      final model.OriginationContext context = new model.OriginationContext()
        ..contactId = 1
        ..receptionId = 2
        ..dialplan = ''
        ..callId = 'test-call';

      Iterable<ValidationException> errors =
          validateOriginationContext(context);

      expect(errors.length, equals(1));

      expect(errors.first, const TypeMatcher<IsEmpty>());
    });

    test('combined errors', () {
      final model.OriginationContext context = new model.OriginationContext()
        ..contactId = model.BaseContact.noId
        ..receptionId = model.Reception.noId
        ..dialplan = '';

      Iterable<ValidationException> errors =
          validateOriginationContext(context);

      expect(errors.length, equals(3));
    });
  });
}
