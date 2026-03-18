import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

class AnimatedAutoScrollTextWidget extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign textAlign;

  const AnimatedAutoScrollTextWidget(this.data,
      {super.key, this.style, this.textAlign = TextAlign.center});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final span = TextSpan(text: data, style: style);

      final tp = TextPainter(
          maxLines: 1,
          textAlign: textAlign,
          textDirection: TextDirection.ltr,
          text: span);

      tp.layout(maxWidth: constraints.maxWidth);

      if (tp.didExceedMaxLines) {
        return SizedBox(
            height: tp.height + 5,
            width: constraints.maxWidth,
            child: Marquee(
              text: '  $data${" " * 30}',
              style: style,
              scrollAxis: Axis.horizontal,
              showFadingOnlyWhenScrolling: false,
              startAfter: Duration(seconds: 3),
              crossAxisAlignment: CrossAxisAlignment.start,
              velocity: 30,
            ));
      } else {
        return SizedBox(
            height: tp.height + 5,
            width: constraints.maxWidth,
            child: Text(data,
                style: style,
                textAlign: TextAlign.start,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis));
      }
    });
  }
}
