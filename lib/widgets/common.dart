import 'package:flutter/material.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
          ),
        ),
      ),
      ?trailing,
    ],
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(22),
  });
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(padding: padding, child: child),
    ),
  );
}
