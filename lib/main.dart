// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This example shows how to perform a simple animation using the underlying
// render tree.

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:vector_math/vector_math.dart';

import './make_fbm.dart';

class NonStopVSync implements TickerProvider {
  const NonStopVSync();
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

const alphaOffset = 24;
const redOffset = 16;
const greenOffset = 8;
const blueOffset = 0;

// const kImageDimension = 100;
const kWidth = 1920;
const kHeight = 1080;

int makeColor(double time, int x, int y) {
  // main function of GLSL.
  int red = 0;
  int green = 0;
  int blue = 0;
  int alpha = 255;
  int resultColor = 0;
  Vector2 p = Vector2(
    (x.toDouble() * 2 - kWidth) / kWidth,
    (y.toDouble() * 2 - kHeight) / kHeight,
  );

  // color processing here
  double primary = fbm(p * 2.0);
  Vector2 secondary = Vector2(
    p.x + primary + time,
    p.y + primary + time,
  );
  red = (fbm(secondary) * 255).toInt();
  green = 0;
  blue = red;

  // convert 8bit integers to 32bit integers
  resultColor += (alpha << alphaOffset);
  resultColor += (red << redOffset);
  resultColor += (green << greenOffset);
  resultColor += (blue << blueOffset);

  return resultColor;
}

// Future<ui.Image> makeImage({double time = 0}) {
//   final c = Completer<ui.Image>();
//   final pixels = Int32List(kImageDimension * kImageDimension);
//   int x = 0;
//   int y = 0;
//   for (int i = 0; i < pixels.length; i++) {
//     y = (i / kImageDimension).floor();
//     x = i % kImageDimension;
//     pixels[i] = makeColor(time, x, y);
//   }
//   ui.decodeImageFromPixels(
//     pixels.buffer.asUint8List(),
//     kImageDimension,
//     kImageDimension,
//     ui.PixelFormat.rgba8888,
//     c.complete,
//   );
//   return c.future;
// }
Future<ui.Image> makeImage({double time = 0}) {
  // FBMでの描画の代わりに、時間によって色が変わる単色画像を生成する
  final c = Completer<ui.Image>();
  final pixels = Int32List(kWidth * kHeight);
  int x = 0;
  int y = 0;
  for (int i = 0; i < pixels.length; i++) {
    y = (i / kHeight).floor();
    x = i % kWidth;
    pixels[i] =
        (time * 4294967295).toInt() % 4294967295; //makeColor(time, x, y);
  }
  ui.decodeImageFromPixels(
    pixels.buffer.asUint8List(),
    kWidth,
    kHeight,
    ui.PixelFormat.rgba8888,
    c.complete,
  );
  return c.future;
}

void main() async {
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

  // final RenderImage image = RenderImage(
  //   width: imageSize,
  //   height: imageSize,
  //   image: await makeImage(),
  // );
  final ui.Image imageFuture = await makeImage();
  final double w = imageFuture.width.toDouble();
  final double h = imageFuture.height.toDouble();
  final RenderImage image =
      RenderImage(image: imageFuture); //await makeImage());

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
    additionalConstraints: BoxConstraints.tightFor(width: w, height: h),
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
    duration: const Duration(milliseconds: 800),
    vsync: const NonStopVSync(),
  )..repeat();

  double time = 0.0;

  animation.addListener(() async {
    image.image = await makeImage(time: time);
    time += 0.01;
  });
}
