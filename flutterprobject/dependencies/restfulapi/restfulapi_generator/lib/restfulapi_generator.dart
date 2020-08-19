library restfulapi_generator;

import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/restful_service_gen.dart';

Builder restfulServiceGenBuilder(BuilderOptions options) {
  return PartBuilder([RestfulServiceGenerator()], ".restapi.dart");
}
