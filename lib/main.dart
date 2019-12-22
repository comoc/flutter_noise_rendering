// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to perform a simple animation using the underlying
// render tree.

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

class NonStopVSync implements TickerProvider {
  const NonStopVSync();
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

int xorshift32(int x) {
  x ^= x << 13;
  x ^= x >> 17;
  x ^= x << 5;
  return x;
}

int seed = 0xDEADBEEF;

const kImageDimension = 1024;

Future<ui.Image> makeImage() {
  final c = Completer<ui.Image>();
  final pixels = Int32List(kImageDimension * kImageDimension);
  for (int i = 0; i < pixels.length; i++) {
    seed = pixels[i] = xorshift32(seed);
  }
  ui.decodeImageFromPixels(
    pixels.buffer.asUint8List(),
    kImageDimension,
    kImageDimension,
    ui.PixelFormat.rgba8888,
    c.complete,
  );
  return c.future;
}

void main() async {
  const imageSize = 500.0;

  // We first create a render object that represents a green box.
  // final RenderBox green = RenderDecoratedBox(
  //     decoration: const BoxDecoration(color: Color(0xFFFFAA00)));
  // Second, we wrap that green box in a render object that forces the green box
  // to have a specific size.
  // final RenderBox square = RenderConstrainedBox(
  //   additionalConstraints:
  //       const BoxConstraints.tightFor(width: 200.0, height: 200.0),
  //   child: green,
  // );

  final RenderImage image = RenderImage(
    width: imageSize,
    height: imageSize,
    image: await makeImage(),
  );
  // Third, we wrap the sized green square in a render object that applies rotation
  // transform before painting its child. Each frame of the animation, we'll
  // update the transform of this render object to cause the green square to
  // spin.
  // final RenderTransform spin = RenderTransform(
  //   transform: Matrix4.identity(),
  //   alignment: Alignment.center,
  //   child: square,
  // );

  final RenderBox imageWrap = RenderConstrainedBox(
    additionalConstraints:
        const BoxConstraints.tightFor(width: imageSize, height: imageSize),
    child: image,
  );
  // Finally, we center the spinning green square...
  final RenderBox root = RenderPositionedBox(
    alignment: Alignment.center,
    child: imageWrap,
  );
  // and attach it to the window.
  RenderingFlutterBinding(root: root);

  final AnimationController animation = AnimationController(
    duration: const Duration(milliseconds: 1800),
    vsync: const NonStopVSync(),
  )..repeat();

  animation.addListener(() async {
    image.image = await makeImage();
  });
}
