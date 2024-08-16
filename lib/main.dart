import 'package:firebase_core/firebase_core.dart';
import 'package:flores_favorite_places/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flores_favorite_places/screens/maps_google.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
  runApp(const WebAPI());
}

class WebAPI extends StatelessWidget {
  const WebAPI({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MapsScreen(),
    );
  }
}