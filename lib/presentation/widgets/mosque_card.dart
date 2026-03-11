import 'package:flutter/material.dart';

class MosqueCard extends StatelessWidget {
  const MosqueCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.mosque_rounded,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(subtitle),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}
