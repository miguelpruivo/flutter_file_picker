abstract class LeaksEmitter {
  void emit(List<Allocation> allocations);
}

final class JsonEmitter implements LeaksEmitter {
  @override
  void emit(List<Allocation> allocations) {}
}

final class PrintEmitter implements LeaksEmitter {
  @override
  void emit(List<Allocation> allocations) {}
}
