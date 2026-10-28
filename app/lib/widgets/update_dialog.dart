import 'package:flutter/material.dart';

import '../update/update_controller.dart';
import 'table_ui.dart';

/// "What's new" for an available release, with the button that installs it.
class UpdateDialog extends StatelessWidget {
  const UpdateDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final updates = UpdateController.of(context);
    final release = updates.available;
    if (release == null) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final progress = updates.progress;
    final action = release.installer == null
        ? 'Открыть страницу'
        : release.installer!.endsWith('.apk')
        ? 'Скачать'
        : 'Обновить';

    return Dialog(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      child: TablePanel(
        title: 'Новая версия ${release.version}',
        width: width < 560 ? width - 32 : 520,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: SingleChildScrollView(child: ReleaseNotes(release.notes)),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              color: gold,
              backgroundColor: Colors.white24,
            ),
          ],
          if (updates.error != null) ...[
            const SizedBox(height: 12),
            Text(
              updates.error!,
              style: const TextStyle(color: Colors.orangeAccent),
            ),
          ],
          PanelButtons([
            GoldButton('Позже', onPressed: () => Navigator.pop(context)),
            GoldButton(
              action,
              onPressed: progress != null ? null : updates.installAvailable,
            ),
          ]),
        ],
      ),
    );
  }
}

/// Renders the CHANGELOG subset used in release notes: "### " headings,
/// "- " bullets and **bold**.
class ReleaseNotes extends StatelessWidget {
  const ReleaseNotes(this.markdown, {super.key});

  final String markdown;

  static const _text = TextStyle(
    color: Colors.white,
    fontSize: 16,
    height: 1.35,
  );

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];
    for (final raw in markdown.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) continue;
      if (line.startsWith('#')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              line.replaceFirst(RegExp(r'^#+\s*'), ''),
              style: _text.copyWith(fontWeight: FontWeight.w700, color: gold),
            ),
          ),
        );
      } else if (line.startsWith('- ')) {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: _text),
                Expanded(child: _rich(line.substring(2))),
              ],
            ),
          ),
        );
      } else {
        blocks.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _rich(line),
          ),
        );
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  /// **bold** spans; other markdown is shown as is.
  Widget _rich(String text) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(
        children: [
          for (final (i, part) in parts.indexed)
            TextSpan(
              text: part.replaceAll('`', ''),
              style: i.isOdd
                  ? const TextStyle(fontWeight: FontWeight.w700)
                  : null,
            ),
        ],
      ),
      style: _text,
    );
  }
}
