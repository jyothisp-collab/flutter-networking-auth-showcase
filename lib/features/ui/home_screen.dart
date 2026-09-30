import 'package:flutter/material.dart';
import 'package:flutter_networking_auth_showcase/auth/auth_service.dart';
import 'package:flutter_networking_auth_showcase/core/network/api_exceptions.dart';
import 'package:flutter_networking_auth_showcase/features/data/data_model.dart';
import 'package:flutter_networking_auth_showcase/features/data/data_service.dart';

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
  bool _isLoggingIn = false;

  final _usernameController = TextEditingController(text: 'test');
  final _passwordController = TextEditingController(text: 'password');
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    widget.authService.addListener(_onAuthStateChanged);
  }

  @override
  void dispose() {
    widget.authService.removeListener(_onAuthStateChanged);
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onAuthStateChanged() {
    if (!mounted) return;
    setState(() {
      _data = null;
      _error = null;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
      _error = null;
    });

    try {
      await widget.authService.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      _showSnackBar('Login successful!', isError: false);
    } on AuthException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.toString(), isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Login failed: ${e.toString()}', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  Future<void> _fetchPublicData() async {
    _setDataState(loading: true);
    try {
      final data = await widget.dataService.getPublicData();
      _setDataState(data: data);
    } on ApiException catch (e) {
      _setDataState(error: e.toString());
      _showSnackBar(e.toString(), isError: true);
    } catch (e) {
      _setDataState(error: e.toString());
      _showSnackBar('Failed to fetch data: ${e.toString()}', isError: true);
    }
  }

  Future<void> _fetchProtectedData() async {
    _setDataState(loading: true);
    try {
      final data = await widget.dataService.getProtectedData();
      _setDataState(data: data);
    } on AuthException catch (e) {
      _setDataState(error: e.toString());
      _showSnackBar(e.toString(), isError: true);
    } on ApiException catch (e) {
      _setDataState(error: e.toString());
      _showSnackBar(e.toString(), isError: true);
    } catch (e) {
      _setDataState(error: e.toString());
      _showSnackBar('Failed to fetch data: ${e.toString()}', isError: true);
    }
  }

  Future<void> _createData() async {
    _setDataState(loading: true);
    try {
      final newItem = DataModel(
        id: 0,
        title: 'New Item ${DateTime.now().millisecondsSinceEpoch % 1000}',
        body: 'Created via POST request.',
      );
      final created = await widget.dataService.createData(newItem);
      _setDataState(data: created);
      _showSnackBar('Created item #${created.id}', isError: false);
    } on ApiException catch (e) {
      _setDataState(error: e.toString());
      _showSnackBar(e.toString(), isError: true);
    } catch (e) {
      _setDataState(error: e.toString());
      _showSnackBar('Failed to create data: ${e.toString()}', isError: true);
    }
  }

  void _setDataState({
    bool loading = false,
    DataModel? data,
    String? error,
  }) {
    setState(() {
      _isLoadingData = loading;
      if (data != null) _data = data;
      if (error != null) _error = error;
      if (loading) _error = null;
    });
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = widget.authService.isAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Networking & Auth Showcase'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Login Section
              if (!isAuthenticated) ...[
                _buildSectionHeader('Authentication'),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'test',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleLogin(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoggingIn ? null : _handleLogin,
                    icon: _isLoggingIn
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isLoggingIn ? 'Logging in...' : 'Login'),
                  ),
                ),
              ] else ...[
                _buildLoggedInCard(),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 24),

              // API Actions Section
              _buildSectionHeader('API Actions'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoadingData ? null : _fetchPublicData,
                      icon: const Icon(Icons.public),
                      label: const Text('Fetch Public Data'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isAuthenticated && !_isLoadingData
                          ? _fetchProtectedData
                          : null,
                      icon: const Icon(Icons.lock),
                      label: const Text('Fetch Protected'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _isLoadingData ? null : _createData,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('POST Create Data'),
              ),

              const SizedBox(height: 24),

              // Result Display
              _buildSectionHeader('Result'),
              const SizedBox(height: 12),
              _buildResultCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildLoggedInCard() {
    final token = widget.authService.currentToken;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Authenticated',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Token: ${token?.accessToken ?? "N/A"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    'Valid: ${token?.isValid ?? false ? "Yes" : "No"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                widget.authService.logout();
                _showSnackBar('Logged out', isError: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_isLoadingData) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_data != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.data_object,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Data #${_data!.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDataRow('ID', '${_data!.id}'),
              _buildDataRow('Title', _data!.title),
              _buildDataRow('Body', _data!.body),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No data fetched yet.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
