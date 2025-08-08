import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/$_baseCurrency'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _rates = Map<String, double>.from(data['rates']);
        });
      } else {
        throw Exception('Failed to load exchange rates');
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

    double amount = double.tryParse(value) ?? 0.0;
    String fromCurrencyCode = _currencies[index].code;

    double amountInBase = 0;
    if (fromCurrencyCode == _baseCurrency) {
      amountInBase = amount;
    } else {
      amountInBase = amount / _rates[fromCurrencyCode]!;
    }

    for (int i = 0; i < _currencies.length; i++) {
      if (i == index) continue;

      String toCurrencyCode = _currencies[i].code;
      double convertedAmount = amountInBase * _rates[toCurrencyCode]!;
      _currencies[i].controller.text = convertedAmount.toStringAsFixed(2);
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
                              width: 200, // Set a fixed width for the input box
                              child: TextField(
                                controller: _currencies[index].controller,
                                keyboardType: TextInputType.number,
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