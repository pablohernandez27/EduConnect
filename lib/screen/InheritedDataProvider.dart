import 'package:flutter/cupertino.dart';

class InheritedDataProvider extends InheritedWidget{
  final ScrollController scrollController;
  const InheritedDataProvider({super.key,
    required super.child, required this.scrollController});

  @override
  bool updateShouldNotify(InheritedDataProvider oldWidget) =>
      scrollController != oldWidget.scrollController;
  static InheritedDataProvider of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedDataProvider>()!;

}