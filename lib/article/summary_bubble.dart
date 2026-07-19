import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/timeline_entry.dart';
import '../l10n/l10n.dart';

class SummaryBubble extends StatelessWidget {
  final TimelineEntry entry;
  final VoidCallback onDetailTap;

  const SummaryBubble({
    super.key,
    required this.entry,
    required this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (entry.summary != null)
          MarkdownBody(data: entry.summary!, selectable: true),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: onDetailTap,
            child: Text(l10n.detail),
          ),
        ),
      ],
    );
  }
}
