import 'allocation.dart';

abstract class LeakFilter {
  bool shouldIgnore(Allocation allocation);
}

final class IgnoreNoneFilter extends LeakFilter {
  @override
  bool shouldIgnore(Allocation allocation) => false;
}

final class IgnoreAllFilter extends LeakFilter {
  @override
  bool shouldIgnore(Allocation allocation) => true;
}
