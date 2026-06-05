import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Downloads remote videos to a local file cache so the player can initialize
/// from disk (fast, no streaming stalls) instead of buffering over the network.
///
/// Used to preload the home banner video on the splash screen so it plays
/// almost instantly once Home renders. Downloads are de-duplicated and persist
/// across app restarts. Falls back gracefully — if a file isn't cached, the
/// player just streams from the network and the file is fetched for next time.
class VideoFileCache {
  VideoFileCache._();
  static final VideoFileCache instance = VideoFileCache._();

  Directory? _dir;
  final Map<String, File> _memory = {};
  final Map<String, Future<File?>> _inflight = {};

  Future<Directory> _cacheDir() async {
    if (_dir != null) return _dir!;
    final base = await getTemporaryDirectory();
    final d = Directory('${base.path}/video_files');
    if (!await d.exists()) await d.create(recursive: true);
    _dir = d;
    _pruneOld(d); // housekeeping: drop stale files from old banner versions
    return d;
  }

  /// Deletes cached files older than [maxAge]. Backend media is versioned by a
  /// new (timestamped) URL, so once a banner changes, its old file is orphaned
  /// — this keeps the cache from growing without bound. Fire-and-forget.
  Future<void> _pruneOld(Directory d, {Duration maxAge = const Duration(days: 7)}) async {
    try {
      final now = DateTime.now();
      await for (final e in d.list()) {
        if (e is File) {
          try {
            final modified = (await e.stat()).modified;
            if (now.difference(modified) > maxAge) await e.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// FNV-1a — deterministic across restarts so a URL always maps to one file.
  String _key(String url) {
    const int prime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final c in url.codeUnits) {
      hash = (hash ^ c) & 0xFFFFFFFF;
      hash = (hash * prime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  /// Returns the cached file for [url] if already downloaded, else null. Fast.
  Future<File?> get(String url) async {
    if (url.isEmpty) return null;
    final mem = _memory[url];
    if (mem != null) return mem;
    final dir = await _cacheDir();
    final f = File('${dir.path}/${_key(url)}.mp4');
    if (await f.exists() && await f.length() > 0) return _memory[url] = f;
    return null;
  }

  /// Downloads [url] to the cache once. Concurrent calls share one download.
  /// Returns the file, or null on failure.
  Future<File?> ensure(String url) {
    if (url.isEmpty) return Future.value(null);
    final mem = _memory[url];
    if (mem != null) return Future.value(mem);
    return _inflight[url] ??=
        _download(url).whenComplete(() => _inflight.remove(url));
  }

  Future<File?> _download(String url) async {
    HttpClient? client;
    File? partial;
    try {
      final dir = await _cacheDir();
      final file = File('${dir.path}/${_key(url)}.mp4');
      if (await file.exists() && await file.length() > 0) {
        return _memory[url] = file;
      }

      partial = File('${file.path}.part');
      client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final req = await client.getUrl(Uri.parse(url));
      req.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
      );
      final resp = await req.close();
      if (resp.statusCode != 200) {
        await resp.drain<void>();
        return null;
      }

      final sink = partial.openWrite();
      await resp.pipe(sink); // pipe closes the sink when done

      if (await partial.exists() && await partial.length() > 0) {
        await partial.rename(file.path);
        debugPrint('VideoFileCache: cached $url');
        return _memory[url] = file;
      }
      return null;
    } catch (e) {
      debugPrint('VideoFileCache: download failed $url → $e');
      try {
        if (partial != null && await partial.exists()) await partial.delete();
      } catch (_) {}
      return null;
    } finally {
      client?.close();
    }
  }
}
