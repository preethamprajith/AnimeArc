import 'package:flutter/material.dart';

class Appbar1 extends StatelessWidget {
  const Appbar1({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 50,
        decoration: BoxDecoration(color: const Color(0xFFEEEEEEE)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
                      "assets/profile.png",
                      width: 50,
                      height: 50,
                    ),
            SizedBox(
              width: 10,
            ),
            Text(
              "Admin",
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(
              width: 40,
            )
          ],
        ));
  }
}
