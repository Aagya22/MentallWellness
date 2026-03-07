import 'dart:async';

class AmbientLightSource {
  const AmbientLightSource();

  Stream<int> get lightStream => const Stream<int>.empty();
}

AmbientLightSource createAmbientLightSource() {
  return const AmbientLightSource();
}
