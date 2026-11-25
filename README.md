# Proyecto DAM 

Proyecto semestral Desarrollo de aplicaciones móviles 2026-2. Tienda de productos alimenticios con carrito de compras, los productos se obtendrán desde openfoodfacts que provee una api abierto la cual entrega información nutricional del producto que aporta mayor información al consumidor al momento de hacer el pedido.

Mockup: https://usmarketrganico.ai.studio/

## Requerimientos

- Flutter
- Dart
- Idealmente emulador android
- Proyecto en firebase configurado para autenticación y firestore

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

- Open Food Facts solo se usa para importar productos desde el panel de administrador. El catálogo, los precios y el stock viven en Firestore; la canasta y el tema se guardan en el teléfono.

## Firebase

- Catálogo en la colección `products` (un documento por código de barras, con `active` para los eliminados). Comprar descuenta el stock con una transacción.
- Las reglas de seguridad están en [firestore.rules](firestore.rules) y se publican desde la consola (Firestore Database > Reglas): cualquiera lee el catálogo, solo un administrador con sesión lo modifica y un cliente solo puede bajar el stock al comprar.
- Android usa `android/app/google-services.json`. Para probar en navegador hay una app web registrada en el proyecto; sus claves se pasan al compilar:

```sh
flutter create . --platforms web   # solo la primera vez, no se sube al repo
flutter run -d chrome --dart-define=FIREBASE_WEB_API_KEY=... --dart-define=FIREBASE_WEB_APP_ID=...
```

## Integrantes

- Nicolás Abarca
- Juan Domenech
- Javier Torres
