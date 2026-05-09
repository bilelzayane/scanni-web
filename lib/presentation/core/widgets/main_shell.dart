import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../features/scan/scan_controller.dart';
import 'top_notched_border.dart';

class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: navigationShell,
      floatingActionButton: _AnimatedShutterButton(
        navigationShell: navigationShell,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: TopNotchedBorder(
        notchMargin: 14.0,
        color: Colors.white.withValues(alpha: 0.5),
        strokeWidth: 1.5,
        child: BottomAppBar(
          clipBehavior: Clip.antiAlias,
          color: Colors.transparent,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.05),
          surfaceTintColor: Colors.transparent,
          shape: const CircularNotchedRectangle(),
          notchMargin: 14.0,
          padding: EdgeInsets.zero,
          height: 60,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              color: Colors.black.withValues(alpha: 0.08),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () => navigationShell.goBranch(0),
                    tooltip: '',
                    icon: Icon(
                      Icons.house_outlined,
                      color: navigationShell.currentIndex == 0
                          ? AppTheme.primaryColor
                          : Colors.grey[500],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 60),
                  IconButton(
                    onPressed: () => navigationShell.goBranch(2),
                    tooltip: '',
                    icon: Icon(
                      Icons.history,
                      color: navigationShell.currentIndex == 2
                          ? AppTheme.primaryColor
                          : Colors.grey[500],
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedShutterButton extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const _AnimatedShutterButton({required this.navigationShell});

  @override
  ConsumerState<_AnimatedShutterButton> createState() =>
      _AnimatedShutterButtonState();
}

class _AnimatedShutterButtonState extends ConsumerState<_AnimatedShutterButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _executeAction() {
    print(
      'DEBUG: FAB pressed - currentIndex: ${widget.navigationShell.currentIndex}',
    );
    if (widget.navigationShell.currentIndex != 1) {
      print('DEBUG: Navigating to scan branch');
      widget.navigationShell.goBranch(1);
    } else {
      // Trigger camera capture!
      print('DEBUG: Triggering camera capture');
      ref.read(cameraTriggerNotifierProvider.notifier).trigger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _controller.forward(),
      onPointerUp: (_) => _controller.reverse(),
      onPointerCancel: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton(
          onPressed: _executeAction,
          backgroundColor: widget.navigationShell.currentIndex == 1
              ? Colors.transparent
              : const Color(0xFF4CAF50),
          elevation: widget.navigationShell.currentIndex == 1 ? 0 : 4,
          shape: CircleBorder(
            side: widget.navigationShell.currentIndex == 1
                ? BorderSide.none
                : const BorderSide(color: Colors.white, width: 3),
          ),
          child: widget.navigationShell.currentIndex == 1
              ? Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                )
              : const Icon(
                  Icons.center_focus_strong,
                  color: Colors.white,
                  size: 28,
                ),
        ),
      ),
    );
  }
}
