import 'package:flutter/material.dart';

class BackButton01 extends StatelessWidget {
  const BackButton01({super.key});

  @override
  
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => Navigator.pop(context),
      backgroundColor: Colors.transparent,
      elevation: 0,
      highlightElevation: 0,
      child: const Row(
        children: [
          Icon(Icons.keyboard_arrow_left, color: Colors.white),
          Text('Atrás', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))
        ],
        )
    );
  }
}