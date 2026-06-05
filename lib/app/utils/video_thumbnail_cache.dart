import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

/// Caches video poster frames so each remote video is decoded only ONCE.
///
/// `VideoThumbnail.thumbnailFile` has to stream the video over the network to
/// grab a frame, which is slow. Doing that on every rebuild/scroll (as the old
/// inline generation did) made thumbnails lag badly. This service:
///   • keeps a stable on-disk cache (survives app restarts), keyed by URL,
///   • keeps an in-memory map for instant hits within a session,
///   • de-duplicates concurrent requests for the same URL into one generation,
///   • caps concurrent generations so prefetch doesn't starve the visible one,
///   • supports prefetch via [warm], and
///   • does stale-while-revalidate: serves the cached poster instantly, then
///     checks the server (cheap HEAD) and regenerates if the video/thumbnail
///     changed — so a swapped-out backend video shows its latest frame.
///
/// Until the backend serves poster images directly, this is the fast path.
class VideoThumbnailCache {
  VideoThumbnailCache._();
  static final VideoThumbnailCache instance = VideoThumbnailCache._();

  /// Max simultaneous frame extractions. Network-bound, so a small number
  /// keeps the on-screen thumbnail responsive while others prefetch.
  static const int _maxConcurrent = 3;

  Directory? _cacheDir;
  final Map<String, File> _memory = {};
  final Map<String, Future<File?>> _inflight = {};
  final Set<String> _revalidated = {}; // revalidate each URL at most once/session

  int _active = 0;
  final List<Completer<void>> _waiters = [];

  Future<Directory> _dir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/video_thumbs');
    if (!await dir.exists()) await dir.create(recursive: true);
    _cacheDir = dir;
    _pruneOld(dir); // housekeeping: drop posters from old (changed) media
    return dir;
  }

  /// Deletes cached posters/meta older than [maxAge] so the cache self-cleans
  /// as backend media changes (new media = new URL = new file). Fire-and-forget.
  Future<void> _pruneOld(Directory dir,
      {Duration maxAge = const Duration(days: 7)}) async {
    try {
      final now = DateTime.now();
      await for (final e in dir.list()) {
        if (e is File) {
          try {
            final modified = (await e.stat()).modified;
            if (now.difference(modified) > maxAge) await e.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// FNV-1a hash → deterministic across restarts, so the same URL always maps
  /// to the same cache file (Dart's String.hashCode is not stable for this).
  String _key(String url) {
    const int prime = 0x01000193;
    int hash = 0x811c9dc5;
    for (final c in url.codeUnits) {
      hash = (hash ^ c) & 0xFFFFFFFF;
      hash = (hash * prime) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }

  File _thumbFile(Directory dir, String url) =>
      File('${dir.path}/${_key(url)}.jpg');
  File _metaFile(Directory dir, String url) =>
      File('${dir.path}/${_key(url)}.meta');

  /// Run [task] under the concurrency cap. [priority] jumps the wait queue —
  /// used for the thumbnail the user is actually looking at.
  Future<T> _withSlot<T>(Future<T> Function() task,
      {bool priority = false}) async {
    if (_active >= _maxConcurrent) {
      final c = Completer<void>();
      priority ? _waiters.insert(0, c) : _waiters.add(c);
      await c.future;
    }
    _active++;
    try {
      return await task();
    } finally {
      _active--;
      if (_waiters.isNotEmpty) _waiters.removeAt(0).complete();
    }
  }

  /// Returns the cached poster for [videoUrl], generating it once if needed.
  ///
  /// On a cache hit the file is returned immediately; if [revalidate] is true a
  /// background freshness check runs and, when the remote changed, [onUpdated]
  /// is invoked with the regenerated file. Returns null if no frame could be
  /// extracted.
  Future<File?> get(
    String videoUrl, {
    int maxHeight = 400,
    int quality = 75,
    bool revalidate = true,
    void Function(File file)? onUpdated,
  }) async {
    final mem = _memory[videoUrl];
    if (mem != null) {
      if (revalidate) {
        unawaited(_maybeRevalidate(videoUrl, maxHeight, quality, onUpdated));
      }
      return mem;
    }

    final disk = await _diskFile(videoUrl);
    if (disk != null) {
      _memory[videoUrl] = disk;
      if (revalidate) {
        unawaited(_maybeRevalidate(videoUrl, maxHeight, quality, onUpdated));
      }
      return disk;
    }

    final fresh = await (_inflight[videoUrl] ??= _withSlot(
      () => _doGenerate(videoUrl, maxHeight, quality),
      priority: true,
    ).whenComplete(() => _inflight.remove(videoUrl)));

    if (fresh != null) {
      _memory[videoUrl] = fresh;
      unawaited(_storeValidator(videoUrl)); // baseline for future revalidation
    }
    return fresh;
  }

  /// Pre-generate posters for [videoUrls] ahead of display. Already-cached URLs
  /// are skipped; the rest queue behind the concurrency cap. Fire-and-forget.
  void warm(Iterable<String> videoUrls, {int maxHeight = 400, int quality = 75}) {
    for (final url in videoUrls) {
      if (url.isEmpty || _memory.containsKey(url)) continue;
      unawaited(get(url, maxHeight: maxHeight, quality: quality, revalidate: false));
    }
  }

  Future<File?> _diskFile(String url) async {
    final dir = await _dir();
    final f = _thumbFile(dir, url);
    if (await f.exists() && await f.length() > 0) return f;
    return null;
  }

  Future<File?> _doGenerate(String url, int maxHeight, int quality) async {
    try {
      final dir = await _dir();
      final file = _thumbFile(dir, url);
      final path = await VideoThumbnail.thumbnailFile(
        video: url,
        thumbnailPath: file.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: maxHeight,
        quality: quality,
      );
      if (path != null) {
        final out = File(path);
        if (await out.exists() && await out.length() > 0) return out;
      }
    } catch (e) {
      debugPrint('VideoThumbnailCache: generation failed for $url → $e');
    }
    return null;
  }

  /// Cheap freshness check — a HEAD request comparing ETag / Last-Modified /
  /// size. If the remote changed since we cached, regenerate and notify.
  Future<void> _maybeRevalidate(
    String url,
    int maxHeight,
    int quality,
    void Function(File file)? onUpdated,
  ) async {
    if (!_revalidated.add(url)) return; // once per session per URL

    final remote = await _remoteValidator(url);
    if (remote == null) return; // offline / HEAD unsupported → keep cached

    final dir = await _dir();
    final meta = _metaFile(dir, url);
    final stored = (await meta.exists())
        ? (await meta.readAsString()).trim()
        : null;

    if (stored == null) {
      // No baseline yet (older cache entry) — record it, don't regenerate.
      try {
        await meta.writeAsString(remote);
      } catch (_) {}
      return;
    }
    if (stored == remote) return; // unchanged

    // Remote video/thumbnail changed → regenerate and swap in the latest.
    final fresh = await _withSlot(() => _doGenerate(url, maxHeight, quality));
    if (fresh != null) {
      await FileImage(fresh).evict(); // drop stale bytes from Flutter's cache
      _memory[url] = fresh;
      try {
        await meta.writeAsString(remote);
      } catch (_) {}
      onUpdated?.call(fresh);
    }
  }

  Future<void> _storeValidator(String url) async {
    final remote = await _remoteValidator(url);
    if (remote == null) return;
    try {
      final dir = await _dir();
      await _metaFile(dir, url).writeAsString(remote);
    } catch (_) {}
  }

  /// Returns a change-signal for [url] (ETag, else Last-Modified, else size),
  /// or null if it can't be determined.
  Future<String?> _remoteValidator(String url) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
      final req = await client.headUrl(Uri.parse(url));
      final resp = await req.close();
      await resp.drain();
      final etag = resp.headers.value(HttpHeaders.etagHeader);
      final lastMod = resp.headers.value(HttpHeaders.lastModifiedHeader);
      final len = resp.headers.value(HttpHeaders.contentLengthHeader);
      return etag ?? lastMod ?? len;
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
  }
}
