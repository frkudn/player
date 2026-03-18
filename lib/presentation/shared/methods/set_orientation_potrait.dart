import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

 ifOrientationLandscapeMakeItPotrait(BuildContext context) {
  if (MediaQuery.orientationOf(context) == Orientation.landscape) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
 
}


isLandscapeOriention(context){
   return MediaQuery.orientationOf(context) == Orientation.landscape;
}


