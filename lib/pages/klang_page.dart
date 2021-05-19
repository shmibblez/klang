import 'package:flutter/material.dart';
import 'package:klang/page_router.dart';

abstract class KlangPage extends Widget {
  PageRoutePath get route;
}
