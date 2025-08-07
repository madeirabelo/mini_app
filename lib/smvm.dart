import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class SmvmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Salario Mínimo, Vital y Móvil (SMVM)'),
      ),
      body: SmvmScreen(),
    );
  }
}

class SmvmScreen extends StatefulWidget {
  @override
  _SmvmScreenState createState() => _SmvmScreenState();
}

class _SmvmScreenState extends State<SmvmScreen> {
  Map<String, String>? _smvmData;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  DateTime? _latestDateInCsv;

  final List<String> _corsProxies = [
    'https://proxy.cors.sh/',
    'https://api.allorigins.win/raw?url=',
    'https://thingproxy.freeboard.io/fetch/',
  ];

  @override
  void initState() {
    super.initState();
    _fetchData(fetchLatest: true);
  }

  Future<void> _fetchData({DateTime? date, bool fetchLatest = false}) async {
    setState(() {
      _isLoading = true;
      _smvmData = null;
    });

    DateTime dateToFetch = date ?? _selectedDate;
    if (!fetchLatest) {
      dateToFetch = DateTime(dateToFetch.year, dateToFetch.month, 1);
    }

    try {
      final String data = await rootBundle.loadString('assets/smvm_data.csv');
      final lines = data.split("\n");
      if (lines.length > 1) {
        List<String> dataLines = lines.sublist(1);
        dataLines.removeWhere((line) => line.trim().isEmpty);

        if (dataLines.isNotEmpty) {
          final latestCsvLine = dataLines.lastWhere((line) => line.split(',').length >= 4, orElse: () => '');
          if (latestCsvLine.isNotEmpty) {
            _latestDateInCsv = DateTime.parse(latestCsvLine.split(',')[0]);
          }
        }

        String? targetLine;
        if (fetchLatest) {
          for (int i = dataLines.length - 1; i >= 0; i--) {
            if (dataLines[i].split(',').length >= 4) {
              targetLine = dataLines[i];
              break;
            }
          }
        } else {
          final formattedDate = DateFormat('yyyy-MM-dd').format(dateToFetch);
          targetLine = dataLines.firstWhere((line) => line.startsWith(formattedDate), orElse: () => 'No data for this date');
        }

        if (targetLine != null && targetLine != 'No data for this date') {
          final values = targetLine.split(',');
          if (values.length >= 4) {
            setState(() {
              _smvmData = {
                'Data': values[0],
                'SMVM Mensual': values[1],
                'SMVM Diario': values[2],
                'SMVM Hora': values[3],
              };
              if (date != null) {
                _selectedDate = DateTime.parse(values[0]);
              }
            });
          } else {
            setState(() {
              _smvmData = {'Error': 'Invalid data format for selected date'};
            });
          }
        } else {
          setState(() {
            _smvmData = {'Error': 'No data available for the selected date'};
          });
        }
      } else {
        setState(() {
          _smvmData = {'Error': 'CSV file is empty or malformed'};
        });
      }
    } catch (e) {
      setState(() {
        _smvmData = {'Error': e.toString()};
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard')),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime.now()) ? _selectedDate : DateTime.now(),
      firstDate: DateTime(1965, 1, 1),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, 1);
      });
      _fetchData(date: _selectedDate);
    }
  }

  void _fetchLatestData() {
    _fetchData(fetchLatest: true);
  }

  @override
  Widget build(BuildContext context) {
    Color dateColor = Colors.black;
    FontWeight dateFontWeight = FontWeight.normal;

    String displayDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    if (_smvmData != null && !_smvmData!.containsKey('Error') && _smvmData!['Data'] != null) {
      displayDate = _smvmData!['Data']!;
      
      if (_latestDateInCsv != null) {
        DateTime dataDate = DateTime.parse(_smvmData!['Data']!);
        if (dataDate.isAtSameMomentAs(_latestDateInCsv!)) {
          dateColor = Colors.blue;
          dateFontWeight = FontWeight.bold;
        } else if (dataDate.isBefore(_latestDateInCsv!)) {
          dateColor = Colors.red;
          dateFontWeight = FontWeight.bold;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text('Select Date'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: _fetchLatestData,
                child: Text('Fetch Latest'),
              ),
              SizedBox(width: 10),
              Text(
                displayDate,
                style: TextStyle(color: dateColor, fontWeight: dateFontWeight),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_smvmData != null)
            if (_smvmData!.containsKey('Error'))
              Text('Error: ${_smvmData!['Error']}')
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCopyableRow('SMVM Mensual', _smvmData!['SMVM Mensual']?.replaceAll('.', ',') ?? ''),
                      _buildCopyableRow('SMVM Diario', _smvmData!['SMVM Diario'] != null ? (double.tryParse(_smvmData!['SMVM Diario']!)?.toStringAsFixed(1) ?? _smvmData!['SMVM Diario']!).replaceAll('.', ',') : ''),
                      _buildCopyableRow('SMVM Hora', _smvmData!['SMVM Hora']?.replaceAll('.', ',') ?? ''),
                      Text('Data : ${_smvmData!['Data']}', style: TextStyle(fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
          Spacer(),
          _buildCopyableRow('Source', 'https://infra.datos.gob.ar/catalog/sspm/dataset/57/distribution/57.1/download/indice-salario-minimo-vital-movil-valores-mensuales-pesos-corrientes-desde-1988.csv'),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Author: Antonio Belo',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
            ),
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
}
