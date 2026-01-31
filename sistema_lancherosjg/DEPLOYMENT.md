# 🚀 Guía de Deployment

## ✅ Deploy Exitoso

**URL de la aplicación:** https://lancheros-sanjose.web.app

---

## 📋 Pasos para hacer Deploy

### 1. **Compilar para producción**
```bash
flutter build web --release
```

### 2. **Deploy a Firebase Hosting**
```bash
firebase deploy --only hosting
```

### 3. **Verificar el deploy**
Visita: https://lancheros-sanjose.web.app

---

## 🔒 Archivos Sensibles Protegidos

Los siguientes archivos están en `.gitignore` y **NO** deben subirse al repositorio:

### Firebase
- `firebase_options.dart` - Credenciales de Firebase
- `google-services.json` - Configuración Android
- `GoogleService-Info.plist` - Configuración iOS
- `*-firebase-adminsdk-*.json` - Service Account Keys
- `.firebase/` - Caché de Firebase

### Claves y Secretos
- `*.key`, `*.pem`, `*.p12` - Archivos de certificados
- `secrets.json` - Configuraciones secretas
- `.env*` - Variables de entorno

---

## 🔧 Configuración Inicial (Solo primera vez)

### 1. Instalar Firebase CLI
```bash
npm install -g firebase-tools
```

### 2. Login en Firebase
```bash
firebase login
```

### 3. Inicializar Firebase (si es necesario)
```bash
firebase init hosting
```

Selecciona:
- **Public directory:** `build/web`
- **Single-page app:** Yes
- **Set up automatic builds:** No
- **Overwrite index.html:** No

---

## 📱 Funcionalidades Implementadas

### ✅ Rotación de Grupos (Semanal)
- Lunes: Grupo 1 → Martes: Grupo 2 → Miércoles: Grupo 3 → Jueves: Grupo 4
- Viernes: Repite el grupo del lunes
- Fin de semana: Trabajan las 28 lanchas

### ✅ Rotación Interna (Semanal)
- Cada lunes, la primera lancha de cada grupo pasa al final
- El orden se mantiene toda la semana

### ✅ Orden Original Respetado
- El orden del rol se mantiene aunque terminen en diferente orden
- Se usa `ordenOriginal` para garantizar el orden correcto

### ✅ Reinicio Automático Diario
- Al inicio de cada día se resetea:
  - Cola de espera
  - Contador de vueltas
  - Estados de pontones

---

## 🐛 Troubleshooting

### Error: "Firebase command not found"
```bash
npm install -g firebase-tools
```

### Error: "Not authorized"
```bash
firebase login --reauth
```

### Error: "Build failed"
```bash
flutter clean
flutter pub get
flutter build web --release
```

---

## 📊 Monitoreo

- **Console:** https://console.firebase.google.com/project/lancheros-sanjose/overview
- **Hosting:** https://console.firebase.google.com/project/lancheros-sanjose/hosting
- **Firestore:** https://console.firebase.google.com/project/lancheros-sanjose/firestore

---

## 🔄 Flujo de Trabajo Recomendado

1. Hacer cambios en el código
2. Probar localmente: `flutter run -d chrome`
3. Compilar: `flutter build web --release`
4. Deploy: `firebase deploy --only hosting`
5. Verificar en producción

---

**Última actualización:** 30 de enero de 2026
