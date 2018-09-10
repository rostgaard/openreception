/*                  This file is part of OpenReception
                   Copyright (C) 2015-, BitStackers K/S

  This is free software;  you can redistribute it and/or modify it
  under terms of the  GNU General Public License  as published by the
  Free Software  Foundation;  either version 3,  or (at your  option) any
  later version. This software is distributed in the hope that it will be
  useful, but WITHOUT ANY WARRANTY;  without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  You should have received a copy of the GNU General Public License along with
  this program; see the file COPYING3. If not, see http://www.gnu.org/licenses.
*/

part of orf.model.dialplan;

/// Performs a [ReceptionTransfer] from an [IvrMenu].
class IvrReceptionTransfer implements IvrEntry {
  /// Create a new [IvrReceptionTransfer] that responds to [digits] and
  /// performs [transfer].
  IvrReceptionTransfer(this.digits, this.transfer);

  @override
  final String digits;

  /// The [ReceptionTransfer] to perform.
  final ReceptionTransfer transfer;

  @override
  String toJson() => '$digits: ${transfer.toJson()}';

  @override
  String toString() => toJson();

  @override
  bool operator ==(Object other) =>
      other is IvrReceptionTransfer &&
      digits == other.digits &&
      transfer == other.transfer;

  @override
  int get hashCode => toString().hashCode;
}
