import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

class CurrencyData {
  final String code;
  final String name;

  CurrencyData(this.code, this.name);

  @override
  String toString() {
    return '$code - $name';
  }
}

class CurrencyExchangeApp extends StatefulWidget {
  @override
  _CurrencyExchangeAppState createState() => _CurrencyExchangeAppState();
}

class _CurrencyExchangeAppState extends State<CurrencyExchangeApp> {
  Map<String, double> _rates = {};
  List<Currency> _currencies = [
    Currency('USD'),
    Currency('EUR'),
    Currency('ARS'),
    Currency('PYG'),
    Currency('BRL'),
    Currency('UYU'),
  ];
  final String _baseCurrency = 'USD';
  bool _isUpdating = false;

  List<CurrencyData> _allApiCurrencies = [];
  CurrencyData? _selectedNewCurrency;

  final Map<String, String> _currencyToCountryMap = {
    'USD': 'United States',
    'EUR': 'Eurozone',
    'JPY': 'Japan',
    'GBP': 'United Kingdom',
    'AUD': 'Australia',
    'CAD': 'Canada',
    'CHF': 'Switzerland',
    'CNY': 'China',
    'SEK': 'Sweden',
    'NZD': 'New Zealand',
    'ARS': 'Argentina',
    'BRL': 'Brazil',
    'PYG': 'Paraguay',
    'UYU': 'Uruguay',
    'AFN': 'Afghanistan',
    'ALL': 'Albania',
    'DZD': 'Algeria',
    'AOA': 'Angola',
    'AMD': 'Armenia',
    'AWG': 'Aruba',
    'AZN': 'Azerbaijan',
    'BSD': 'Bahamas',
    'BHD': 'Bahrain',
    'BDT': 'Bangladesh',
    'BBD': 'Barbados',
    'BYN': 'Belarus',
    'BZD': 'Belize',
    'BMD': 'Bermuda',
    'BTN': 'Bhutan',
    'BOB': 'Bolivia',
    'BAM': 'Bosnia and Herzegovina',
    'BWP': 'Botswana',
    'BND': 'Brunei',
    'BGN': 'Bulgaria',
    'BIF': 'Burundi',
    'CVE': 'Cabo Verde',
    'KHR': 'Cambodia',
    'XAF': 'CEMAC',
    'XOF': 'BCEAO',
    'CLP': 'Chile',
    'COP': 'Colombia',
    'KMF': 'Comoros',
    'CDF': 'Congo (DRC)',
    'CRC': 'Costa Rica',
    'HRK': 'Croatia',
    'CUP': 'Cuba',
    'CZK': 'Czech Republic',
    'DKK': 'Denmark',
    'DJF': 'Djibouti',
    'DOP': 'Dominican Republic',
    'EGP': 'Egypt',
    'ERN': 'Eritrea',
    'ETB': 'Ethiopia',
    'FJD': 'Fiji',
    'GMD': 'Gambia',
    'GEL': 'Georgia',
    'GHS': 'Ghana',
    'GIP': 'Gibraltar',
    'GTQ': 'Guatemala',
    'GNF': 'Guinea',
    'GYD': 'Guyana',
    'HTG': 'Haiti',
    'HNL': 'Honduras',
    'HKD': 'Hong Kong',
    'HUF': 'Hungary',
    'ISK': 'Iceland',
    'INR': 'India',
    'IDR': 'Indonesia',
    'IRR': 'Iran',
    'IQD': 'Iraq',
    'ILS': 'Israel',
    'JMD': 'Jamaica',
    'JOD': 'Jordan',
    'KZT': 'Kazakhstan',
    'KES': 'Kenya',
    'KWD': 'Kuwait',
    'KGS': 'Kyrgyzstan',
    'LAK': 'Laos',
    'LBP': 'Lebanon',
    'LSL': 'Lesotho',
    'LRD': 'Liberia',
    'LYD': 'Libya',
    'MOP': 'Macau',
    'MKD': 'Macedonia',
    'MGA': 'Madagascar',
    'MWK': 'Malawi',
    'MYR': 'Malaysia',
    'MVR': 'Maldives',
    'MRU': 'Mauritania',
    'MUR': 'Mauritius',
    'MXN': 'Mexico',
    'MDL': 'Moldova',
    'MNT': 'Mongolia',
    'MAD': 'Morocco',
    'MZN': 'Mozambique',
    'MMK': 'Myanmar',
    'NAD': 'Namibia',
    'NPR': 'Nepal',
    'NIO': 'Nicaragua',
    'NGN': 'Nigeria',
    'NOK': 'Norway',
    'OMR': 'Oman',
    'PKR': 'Pakistan',
    'PAB': 'Panama',
    'PGK': 'Papua New Guinea',
    'PEN': 'Peru',
    'PHP': 'Philippines',
    'PLN': 'Poland',
    'QAR': 'Qatar',
    'RON': 'Romania',
    'RUB': 'Russia',
    'RWF': 'Rwanda',
    'SAR': 'Saudi Arabia',
    'RSD': 'Serbia',
    'SCR': 'Seychelles',
    'SLL': 'Sierra Leone',
    'SGD': 'Singapore',
    'SOS': 'Somalia',
    'ZAR': 'South Africa',
    'KRW': 'South Korea',
    'SSP': 'South Sudan',
    'LKR': 'Sri Lanka',
    'SDG': 'Sudan',
    'SRD': 'Suriname',
    'SZL': 'Swaziland',
    'SYP': 'Syria',
    'TWD': 'Taiwan',
    'TZS': 'Tanzania',
    'THB': 'Thailand',
    'TOP': 'Tonga',
    'TTD': 'Trinidad and Tobago',
    'TND': 'Tunisia',
    'TRY': 'Turkey',
    'TMT': 'Turkmenistan',
    'UGX': 'Uganda',
    'UAH': 'Ukraine',
    'AED': 'United Arab Emirates',
    'UZS': 'Uzbekistan',
    'VUV': 'Vanuatu',
    'VES': 'Venezuela',
    'VND': 'Vietnam',
    'YER': 'Yemen',
    'ZMW': 'Zambia',
    'ZWL': 'Zimbabwe'
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadCurrenciesFromPrefs();
    await _fetchCurrencyCodes();
    await _loadRatesFromPrefs();
    await _fetchRatesFromApi();
  }

  Future<void> _saveCurrenciesToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> currencyCodes = _currencies.map((c) => c.code).toList();
    await prefs.setStringList('user_currencies', currencyCodes);
  }

  Future<void> _loadCurrenciesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final currencyCodes = prefs.getStringList('user_currencies');
    if (currencyCodes != null && currencyCodes.isNotEmpty) {
      setState(() {
        _currencies = currencyCodes.map((code) => Currency(code)).toList();
      });
    }
  }

  Future<void> _fetchCurrencyCodes() async {
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;

        final List<CurrencyData> currencyList = rates.keys.map((code) {
          final countryName = _currencyToCountryMap[code] ?? code;
          return CurrencyData(code, countryName);
        }).toList();

        currencyList.sort((a, b) => a.code.compareTo(b.code));

        setState(() {
          _allApiCurrencies = currencyList;
          if (_allApiCurrencies.isNotEmpty) {
            _selectedNewCurrency = _allApiCurrencies.firstWhere((c) => c.code == 'USD');
          }
        });
      } else {
        print('Failed to load currency codes');
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> _loadRatesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesString = prefs.getString('rates');
    if (ratesString != null) {
      setState(() {
        _rates = Map<String, double>.from(json.decode(ratesString));
      });
    }
  }

  Future<void> _fetchRatesFromApi() async {
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/$_baseCurrency'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('rates', json.encode(data['rates']));
        setState(() {
          _rates = Map<String, double>.from(data['rates']);
        });
      } else {
        print('Failed to load exchange rates from API');
      }
    } catch (e) {
      print(e);
    }
  }

  void _onCurrencyChanged(int index, String value) {
    if (_isUpdating) return;
    _isUpdating = true;

    if (value.isEmpty) {
      for (var currency in _currencies) {
        currency.controller.clear();
      }
      _isUpdating = false;
      return;
    }

    final formatStandard = NumberFormat('#,##0.###', 'en_US');
    final formatTwoDecimals = NumberFormat('#,##0.00', 'en_US');

    final cleanValue = value.replaceAll(' ', '').replaceAll(',', '.');
    double amount = double.tryParse(cleanValue) ?? 0.0;
    String fromCurrencyCode = _currencies[index].code;

    double amountInBase = 0;
    if (_rates.isNotEmpty) {
      if (fromCurrencyCode == _baseCurrency) {
        amountInBase = amount;
      } else {
        if (_rates[fromCurrencyCode] == null || _rates[fromCurrencyCode] == 0) {
          _isUpdating = false;
          return;
        }
        amountInBase = amount / _rates[fromCurrencyCode]!;
      }

      for (int i = 0; i < _currencies.length; i++) {
        if (i == index) continue;

        String toCurrencyCode = _currencies[i].code;
        if (_rates[toCurrencyCode] == null) continue;

        double convertedAmount = amountInBase * _rates[toCurrencyCode]!;
        String formattedValue;

        if (convertedAmount > 1000) {
          formattedValue = NumberFormat('#,##0', 'en_US').format(convertedAmount).replaceAll(',', ' ');
        } else if (toCurrencyCode == 'USD' || toCurrencyCode == 'EUR') {
          formattedValue = formatTwoDecimals.format(convertedAmount).replaceAll(',', ' ');
        } else {
          formattedValue = formatStandard.format(convertedAmount).replaceAll(',', ' ');
        }
        
        final currentController = _currencies[i].controller;
        currentController.value = TextEditingValue(
          text: formattedValue,
          selection: TextSelection.collapsed(offset: formattedValue.length),
        );
      }
    }

    _isUpdating = false;
  }

  void _addCurrency() {
    if (_selectedNewCurrency != null && !_currencies.any((c) => c.code == _selectedNewCurrency!.code)) {
      setState(() {
        _currencies.add(Currency(_selectedNewCurrency!.code));
      });
      _saveCurrenciesToPrefs();
    }
  }

  void _removeCurrency(int index) {
    setState(() {
      _currencies.removeAt(index);
    });
    _saveCurrenciesToPrefs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
      ),
      body: _rates.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _currencies.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _currencies.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 80,
                                child: Text(_currencies[index].code, style: TextStyle(fontSize: 16.0)),
                              ),
                              SizedBox(width: 16),
                              SizedBox(
                                width: 150,
                                child: TextField(
                                  controller: _currencies[index].controller,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) => _onCurrencyChanged(index, value),
                                ),
                              ),
                              SizedBox(
                                width: 50,
                                child: IconButton(
                                  icon: Icon(Icons.remove_circle_outline),
                                  onPressed: () => _removeCurrency(index),
                                ),
                              )
                            ],
                          ),
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 80,
                                child: ElevatedButton(
                                  onPressed: _addCurrency,
                                  child: Text('Add'),
                                ),
                              ),
                              SizedBox(width: 16),
                              SizedBox(
                                width: 200,
                                child: DropdownSearch<CurrencyData>(
                                  popupProps: PopupProps.menu(
                                    showSearchBox: true,
                                    searchFieldProps: TextFieldProps(
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        hintText: "Search currency",
                                      ),
                                    ),
                                  ),
                                  items: _allApiCurrencies,
                                  selectedItem: _selectedNewCurrency,
                                  onChanged: (CurrencyData? newValue) {
                                    setState(() {
                                      _selectedNewCurrency = newValue;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildCopyableRow('Source', 'https://api.exchangerate-api.com/v4/latest/USD'),
                ),
              ],
            ),
    );
  }

  Widget _buildCopyableRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$label : $value', style: TextStyle(fontFamily: 'monospace')),
        SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.copy, size: 16.0),
          onPressed: () => _copyToClipboard(value),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }
}

class Currency {
  String code;
  TextEditingController controller = TextEditingController();

  Currency(this.code);
}