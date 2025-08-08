import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrencyExchangeApp extends StatefulWidget {
  @override
  _CurrencyExchangeAppState createState() => _CurrencyExchangeAppState();
}

class _CurrencyExchangeAppState extends State<CurrencyExchangeApp> {
  final List<String> _currencies = ['USD', 'EUR', 'ARS', 'PYG', 'BRL', 'UYU'];
  String _fromCurrency = 'USD';
  String _toCurrency = 'EUR';
  double _rate = 0.0;
  double _amount = 1.0;
  double _convertedAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchExchangeRate();
  }

  Future<void> _fetchExchangeRate() async {
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate-api.com/v4/latest/$_fromCurrency'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _rate = data['rates'][_toCurrency];
          _convert();
        });
      } else {
        throw Exception('Failed to load exchange rate');
      }
    } catch (e) {
      print(e);
    }
  }

  void _convert() {
    setState(() {
      _convertedAmount = _amount * _rate;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                    ),
                    onChanged: (value) {
                      setState(() {
                        _amount = double.tryParse(value) ?? 0.0;
                        _convert();
                      });
                    },
                  ),
                ),
                SizedBox(width: 16.0),
                DropdownButton<String>(
                  value: _fromCurrency,
                  onChanged: (String? newValue) {
                    setState(() {
                      _fromCurrency = newValue!;
                      _fetchExchangeRate();
                    });
                  },
                  items: _currencies.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _convertedAmount.toStringAsFixed(2),
                    style: TextStyle(fontSize: 24.0),
                  ),
                ),
                SizedBox(width: 16.0),
                DropdownButton<String>(
                  value: _toCurrency,
                  onChanged: (String? newValue) {
                    setState(() {
                      _toCurrency = newValue!;
                      _fetchExchangeRate();
                    });
                  },
                  items: _currencies.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
