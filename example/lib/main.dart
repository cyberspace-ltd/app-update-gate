import 'package:flutter/material.dart';
import 'package:app_update_gate/app_update_gate.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Update Gate Example',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Run the version check after the first frame so context is available.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  Future<void> _checkForUpdate() async {
    // ── Option A: Explicit version ──────────────────────────────────────
    final status = await AppUpdateGate.check(
      context: context,
      appId: 'com.myorg.coolapp',
      currentVersion: '2.3.0', // Simulate an older version.
    );

    // ── Option B: Auto-detect version (comment out Option A first) ──────
    // final status = await AppUpdateGate.check(
    //   context: context,
    //   appId: 'com.myorg.coolapp',
    // );

    debugPrint('Update check result: $status');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Gate Example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('App is running!'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _checkForUpdate,
              child: const Text('Re-check for update'),
            ),
          ],
        ),
      ),
    );
  }
}
