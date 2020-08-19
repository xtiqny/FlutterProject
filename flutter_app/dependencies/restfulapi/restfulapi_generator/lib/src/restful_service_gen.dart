import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:built_collection/built_collection.dart';
import 'package:cn21base/cn21base.dart';
import 'package:restfulapi/src/annotations.dart' as restapi;
import 'package:restfulapi/src/restful_service.dart';
import 'package:source_gen/source_gen.dart';

class RestfulServiceGenerator extends GeneratorForAnnotation<restapi.RestApi> {
  @override
  FutureOr<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    print('------> generateForAnnotatedElement');
    if (element is! ClassElement) {
      final friendlyName = element.displayName;
      throw new InvalidGenerationSourceError(
        'Generator cannot target `$friendlyName`.',
        todo: 'Remove the [ChopperApi] annotation from `$friendlyName`.',
      );
    }

    String str = _buildImplementionClass(element, annotation, buildStep);
    print('-------> End of generation.');
    return str;
  }

  bool _extendsRestfulApiService(InterfaceType t) =>
      _typeChecker(RestfulApiService).isExactlyType(t);

  String _buildImplementionClass(
    ClassElement element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element.allSupertypes.any(_extendsRestfulApiService) == false) {
      final friendlyName = element.displayName;
      throw new InvalidGenerationSourceError(
        'Generator cannot target `$friendlyName`.',
        todo: '`$friendlyName` need to extends the [ChopperService] class.',
      );
    }

    final friendlyName = element.name;
    final genSrcs = StringBuffer();
    genSrcs
      ..writeln('''
      class ${friendlyName}Impl extends $friendlyName {
    ''')
      ..writeln(_generateConstructor(element, annotation, buildStep))
      ..writeln(_parseMethods(element, buildStep))
      ..writeln('''
      }''');
    return genSrcs.toString();
  }

  String _generateConstructor(
      ClassElement element, ConstantReader annotation, BuildStep buildStep) {
    return '''
      ${element.displayName}Impl(RestfulAgent agent) : super(agent);\n
    ''';
  }

  String _generateHeaders(
      MethodElement m, ConstantReader method, BuildStep buildStep) {
    final buffer = StringBuffer();
    final annotations = _getAnnotations(m, restapi.Header);
    final methodAnnotations = method.peek("headers").mapValue;
    bool hasHeader = ((annotations != null && annotations.isNotEmpty) ||
        (methodAnnotations != null && methodAnnotations.isNotEmpty));

    // 不管有没有header都要把对象创建出来，否则后面Interceptor无法修改
    buffer.write('''
        final genHeaders = HttpHeaders();
      ''');

    if (hasHeader) {
      // Generate headers backed by @Header arguments
      annotations?.forEach((p, ConstantReader r) {
        final name = r.peek("name")?.stringValue ?? p.displayName;
        buffer.write('''
        genHeaders.add("$name", ${p.displayName});
      ''');
      });
      // Generate headers backed by @Method's header define.
      methodAnnotations?.forEach((k, v) {
        String val = v.toStringValue().replaceAll("\"", "\\\"");
        buffer.write('''
        genHeaders.add("${k.toStringValue()}", "$val");
      ''');
      });
    }
    return buffer.toString();
  }

  String _parseMethods(ClassElement element, BuildStep buildStep) {
    print(
        '-------> Start to parse methods. count=${element.methods.length} first=${element.methods.first?.displayName}');
    final buffer = StringBuffer();
    element.methods.forEach((m) {
      print('------> function: ${m.displayName}');
      final methodAnnot = _getMethodAnnotation(m);
      print(
          '------> http method:${methodAnnot.runtimeType} abs:${m.isAbstract} ret type:${m.returnType.displayName}');
      if (methodAnnot != null &&
          m.isAbstract &&
          _typeChecker(CancelableFuture).isAssignableFromType(m.returnType)) {
        buffer
          ..writeln("@override")
          ..writeln(_generateMethod(m, buildStep))
          ..writeln('}');
      }
    });
    print('-------> End or methods parsing.');
    return buffer.toString();
  }

  String _generateMethod(MethodElement m, BuildStep buildStep) {
    final method = _getMethodAnnotation(m);
//    final multipart = _hasAnnotation(m, restapi.Multipart);

    final body = _getAnnotationElement(m, restapi.Body);
    final paths = _getAnnotations(m, restapi.Path);
    final queries = _getAnnotations(m, restapi.Query);
    final queryMap = _getAnnotation(m, restapi.QueryMap);
    final fields = _getAnnotations(m, restapi.Field);
//    final parts = _getAnnotations(m, restapi.Part);
//    final fileFields = _getAnnotations(m, restapi.PartFile);

    final urlPath = _generateUrlPath(method, paths);
    final responseType = _getResponseType(m.returnType);
    final responseInnerType =
        _getResponseInnerType(m.returnType) ?? responseType;
    print(
        '>>>> responseType=${responseType?.displayName} responseInnerType=${responseInnerType?.displayName}');
    final buffer = StringBuffer();
    final parbuffer = StringBuffer();
    // Check required parameters.
    bool firstReqPar = true;
    m.parameters.where((p) => p.isNotOptional).forEach((p) {
      print(
          '-------> param: type=${p.type} name=${p.displayName} isfunc=${p.type is FunctionType} p=${p.parameters}');
      if (firstReqPar) {
        firstReqPar = false;
      } else {
        parbuffer.write(', ');
      }
      parbuffer.write(
          '${p.type is FunctionType ? p.type.element : p.type.displayName} ${p.displayName}');
    });
    // Check optional positional parameters.
    bool firstOptPosPar = true;
    m.parameters.where((p) => p.isOptionalPositional).forEach((p) {
      if (firstOptPosPar) {
        if (!firstReqPar) parbuffer.write(', ');
        parbuffer.write('[');
        firstOptPosPar = false;
      } else {
        parbuffer.write(', ');
      }
      final defValue =
          p.defaultValueCode != null ? '=${p.defaultValueCode}' : '';
      print('-------> pos opt param: ${p.displayName} def val=$defValue');
      parbuffer.write(
          '${p.type is FunctionType ? p.type.element : p.type.displayName} ${p.displayName}$defValue');
    });
    if (!firstOptPosPar) parbuffer.write(']');
    // Check named parameters
    bool firstNamedPar = true;
    m.parameters.where((p) => p.isNamed).forEach((p) {
      if (firstNamedPar) {
        if (!firstReqPar) parbuffer.write(', ');
        parbuffer.write('{');
        firstNamedPar = false;
      } else {
        parbuffer.write(', ');
      }
      final defValue =
          p.defaultValueCode != null ? '=${p.defaultValueCode}' : '';
      print('-------> named param: $p def val=$defValue');
      parbuffer.write(
          '${p.type is FunctionType ? p.type.element : p.type.displayName} ${p.displayName}$defValue');
    });
    if (!firstNamedPar) parbuffer.write('}');
    // Generate the method signature
    buffer..writeln('''
      ${m.returnType.displayName} ${m.displayName}($parbuffer) {
        var genUrl = agent.baseUrl.resolve('$urlPath');
    ''');

    // Generate Headers
    final headers = _generateHeaders(m, method, buildStep);
    buffer.write(headers);

    // Check and generate query params backed by @Query arguments
    final hasQueryMap = queryMap.isNotEmpty;
    final hasQuery = hasQueryMap || queries.isNotEmpty;
    if (hasQuery) {
      buffer.write('''
      final queryBuffer = StringBuffer();
    ''');
      if (queries.isNotEmpty) {
        final qryStr = _generateMap(queries);
        buffer.write('$qryStr');
        if (hasQueryMap) buffer.write('queryBuffer.write("&");');
      }

      // Check and generate query params backed by @QueryMap argument
      if (hasQueryMap) {
        buffer.write('''
        $queryMap.forEach((k, v) {
          if(v == null) continue;
          if(queryBuffer.isNotEmpty) queryBuffer.write("&");
          queryBuffer.write('\$k=\${Uri.encodeQueryComponent(v.toString())}');
        });
      ''');
      }
      buffer.write('genUrl = genUrl.replace(query:queryBuffer.toString());');
    }

    // Check request body
    final hasBody = body.isNotEmpty || fields.isNotEmpty;
    if (hasBody) {
      if (body.isNotEmpty) {
        // Body with specified type
        final p = body.keys.first;
        final typename = p.type;
        buffer.write('''
          final genBody = agent.convFactoryManager.getRequestConverter($typename)?.call(${p.displayName});
        ''');
      } else {
        // Form post style body
        buffer.write('''
          final fieldBuffer = StringBuffer();
          final genContentType = 'application/x-www-form-urlencoded';
          ${_generateFieldMap(fields)}
          final genContent = utf8.encode(fieldBuffer.toString()) as Uint8List;
          final genBody = HttpBody.fromBytes(genContentType, genContent);
        ''');
      }
    }

    // Generate final Request object
    buffer.write('''
    final genRequest = Request('${method.read('method').stringValue}', genUrl
          ${headers.isNotEmpty ? ", headers:genHeaders" : ""} 
          ${hasBody ? ", body: genBody" : ""});
    ''');
    final onCancelAnno = _getAnnotationElement(m, restapi.OnCancel);
    if (onCancelAnno.isNotEmpty) {
      final onCancel = onCancelAnno.keys.first.displayName;
      buffer.write('return sendRequest(genRequest, $onCancel);');
    } else {
      buffer.write('return sendRequest(genRequest);');
    }
    print('----------------------------------------------------');
    print(buffer.toString());
    return buffer.toString();
  }

  Map<String, ConstantReader> _getAnnotation(MethodElement m, Type type) {
    var annot;
    String name;
    for (final p in m.parameters) {
      final a = _typeChecker(type).firstAnnotationOf(p);
      if (annot != null && a != null) {
        throw new Exception("Too many $type annotation for '${m.displayName}");
      } else if (annot == null && a != null) {
        annot = a;
        name = p.displayName;
      }
    }
    if (annot == null) return {};
    return {name: new ConstantReader(annot)};
  }

  Map<ParameterElement, ConstantReader> _getAnnotationElement(
      MethodElement m, Type type) {
    var annot;
    ParameterElement name;
    for (final p in m.parameters) {
      final a = _typeChecker(type).firstAnnotationOf(p);
      if (annot != null && a != null) {
        throw new Exception("Too many $type annotation for '${m.displayName}");
      } else if (annot == null && a != null) {
        annot = a;
        name = p;
      }
    }
    if (annot == null) return {};
    return {name: new ConstantReader(annot)};
  }

  Map<ParameterElement, ConstantReader> _getAnnotations(
      MethodElement m, Type type) {
    var annot = <ParameterElement, ConstantReader>{};
    for (final p in m.parameters) {
      final a = _typeChecker(type).firstAnnotationOf(p);
      if (a != null) {
        annot[p] = new ConstantReader(a);
      }
    }
    return annot;
  }

  TypeChecker _typeChecker(Type type) => new TypeChecker.fromRuntime(type);

  ConstantReader _getMethodAnnotation(MethodElement method) {
    for (final type in _methodsAnnotations) {
      final annot = _typeChecker(type)
          .firstAnnotationOf(method, throwOnUnresolved: false);
      if (annot != null) return new ConstantReader(annot);
    }
    return null;
  }

  final _methodsAnnotations = const [
    restapi.Get,
    restapi.Post,
    restapi.Delete,
    restapi.Put,
    restapi.Patch,
    restapi.Method
  ];

  DartType _genericOf(DartType type) {
    return type is InterfaceType && type.typeArguments.isNotEmpty
        ? type.typeArguments.first
        : null;
  }

  DartType _getResponseType(DartType type) {
    return _genericOf(_genericOf(type));
  }

  DartType _getResponseInnerType(DartType type) {
    final generic = _genericOf(type);

    if (generic == null ||
        _typeChecker(Map).isExactlyType(type) ||
        _typeChecker(BuiltMap).isExactlyType(type)) return type;

    if (generic.isDynamic) return null;

    if (_typeChecker(List).isExactlyType(type) ||
        _typeChecker(BuiltList).isExactlyType(type)) return generic;

    return _getResponseInnerType(generic);
  }

  String _generateUrlPath(
    ConstantReader method,
    Map<ParameterElement, ConstantReader> paths,
  ) {
    String path = "${method.read("path").stringValue}";
    paths.forEach((p, ConstantReader r) {
      final name = r.peek("name")?.stringValue ?? p.displayName;
      path = path.replaceFirst("{$name}", "\$${p.displayName}");
    });
    return path.replaceAll("'", "\\'");
  }

  String _generateMap(Map<ParameterElement, ConstantReader> queries) {
    final buffer = StringBuffer();
    queries.forEach((p, ConstantReader r) {
      final name = r.peek("name")?.stringValue ?? p.displayName;
      buffer.write('''
        if(${p.displayName} != null) {
          queryBuffer.write('\${queryBuffer.isNotEmpty? "&" : ""}$name=\${Uri.encodeQueryComponent(${p.displayName}.toString())}');
        }
      ''');
    });
    return buffer.toString();
  }

  String _generateFieldMap(Map<ParameterElement, ConstantReader> fields) {
    final buffer = StringBuffer();
    fields.forEach((p, ConstantReader r) {
      final name = r.peek("name")?.stringValue ?? p.displayName;
      buffer.write('''
        if(${p.displayName} != null) {
          fieldBuffer.write('\${fieldBuffer.isNotEmpty? "&" : ""}$name=\${Uri.encodeQueryComponent(${p.displayName}.toString())}');
        }
      ''');
    });
    return buffer.toString();
  }
}
