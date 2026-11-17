import 'package:flutter/material.dart';

import '../theme/home_tokens.dart';
import 'home_gem_stage.dart';

/// Closing section: full-screen live gem stage, spaced like other home blocks.
class HomeFooter extends StatelessWidget {
  const HomeFooter({this.stageHeight, super.key});

  /// Height of the gem stage; defaults to the screen height.
  final double? stageHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: HomeSpace.section),
      child: HomeGemStage(height: stageHeight),
    );
  }
}
