import 'dart:io';

import 'package:kernel/ast.dart';
import 'package:vm/target/flutter.dart';

import 'inspector_visitor.dart';
import 'track_visitor.dart';

class InspectorTransformer extends FlutterProgramTransformer {

  @override
  void transform(Component component) {
    Directory('MC').create(recursive: true)
// The created directory is returned as a Future.
        .then((Directory directory) {
      print('Path of New Dir: ' + directory.path);
    });
    // component.transformChildren(InspectorVisitor(component.libraries));
    WidgetCreatorTracker().transform(component, component.libraries, null);
  }
}
