import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '千代田区マップ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MapScreen(),
    );
  }
}

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> markers = [];
  List<Map<String, dynamic>> locations = [];
  MapController mapController = MapController();
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadGeoJsonData();
  }

  Future<void> loadGeoJsonData() async {
    String geoJsonString = await DefaultAssetBundle.of(context)
        .loadString('assets/chiyoda_facilities.geojson');
    final geojson = json.decode(geoJsonString);
    setState(() {
      locations = geojson['features'].map<Map<String, dynamic>>((feature) {
        final coordinates = feature['geometry']['coordinates'];
        final properties = feature['properties'];
        return {
          'name': properties['name'],
          'address': properties['address'],
          'type': properties['type'],
          'note': properties['note'],
          'capacity': properties['capacity'],
          'url': properties['url'],
          'coordinates': LatLng(coordinates[1], coordinates[0]),
        };
      }).toList();

      markers = locations.map((location) {
        return Marker(
          width: 80.0,
          height: 80.0,
          point: location['coordinates'],
          builder: (ctx) => Container(
            child: Icon(Icons.location_on, color: Colors.red),
          ),
        );
      }).toList();
    });
  }

  void _showLocationList() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: locations.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(locations[index]['name']),
              subtitle: Text(locations[index]['address']),
              onTap: () {
                mapController.move(locations[index]['coordinates'], 15);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _searchLocations(String query) {
    return locations.where((location) {
      return location['name'] != null &&
          location['name'].toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('千代田区マップ'),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: _showLocationList,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: '場所を検索',
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    center: LatLng(35.6940, 139.7536),
                    zoom: 14.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: markers,
                    ),
                  ],
                ),
                if (searchController.text.isNotEmpty)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.white,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount:
                            _searchLocations(searchController.text).length,
                        itemBuilder: (context, index) {
                          final location =
                              _searchLocations(searchController.text)[index];
                          return ListTile(
                            title: Text(location['name']),
                            subtitle: Text(location['address']),
                            onTap: () {
                              mapController.move(location['coordinates'], 15);
                              searchController.clear();
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
