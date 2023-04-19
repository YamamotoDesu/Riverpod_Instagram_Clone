import 'package:flutter/material.dart';

class DividerWithMargins extends StatelessWidget {
  const DividerWithMargins({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        SizedBox(
          height: 20.0,
        ),
        Divider(),
        SizedBox(
          height: 20.0,
        ),
      ],
    );
  }
}
