Guía: Instalar Firebase iOS SDK usando Swift Package Manager (SPM)

Resumen
- Esta guía explica cómo añadir Firebase al target iOS de tu app Flutter usando Swift Package Manager (SPM) desde Xcode.
- Requisitos: debes realizar esto en Mac con Xcode instalado. No se puede completar desde Windows.

Pasos (Xcode)
1. Abre el proyecto iOS en Xcode
   - En macOS, desde terminal en la carpeta `ios` del proyecto Flutter:
     ```bash
     cd ios
     xed .
     ```
   - Alternativamente abre `ios/Runner.xcworkspace` si ya usas CocoaPods.

2. Añadir el paquete de Firebase
   - En Xcode: `File` → `Add Packages...`
   - En el campo "Enter package repository URL" pega:
     ```text
     https://github.com/firebase/firebase-ios-sdk
     ```
   - Pulsa `Next` y selecciona la versión (Recomendado: la versión por defecto o "Up to Next Major" para la última estable).

3. Selecciona los productos (librerías) que quieres incluir
   - En la lista de productos selecciona (mínimo recomendado para esta app):
     - `FirebaseCore` (requerido)
     - `FirebaseAnalytics`  — o si no usarás IDFA, selecciona `FirebaseAnalyticsWithoutAdId`
     - `FirebaseAuth` (si vas a usar autenticación)
     - `FirebaseFirestore` (si usas Cloud Firestore)
     - `FirebaseMessaging` (para FCM push notifications)
     - Opcionales: `FirebaseCrashlytics`, `FirebaseRemoteConfig`, etc.
   - Asegúrate de marcar la casilla del target `Runner` (o el target iOS de tu app).
   - Haz click en `Add Package` / `Finish` y Xcode resolverá y descargará los artefactos.

4. Verificar que las librerías aparecen en el proyecto
   - En el navegador de proyecto, selecciona el target `Runner` → `Package Dependencies` y verás `firebase-ios-sdk` con los productos añadidos.

Configurar Firebase (GoogleService-Info.plist)
- Copia `GoogleService-Info.plist` (descargado desde Firebase Console) a `ios/Runner/`.
- En Xcode arrastra `GoogleService-Info.plist` al proyecto `Runner` y asegúrate de que está agregado al target `Runner`.

Inicializar Firebase en iOS (AppDelegate)
- Abre `ios/Runner/AppDelegate.swift` y modifica `didFinishLaunchingWithOptions` para configurar Firebase:

```swift
import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

- Si ya tienes `FirebaseApp.configure()` en otro sitio (por ejemplo generado por `flutterfire`), no dupliques la llamada.

Push Notifications (FCM) — permisos y capacidades
- En Xcode: Target `Runner` → `Signing & Capabilities` → `+ Capability`
  - Agrega `Push Notifications`.
  - Agrega `Background Modes` y marca `Remote notifications` si usas FCM en background.
- Configura App Groups/Entitlements si tu app los requiere.

Permisos en runtime (notificaciones)
- Para recibir notificaciones, en `AppDelegate` solicita permisos y configura `UNUserNotificationCenter` y `Messaging` delegate según la documentación de FCM.

Construir y probar
1. En Xcode, selecciona un simulador o dispositivo y pulsa `Product` → `Build`.
2. Observa la consola; si Firebase se inicializa correctamente verás mensajes relacionados con Firebase.
3. Para probar FCM en un dispositivo, instala la app en un dispositivo real y envía una notificación desde Firebase Console.

Notas y consideraciones (Flutter)
- Flutter normalmente usa CocoaPods para dependencias nativas en iOS; SPM se integra desde Xcode y coexiste con CocoaPods, pero ten cuidado con conflictos.
- Si prefieres la forma automática, también puedes usar FlutterFire CLI (`flutterfire configure`) en macOS para generar `firebase_options.dart` y configurar automáticamente iOS/Android.
- Asegúrate de que la versión mínima de iOS en `ios/Podfile` y en Xcode sea compatible con los SDKs (ej. iOS 11+ o 12+ según requerimiento).

Comandos útiles en Mac terminal
```bash
# Abrir el proyecto iOS en Xcode
cd ios
xed .

# O abrir el workspace si existe (CocoaPods)
open Runner.xcworkspace

# Construir la app desde terminal (requiere macOS toolchain)
flutter build ios
```

Si quieres, puedo:
- Generar este archivo de documentación en tu repo (ya lo hago ahora).
- Preparar el snippet exacto para `AppDelegate.swift` si me muestras su contenido actual.
- Guiarte paso a paso en tiempo real (indícame si estás en un Mac con Xcode abierto y te guío por los clicks).

Recordatorio: debes ejecutar los pasos de Xcode en una Mac. Si solo tienes Windows ahora, dímelo y te doy instrucciones alternativas (por ejemplo usar `flutterfire configure` en un Mac o usar CocoaPods).