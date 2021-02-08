import 'package:aspectd/aspectd.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:example/user_widget.dart';
import 'package:example/track_object.dart';


// @Aspect()
// @pragma("vm:entry-point")
// class RegularCallDemo {
//   @pragma("vm:entry-point")
//   RegularCallDemo();
//
//   @Call("package:example/main.dart", "", "+appInit")
//   @pragma("vm:entry-point")
//   static dynamic appInit(PointCut pointcut) {
//     print('[KWLM1]: Before appInit!');
//     dynamic object = pointcut.proceed();
//     print('[KWLM1]: After appInit!');
//     return object;
//   }
//
//   @Call("package:example/main.dart", "MyApp", "+MyApp")
//   @pragma("vm:entry-point")
//   static dynamic myAppDefine(PointCut pointcut) {
//     print('[KWLM2]: MyApp default constructor!');
//     return pointcut.proceed();
//   }
//
//   @Call("package:example/main.dart", "MyHomePage", "+MyHomePage")
//   @pragma("vm:entry-point")
//   static dynamic myHomePage(PointCut pointcut) {
//     dynamic obj = pointcut.proceed();
//     print('[KWLM3]: MyHomePage named constructor!');
//     return obj;
//   }
// }
//

// @Aspect()
// @pragma("vm:entry-point")
// class RegexCallDemo {
//   @pragma("vm:entry-point")
//   RegexCallDemo();
//
//  @Call("package:example\\/.+\\.dart", ".*", "-.+", isRegex: true)
//  @pragma("vm:entry-point")
//  dynamic instanceUniversalHook(PointCut pointcut) {
//    print('[KWLM11]Before:${pointcut.target}-${pointcut.function}-${pointcut.namedParams}-${pointcut.positionalParams}');
//    dynamic obj = pointcut.proceed();
//    return obj;
//  }
//
//  @Call('package:example\\/.+\\.dart', '.*A', '-fa', isRegex: true)
//  @pragma("vm:entry-point")
//  dynamic instanceUniversalHookCustomMixin(PointCut pointcut) {
//    print('[KWLM12]Before:${pointcut.target}-${pointcut.function}-${pointcut.namedParams}-${pointcut.positionalParams}');
//    dynamic obj = pointcut.proceed();
//    return obj;
//  }
// }

// @Aspect()
// @pragma("vm:entry-point")
// class RegularExecuteDemo {
//   @pragma("vm:entry-point")
//   RegularExecuteDemo();
//
//   @Execute("package:example/main.dart", "_MyHomePageState", "-_incrementCounter")
//   @pragma("vm:entry-point")
//   dynamic _incrementCounter(PointCut pointcut) {
//     dynamic obj = pointcut.proceed();
//     print('[KWLM21]:${pointcut.sourceInfos}:${pointcut.target}:${pointcut.function}!');
//     return obj;
//   }
//
//   @Execute("dart:math", "Random", "-next.*", isRegex: true)
//   @pragma("vm:entry-point")
//   static dynamic randomNext(PointCut pointcut) {
//     print('[KWLM22]:randomNext!');
//     return 10;
//   }
// }
//
// @Aspect()
// @pragma('vm:entry-point')
// class RegexExecuteDemo {
//   @pragma('vm:entry-point')
//   RegexExecuteDemo();
//
//  @Execute('package:example\\/.+\\.dart', '.*A', '-fa', isRegex: true)
//  @pragma('vm:entry-point')
//  dynamic instanceUniversalHookCustomMixin(PointCut pointcut) {
//    print(
//        '[KWLM31]Before:${pointcut.target}-${pointcut.function}-${pointcut.namedParams}-${pointcut.positionalParams}');
//    final dynamic obj = pointcut.proceed();
//    return obj;
//  }
// }

@Aspect()
@pragma("vm:entry-point")
class InjectDemo{
  @Inject("package:example/main.dart","","+injectDemo", lineNum:27)
  @pragma("vm:entry-point")
  static void onInjectDemoHook1() {
    print('Aspectd:KWLM41');
  }

  @Inject("package:example/main.dart","C","+C", lineNum:195)
  @pragma("vm:entry-point")
  static void onInjectDemoHook3() {
    print('Aspectd:KWLM42');
    print('Aspectd:MC_inject1');
  }

  @Inject("package:example/main.dart","C","-fc", lineNum:196)
  @pragma("vm:entry-point")
  static void onInjectDemoHookMC() {
    print('Aspectd:MC_fc');
  }

  static var curPointerCode = 0;
  static var prePointerCode = 0;
  static var preHitPointer = 0;
  static var clickRenderMap = new Map<int, Object>();

  @Call("package:flutter/src/gestures/hit_test.dart", "HitTestTarget", "-handleEvent")
  @pragma("vm:entry-point")
  dynamic hookHitTestTargetHandleEvent(PointCut pointCut) {
    dynamic target = pointCut.target;
    PointerEvent pointerEvent = pointCut.positionalParams[0];
    HitTestEntry entry = pointCut.positionalParams[1];
    curPointerCode = pointerEvent.pointer;
    if (target is RenderObject) {

      if (curPointerCode > prePointerCode) {
        clickRenderMap.clear();
      }
      if (!clickRenderMap.containsKey(curPointerCode)) {
        clickRenderMap[curPointerCode] = target;
      }
    }
    prePointerCode = curPointerCode;
    target.handleEvent(pointerEvent, entry);
  }

  @Call("package:flutter/src/gestures/recognizer.dart", "GestureRecognizer", "-invokeCallback")
  @pragma("vm:entry-point")
  dynamic hookinvokeCallback(PointCut pointcut) {
    print("callback ====start=====");

    var result = pointcut.proceed();
    if (curPointerCode > preHitPointer) {
      String argumentName = pointcut.positionalParams[0];

      if (argumentName == 'onTap' ||
          argumentName == 'onTapDown' ||
          argumentName == 'onDoubleTap') {
        print("callback tap tap");

        RenderObject clickRender = clickRenderMap[curPointerCode];
        if (clickRender != null) {
          DebugCreator creator = clickRender.debugCreator;
          Element element = creator.element;

          //通过element获取路径
          String elementPath = getElementPath(element);
          print(elementPath);
        }
        preHitPointer = curPointerCode;
      }
    }
    print("callback ====end=====");

    return result;
  }

  String getElementPath(Element element) {
    var buffer = new StringBuffer();
    var current = element;

    element.visitAncestorElements((parent) {
      // print("callback getPath : ${parent.widget.toStringShort()}");

      var count = 0;
      parent.visitChildElements((child) {
        if (current == child) {
          if (current is HasCreation) {
            print('every is wrong');
          }
          if (current.widget is HasCreation && isLocalWidget(current)) {
            print('current is user widget : ${current.widget}');
            buffer.write(current.widget.toStringShort());
            buffer.write("[$count]/");
          }

          current = parent;
          return;
        }
        count++;
      });

      return true;
    });
    return buffer.toString();
  }
  bool isLocalWidget(Object object) {

    final Object candidate =  object is Element ? object.widget : object;
    bool location = candidate is HasCreation ? candidate.locInfo : false;
    return location;

    // if (location == null || location.file == null) {
    //   return false;
    // }
    // final String file = Uri.parse(location.file).path;
    //
    // return !file.contains('packages/flutter/');
  }
}
