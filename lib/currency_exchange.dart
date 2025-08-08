import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static const separator = ' '; // Change this to ',' for other locales

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // Short-circuit if the new value is empty
    if (newValue.text.length == 0) {
      return newValue.copyWith(text: '');
    }

    // Handle case of deleting separator
    String oldValueText = oldValue.text.replaceAll(separator, '');
    String newValueText = newValue.text.replaceAll(separator, '');

    if (oldValue.text.endsWith(separator) && oldValue.text.length > newValue.text.length) {
      newValueText = newValueText.substring(0, newValueText.length - 1);
    }

    // Try to parse the string as a number
    if (double.tryParse(newValueText) == null) {
      return oldValue;
    }

    final f = NumberFormat('# ###');
    String newText = f.format(double.parse(newValueText));

    return newValue.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
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
    Currency('Ad-hoc'),
  ];
  String _baseCurrency = 'USD';

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
    if (value.isEmpty) {
      for (var currency in _currencies) {
        currency.controller.clear();
      }
      return;
    }

    final formatWithDecimal = NumberFormat.decimalPattern('fr_FR');
    final formatTwoDecimals = NumberFormat('#,##0.00', 'fr_FR');

    double amount = double.tryParse(value.replaceAll(' ', '')) ?? 0.0;
    String fromCurrencyCode = _currencies[index].code;

    double amountInBase = 0;
    if (fromCurrencyCode == _baseCurrency) {
      amountInBase = amount;
    } else {
      if (_rates[fromCurrencyCode] == null || _rates[fromCurrencyCode] == 0) return;
      amountInBase = amount / _rates[fromCurrencyCode]!;
    }

    for (int i = 0; i < _currencies.length; i++) {
      if (i == index) continue;

      String toCurrencyCode = _currencies[i].code;
      if (_rates[toCurrencyCode] == null) continue;
      double convertedAmount = amountInBase * _rates[toCurrencyCode]!;

      if (toCurrencyCode == 'USD' || toCurrencyCode == 'EUR') {
        _currencies[i].controller.text = formatTwoDecimals.format(convertedAmount);
      } else {
        _currencies[i].controller.text = formatWithDecimal.format(convertedAmount);
      }
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
                    itemCount: _currencies.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                                  ThousandsSeparatorInputFormatter(),
                                ],
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
