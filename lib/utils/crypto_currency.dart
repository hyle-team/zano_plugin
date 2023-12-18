

import 'package:cw_zano/utils/currency.dart';
import 'package:cw_zano/utils/enumerable_item.dart';

class CryptoCurrency extends EnumerableItem<int> with Serializable<int> implements Currency {
  const CryptoCurrency({
    String title = '',
    int raw = -1,
    required this.name,
    this.fullName,
    this.iconPath,
    this.tag})
      : super(title: title, raw: raw);

  final String name;
  final String? tag;
  final String? fullName;
  final String? iconPath;

  static const all = [
    CryptoCurrency.zano,
  ];

  // title, tag (if applicable), fullName (if unique), raw, name, iconPath
  static const zano = CryptoCurrency(title: 'ZANO', tag: 'ZANO', fullName: 'Zano', raw: 86, name: 'zano', iconPath: 'assets/images/zano_icon.png');


  static final Map<int, CryptoCurrency> _rawCurrencyMap =
    [...all,].fold<Map<int, CryptoCurrency>>(<int, CryptoCurrency>{}, (acc, item) {
      acc.addAll({item.raw: item});
      return acc;
    });

  static final Map<String, CryptoCurrency> _nameCurrencyMap =
    [...all,].fold<Map<String, CryptoCurrency>>(<String, CryptoCurrency>{}, (acc, item) {
      acc.addAll({item.name: item});
      return acc;
    });

  static final Map<String, CryptoCurrency> _fullNameCurrencyMap =
    [...all,].fold<Map<String, CryptoCurrency>>(<String, CryptoCurrency>{}, (acc, item) {
      if(item.fullName != null){
        acc.addAll({item.fullName!.toLowerCase(): item});
      }
      return acc;
    });

  static CryptoCurrency deserialize({required int raw}) {

    if (CryptoCurrency._rawCurrencyMap[raw] == null) {
      final s = 'Unexpected token: $raw for CryptoCurrency deserialize';
      throw  ArgumentError.value(raw, 'raw', s);
    }
    return CryptoCurrency._rawCurrencyMap[raw]!;
  }

  static CryptoCurrency fromString(String name) {

    if (CryptoCurrency._nameCurrencyMap[name.toLowerCase()] == null) {
      final s = 'Unexpected token: $name for CryptoCurrency fromString';
      throw  ArgumentError.value(name, 'name', s);
    }
    return CryptoCurrency._nameCurrencyMap[name.toLowerCase()]!;
  }

  static CryptoCurrency fromFullName(String name) {

    if (CryptoCurrency._fullNameCurrencyMap[name.toLowerCase()] == null) {
      final s = 'Unexpected token: $name for CryptoCurrency fromFullName';
      throw  ArgumentError.value(name, 'Fullname', s);
    }
    return CryptoCurrency._fullNameCurrencyMap[name.toLowerCase()]!;
  }
  

  @override
  String toString() => title;
}
