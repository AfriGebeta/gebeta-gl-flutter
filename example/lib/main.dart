import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:gebeta_gl/gebeta_gl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gebeta Maps Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Gebeta maps Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Function to load the map style
  Future<String> loadMapStyle() async {
    return await rootBundle.loadString('assets/styles/basic.json');
  }

  Future<Uint8List> loadMarkerImage() async {
    var byteData = await rootBundle.load("assets/marker-black.png");
    return byteData.buffer.asUint8List();
  }

  void onMapCreated(GebetaMapController controller) async {
    var markerImage = await loadMarkerImage();
    controller.addImage('marker', markerImage);


    await controller.addSymbol(
      SymbolOptions(
        iconSize: 2,
        iconImage: "marker",
        iconAnchor: "bottom",
        // Marker just to the west of the fill:
        geometry: LatLng(9.0350, 38.7450),
      ),
    );

    await controller.addSymbol(
      SymbolOptions(
        iconSize: 2,
        iconImage: "marker",
        iconAnchor: "bottom",
        // Marker just to the east of the fill:
        geometry: LatLng(9.0350, 38.7850),
      ),
    );

    await controller.addLine(
      LineOptions(
        lineColor: '#FF0000',
        lineWidth: 2,
        // Line connecting the two markers:
        geometry: [
          LatLng(9.0350, 38.7450),
          LatLng(9.0350, 38.7850),
        ],
      ),
    );

    await controller.addFill(
      FillOptions(
        fillColor: '#007AFF',
        fillOpacity: 0.5,
        geometry: [
          [
            LatLng(9.0200, 38.7500),
            LatLng(9.0200, 38.7800),
            LatLng(9.0500, 38.7800),
            LatLng(9.0500, 38.7500),
            LatLng(9.0200, 38.7500), // Close the polygon.
          ]
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: loadMapStyle(), // Load the JSON style file
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // While the future is loading, show a loading spinner
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            // If the future completed with an error, show an error message
            print(snapshot.error);
            return Center(child: Text('Error loading map style'));
          } else if (snapshot.hasData) {
            // If the future completed successfully, show the map
            String styleString = snapshot.data!;
            return GebetaMap(
              compassViewPosition: CompassViewPosition.topRight,
              styleString: styleString,
              initialCameraPosition: CameraPosition(
                target: LatLng(9.0192, 38.7525), // Example: San Francisco
                zoom: 10.0,
              ),
              onMapCreated: onMapCreated,
            );
          } else {
            // Handle any other unexpected states
            return Center(child: Text('No map style found'));
          }
        },
      ),
    );
  }
}
