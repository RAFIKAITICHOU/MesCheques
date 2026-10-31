import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../screens/lock_screen.dart';
import '../screens/setup_pin_screen.dart';

class LockGate extends StatefulWidget {
  final Widget child;

  const LockGate({
    super.key,
    required this.child,
  });

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final auth = context.read<AuthProvider>();

    if (state == AppLifecycleState.paused) {
      auth.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      auth.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (!auth.hasPinSet) {
      return const SetupPinScreen();
    }

    if (auth.isLocked) {
      return const LockScreen();
    }

    return widget.child;
  }
}
