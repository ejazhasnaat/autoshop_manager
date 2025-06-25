// lib/core/extensions/iterable_extensions.dart

extension IterableExtension<T> on Iterable<T> {
  /// Finds the first element that satisfies the test.
  /// Returns null if no element is found.
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }
}
