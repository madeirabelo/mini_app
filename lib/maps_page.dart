import 'package:flutter/material.dart';
import 'argentina_map.dart';
import 'argentina_province_map.dart';
import 'barrios_corrientes_map.dart';
import 'departamento_map.dart';
import 'municipio_map.dart';

class MapsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maps'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: Text('Argentina Map'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArgentinaMapApp()),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Argentina Province Map'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ArgentinaProvinceMapApp()),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Departamento Map'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DepartamentoMapApp()),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Municipio Map'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MunicipioMapApp()),
                );
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('Barrios de Corrientes'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BarriosCorrientesMapApp()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
