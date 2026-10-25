import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// Dasar state mixer. Semua aksi UI lewat [send] sehingga tampilan
/// Windows (host) dan Android (remote) memakai kode yang sama.
abstract class MixerController extends ChangeNotifier {
  final List<ChannelState> channels = List.generate(
      kChannels, (i) => ChannelState('CH ${(i + 1).toString().padLeft(2, '0')}'));
  final List<GroupState> groups = List.generate(kGroups, (_) => GroupState());

  double master = 0.8;
  int selected = 0;
  int selGroup = 0;
  int page = 0; // 0 channel, 1 master, 2 grup, 3 sistem
  int slot = 1;
  bool playing = false;
  bool loop = false;
  double meterL = 0;
  double meterR = 0;
  String toast = '';

  void send(Map<String, dynamic> cmd);
  List<String> systemLines();

  void notify() => notifyListeners();

  Map<String, dynamic> toWire() => {
        'ch': channels.map((c) => c.toWire()).toList(),
        'gr': groups.map((g) => g.toJson()).toList(),
        'master': master,
        'sel': selected,
        'selGroup': selGroup,
        'page': page,
        'slot': slot,
        'playing': playing,
        'loop': loop,
        'mL': (meterL * 100).round() / 100,
        'mR': (meterR * 100).round() / 100,
        'toast': toast,
      };

  void applyWire(Map m) {
    final list = m['ch'] as List;
    for (var i = 0; i < kChannels && i < list.length; i++) {
      channels[i].fromWire(list[i] as Map);
    }
    final gr = m['gr'] as List;
    for (var i = 0; i < kGroups && i < gr.length; i++) {
      groups[i].fromJson(gr[i] as Map);
    }
    master = clamp01((m['master'] ?? 0.8) as num);
    selected = ((m['sel'] ?? 0) as num).toInt().clamp(0, kChannels - 1).toInt();
    selGroup = ((m['selGroup'] ?? 0) as num).toInt().clamp(0, kGroups - 1).toInt();
    page = ((m['page'] ?? 0) as num).toInt().clamp(0, 3).toInt();
    slot = ((m['slot'] ?? 1) as num).toInt().clamp(1, 5).toInt();
    playing = m['playing'] == true;
    loop = m['loop'] == true;
    meterL = clamp01((m['mL'] ?? 0) as num);
    meterR = clamp01((m['mR'] ?? 0) as num);
    toast = (m['toast'] ?? '').toString();
  }
}

// ---------------------------------------------------------------------------
// HOST (Windows): memutar audio, menjalankan server WebSocket untuk remote.
// ---------------------------------------------------------------------------
class HostController extends MixerController {
  final Map<int, AudioPlayer> _players = {};
  final Map<int, List<StreamSubscription<dynamic>>> _subs = {};
  final List<WebSocket> _clients = [];
  HttpServer? _server;
  List<String> ips = [];
  String serverError = '';
  Timer? _timer;
  final Stopwatch _clock = Stopwatch()..start();
  final Random _rnd = Random();
  bool _dirty = true;
  int _toastUntil = 0;
  bool _busy = false;

  int get clientCount => _clients.length;

  HostController() {
    _timer = Timer.periodic(const Duration(milliseconds: 60), (_) => _tick());
    _startServer();
  }

  // ----- perintah -----
  @override
  void send(Map<String, dynamic> cmd) => _apply(cmd);

  void _apply(Map cmd) {
    final t = cmd['t'];
    int ch() => ((cmd['ch'] ?? selected) as num).toInt().clamp(0, kChannels - 1).toInt();
    int g() => ((cmd['g'] ?? selGroup) as num).toInt().clamp(0, kGroups - 1).toInt();

    switch (t) {
      case 'vol':
        channels[ch()].volume = clamp01(cmd['v'] as num);
        break;
      case 'mute':
        {
          final c = channels[ch()];
          c.mute = !c.mute;
          break;
        }
      case 'solo':
        {
          final c = channels[ch()];
          c.solo = !c.solo;
          break;
        }
      case 'sel':
        selected = ch();
        break;
      case 'selgrp':
        selGroup = g();
        break;
      case 'master':
        master = clamp01(cmd['v'] as num);
        break;
      case 'group':
        {
          final c = channels[ch()];
          c.group = (c.group + 1) % (kGroups + 1);
          break;
        }
      case 'gvol':
        groups[g()].volume = clamp01(cmd['v'] as num);
        break;
      case 'gmute':
        groups[g()].mute = !groups[g()].mute;
        break;
      case 'page':
        page = (page + 1) % 4;
        break;
      case 'nav':
        _nav(cmd['d'].toString());
        break;
      case 'play':
        _togglePlay();
        return;
      case 'stop':
        _stopAll();
        return;
      case 'loop':
        _toggleLoop();
        return;
      case 'add':
        _addTracks(ch());
        return;
      case 'clear':
        _clearTrack(ch());
        return;
      case 'save':
        _save();
        return;
      case 'load':
        _load();
        return;
    }
    _applyVolumes();
    _dirty = true;
  }

  void _nav(String d) {
    const step = 0.02;
    final delta = d == 'u' ? step : (d == 'd' ? -step : 0.0);
    switch (page) {
      case 0:
        if (d == 'l') selected = (selected + kChannels - 1) % kChannels;
        if (d == 'r') selected = (selected + 1) % kChannels;
        if (delta != 0) {
          channels[selected].volume = clamp01(channels[selected].volume + delta);
        }
        break;
      case 1:
        if (delta != 0) master = clamp01(master + delta);
        break;
      case 2:
        if (d == 'l') selGroup = (selGroup + kGroups - 1) % kGroups;
        if (d == 'r') selGroup = (selGroup + 1) % kGroups;
        if (delta != 0) {
          groups[selGroup].volume = clamp01(groups[selGroup].volume + delta);
        }
        break;
      default:
        if (d == 'l') slot = slot <= 1 ? 5 : slot - 1;
        if (d == 'r') slot = slot >= 5 ? 1 : slot + 1;
    }
  }

  // ----- volume efektif (fader x master x grup x mute/solo) -----
  double _effective(int i) {
    final c = channels[i];
    if (c.mute) return 0;
    if (channels.any((e) => e.solo) && !c.solo) return 0;
    var v = c.volume * master;
    if (c.group > 0) {
      final g = groups[c.group - 1];
      if (g.mute) return 0;
      v *= g.volume;
    }
    return clamp01(v);
  }

  void _applyVolumes() {
    for (final e in _players.entries) {
      e.value.setVolume(_effective(e.key)).catchError((_) {});
    }
  }

  void _toast(String s) {
    toast = s;
    _toastUntil = _clock.elapsedMilliseconds + 2200;
    _dirty = true;
  }

  // ----- audio -----
  Future<void> _togglePlay() async {
    try {
      if (_players.isEmpty) {
        _toast('ADD TRACK DULU');
        return;
      }
      if (playing) {
        await Future.wait(_players.values.map((p) => p.pause()));
        for (final c in channels) {
          c.playing = false;
        }
        playing = false;
        _toast('PAUSE');
      } else {
        _applyVolumes();
        for (final p in _players.values) {
          if (p.state == PlayerState.completed) await p.seek(Duration.zero);
        }
        await Future.wait(_players.values.map((p) => p.resume()));
        for (final i in _players.keys) {
          channels[i].playing = true;
        }
        playing = true;
        _toast('PLAY');
      }
    } catch (_) {
      _toast('GAGAL PUTAR');
    }
    _dirty = true;
  }

  Future<void> _stopAll() async {
    for (final e in _players.entries) {
      try {
        await e.value.pause();
        await e.value.seek(Duration.zero);
      } catch (_) {}
      channels[e.key].playing = false;
      channels[e.key].posMs = 0;
    }
    playing = false;
    _toast('STOP');
  }

  Future<void> _toggleLoop() async {
    loop = !loop;
    for (final p in _players.values) {
      try {
        await p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      } catch (_) {}
    }
    _toast(loop ? 'LOOP ON' : 'LOOP OFF');
  }

  Future<void> _addTracks(int start) async {
    if (_busy) return;
    _busy = true;
    try {
      _toast('PILIH FILE DI PC...');
      notify();
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'flac', 'm4a', 'aac', 'ogg'],
        allowMultiple: true,
      );
      if (res == null) {
        _toast('BATAL');
        return;
      }
      var i = start;
      for (final f in res.files) {
        final p = f.path;
        if (p == null) continue;
        if (i >= kChannels) break;
        await _loadTrack(i, p);
        i++;
      }
      _toast('${i - start} TRACK DITAMBAH');
    } catch (_) {
      _toast('GAGAL ADD');
    } finally {
      _busy = false;
    }
    _applyVolumes();
    _dirty = true;
  }

  Future<void> _loadTrack(int i, String path) async {
    await _disposePlayer(i);
    final p = AudioPlayer();
    final c = channels[i];
    try {
      await p.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.stop);
      await p.setSource(DeviceFileSource(path));
    } catch (_) {
      try {
        await p.dispose();
      } catch (_) {}
      _toast('GAGAL BUKA CH ${i + 1}');
      return;
    }
    _players[i] = p;
    c.path = path;
    c.file = fileNameOf(path);
    c.playing = false;
    c.posMs = 0;
    c.durMs = 0;
    _subs[i] = [
      p.onDurationChanged.listen((d) {
        c.durMs = d.inMilliseconds;
        _dirty = true;
      }),
      p.onPositionChanged.listen((d) {
        c.posMs = d.inMilliseconds;
        if (i == selected) _dirty = true;
      }),
      p.onPlayerComplete.listen((_) {
        c.playing = false;
        c.posMs = 0;
        playing = channels.any((x) => x.playing);
        _dirty = true;
      }),
    ];
    try {
      await p.setVolume(_effective(i));
    } catch (_) {}
  }

  Future<void> _disposePlayer(int i) async {
    final subs = _subs.remove(i);
    if (subs != null) {
      for (final s in subs) {
        await s.cancel();
      }
    }
    final p = _players.remove(i);
    if (p != null) {
      try {
        await p.dispose();
      } catch (_) {}
    }
  }

  Future<void> _clearTrack(int i) async {
    await _disposePlayer(i);
    final c = channels[i];
    c.path = null;
    c.file = '';
    c.playing = false;
    c.posMs = 0;
    c.durMs = 0;
    playing = channels.any((x) => x.playing);
    _toast('CH ${i + 1} DIKOSONGKAN');
  }

  // ----- simpan / muat setting -----
  Future<File> _settingFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}UxMix_setting_$slot.json');
  }

  Future<void> _save() async {
    try {
      final f = await _settingFile();
      await f.writeAsString(jsonEncode({
        'master': master,
        'loop': loop,
        'channels': channels.map((c) => c.toSettings()).toList(),
        'groups': groups.map((g) => g.toJson()).toList(),
      }));
      _toast('SETTING $slot TERSIMPAN');
    } catch (_) {
      _toast('GAGAL SIMPAN');
    }
  }

  Future<void> _load() async {
    try {
      final f = await _settingFile();
      if (!await f.exists()) {
        _toast('SLOT $slot KOSONG');
        return;
      }
      await _stopAll();
      final m = jsonDecode(await f.readAsString()) as Map;
      master = clamp01((m['master'] ?? 0.8) as num);
      loop = m['loop'] == true;
      final chs = (m['channels'] as List?) ?? const [];
      for (var i = 0; i < kChannels && i < chs.length; i++) {
        final cm = chs[i] as Map;
        channels[i].loadSettings(cm);
        final p = cm['path'];
        if (p is String && p.isNotEmpty && File(p).existsSync()) {
          await _loadTrack(i, p);
        } else {
          await _disposePlayer(i);
          channels[i].path = null;
          channels[i].file = '';
        }
      }
      final gs = (m['groups'] as List?) ?? const [];
      for (var i = 0; i < kGroups && i < gs.length; i++) {
        groups[i].fromJson(gs[i] as Map);
      }
      _applyVolumes();
      _toast('SETTING $slot DIMUAT');
    } catch (_) {
      _toast('GAGAL MUAT');
    }
  }

  // ----- tick: VU meter + kirim state ke remote -----
  void _tick() {
    final now = _clock.elapsedMilliseconds;
    if (toast.isNotEmpty && now > _toastUntil) {
      toast = '';
      _dirty = true;
    }
    final t = now / 1000.0;
    double sum = 0;
    for (var i = 0; i < kChannels; i++) {
      final c = channels[i];
      double target = 0;
      if (c.playing) {
        final e = _effective(i);
        if (e > 0) {
          var env = 0.5 +
              0.22 * sin(t * 6.7 + i * 1.3) +
              0.14 * sin(t * 13.1 + i * 0.7) +
              0.10 * sin(t * 2.3 + i);
          final beat =
              pow(max(0.0, sin(t * pi * 2 * (1.6 + (i % 5) * 0.15))), 6).toDouble();
          env += 0.25 * beat + _rnd.nextDouble() * 0.08;
          target = clamp01(env * pow(e, 0.7) * 1.1);
        }
      }
      final old = c.level;
      var nv = target > old ? old * 0.35 + target * 0.65 : old * 0.82 + target * 0.18;
      if (nv < 0.01) nv = 0;
      c.level = nv;
      sum += nv;
    }
    final m = clamp01(1 - exp(-sum * 0.55));
    final tl = m * (0.92 + _rnd.nextDouble() * 0.08);
    final tr = m * (0.92 + _rnd.nextDouble() * 0.08);
    meterL = tl > meterL ? tl : meterL * 0.85 + tl * 0.15;
    meterR = tr > meterR ? tr : meterR * 0.85 + tr * 0.15;
    if (meterL < 0.01) meterL = 0;
    if (meterR < 0.01) meterR = 0;

    final active = playing || _dirty || sum > 0 || meterL > 0 || meterR > 0;
    if (active) {
      _dirty = false;
      notifyListeners();
      _broadcast();
    }
  }

  // ----- server WebSocket -----
  Future<void> _startServer() async {
    try {
      final list = await NetworkInterface.list(type: InternetAddressType.IPv4);
      final found = <String>[];
      for (final n in list) {
        for (final a in n.addresses) {
          if (!a.isLoopback) found.add(a.address);
        }
      }
      found.sort((a, b) =>
          (b.startsWith('192.168') ? 1 : 0) - (a.startsWith('192.168') ? 1 : 0));
      ips = found;
      _server = await HttpServer.bind(InternetAddress.anyIPv4, kPort, shared: true);
      _server!.listen(_onRequest, onError: (_) {});
    } catch (e) {
      serverError = e.toString();
    }
    _dirty = true;
  }

  Future<void> _onRequest(HttpRequest req) async {
    try {
      if (WebSocketTransformer.isUpgradeRequest(req)) {
        final ws = await WebSocketTransformer.upgrade(req);
        ws.pingInterval = const Duration(seconds: 5);
        _clients.add(ws);
        ws.add(jsonEncode(toWire()));
        ws.listen(
          (data) {
            try {
              final m = jsonDecode(data as String);
              if (m is Map) _apply(m);
            } catch (_) {}
          },
          onDone: () {
            _clients.remove(ws);
            _dirty = true;
          },
          onError: (_) {
            _clients.remove(ws);
          },
        );
        _toast('REMOTE TERHUBUNG');
      } else {
        req.response
          ..statusCode = 200
          ..write('UxMix OK')
          ..close();
      }
    } catch (_) {}
  }

  void _broadcast() {
    if (_clients.isEmpty) return;
    final s = jsonEncode(toWire());
    for (final ws in List<WebSocket>.of(_clients)) {
      try {
        ws.add(s);
      } catch (_) {
        _clients.remove(ws);
      }
    }
  }

  @override
  List<String> systemLines() {
    if (serverError.isNotEmpty) return ['SERVER ERROR', serverError];
    if (ips.isEmpty) return ['REMOTE: TIDAK ADA WIFI'];
    return [
      'REMOTE ANDROID KE:',
      ...ips.map((e) => '$e:$kPort'),
      'TERHUBUNG: ${_clients.length}',
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final ws in _clients) {
      ws.close();
    }
    _server?.close(force: true);
    for (final i in _players.keys.toList()) {
      _disposePlayer(i);
    }
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// REMOTE (Android): hanya mengirim perintah & menampilkan state dari Windows.
// ---------------------------------------------------------------------------
class RemoteController extends MixerController {
  WebSocket? _ws;
  bool connected = false;
  bool connecting = false;
  String host = '';
  String error = '';
  String lastIp = '';

  final Stopwatch _clock = Stopwatch()..start();
  final Map<int, int> _holdCh = {};
  final Map<int, int> _holdGr = {};
  int _holdMaster = -1000;

  Future<File> _ipFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}uxmix_remote.json');
  }

  Future<void> init() async {
    try {
      final f = await _ipFile();
      if (await f.exists()) {
        final m = jsonDecode(await f.readAsString()) as Map;
        lastIp = (m['ip'] ?? '').toString();
      }
    } catch (_) {}
    notify();
  }

  Future<void> connect(String ip) async {
    var h = ip.trim();
    if (h.isEmpty) return;
    if (!h.contains(':')) h = '$h:$kPort';
    await disconnect();
    connecting = true;
    error = '';
    notify();
    try {
      final ws = await WebSocket.connect('ws://$h').timeout(const Duration(seconds: 4));
      ws.pingInterval = const Duration(seconds: 5);
      _ws = ws;
      connected = true;
      host = h;
      lastIp = ip.trim();
      try {
        final f = await _ipFile();
        await f.writeAsString(jsonEncode({'ip': lastIp}));
      } catch (_) {}
      ws.listen(_onData, onDone: _lost, onError: (_) => _lost());
    } catch (_) {
      error = 'Gagal terhubung ke $h. Cek WiFi sama & izinkan UxMix di firewall Windows.';
    }
    connecting = false;
    notify();
  }

  Future<void> disconnect() async {
    connected = false;
    final ws = _ws;
    _ws = null;
    try {
      await ws?.close();
    } catch (_) {}
    notify();
  }

  void _lost() {
    if (!connected) return;
    connected = false;
    _ws = null;
    error = 'Koneksi terputus.';
    notify();
  }

  void _onData(dynamic data) {
    try {
      final m = jsonDecode(data as String) as Map;
      final now = _clock.elapsedMilliseconds;
      // jangan timpa fader yang sedang digeser di HP
      final keepCh = <int, double>{};
      _holdCh.forEach((k, ts) {
        if (now - ts < 350) keepCh[k] = channels[k].volume;
      });
      final keepGr = <int, double>{};
      _holdGr.forEach((k, ts) {
        if (now - ts < 350) keepGr[k] = groups[k].volume;
      });
      final keepM = (now - _holdMaster < 350) ? master : null;
      applyWire(m);
      keepCh.forEach((k, v) => channels[k].volume = v);
      keepGr.forEach((k, v) => groups[k].volume = v);
      if (keepM != null) master = keepM;
      notify();
    } catch (_) {}
  }

  @override
  void send(Map<String, dynamic> cmd) {
    final now = _clock.elapsedMilliseconds;
    switch (cmd['t']) {
      case 'vol':
        {
          final i = (cmd['ch'] as num).toInt();
          channels[i].volume = clamp01(cmd['v'] as num);
          _holdCh[i] = now;
          break;
        }
      case 'master':
        master = clamp01(cmd['v'] as num);
        _holdMaster = now;
        break;
      case 'gvol':
        {
          final g = (cmd['g'] as num).toInt();
          groups[g].volume = clamp01(cmd['v'] as num);
          _holdGr[g] = now;
          break;
        }
      case 'sel':
        selected = (cmd['ch'] as num).toInt();
        break;
      case 'selgrp':
        selGroup = (cmd['g'] as num).toInt();
        break;
    }
    if (connected) {
      try {
        _ws?.add(jsonEncode(cmd));
      } catch (_) {}
    }
    notify();
  }

  @override
  List<String> systemLines() =>
      ['MODE REMOTE', connected ? 'HOST $host' : 'OFFLINE'];

  @override
  void dispose() {
    _ws?.close();
    super.dispose();
  }
}
