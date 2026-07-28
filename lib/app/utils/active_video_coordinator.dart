import 'package:flutter/foundation.dart';

// Ensures at most one inline video plays at a time across the Updates feed.
// Each [VideoPlayerPreview] reports its visibility fraction; the coordinator
// picks the most-visible tile as the winner. This avoids a race on page open
// where two tiles both cross the autoplay threshold and the "last caller wins"
// rule would pick whichever VisibilityDetector callback happened to fire last.
class ActiveVideoCoordinator {
  ActiveVideoCoordinator._();
  static final ActiveVideoCoordinator instance = ActiveVideoCoordinator._();

  final Map<Object, _Candidate> _candidates = {};
  Object? _active;

  // Widget wants to play. Coordinator will call [play] if this widget is the
  // most-visible candidate, and [stop] later if another tile takes over.
  void request({
    required Object token,
    required double fraction,
    required VoidCallback play,
    required VoidCallback stop,
  }) {
    _candidates[token] = _Candidate(fraction, play, stop);
    _elect();
  }

  // Widget no longer wants to play (scrolled off, disposed, slow-net fallback).
  void withdraw(Object token) {
    _candidates.remove(token);
    if (_active == token) _active = null;
    _elect();
  }

  void _elect() {
    Object? winner;
    double best = -1;
    _candidates.forEach((k, v) {
      if (v.fraction > best) {
        best = v.fraction;
        winner = k;
      }
    });
    if (winner == _active) return;
    final prev = _active;
    _active = winner;
    if (prev != null) _candidates[prev]?.stop();
    if (winner != null) _candidates[winner]?.play();
  }
}

class _Candidate {
  final double fraction;
  final VoidCallback play;
  final VoidCallback stop;
  _Candidate(this.fraction, this.play, this.stop);
}
