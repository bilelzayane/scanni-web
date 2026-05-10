import 'package:flutter/material.dart';
import 'dart:html' as html;

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If the screen is wider than 600px, redirect to the desktop site
        if (constraints.maxWidth > 600) {
          html.window.location.href = 'https://www.horizon-impact.site/';
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return child;
      },
    );
  }
}
