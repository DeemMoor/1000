import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:thousand_engine/thousand_engine.dart';
import 'package:vector_graphics/vector_graphics.dart';

/// Rasterized faces and back of one deck, kept in memory so cards draw
/// instantly instead of decoding vector art every time one appears.
class CardImages extends ChangeNotifier {
  /// Native size of the deck artwork.
  static const width = 360;
  static const height = 540;

  String? _dir;
  Map<String, ui.Image> _images = {};

  /// Face of [card], or null while the deck is still loading.
  ui.Image? face(Card card) => _images[card.id];

  ui.Image? get back => _images['back'];

  /// Loads all images from [dir] (a folder of compiled SVGs), replacing the
  /// previous deck once ready. Null clears the cache.
  Future<void> load(String? dir) async {
    if (dir == _dir) return;
    _dir = dir;
    if (dir == null) {
      _replace({});
      return;
    }
    final images = <String, ui.Image>{};
    for (final id in [...Deck.full.map((c) => c.id), 'back']) {
      images[id] = await _rasterize('$dir/$id.svg');
      // A newer request superseded this one.
      if (_dir != dir) {
        for (final image in images.values) {
          image.dispose();
        }
        return;
      }
    }
    _replace(images);
  }

  Future<ui.Image> _rasterize(String asset) async {
    final info = await vg.loadPicture(AssetBytesLoader(asset), null);
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..scale(width / info.size.width, height / info.size.height)
      ..drawPicture(info.picture);
    info.picture.dispose();
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    return image;
  }

  void _replace(Map<String, ui.Image> images) {
    final old = _images;
    _images = images;
    notifyListeners();
    // Widgets switch to the new images on the next frame; free the old
    // ones only after that.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      for (final image in old.values) {
        image.dispose();
      }
    });
  }

  @override
  void dispose() {
    for (final image in _images.values) {
      image.dispose();
    }
    super.dispose();
  }
}
