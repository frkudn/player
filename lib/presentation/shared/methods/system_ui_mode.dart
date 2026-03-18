import 'package:flutter/services.dart';

hideSystemTopBar() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
}

setToDefaultSystemTopBar() async {
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
