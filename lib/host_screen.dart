import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'controller.dart';
import 'models.dart';
import 'strips.dart';
import 'widgets.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  late final HostController c;
  final ScrollController sc = ScrollController();

  @override
  void initState() {
    super.initState();
    c = HostController();
  }

  @override
  void dispose() {
    c.dispose();
    sc.dispose();
    super.dispose();
  }

  void _wheel(PointerSignalEvent e) {
    if (e is PointerScrollEvent && sc.hasClients) {
      GestureBinding.instance.pointerSignalResolver.register(e, (ev) {
        final pe = ev as PointerScrollEvent;
        final t = (sc.offset + pe.scrollDelta.dy)
            .clamp(0.0, sc.position.maxScrollExtent)
            .toDouble();
        sc.jumpTo(t);
      });
    }
  }

  Widget _brand() {
    final ip = c.ips.isEmpty ? 'OFFLINE' : '${c.ips.first}:$kPort';
    const lcd = Color(0xFF5CF4FF);
    return MetalPanel(
      radius: 8,
      screws: true,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LogoMark(size: 58),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  BrandTitle(size: 34),
                  Text('Digital Mixer 24 CH',
                      style: TextStyle(fontSize: 10, color: Color(0xFF9AA3AE))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF0B3C49), Color(0xFF04202A)],
              ),
              border: Border.all(color: Colors.black),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('REMOTE ANDROID  (${c.clientCount})',
                      style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.bold, color: op(lcd, 0.7))),
                  Text(ip,
                      style: const TextStyle(
                        fontFamily: 'Consolas',
                        fontFamilyFallback: ['Courier New', 'monospace'],
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: lcd,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _b(String label, Map<String, dynamic> cmd,
      {bool lit = false, Color litColor = UX.accent}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: MixButton(
          lit: lit,
          litColor: litColor,
          fontSize: 12,
          onTap: () => c.send(cmd),
          child: Text(label),
        ),
      ),
    );
  }

  Widget _buttons() {
    final grp = c.page == 2;
    final muteOn = grp ? c.groups[c.selGroup].mute : c.channels[c.selected].mute;
    final Map<String, dynamic> muteCmd =
        grp ? {'t': 'gmute', 'g': c.selGroup} : {'t': 'mute', 'ch': c.selected};
    return Column(
      children: [
        Expanded(
          child: Row(children: [
            _b('MUTE', muteCmd, lit: muteOn, litColor: UX.red),
            _b('SOLO', {'t': 'solo', 'ch': c.selected},
                lit: c.channels[c.selected].solo, litColor: UX.yellow),
            _b('CLEAR', {'t': 'clear', 'ch': c.selected}),
          ]),
        ),
        Expanded(
          child: Row(children: [
            _b('ADD', {'t': 'add', 'ch': c.selected}),
            _b('LOAD', {'t': 'load'}),
            _b('SAVE', {'t': 'save'}),
          ]),
        ),
        Expanded(
          child: Row(children: [
            _b(c.playing ? 'PAUSE' : 'PLAY', {'t': 'play'},
                lit: c.playing, litColor: UX.green),
            _b('STOP', {'t': 'stop'}),
            _b('LOOP', {'t': 'loop'}, lit: c.loop, litColor: UX.accent),
          ]),
        ),
      ],
    );
  }

  Widget _top() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 250, child: _brand()),
        const SizedBox(width: 10),
        Expanded(
          child: MetalPanel(
            radius: 8,
            screws: true,
            padding: const EdgeInsets.all(14),
            child: LcdScreen(c: c),
          ),
        ),
        const SizedBox(width: 10),
        MetalPanel(
          radius: 8,
          screws: true,
          padding: const EdgeInsets.all(18),
          child: Center(child: DPad(c: c, cell: 48)),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 330,
          child: MetalPanel(
            radius: 8,
            screws: true,
            padding: const EdgeInsets.all(14),
            child: _buttons(),
          ),
        ),
      ],
    );
  }

  Widget _strips() {
    return LayoutBuilder(builder: (context, box) {
      const gw = 62.0;
      const mw = 118.0;
      final avail = box.maxWidth - (gw * 4) - mw - 40;
      final w = (avail / kChannels).clamp(50.0, 96.0).toDouble();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Listener(
              onPointerSignal: _wheel,
              child: Scrollbar(
                controller: sc,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: sc,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < kChannels; i++)
                          ChannelStrip(c: c, i: i, width: w),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          for (var g = 0; g < kGroups; g++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GroupStrip(c: c, g: g, width: gw),
            ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: MasterStrip(c: c, width: mw),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UX.bg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B1E24), Color(0xFF090A0C)],
          ),
        ),
        padding: const EdgeInsets.all(10),
        child: ListenableBuilder(
          listenable: c,
          builder: (context, _) => Column(
            children: [
              SizedBox(height: 206, child: _top()),
              const SizedBox(height: 10),
              Expanded(child: _strips()),
            ],
          ),
        ),
      ),
    );
  }
}
