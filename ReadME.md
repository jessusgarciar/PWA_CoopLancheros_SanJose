# 🚤 Sistema de Gestión de Turnos - Lancheros San José

> **Sistema de gestión en tiempo real para el control de turnos, viajes y finanzas de una cooperativa de lanchas en San José de Gracia, Aguascalientes.**

## 📋 Descripción

Sistema PWA (Progressive Web App) desarrollado para digitalizar y optimizar las operaciones diarias de una cooperativa de lancheros. Permite gestionar la cola de turnos, registrar viajes, controlar tarifas y generar reportes financieros en tiempo real.

### 🎯 Problema que resuelve

Antes del sistema, los lancheros manejaban sus turnos y finanzas de forma manual con papel, lo que causaba:
- ❌ Conflictos por turnos no claros
- ❌ Pérdida de información financiera
- ❌ Dificultad para auditar viajes
- ❌ Falta de transparencia en la operación

### ✅ Solución implementada

- ✅ Cola de turnos digital en tiempo real
- ✅ Registro automático de viajes y pasajeros
- ✅ Cálculo automático de tarifas por tipo de pasajero
- ✅ Dashboard con métricas del día
- ✅ Acceso multiplataforma (Web, iOS, Android)

---

## 🏗️ Arquitectura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada de la aplicación
├── config/
│   └── router.dart           # Configuración de navegación (GoRouter)
├── models/
│   ├── cola_model.dart       # Modelo de cola de turnos
│   ├── viaje_model.dart      # Modelo de viajes/registros
│   ├── ponton_model.dart     # Modelo de embarcaciones
│   └── configuracion_model.dart
├── providers/
│   ├── cola_provider.dart    # Estado de la cola (Riverpod)
│   ├── viajes_provider.dart  # Estado de viajes
│   └── firebase_provider.dart
├── screens/
│   ├── home_screen.dart      # Pantalla principal (lancheros)
│   ├── dispatch_screen.dart  # Pantalla de despacho
│   └── admin_screen.dart     # Panel de administración
└── services/
    └── firebase_service.dart # Capa de datos con Firestore
```

---

## 🛠️ Stack Tecnológico

| Categoría | Tecnología | Uso |
|-----------|------------|-----|
| **Framework** | Flutter 3.x | Desarrollo multiplataforma |
| **Lenguaje** | Dart | Lógica de aplicación |
| **Backend** | Firebase | BaaS (Backend as a Service) |
| **Base de datos** | Cloud Firestore | Base de datos NoSQL en tiempo real |
| **Autenticación** | Firebase Auth | Gestión de usuarios |
| **State Management** | Riverpod | Manejo de estado reactivo |
| **Navegación** | GoRouter | Enrutamiento declarativo |
| **UI/UX** | Material 3 + Google Fonts | Diseño moderno y accesible |

---

## ✨ Funcionalidades Principales

### 📊 Dashboard en Tiempo Real
- Visualización de quién está cargando actualmente
- "Cuadro" con los próximos 5 lancheros en turno
- Cola de espera ordenada por llegada
- Contador de vueltas del día

### 🎫 Gestión de Viajes
- Registro de pasajeros por categoría:
  - 👨 Adultos
  - 👶 Niños
  - 👴 INAPAM (tercera edad)
  - 🎫 Especiales
  - 👷 Trabajadores
  - 🎁 Cortesías

### 💰 Control Financiero
- Cálculo automático según tarifas configurables
- Registro de monto cobrado vs calculado
- Notas y observaciones por viaje
- Reportes diarios de ingresos

### 👥 Roles de Usuario
- **Lanchero**: Ve su turno y estadísticas
- **Despachador**: Registra viajes y pasajeros
- **Administrador**: Configura tarifas y gestiona pontones

---

## 🚀 Instalación y Configuración

### Prerrequisitos

- Flutter SDK 3.10+
- Dart SDK 3.0+
- Cuenta de Firebase
- IDE (VS Code recomendado)

### Pasos de instalación

```bash
# 1. Clonar el repositorio
git clone https://github.com/TU_USUARIO/sistema-lancheros-sanjose.git
cd sistema-lancheros-sanjose

# 2. Instalar dependencias
flutter pub get

# 3. Configurar Firebase (ver sección de configuración)
# Crear archivo lib/firebase_options.dart con tus credenciales

# 4. Ejecutar la aplicación
flutter run -d chrome    # Web
flutter run -d android   # Android
flutter run -d ios       # iOS
```

### ⚙️ Configuración de Firebase

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com)
2. Habilitar Authentication y Firestore
3. Descargar archivos de configuración:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`
4. Crear `lib/firebase_options.dart` con las credenciales

> ⚠️ **Nota de seguridad**: Los archivos de credenciales no están incluidos en el repositorio por seguridad.

---

## 📈 Roadmap

- [x] Sistema de cola de turnos
- [x] Registro de viajes
- [x] Integración con Firebase
- [ ] Notificaciones push cuando es tu turno
- [ ] Reportes exportables (PDF/Excel)
- [ ] Modo offline con sincronización
- [ ] Gráficas de estadísticas mensuales
- [ ] App nativa para iOS/Android en stores

---

## 🤝 Contribuciones

Las contribuciones son bienvenidas. Por favor, abre un issue primero para discutir los cambios que te gustaría hacer.


