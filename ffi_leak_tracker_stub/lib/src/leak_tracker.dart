import 'package:ffi/ffi.dart';

import 'allocation.dart';
import 'emitter.dart';
import 'exception.dart';
import 'filter.dart';

const Allocator adaptiveCalloc = calloc;
const Allocator adaptiveMalloc = malloc;
const diagnosticCalloc = calloc;
const diagnosticMalloc = malloc;

const isReleaseMode = bool.fromEnvironment('dart.vm.product');

sealed class TrackingAllocator implements Allocator {
  const TrackingAllocator._();
  Pointer<NativeFinalizerFunction> get nativeFree => calloc.nativeFree;
}

final class LeakTracker {
  static final LeakTracker _instance = LeakTracker._();
  factory LeakTracker() => _instance;
  LeakTracker._();

  static void enable() {}
  static void enableInDebug() {}
  static void disable() {}
  static void verifyNoLeaks() {}
  static void verifyNoLeaksInDebug() {}
  static void collectThemAll() {}
  static List<Allocation> get allocations => [];
  static void reset() {}
}
