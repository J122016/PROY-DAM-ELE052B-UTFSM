import 'package:firebase_core/firebase_core.dart';

// Android lee su configuración de android/app/google-services.json.
// La versión web la recibe al compilar, por ejemplo:
// flutter run -d chrome --dart-define=FIREBASE_WEB_API_KEY=... --dart-define=FIREBASE_WEB_APP_ID=...
const webFirebaseOptions = FirebaseOptions(
  apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY'),
  appId: String.fromEnvironment('FIREBASE_WEB_APP_ID'),
  messagingSenderId: '1038460412878',
  projectId: 'nutrimarket-dam',
  authDomain: 'nutrimarket-dam.firebaseapp.com',
  storageBucket: 'nutrimarket-dam.firebasestorage.app',
);
