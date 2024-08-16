import 'package:flores_favorite_places/screens/favorite_places.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  static const initialPosition = LatLng(15.974751627261558, 120.46030049416085);

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  late GoogleMapController mapController;

  Set<Marker> markers = {};

  TextEditingController searchController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchFavoriteLocations();
  }

  void fetchFavoriteLocations() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('favorite_places').get();

    final List<Marker> newMarkers = snapshot.docs.map((doc) {
      final data = doc.data();
      final LatLng position =
          LatLng(data['latitude'] as double, data['longitude'] as double);

      return Marker(
        markerId: MarkerId(doc.id),
        position: position,
        infoWindow: InfoWindow(title: data['name'] as String),
        onTap: () {
          _showDeleteDialog(doc.id);
        },
      );
    }).toList();

    setState(() {
      markers = Set.from(newMarkers);
    });
  }

  void _showDeleteDialog(String markerId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Favorite Place'),
          content: const Text('Do you want to delete this favorite place?'),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextButton(
                onPressed: () {
                  deleteLocation(markerId);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    setState(() {});
  }

  void deleteLocation(String markerId) async {
    await FirebaseFirestore.instance
        .collection('favorite_places')
        .doc(markerId)
        .delete();

    fetchFavoriteLocations();
    // ignore: avoid_print
    print('Location deleted!');
  }

  void saveToFavoritePlace(LatLng position) {
    // Show dialog for saving location
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Save Favorite Place'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                      labelText: 'Name', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name.';
                    }
                    return null;
                  },
                ),
                const Gap(8),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Description', border: OutlineInputBorder()),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description.';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xff273ea5),
                borderRadius: BorderRadius.circular(15),
              ),
              child: TextButton(
                onPressed: () {
                  if (!(_formKey.currentState!.validate())) {
                    return;
                  }
                  saveLocation(position);
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );

    mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: position, zoom: 15),
    ));

    setState(() {});
  }

  void saveLocation(LatLng position) {
    String name = nameController.text;
    String description = descriptionController.text;

    FirebaseFirestore.instance.collection('favorite_places').add({
      'name': name,
      'description': description,
      'latitude': position.latitude,
      'longitude': position.longitude,
    }).then((docRef) {
      markers.add(Marker(
        markerId: MarkerId(docRef.id),
        position: position,
        infoWindow: InfoWindow(title: name),
      ));

      setState(() {});

      // ignore: avoid_print
      print('Location saved!');
    }).catchError((error) {
      // ignore: avoid_print
      print('Failed to save location: $error');
    });

    nameController.clear();
    descriptionController.clear();
  }

  void searchLocation() async {
    String searchTerm = searchController.text;

    if (searchTerm.isNotEmpty) {
      try {
        List<Location> locations = await locationFromAddress(searchTerm);

        if (locations.isNotEmpty) {
          Location firstLocation = locations.first;
          LatLng position =
              LatLng(firstLocation.latitude, firstLocation.longitude);

          mapController.animateCamera(CameraUpdate.newLatLng(position));
        } else {
          // ignore: avoid_print
          print('No locations found for the search term: $searchTerm');
        }
      } catch (e) {
        // ignore: avoid_print
        print('Error geocoding: $e');
      }
    } else {
      // ignore: avoid_print
      print('Search term is empty');
    }

    // searchController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff0f2f5),
      appBar: AppBar(
        title: const Text('Mark Your Favorite Places'),
        backgroundColor: const Color(0xfff0f2f5),
        actions: [
          IconButton(
            icon: const Icon(
              (Icons.favorite_rounded),
              color: Color(0xffe5322d),
              size: 30,
            ),
            onPressed: () async {
              final updatedMarkers = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FavoritePlacesScreen(markers: markers),
                ),
              );
              if (updatedMarkers != null) {
                setState(() {
                  markers = updatedMarkers;
                });
              }
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller:
                          searchController, // Add controller to TextField
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        contentPadding: EdgeInsets.all(16),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Gap(8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xff273ea5),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: IconButton(
                      onPressed: searchLocation,
                      icon: const Icon(Icons.search),
                      color: Colors.white, // Set the color of the icon itself
                    ),
                  )
                ],
              ),
            ),
            Flexible(
              child: GoogleMap(
                mapType: MapType.normal,
                mapToolbarEnabled: true,
                zoomControlsEnabled: true,
                zoomGesturesEnabled: true,
                myLocationButtonEnabled: true,
                myLocationEnabled: true,
                initialCameraPosition: const CameraPosition(
                  target: MapsScreen.initialPosition,
                  zoom: 15,
                ),
                markers: markers,
                onTap: (position) {
                  saveToFavoritePlace(position);
                },
                onMapCreated: (controller) {
                  mapController = controller;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
