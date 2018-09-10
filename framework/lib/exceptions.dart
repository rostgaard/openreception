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

/// Shared errors and exceptions.
library orf.exceptions;

/// General storage exception. Should only be treated as an abstract
/// superclass, but may also be used directly in cases where creating a new
/// subclass make little or no sense.
class StorageException implements Exception {}

/// Storage-class exception that indicate that a resource is not found.
class NotFound implements StorageException {
  /// Create a new [NotFound] exception with [message].
  const NotFound([this.message = ""]);

  /// The carried exception message.
  final String message;

  @override
  String toString() => "NotFound: $message";
}

/// Storage-class exception that indicate that a resource is unavailable
/// due to insufficient authorization.
class Forbidden implements StorageException {
  /// The carried exception message.
  final String message;

  /// Create a new [Forbidden] exception with [message].
  const Forbidden([this.message = ""]);

  @override
  String toString() => "Forbidden: $message";
}

/// Storage-class exception that indicate that a resource conflict has
/// occured.
///
/// This means that, for instance, trying to request an assigned call will
/// fail with a [Conflict] exception.
class Conflict implements StorageException {
  /// The carried exception message.
  final String message;

  /// Create a new [Conflict] exception with [message].
  const Conflict([this.message = ""]);

  @override
  String toString() => "Conflict: $message";
}

/// Storage-class exception that indicate that a no credentials are
/// supplied.
class NotAuthorized implements StorageException {
  /// The carried exception message.
  final String message;

  /// Create a new [NotAuthorized] exception with [message].
  const NotAuthorized([this.message = ""]);

  @override
  String toString() => "NotAuthorized: $message";
}

/// Storage-class exception that indicate that an unspecified client error
/// occured.
///
/// These errors are typically caused by bad parameters passed by clients.
/// The [message] field may carry addtional information about what
/// triggered the exception.
class ClientError implements StorageException {
  /// The carried exception message.
  final String message;

  /// Create a new [ClientError] exception with [message].
  const ClientError([this.message = ""]);

  @override
  String toString() => "ClientError: $message";
}

/// Storage-class exception that indicate that an unspecified server error
/// occured.
///
/// These errors are typically caused by bad state information on the
/// server or a bad reply from a proxy server or datastore.
/// The [message] field may carry addtional information about what
/// triggered the exception.
class ServerError implements StorageException {
  /// The carried exception message.
  final String message;

  /// Create a new [ServerError] exception with [message].
  const ServerError([this.message = ""]);

  @override
  String toString() => "ServerError: $message";
}

/// Storage-class exception that indicate that a resource/method combination
/// is currently not available.
///
/// This means that, for instance, trying to request a locked call will
/// fail with a [Busy] exception.
class Busy implements StorageException {
  /// The carried exception message.
  final String message;

  /// Create a new [Busy] exception with [message].
  const Busy([this.message = ""]);

  @override
  String toString() => "Busy: $message";
}

/// Storage-class exception that indicate that a posted resource update
/// contained no changes.
class Unchanged implements StorageException {
  /// The carried exception message.
  final String message;

  /// Create a new [Unchanged] exception with [message].
  const Unchanged([this.message = ""]);

  @override
  String toString() => "Unchanged: $message";
}

/// General validation exception. Should only be treated as an abstract
/// superclass, but may also be used directly in cases where creating a new
/// subclass make little or no sense.
class ValidationException implements Exception {
  /// The carried exception message.
  final String message;

  /// Create a new [ValidationException] with [message].
  const ValidationException([this.message = '']);

  @override
  String toString() => 'ParseException: $message';
}

/// Exception for signifying that an object field contains an invalid ID.
class InvalidId implements ValidationException {
  @override
  final String message;

  /// The name if the ID field that is invalid.
  final String field;

  /// Create a new [InvalidId] exception that signifies that [field] is invalid.
  ///
  /// Optionally provide additional information in [message].
  const InvalidId(this.field, [this.message = '']);

  @override
  String toString() => 'IdIsNoId: $field - $message';
}

/// Exception for signifying that an object field contains an invalid characters.
class InvalidCharacters implements ValidationException {
  @override
  final String message;

  /// The name if the ID field that contains invalid characters.
  final String field;

  /// Create a new [InvalidCharacters] exception that signifies that
  /// [field] contains invalid characters.
  ///
  /// Optionally provide additional information in [message].
  const InvalidCharacters(this.field, [this.message = '']);

  @override
  String toString() => 'InvalidCharacters: $field - $message';
}

/// Exception for signifying that an object field contains a null value.
class NullValue implements ValidationException {
  @override
  final String message;

  /// The name if the ID field that contains a null value.
  final String field;

  /// Create a new [NullValue] exception that signifies that value of [field]
  /// is null.
  ///
  /// Optionally provide additional information in [message].
  const NullValue(this.field, [this.message = '']);

  @override
  String toString() => 'NullValue: $field - $message';
}

/// Exception for signifying that an object field contains an empty value.
class IsEmpty implements ValidationException {
  @override
  final String message;

  /// The name if the ID field that is empty.
  final String field;

  /// Create a new [IsEmpty] exception that signifies that [field] is empty.
  ///
  /// Optionally provide additional information in [message].
  const IsEmpty(this.field, [this.message = '']);

  @override
  String toString() => 'IsEmpty: $field - $message';
}

/// Exception for signifying that an object field contains a bad type.
class BadType implements ValidationException {
  @override
  final String message;

  /// The name if the ID field that contains an invalid type.
  final String field;

  /// Create a new [BadType] exception that signifies that [field] contains a
  /// bad type.
  ///
  /// Optionally provide additional information in [message].
  const BadType(this.field, this.message);

  @override
  String toString() => 'BadType: $field - $message';
}

/// Exception for signifying that an object field two [DateTime] fields that are
/// out of order.
class TimeOrderConstraint implements ValidationException {
  @override
  final String message;

  /// The name of the field containing the reference time.
  final String time;

  /// The name of the field that is before the reference [time].
  final String isBefore;

  /// Create a new [TimeOrderConstraint] exception that signifies that
  /// the time [isBefore] is before [time].
  ///
  /// Optionally provide additional information in [message].
  const TimeOrderConstraint(this.time, this.isBefore, [this.message = '']);

  @override
  String toString() =>
      'TimeOrderConstraint: $time is before $isBefore - $message';
}

/// Exception for signifying that a object fields contains duplicate digits.
class DuplicateDigits implements ValidationException {
  @override
  final String message;

  /// The field that was contained duplicated digits
  final String field;

  /// The duplicated digits
  final String duplicated;

  /// Create a new [DuplicateDigits] exception that signifies that [field]
  /// contains the duplicate digits [duplicated].
  const DuplicateDigits(this.field, this.duplicated, [this.message = '']);

  @override
  String toString() => 'DuplicateDigits: $field - $message';
}
