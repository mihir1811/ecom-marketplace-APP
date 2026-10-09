import 'package:flutter/material.dart';

import '../theme/home_tokens.dart';
import 'home_gem_stage.dart';

/// Closing section: full-screen live gem stage, spaced like other home blocks.
class HomeFooter extends StatelessWidget {
  const HomeFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: HomeSpace.section),
      child: HomeGemStage(),
    );
  }
}
