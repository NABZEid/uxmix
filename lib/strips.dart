import 'package:flutter/material.dart';

import 'controller.dart';
import 'models.dart';
import 'widgets.dart';

const _dimText = Color(0xFF9AA3AE);

class ChannelStrip extends StatelessWidget {
  final MixerController c;
  final int i;
  final double width;
  final bool compact;

  const ChannelStrip({
    super.key,
    required this.c,
    required this.i,
    required this.width,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final ch = c.channels[i];
    final sel = c.selected == i;
    final headH = compact ? 20.0 : 24.0;

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: MetalPanel(
          radius: 6,
          glow: sel ? UX.accent : null,
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => c.send({'t': 'sel', 'ch': i}),
                child: Container(
                  height: headH,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: sel
                          ? const [Color(0xFF7FE6FF), Color(0xFF1AA8D6)]
                          : const [Color(0xFF16191D), Color(0xFF23272D)],
                    ),
                    border: Border.all(color: const Color(0xFF07080A)),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: sel ? Colors.black : const Color(0xFFB6BEC8),
                    ),
                  ),
                ),
              ),
              SizedBox(height: compact ? 4 : 5),
              Expanded(flex: 3, child: VuLamps(level: ch.level)),
              SizedBox(height: compact ? 4 : 5),
              Row(
                children: [
                  Expanded(
                    child: MixButton(
                      height: compact ? 26 : 28,
                      lit: ch.mute,
                      litColor: UX.red,
                      onTap: () => c.send({'t': 'mute', 'ch': i}),
                      child: const Text('M'),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: MixButton(
                      height: compact ? 26 : 28,
                      lit: ch.solo,
                      litColor: UX.yellow,
                      onTap: () => c.send({'t': 'solo', 'ch': i}),
                      child: const Text('S'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              MixButton(
                height: compact ? 20 : 22,
                lit: ch.group > 0,
                litColor: groupColor(ch.group),
                fontSize: 9,
                onTap: () => c.send({'t': 'group', 'ch': i}),
                child: Text('GRP ${kGroupLetters[ch.group]}'),
              ),
              SizedBox(height: compact ? 4 : 5),
              Expanded(
                flex: 5,
                child: Fader(
                  value: ch.volume,
                  onChanged: (v) => c.send({'t': 'vol', 'ch': i, 'v': v}),
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text('${(ch.volume * 100).round()}',
                    style: const TextStyle(fontSize: 10, color: _dimText)),
              ],
              SizedBox(height: compact ? 3 : 3),
              MixButton(
                height: compact ? 20 : 22,
                fit: false,
                lit: ch.hasTrack,
                litColor: const Color(0xFF3BD88A),
                fontSize: 8,
                onTap: () => c.send({'t': 'add', 'ch': i}),
                onLongPress: () => c.send({'t': 'clear', 'ch': i}),
                child: Text(
                  ch.hasTrack ? ch.file : '+ MP3',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              if (!compact) ...const [
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Screw(size: 7, angle: 0.8), Screw(size: 7, angle: 2.2)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class GroupStrip extends StatelessWidget {
  final MixerController c;
  final int g; // 0..3
  final double width;
  final bool compact;

  const GroupStrip({
    super.key,
    required this.c,
    required this.g,
    required this.width,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final gs = c.groups[g];
    final col = groupColor(g + 1);
    final sel = c.selGroup == g;
    double level = 0;
    var count = 0;
    for (final ch in c.channels) {
      if (ch.group == g + 1) {
        count++;
        if (ch.level > level) level = ch.level;
      }
    }
    if (gs.mute) level = 0;

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: MetalPanel(
          radius: 6,
          glow: sel ? col : null,
          padding: const EdgeInsets.all(4),
          colors: const [Color(0xFF3B3F4A), Color(0xFF23262E), Color(0xFF16181D)],
          child: Column(
            children: [
              GestureDetector(
                onTap: () => c.send({'t': 'selgrp', 'g': g}),
                child: Container(
                  height: compact ? 20 : 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color.lerp(col, Colors.white, 0.4)!, col],
                    ),
                    border: Border.all(color: const Color(0xFF07080A)),
                  ),
                  child: Text(
                    'GRP ${kGroupLetters[g + 1]}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Expanded(flex: 3, child: VuLamps(level: level * gs.volume)),
              const SizedBox(height: 5),
              MixButton(
                height: compact ? 26 : 28,
                lit: gs.mute,
                litColor: UX.red,
                onTap: () => c.send({'t': 'gmute', 'g': g}),
                child: const Text('MUTE'),
              ),
              const SizedBox(height: 5),
              Expanded(
                flex: 5,
                child: Fader(
                  accent: col,
                  value: gs.volume,
                  onChanged: (v) => c.send({'t': 'gvol', 'g': g, 'v': v}),
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text('${(gs.volume * 100).round()}',
                    style: const TextStyle(fontSize: 10, color: _dimText)),
              ],
              const SizedBox(height: 3),
              Text('$count CH', style: const TextStyle(fontSize: 9, color: _dimText)),
              if (!compact) ...const [
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Screw(size: 7, angle: 1.4), Screw(size: 7, angle: 0.3)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MasterStrip extends StatelessWidget {
  final MixerController c;
  final double width;
  final bool compact;

  const MasterStrip({
    super.key,
    required this.c,
    required this.width,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: MetalPanel(
          radius: 6,
          glow: UX.accent2,
          padding: const EdgeInsets.all(5),
          colors: const [Color(0xFF3F3A52), Color(0xFF26222F), Color(0xFF17151D)],
          child: Column(
            children: [
              Container(
                height: compact ? 20 : 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFB59BFF), Color(0xFF6E48D8)],
                  ),
                  border: Border.all(color: const Color(0xFF07080A)),
                ),
                child: const Text('MASTER',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w900, color: Colors.black)),
              ),
              const SizedBox(height: 5),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Expanded(child: VuLamps(level: c.meterL)),
                    Expanded(child: VuLamps(level: c.meterR)),
                  ],
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text('L', style: TextStyle(fontSize: 9, color: _dimText)),
                  Text('R', style: TextStyle(fontSize: 9, color: _dimText)),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                flex: 5,
                child: Fader(
                  accent: UX.accent2,
                  value: c.master,
                  onChanged: (v) => c.send({'t': 'master', 'v': v}),
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text('${(c.master * 100).round()}',
                    style: const TextStyle(fontSize: 10, color: _dimText)),
                const SizedBox(height: 4),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Screw(size: 7, angle: 0.6), Screw(size: 7, angle: 2.0)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
