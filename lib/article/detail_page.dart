import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import '../models/timeline_entry.dart';
import '../l10n/l10n.dart';

class DetailPage extends StatelessWidget {
  final TimelineEntry entry;

  const DetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(entry.label)),
      body: FutureBuilder<String>(
        future: _loadHtmlContent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: ${snapshot.error}'),
                ],
              ),
            );
          }

          final htmlContent = snapshot.data ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: HtmlWidget(
              htmlContent,
              textStyle: const TextStyle(fontSize: 16),
            ),
          );
        },
      ),
    );
  }

  Future<String> _loadHtmlContent() async {
    if (entry.description == null) return '';

    final file = File('data/${entry.description}');
    if (!await file.exists()) {
      throw Exception('HTML 文件不存在: ${entry.description}');
    }

    return await file.readAsString();
  }
}
