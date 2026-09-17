import 'package:flutter/material.dart';
import '../../auth/auth_service.dart';
import '../data/data_model.dart';
import '../data/data_service.dart';

class HomeScreen extends StatefulWidget {
  final AuthService authService;
  final DataService dataService;

  const HomeScreen({
    super.key,
    required this.authService,
    required this.dataService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DataModel? _data;
  String? _error;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthStateChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    setState(() {
      // Rebuild when auth state changes
    });
  }

  Future<void> _fetchPublicData() async {
    _setStateData(loading: true);
    try {
      final data = await widget.dataService.getPublicData();
      _setStateData(data: data);
    } catch (e) {
      _setStateData(error: e.toString());
    }
  }

  Future<void> _fetchProtectedData() async {
    _setStateData(loading: true);
    try {
      final data = await widget.dataService.getProtectedData();
      _setStateData(data: data);
    } catch (e) {
      _setStateData(error: e.toString());
    }
  }

  void _setStateData({bool loading = false, DataModel? data, String? error}) {
    setState(() {
      _isLoadingData = loading;
      if (data != null) _data = data;
      if (error != null) _error = error;
      if (loading) {
        _error = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = widget.authService.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Networking & Auth Showcase'),
        actions: [
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                widget.authService.logout();
                setState(() {
                  _data = null;
                  _error = null;
                });
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isAuthenticated) ...[
              const Text('Not logged in. (Use test / password)'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.authService.isLoading
                    ? null
                    : () => _handleLogin(context),
                child: widget.authService.isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Login'),
              ),
            ] else ...[
              Text(
                'Logged in! Token: ${widget.authService.currentToken?.accessToken}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
            const Divider(height: 32),
            ElevatedButton(
              onPressed: _fetchPublicData,
              child: const Text('Fetch Public Data'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchProtectedData,
              child: const Text('Fetch Protected Data (Requires Auth)'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Result:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (_isLoadingData)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red))
            else if (_data != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${_data!.id}'),
                      Text(
                        'Title: ${_data!.title}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Body: ${_data!.body}'),
                    ],
                  ),
                ),
              )
            else
              const Text('No data fetched yet.'),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    try {
      await widget.authService.login('test', 'password');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }
}
