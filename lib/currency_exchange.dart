import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';

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

  List<String> _allApiCurrencies = [];
  String? _selectedNewCurrency;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    await _loadRatesFromPrefs();
    await _fetchRatesFromApi();
  }

  Future<void> _loadRatesFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final ratesString = prefs.getString('rates');
    if (ratesString != null) {
      setState(() {
        _rates = Map<String, double>.from(json.decode(ratesString));
        _allApiCurrencies = _rates.keys.toList()..sort();
        if (_allApiCurrencies.isNotEmpty) {
          _selectedNewCurrency = _allApiCurrencies[0];
        }
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
          _allApiCurrencies = _rates.keys.toList()..sort();
          if (_allApiCurrencies.isNotEmpty) {
            _selectedNewCurrency = _allApiCurrencies[0];
          }
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
    if (_selectedNewCurrency != null && !_currencies.any((c) => c.code == _selectedNewCurrency)) {
      setState(() {
        _currencies.add(Currency(_selectedNewCurrency!));
      });
    }
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
                    itemCount: _currencies.length + 1, // Add one for the "Add New" row
                    itemBuilder: (context, index) {
                      if (index == _currencies.length) {
                        // This is the "Add New" row
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 150,
                                child: DropdownSearch<String>(
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
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedNewCurrency = newValue;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _addCurrency,
                                child: Text('Add'),
                              ),
                            ],
                          ),
                        );
                      }
                      // This is a currency row
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
                              width: 200,
                              child: TextField(
                                controller: _currencies[index].controller,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) => _onCurrencyChanged(index, value),
                              ),
                            ),
                          ],
                        ),
                      );
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