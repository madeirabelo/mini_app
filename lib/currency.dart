
import 'package:flutter/material.dart';

class CurrencyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print('Olá Currency');
    return Scaffold(
      appBar: AppBar(
        title: Text('Currency Converter'),
      ),
      body: Center(
        child: Text('Currency Converter App'),
      ),
    );
  }
}
