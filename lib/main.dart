import 'package:flutter/material.dart';
import 'auth/auth_service.dart';
import 'core/network/api_client.dart';
import 'features/data/data_service.dart';
import 'features/ui/home_screen.dart';

void main() {
  final authService = AuthService();
  final apiClient = ApiClient(authService);
  final dataService = DataService(apiClient);

  runApp(MyApp(authService: authService, dataService: dataService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final DataService dataService;

  const MyApp({
    super.key,
    required this.authService,
    required this.dataService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Networking & Auth Showcase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: HomeScreen(authService: authService, dataService: dataService),
    );
  }
}
