import 'package:flutter/material.dart';

class ListItemDownloadOverlay extends StatelessWidget {
  final double progress;
  final double maxWidth;

  const ListItemDownloadOverlay({
    super.key,
    required this.progress,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. 底層：長條型進度條
        Positioned.fill(
          child: Container(
            color: Colors.redAccent.withOpacity(0.05),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                ),
              ),
            ),
          ),
        ),

        // 2. 中層：GIF 動畫 (讓它跟著進度條跑)
        Positioned(
          // 計算 GIF 位置，讓它保持在進度條的最前端
          left: (maxWidth * progress) - 100,
          top: 0,
          bottom: 0,
          child: SizedBox(
            width: 100,
            child: Opacity(
              opacity: 0.6,
              child: Image.asset(
                'assets/Hoshina.gif',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const SizedBox(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
