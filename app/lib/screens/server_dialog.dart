import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../state.dart';

/// Hidden developer setting: point the app at another content host without rebuilding.
Future<void> showServerDialog(BuildContext context) {
  final st = context.read<AppState>();
  final ctrl = TextEditingController(text: AppConfig.baseUrl);
  return showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Server'),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Base URL', hintText: 'https://am-veg.vercel.app'),
        ),
        const SizedBox(height: 12),
        Text('Build default: ${AppConfig.defaultBaseUrl}', style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          ActionChip(label: const Text('Local'), onPressed: () => ctrl.text = 'http://10.0.2.2:8080'),
          ActionChip(label: const Text('Vercel'), onPressed: () => ctrl.text = 'https://am-veg.vercel.app'),
        ]),
      ]),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
            st.changeHost(null);
          },
          child: const Text('Reset'),
        ),
        FilledButton(
          onPressed: () {
            final url = ctrl.text.trim();
            if (!url.startsWith('http://') && !url.startsWith('https://')) return;
            Navigator.pop(ctx);
            st.changeHost(url);
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
