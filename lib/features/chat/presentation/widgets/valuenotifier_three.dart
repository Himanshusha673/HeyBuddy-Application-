import 'package:flutter/material.dart';

class ValueListenableBuilder3<A, B, C> extends StatelessWidget {
  final ValueNotifier<A> firstNotifier;
  final ValueNotifier<B> secondNotifier;
  final ValueNotifier<C> thirdNotifier;
  final Widget Function(BuildContext, A, B, C, Widget?) builder;
  final Widget? child;

  const ValueListenableBuilder3({
    Key? key,
    required this.firstNotifier,
    required this.secondNotifier,
    required this.thirdNotifier,
    required this.builder,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: firstNotifier,
      builder: (context, a, _) {
        return ValueListenableBuilder<B>(
          valueListenable: secondNotifier,
          builder: (context, b, __) {
            return ValueListenableBuilder<C>(
              valueListenable: thirdNotifier,
              builder: (context, c, ___) {
                return builder(context, a, b, c, child);
              },
            );
          },
        );
      },
    );
  }
}