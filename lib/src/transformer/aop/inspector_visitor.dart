import 'package:kernel/ast.dart';

// Parameter name used to track were widget constructor calls were made from.
//
// The parameter name contains a randomly generate hex string to avoid collision
// with user generated parameters.
const String _creationLocationParameterName =
    r'$creationLocationd_0dea112b090073317d4';
const String _locationFieldName = r'location';

class InspectorVisitor extends Transformer {
  Class _widgetClass;
  Class _userClass;

  InspectorVisitor(List<Library> libraries) {
    print("start222");

    _resolveFlutterClasses(libraries);

  }

  void _resolveFlutterClasses(Iterable<Library> libraries) {
    // If the Widget or Debug location classes have been updated we need to get
    // the latest version
    for (Library library in libraries) {
      final Uri importUri = library.importUri;
      if (importUri != null && importUri.scheme == 'package') {
        if (importUri.path == 'flutter/src/widgets/framework.dart' ||
            importUri.path == 'flutter_web/src/widgets/framework.dart') {
          for (Class class_ in library.classes) {
            if (class_.name == 'Widget') {
              _widgetClass = class_;
            }
          }
        } else {
          if (importUri.path == 'example/user_widget.dart') {
            for (Class class_ in library.classes) {
              if (class_.name == 'UserWidget') {
                _userClass = class_;
              }
            }
          }
        }
      }
    }
    print('widiget class is : $_widgetClass');
    print('user class is : $_userClass');
  }

  bool _isSubclassOfWidget(Class clazz) {
    // TODO(askesc): Cache results.
    // TODO(askesc): Test for subtype rather than subclass.
    Class current = clazz;
    while (current != null) {
      if (current == _widgetClass) {
        return true;
      }
      current = current.superclass;
    }
    return false;
  }

  bool _hasNamedParameter(FunctionNode function, String name) {
    return function.namedParameters
        .any((VariableDeclaration parameter) => parameter.name == name);
  }

  bool _hasNamedArgument(Arguments arguments, String argumentName) {
    return arguments.named
        .any((NamedExpression argument) => argument.name == argumentName);
  }

  void _maybeAddCreationLocationArgument(
      Arguments arguments,
      FunctionNode function,
      Expression creationLocation,
      ) {
    if (_hasNamedArgument(arguments, _creationLocationParameterName)) {
      return;
    }
    if (!_hasNamedParameter(function, _creationLocationParameterName)) {
      if (function.requiredParameterCount !=
          function.positionalParameters.length) {
        return;
      }
    }


    final NamedExpression namedArgument = NamedExpression(_creationLocationParameterName, creationLocation);
    namedArgument.parent = arguments;
    arguments.named.add(namedArgument);


  }

  void _addLocationArgument(InvocationExpression node, FunctionNode function,
      Class constructedClass) {
    _maybeAddCreationLocationArgument(
      node.arguments,
      function,
      ConstantExpression(BoolConstant(true)),
    );
  }

  /// Adds a named parameter to a function if the function does not already have
  /// a named parameter with the name or optional positional parameters.
  bool _maybeAddNamedParameter(
      FunctionNode function,
      VariableDeclaration variable,
      ) {
    if (_hasNamedParameter(function, _creationLocationParameterName)) {
      // Gracefully handle if this method is called on a function that has already
      // been transformed.
      return false;
    }
    // Function has optional positional parameters so cannot have optional named
    // parameters.
    if (function.requiredParameterCount != function.positionalParameters.length) {
      return false;
    }
    variable.parent = function;
    function.namedParameters.add(variable);
    return true;
  }

  /// Modify [clazz] to add a field named [_locationFieldName] that is the
  /// first parameter of all constructors of the class.
  ///
  /// This method should only be called for classes that implement but do not
  /// extend [Widget].
  void _transformClassImplementingWidget(
      Class clazz, Object changedStructureNotifier) {
    if (clazz.fields
        .any((Field field) => field.name.name == _locationFieldName)) {
      // This class has already been transformed. Skip
      return;
    }
    clazz.implementedTypes
        .add(Supertype(_userClass, <DartType>[]));
    // changedStructureNotifier?.registerClassHierarchyChange(clazz);

    // We intentionally use the library context of the _HasCreationLocation
    // class for the private field even if [clazz] is in a different library
    // so that all classes implementing Widget behave consistently.
    final Name fieldName = Name(
      _locationFieldName,
      _userClass.enclosingLibrary,
    );
    final Field locationField = Field(fieldName,
        type: DynamicType(),
        isFinal: true,
        reference: clazz.reference.canonicalName
            ?.getChildFromFieldWithName(fieldName)
            ?.reference);
    clazz.addMember(locationField);

    final Set<Constructor> _handledConstructors =
    new Set<Constructor>.identity();

    void handleConstructor(Constructor constructor) {
      if (!_handledConstructors.add(constructor)) {
        return;
      }
      assert(!_hasNamedParameter(
        constructor.function,
        _creationLocationParameterName,
      ));
      final VariableDeclaration variable = VariableDeclaration(
        _creationLocationParameterName,
        type: DynamicType(),
      );
      if (!_maybeAddNamedParameter(constructor.function, variable)) {
        return;
      }

      bool hasRedirectingInitializer = false;
      for (Initializer initializer in constructor.initializers) {
        if (initializer is RedirectingInitializer) {
          if (initializer.target.enclosingClass == clazz) {
            // We need to handle this constructor first or the call to
            // addDebugLocationArgument bellow will fail due to the named
            // parameter not yet existing on the constructor.
            handleConstructor(initializer.target);
          }
          _maybeAddCreationLocationArgument(
            initializer.arguments,
            initializer.target.function,
            new VariableGet(variable),
          );
          hasRedirectingInitializer = true;
          break;
        }
      }
      if (!hasRedirectingInitializer) {
        constructor.initializers.add(new FieldInitializer(
          locationField,
          new VariableGet(variable),
        ));
        // TODO(jacobr): add an assert verifying the locationField is not
        // null. Currently, we cannot safely add this assert because we do not
        // handle Widget classes with optional positional arguments. There are
        // no Widget classes in the flutter repo with optional positional
        // arguments but it is possible users could add classes with optional
        // positional arguments.
        //
        // constructor.initializers.add(new AssertInitializer(new AssertStatement(
        //   new IsExpression(
        //       new VariableGet(variable), _locationClass.thisType),
        //   conditionStartOffset: constructor.fileOffset,
        //   conditionEndOffset: constructor.fileOffset,
        // )));
      }
    }

    // Add named parameters to all constructors.
    clazz.constructors.forEach(handleConstructor);
  }

  @override
  StaticInvocation visitStaticInvocation(StaticInvocation node) {
    node.transformChildren(this);
    final Procedure target = node.target;
    if (!target.isFactory) {
      return node;
    }
    final Class constructedClass = target.enclosingClass;
    if (!_isSubclassOfWidget(constructedClass)) {
      return node;
    }
    _addLocationArgument(node, target.function, constructedClass);
    return node;
  }

  @override
  ConstructorInvocation visitConstructorInvocation(ConstructorInvocation node) {
    node.transformChildren(this);
    final Constructor constructor = node.target;
    final Class constructedClass = constructor.enclosingClass;
    if (_isSubclassOfWidget(constructedClass)) {
      _addLocationArgument(node, constructor.function, constructedClass);
    }
    return node;
  }
}
