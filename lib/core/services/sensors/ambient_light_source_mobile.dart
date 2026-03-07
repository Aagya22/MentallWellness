import 'package:light/light.dart';

class AmbientLightSource {
  final Light _light = Light();

  Stream<int> get lightStream => _light.lightSensorStream;
}

AmbientLightSource createAmbientLightSource() {
  return AmbientLightSource();
}
