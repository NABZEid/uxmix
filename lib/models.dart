import 'dart:math';

const int kChannels = 24;
const int kGroups = 4;
const int kPort = 8765;
const List<String> kGroupLetters = ['-', 'A', 'B', 'C', 'D'];

double clamp01(num v) {
  final d = v.toDouble();
  if (d.isNaN) return 0;
  return d < 0 ? 0 : (d > 1 ? 1 : d);
}

String fileNameOf(String? p) {
  if (p == null || p.isEmpty) return '';
  final i = max(p.lastIndexOf('/'), p.lastIndexOf('\\'));
  return i < 0 ? p : p.substring(i + 1);
}

String fmtMs(int ms) {
  final s = ms ~/ 1000;
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

class ChannelState {
  String name;
  double volume = 0.75;
  bool mute = false;
  bool solo = false;
  int group = 0; // 0 = tanpa grup, 1..4 = A..D
  String? path; // hanya dipakai di Windows (host)
  String file = '';

  // runtime (tidak disimpan)
  bool playing = false;
  int posMs = 0;
  int durMs = 0;
  double level = 0;

  ChannelState(this.name);

  bool get hasTrack => file.isNotEmpty;

  Map<String, dynamic> toSettings() => {
        'name': name,
        'volume': volume,
        'mute': mute,
        'solo': solo,
        'group': group,
        'path': path,
      };

  void loadSettings(Map m) {
    volume = clamp01((m['volume'] ?? 0.75) as num);
    mute = m['mute'] == true;
    solo = m['solo'] == true;
    group = ((m['group'] ?? 0) as num).toInt().clamp(0, kGroups).toInt();
  }

  Map<String, dynamic> toWire() => {
        'n': name,
        'v': volume,
        'm': mute,
        's': solo,
        'g': group,
        'f': file,
        'p': playing,
        'pos': posMs,
        'dur': durMs,
        'lv': (level * 100).round() / 100,
      };

  void fromWire(Map m) {
    name = (m['n'] ?? name).toString();
    volume = clamp01((m['v'] ?? 0) as num);
    mute = m['m'] == true;
    solo = m['s'] == true;
    group = ((m['g'] ?? 0) as num).toInt().clamp(0, kGroups).toInt();
    file = (m['f'] ?? '').toString();
    playing = m['p'] == true;
    posMs = ((m['pos'] ?? 0) as num).toInt();
    durMs = ((m['dur'] ?? 0) as num).toInt();
    level = clamp01((m['lv'] ?? 0) as num);
  }
}

class GroupState {
  double volume = 1;
  bool mute = false;

  Map<String, dynamic> toJson() => {'v': volume, 'm': mute};

  void fromJson(Map m) {
    volume = clamp01((m['v'] ?? 1) as num);
    mute = m['m'] == true;
  }
}
