UxMix - Mixer Digital 24 Channel (Windows) + Remote Android
============================================================

CARA PAKAI
1. Ekstrak zip, klik 2x  setup.bat
2. Klik 2x  run_windows.bat  untuk coba, atau  build_all.bat  untuk membuat
   aplikasi Windows (OUTPUT\UxMix_Windows\uxmix.exe) dan APK (OUTPUT\UxMix.apk)
3. Install UxMix.apk di HP Android. HP dan PC harus satu WiFi.
4. Buka UxMix di Windows. Alamat IP tampil di kotak "REMOTE ANDROID" (kiri atas).
5. Buka UxMix di HP, isi IP itu, tekan Hubungkan.
   Saat pertama kali, Windows akan menanyakan izin firewall. Pilih Izinkan (Private).

PERLU DI PC
- Flutter SDK + Visual Studio 2022 (workload "Desktop development with C++")
- Untuk APK: Android SDK (sudah ikut kalau Android Studio terpasang)

KONTROL DI WINDOWS
- Tombol panah kiri/kanan : pilih channel (halaman CH), pilih grup (GRP), ganti slot (SYS)
- Tombol panah atas/bawah : naik/turun volume (channel / master / grup). Tahan = cepat
- SELECT : ganti halaman LCD  (CH -> MST -> GRP -> SYS)
- MUTE / SOLO : pada channel terpilih (di halaman GRP, MUTE untuk grup)
- ADD : pilih file mp3/wav/flac/m4a/ogg. Boleh pilih banyak file sekaligus,
        otomatis masuk ke channel berurutan mulai dari channel terpilih
- CLEAR : kosongkan track channel terpilih (atau tekan lama tombol file di strip)
- LOAD / SAVE : muat / simpan setting ke slot 1-5 (ganti slot di halaman SYS).
  Disimpan di folder Documents:  UxMix_setting_<slot>.json
- PLAY/PAUSE, STOP, LOOP
- Fader : geser, klik, scroll mouse, atau klik 2x untuk reset ke 75%
- Tombol GRP di tiap strip : putar tanpa grup -> A -> B -> C -> D
- Bar scroll di bawah strip, atau scroll mouse, untuk melihat channel yang
  tidak muat di layar

REMOTE ANDROID
- Selalu landscape. Semua fader, mute, solo, grup, play/stop bisa dikontrol.
- Tap nomor channel untuk memilih channel.
- Tombol "+ MP3" di HP membuka dialog pilih file di PC (file ada di PC).

CATATAN
- VU meter lampu bulat adalah simulasi dari fader + status play, bukan
  amplitudo asli file (plugin audio tidak memberi data level).
- Semua track mulai bersamaan, tapi bisa selisih beberapa milidetik.
