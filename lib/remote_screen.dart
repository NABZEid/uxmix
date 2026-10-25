import 'package:flutter/material.dart';

import 'controller.dart';
import 'models.dart';
import 'strips.dart';
import 'widgets.dart';

class RemoteScreen extends StatefulWidget {
  const RemoteScreen({super.key});

  @override
  State<RemoteScreen> createState() => _RemoteScreenState();
}

class _RemoteScreenState extends State<RemoteScreen> {
  final RemoteController c = RemoteController();
  final TextEditingController ip = TextEditingController();

  @override
  void initState() {
    super.initState();
    c.init().then((_) {
      if (!mounted) return;
      ip.text = c.lastIp;
      if (c.lastIp.isNotEmpty) c.connect(c.lastIp);
    });
  }

  @override
  void dispose() {
    c.dispose();
    ip.dispose();
    super.dispose();
  }

  BoxDecoration get _bg => const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1E24), Color(0xFF090A0C)],
        ),
      );

  // ----- layar hubungkan -----
  Widget _connect() {
    return Container(
      decoration: _bg,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LogoMark(size: 120),
            const SizedBox(width: 32),
            SizedBox(
              width: 340,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BrandTitle(size: 40),
                  const Text('Remote mixer',
                      style: TextStyle(color: Color(0xFF9AA3AE), fontSize: 13)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: ip,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'IP Windows',
                      hintText: '192.168.1.5',
                      helperText: 'Lihat di kotak REMOTE ANDROID pada UxMix Windows',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (v) => c.connect(v),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: MixButton(
                      lit: true,
                      litColor: UX.accent,
                      fontSize: 14,
                      onTap: c.connecting ? null : () => c.connect(ip.text),
                      child: Text(c.connecting ? 'Menghubungkan...' : 'Hubungkan'),
                    ),
                  ),
                  if (c.error.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(c.error,
                          style: const TextStyle(color: Color(0xFFFF7B7B), fontSize: 12)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----- bar atas -----
  Widget _tb(String label, Map<String, dynamic> cmd,
      {bool lit = false, Color litColor = UX.accent}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: MixButton(
        width: 54,
        height: 38,
        lit: lit,
        litColor: litColor,
        fontSize: 11,
        onTap: () => c.send(cmd),
        child: Text(label),
      ),
    );
  }

  Widget _miniLcd() {
    const lcd = Color(0xFF5CF4FF);
    const mono = TextStyle(
      fontFamily: 'monospace',
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: lcd,
      height: 1.15,
    );
    final ch = c.channels[c.selected];
    final line1 =
        'CH ${(c.selected + 1).toString().padLeft(2, '0')}  ${(ch.volume * 100).round()}%  GRP ${kGroupLetters[ch.group]}${ch.mute ? '  MUTE' : ''}${ch.solo ? '  SOLO' : ''}';
    final line2 = c.toast.isNotEmpty
        ? c.toast
        : (ch.hasTrack ? ch.file : '-- NO TRACK --');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B3C49), Color(0xFF04202A)],
        ),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line1, style: mono, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(line2,
              style: mono.copyWith(fontSize: 11, color: op(lcd, 0.8)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _bar() {
    return MetalPanel(
      radius: 6,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          const LogoMark(size: 36),
          const SizedBox(width: 8),
          Expanded(child: _miniLcd()),
          const SizedBox(width: 2),
          _tb(c.playing ? 'PAUSE' : 'PLAY', {'t': 'play'}, lit: c.playing, litColor: UX.green),
          _tb('STOP', {'t': 'stop'}),
          _tb('SAVE', {'t': 'save'}),
          _tb('LOAD', {'t': 'load'}),
          _tb('LOOP', {'t': 'loop'}, lit: c.loop),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: MixButton(
              width: 40,
              height: 38,
              onTap: () => c.disconnect(),
              child: const Icon(Icons.link_off, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _console() {
    const sw = 74.0;
    return Container(
      decoration: _bg,
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
      child: Column(
        children: [
          SizedBox(height: 52, child: _bar()),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < kChannels; i++)
                    ChannelStrip(c: c, i: i, width: sw, compact: true),
                  const SizedBox(width: 8),
                  for (var g = 0; g < kGroups; g++)
                    GroupStrip(c: c, g: g, width: sw, compact: true),
                  const SizedBox(width: 8),
                  MasterStrip(c: c, width: 120, compact: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UX.bg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) => c.connected ? _console() : _connect(),
        ),
      ),
    );
  }
}
