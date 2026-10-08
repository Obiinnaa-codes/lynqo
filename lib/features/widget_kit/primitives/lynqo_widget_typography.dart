import 'package:flutter/material.dart';

import '../sizing/lynqo_widget_size.dart';
import '../theme/lynqo_widget_theme.dart';

class LynqoWidgetTitle extends StatelessWidget {
  const LynqoWidgetTitle({super.key, required this.text, this.size});

  final String text;
  final LynqoWidgetSize? size;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    return Text(
      text,
      style: theme.captionStyle(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class LynqoWidgetPrimaryValue extends StatelessWidget {
  const LynqoWidgetPrimaryValue({
    super.key,
    required this.text,
    required this.size,
  });

  final String text;
  final LynqoWidgetSize size;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    return Text(
      text,
      style: theme.primaryValueStyle(size),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class LynqoWidgetSecondaryText extends StatelessWidget {
  const LynqoWidgetSecondaryText({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    return Text(
      text,
      style: theme.secondaryStyle(),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class LynqoWidgetCaption extends StatelessWidget {
  const LynqoWidgetCaption({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = LynqoWidgetTheme.of(context);
    return Text(
      text,
      style: theme.captionStyle(fontSize: 12),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
