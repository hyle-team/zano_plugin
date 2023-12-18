// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WalletTypeAdapter extends TypeAdapter<WalletType> {
  @override
  final int typeId = 5;

  @override
  WalletType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 6:
        return WalletType.zano;
      default:
        return WalletType.zano;
    }
  }

  @override
  void write(BinaryWriter writer, WalletType obj) {
    switch (obj) {
      case WalletType.zano:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) => identical(this, other) || other is WalletTypeAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
