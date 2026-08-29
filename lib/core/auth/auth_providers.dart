import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_controller.dart';
import 'auth_state.dart';

/// Auth session provider used by auth screens and authenticated drawer.
final authProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
