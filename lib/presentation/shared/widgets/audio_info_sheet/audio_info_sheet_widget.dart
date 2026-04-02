import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:open_player/data/models/audio_model.dart';
import 'package:open_player/utils/formater.dart';

class AudioInfoSheetWidget extends StatelessWidget {
  const AudioInfoSheetWidget({super.key, required this.audio});

  final AudioModel audio;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final onSurface = cs.onSurface;
    final primary = cs.primary;
    final scaffold = Theme.of(context).scaffoldBackgroundColor;
    final cardBg =
        scaffold == Colors.black ? const Color(0xFF0D0D0D) : cs.surface;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.info_outline_rounded,
                      color: primary, size: 19),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Track Info',
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        audio.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: onSurface.withValues(alpha: 0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Thumbnail ────────────────────────────────────────────────────
          if (audio.thumbnail.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  audio.thumbnail.first.bytes,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
            ),

          // ── Info tiles ───────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Column(
                children: [
                  Divider(
                    color: onSurface.withValues(alpha: 0.06),
                    height: 1,
                  ),
                  const Gap(8),

                  // ── All your original fields, untouched ─────────────────
                  _Tile(
                      leading: "Title",
                      title: audio.title,
                      onSurface: onSurface,
                      primary: primary),
                  _Tile(
                      leading: "Album",
                      title: audio.album,
                      onSurface: onSurface,
                      primary: primary),
                  _Tile(
                      leading: "Artists",
                      title: audio.artists,
                      onSurface: onSurface,
                      primary: primary),
                  _Tile(
                    leading: "Genre",
                    title: audio.genre.isNotEmpty
                        ? audio.genre.join(", ")
                        : "Unknown",
                    onSurface: onSurface,
                    primary: primary,
                  ),
                  _Tile(
                    leading: "Size",
                    title: Formatter.formatBitSize(audio.size),
                    onSurface: onSurface,
                    primary: primary,
                  ),
                  _Tile(
                    leading: "Bitrate",
                    title: audio.bitrate != null
                        ? Formatter.formatBitrate(audio.bitrate!)
                        : "Unknown",
                    onSurface: onSurface,
                    primary: primary,
                  ),
                  _Tile(
                      leading: "Sample Rate",
                      title: audio.sampleRate,
                      onSurface: onSurface,
                      primary: primary),
                  _Tile(
                    leading: "Year",
                    title: audio.year != null
                        ? Formatter.formatDate(audio.year!)
                        : "Unknown",
                    onSurface: onSurface,
                    primary: primary,
                  ),
                  _Tile(
                      leading: "Extension",
                      title: audio.ext,
                      onSurface: onSurface,
                      primary: primary),
                ],
              ),
            ),
          ),

          Gap(80),
        ],
      ),
    );
  }
}

// ── Info tile ─────────────────────────────────────────────────────────────────

class _Tile extends StatelessWidget {
  const _Tile({
    required this.leading,
    required this.title,
    required this.onSurface,
    required this.primary,
  });

  final String leading;
  final dynamic title;
  final Color onSurface;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: 96,
            child: Text(
              leading,
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
          // Separator dot
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 10),
            child: Text(
              '·',
              style: TextStyle(
                color: primary.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Value
          Expanded(
            child: Text(
              '$title',
              style: TextStyle(
                color: onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
