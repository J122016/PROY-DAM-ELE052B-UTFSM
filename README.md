# Proyecto DAM 

Proyecto semestral Desarrollo de aplicaciones móviles 2026-2. Tienda de productos alimenticios con carrito de compras, los productos se obtendrán desde openfoodfacts que provee una api abierto la cual entrega información nutricional del producto que aporta mayor información al consumidor al momento de hacer el pedido.

Mockup: https://usmarketrganico.ai.studio/

## Requerimientos

- Flutter
- Dart
- Idealmente emulador android

## Cómo inicializar el proyecto

Instalar requerimientos con:
```sh
flutter clean
flutter pub get
```

Si hace falta instalar:
```sh
flutter pub add http 
```

Inicial el proyecto con VS code + Android Studio en [main.dart](lib/main.dart) o bien:
```sh
flutter run
```

## Esrtuctura del proyecto

Se sigue la siguiente organización de carpetas:
```sh
lib/ 
├── data/ 
├──── models/   
├──── repositories/  
└──── services/ 
│ 
├── domain/  
└──── entities/
│ 
├── presentation/
├──── components/  
├──── screens/ 
└──── providers/ 
│  
├── constants.dart
└── main.dart
```

## Otros comandos útiles

```sh
flutter analyze # Chequeo estático
flutter test    # Ejecutar pruebas
flutter build apk --split-per-abi # generar apk
```

## Notas API

- La primera carga consulta productos orgánicos de Open Food Facts, pero, el catálogo, el stock y el tema se guardan localmente ya que API no los provee.

## Integrantes

- Nicolás Abarca
- Juan Domenech
- Javier Torres
