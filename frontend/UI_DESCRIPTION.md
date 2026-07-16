# EcoSmartBin Frontend — Descripción Completa de Pantallas (UI)

> Documento generado para que una IA (Stitches) pueda recrear los estilos del frontend Flutter.

---

## 1. LANDING PAGE (`/`)

**Archivo:** `lib/screens/landing/landing_screen.dart` + `landing_view.dart`

### Layout General
```
Scaffold
├── Column
│   ├── Navbar (fija arriba, fuera del scroll)
│   └── Expanded > SingleChildScrollView
│       ├── HeroSection
│       ├── EcoDashboard (gamified stats)
│       ├── FeaturesSection (3 cards)
│       ├── HowItWorksSection (3 step cards)
│       ├── CTASection
│       └── Footer
```

### Componentes Internos (privados en landing_screen.dart)

#### `_Navbar`
- Brand: icono `recycling_rounded` + texto "EcoSmartBin"
- Actions: `_NavButton` "Iniciar Sesión" + `_PrimaryButton` "Registrarse"
- Se vuelve semi-opaca al hacer scroll (`_navScrolled` state)
- Responsive: padding horizontal 64px desktop / 24px mobile

#### `_PrimaryButton`
- Gradient emerald (`#10B981 → #059669`)
- Border radius 16px
- Hover: se eleva -2px, sombra más intensa, gradiente a `#34D399 → #10B981`
- Opcional: icono a la izquierda, modo compacto (padding menor)

#### `_OutlineButton`
- Borde emerald 1.5px, fondo transparente
- Hover: fondo emerald 10%, texto emerald
- Border radius 16px

#### `_NavButton`
- Texto plano sin fondo
- Hover: color emerald

#### `_HoverFeatureCard` (para Features)
- Fondo blanco, border radius 24px, borde `#E2E8F0`
- Hover: se eleva -8px, glow emerald, sombra grande
- Icono circular con color por card: emerald, blue, purple
- Título + descripción

#### `_StepCard` (How It Works)
- Número circular, icono, título, descripción
- Sin hover animation

#### `_StatItem` (dashboard stats)
- Icono + valor numérico grande + label

#### `_HoverScale`
- Wrapper genérico que escala 1.03x al hover

#### `_FloatingBadge`
- Badge flotante con animación moveY (para la ilustración hero)

### Secciones específicas:
- **HeroSection:** side-by-side (desktop) o stacked (mobile). Incluye badge "Gestión Ecológica Inteligente", heading grande, subtitle, 2 CTAs, y una ilustración con badges flotantes ("IA Integrada", "+50 EcoPuntos")
- **EcoDashboard:** Medidor radial SVG, stats (1.2K Puntos, 45 Rachas, 120 kg), botón "Empezar a Reciclar"
- **FeaturesSection:** 3 `_HoverFeatureCard` (IA, Recompensas, Dashboard)
- **HowItWorksSection:** 3 `_StepCard` (Escanea → Deposita → Acumula)
- **CTASection:** Fondo con gradiente, heading, subtitle, `_PrimaryButton`
- **Footer:** Links, copyright, redes sociales

---

## 2. LOGIN (`/login`)

**Archivo:** `lib/screens/auth/login_screen.dart` + `login_view.dart`

### Layout
```
Scaffold (bg #F8FAFC)
└── Center > SingleChildScrollView
    └── Card blanca (maxWidth 450px, border radius 24px, sombra suave)
        └── Form
            ├── Header: icono recycling + "EcoSmartBin" + subtítulo
            ├── Error alert (condicional, rojo con icono)
            ├── Email TextFormField (con icono, label, validación)
            ├── Password TextFormField (con toggle visibilidad, icono)
            ├── "¿Olvidaste tu contraseña?" link (derecha)
            ├── ElevatedButton "Iniciar Sesión" (emerald, loading state)
            └── Row: "¿No tienes una cuenta?" + link "Regístrate"
```

### Componentes:
- **Input fields:** filled con `#F1F5F9`, border radius 14px, focus emerald, error rojo
- **Error alert:** contenedor rojo 10% opacidad, icono + texto
- **ElevatedButton:** bg `#10B981`, white text, bold, radius 14px. Loading muestra CircularProgressIndicator

---

## 3. REGISTER (`/register`)

**Archivo:** `lib/screens/auth/register_screen.dart` + `register_view.dart`

### Layout
Misma estructura que Login pero con más campos:
```
Scaffold > Center > ScrollView > Card Blanca (maxWidth 500px)
└── Form
    ├── Header: icono person_add + "Registro" + subtítulo
    ├── Error alert (rojo, condicional)
    ├── Success alert (verde, condicional)
    ├── Row: [Nombres] [Apellidos] (side-by-side)
    ├── Cédula / ID
    ├── Email
    ├── Password (con toggle visibilidad)
    ├── Facultad (Opcional)
    ├── ElevatedButton "Registrar Cuenta"
    └── Row: "¿Ya tienes cuenta?" + link "Inicia Sesión"
```

- `_buildInputDecoration()` reutiliza el estilo de input (filled, radius 14px, icono)

---

## 4. RECOVER PASSWORD (`/recover-password`)

**Archivo:** `lib/screens/auth/recover_password_screen.dart` + `recover_password_view.dart`

### Layout (2 estados)
```
Scaffold (bg #F8FAFC)
└── Card blanca (maxWidth 450px)
    ├── (state._success == false) Form: email input + "Enviar Enlace" button
    └── (state._success == true) Success: icono check, "¡Revisa tu correo!", texto informativo
```

---

## 5. RESET PASSWORD (`/reset-password`)

**Archivo:** `lib/screens/auth/reset_password_screen.dart` + `reset_password_view.dart`

### Layout (3 estados)
```
Scaffold (gradiente oscuro: #0F172A → #1E293B → #0F172A)
└── Card glassmorphism (bg blanco 5%, borde blanco 10%, blur)
    ├── (token == null): "Enlace inválido" + botón "Volver al Login"
    ├── (success == false): Form: password + confirm password + "Restablecer"
    └── (success == true): icono check + "¡Contraseña actualizada!" + botón login
```

---

## 6. EMAIL VERIFIED (`/email-verified`)

**Archivo:** `lib/screens/auth/email_verified_screen.dart`

Standalone StatelessWidget:
```
Scaffold (bg #F8FAFC)
└── Card blanca
    ├── Brand: recycling icon + "EcoSmartBin"
    ├── Icono verified_user (72px, emerald)
    ├── "¡Correo Verificado!"
    ├── Texto de confirmación
    └── ElevatedButton "Iniciar Sesión" → navega a /login
```

---

## 7. PROFILE / MAIN SHELL (`/profile`)

**Archivo:** `lib/screens/profile/profile_screen.dart` + `profile_view.dart`

### Layout
```
Scaffold (bg #F8FAFC)
├── IndexedStack [Tab0, Tab1, Tab2, Tab3, Tab4]
└── BottomNavigationBar (5 items, fijo)
    ├── Perfil (person_rounded)
    ├── Reciclar (qr_code_scanner_rounded)
    ├── Canjear (card_giftcard_rounded)
    ├── H. Reciclaje (history_rounded)
    └── H. Canjes (shopping_bag_rounded)
```

### Tab 0 — Profile (inline, no es screen separada)
```
Scaffold interno
├── AppBar: "Mi Perfil Ecológico" + logout icon (red)
└── Body (loading | error | content)
    ├── [Loading] CircularProgressIndicator emerald
    ├── [Error] _buildErrorWidget(): icono cloud_off, texto, botones "Reintentar" + "Ir al Login"
    └── [Content] SingleChildScrollView
        ├── _buildEcoPointsCard(): gradient emerald, icono forest, "EcoPuntos Acumulados", número grande
        ├── _buildPersonalInfoCard(): bg blanco, borde, secciones con:
        │   ├── _buildInfoRow(icon, label, value) × N
        │   └── _buildDivider() entre rows
        └── [if admin] _buildAdminAccessButton(): indigo (#6366F1), icono admin_panel
```

### Tab 1-4: Embebidos
- Tab 1: `ReciclarScreen()` (full widget)
- Tab 2: `CanjearScreen()` (full widget)
- Tab 3: `ReciclajeHistorialScreen()` (full widget)
- Tab 4: `CanjesHistorialScreen()` (full widget)

---

## 8. PUNTOS DASHBOARD (`/puntos`)

**Archivo:** `lib/screens/puntos/puntos_screen.dart` + `puntos_view.dart`

### Layout
```
Scaffold (bg #0F172A — dark)
├── AppBar: back arrow blanco, "EcoPuntos", refresh icon
└── RefreshIndicator > SingleChildScrollView
    ├── _buildBalanceCard(): gradient verde oscuro (#047857 → #065F46), icono eco, "Hola, nombre", número enorme, "EcoPuntos acumulados"
    ├── "Servicios de EcoPuntos" (label)
    └── 4× _buildDashboardOption(title, desc, icon, gradient colors)
        ├── "Reciclar en Basurero" (emerald gradient) → /puntos/reciclar
        ├── "Canjear Premios" (purple gradient) → /puntos/canjear
        ├── "Historial de Reciclaje" (blue gradient) → /puntos/historial-reciclaje
        └── "Historial de Canjes" (sky blue gradient) → /puntos/historial-canjes
```

### Componente `_buildDashboardOption`
- Container con gradient de fondo
- InkWell con border radius 20px
- Título blanco bold 18px, descripción blanca 85% opacidad
- Icon container a la derecha con fondo semitransparente

---

## 9. RECICLAR FLOW (`/puntos/reciclar`)

**Archivo:** `lib/screens/puntos/reciclar_screen.dart` + `reciclar_view.dart`

### Layout — Multi-step con AnimatedSwitcher
```
Scaffold (bg #F8FAFC)
├── AppBar: "Reciclar y Acumular"
└── AnimatedSwitcher (fade + slide)
    └── Step según state._step (0-4)
```

### Step 0 — Scanning QR
```
Center
└── Column
    ├── "Escaneando Basurero" + subtítulo
    ├── Scanner box: 280×280, white bg, emerald border, esquinas decorativas (_buildCorner ×4)
    │   └── Láser animado con gradient + glow (Positioned animado)
    └── Indicador "Buscando basurero cercano..." con spinner
```

### Step 1 — Esperando IA
```
Center
├── _buildConnectedBanner(): "¡Basurero Conectado!" + bin ID + punto verde pulsante
├── Círculo azul con icono psychology (animación scale pulse)
├── "Analizando con IA..."
├── Subtítulo
└── Contador "Intento X/Y" con spinner
```

### Step 2 — Confirmación
```
SingleChildScrollView
├── _buildConnectedBanner()
├── [IA mode] _buildIADetectionCard():
│   ├── Imagen (base64) opcional
│   ├── Círculo con icono del tipo detectado + badge IA
│   ├── "🤖 Detectado por IA" badge
│   ├── Nombre del tipo (grande, color)
│   ├── "Confianza: XX%" + barra LinearProgressIndicator
│   └── Row: [_ActionChip "Cambiar manual"] [_ActionChip "Tomar otra foto"]
├── [Manual mode] Dropdown de materiales + puntos por unidad
├── Selector de cantidad:
│   ├── _QuantityButton (-) white bg, emerald border, hover effect
│   ├── Número grande
│   └── _QuantityButton (+)
└── _GradientButton "Confirmar Clasificación IA" / "Confirmar Depósito"
```

### Step 3 — Submitting
```
Center: círculo con spinner + "Registrando reciclaje..." + texto secundario
```

### Step 4 — Success
```
Center
├── Círculo con check (animación elasticIn)
├── "¡Reciclaje Completado!"
├── "Has acumulado con éxito:"
├── Badge "+X EcoPuntos" (gradiente emerald)
└── _GradientButton "Volver al Panel" (dark gradient)
```

### Componentes Reutilizables en reciclar_view.dart:
- `_QuantityButton`: +/− circular con hover (bg emerald 10% → 20%)
- `_ActionChip`: botón secundario con icono, borde, hover bg
- `_GradientButton`: botón gradiente premium con hover lift + glow
- `_buildCorner()`: esquinas L para el visor QR
- `_buildConnectedBanner()`: banner de conexión exitosa
- `_buildIADetectionCard()`: card de resultado de IA

---

## 10. CANJEAR PREMIOS (`/puntos/canjear`)

**Archivo:** `lib/screens/puntos/canjear_screen.dart` + `canjear_view.dart`

### Layout
```
Scaffold (bg #F8FAFC)
├── AppBar: "Canjear EcoPuntos"
└── [loading] spinner
    └── [content] Stack
        ├── Column
        │   ├── _buildPointsBanner(): gradient verde, icono eco, "Tus EcoPuntos", número, badge "pts"
        │   └── Expanded
        │       ├── [empty] _buildEmptyState(): icono gift, "Sin recompensas"
        │       ├── [desktop] GridView (2 cols, aspect 1.6)
        │       └── [mobile] ListView
        │           └── _RecompensaCard × N
        └── [submitting] Overlay semitransparente con spinner
```

### Componente `_RecompensaCard` (StatefulWidget con hover)
```
AnimatedContainer (hover: translateY -8px, borde emerald, glow)
├── ClipRRect top: imagen (NetworkImage) o fallback icon gift
├── Padding
│   ├── Row: nombre (bold) + badge costo "X pts" (emerald bg)
│   ├── Descripción (max 2 líneas)
│   └── Row: stock indicator + _CanjearButton
```

### Componente `_CanjearButton`
- Gradient emerald (hover: más claro), disabled: gris
- Hover: translateY -1.5px, glow
- Cursor: forbidden si no se puede canjear

---

## 11. HISTORIAL DE RECICLAJE (`/puntos/historial-reciclaje`)

**Archivo:** `lib/screens/puntos/reciclaje_historial_screen.dart` + `reciclaje_historial_view.dart`

### Layout
```
Scaffold (bg #F8FAFC)
├── AppBar: "Historial de Reciclaje" + refresh _HoverIconButton
├── [loading] spinner
└── [content] RefreshIndicator > CustomScrollView
    ├── SliverToBoxAdapter > KPIs
    │   ├── "Resumen" label
    │   └── Row: 3× _KpiCard
    │       ├── KPI 1: eco icon, "EcoPuntos Ganados" (emerald)
    │       ├── KPI 2: recycling icon, "Reciclajes Realizados" (blue)
    │       └── KPI 3: star icon, "Material Favorito" (amber)
    └── SliverPadding > SliverList
        ├── "Actividad reciente" label
        └── _HistorialItemCard × N
```

### Componentes:
- `_KpiCard`: icono en círculo pequeño, valor grande, label small, color accent. Animación cascade fade+slide.
- `_HistorialItemCard`: row con icono de material (color según tipo: azul plástico, purple papel, cyan vidrio, amber metal), descripción, fecha, badge "+X pts" verde. Hover: bg del icono más intenso, borde coloreado. Animación cascade.
- `_HoverIconButton`: icono redondo con hover bg semitransparente

---

## 12. HISTORIAL DE CANJES (`/puntos/historial-canjes`)

**Archivo:** `lib/screens/puntos/canjes_historial_screen.dart` + `canjes_historial_view.dart`

### Layout
```
Scaffold (bg #F8FAFC)
├── AppBar: "Historial de Canjes" + refresh
├── [loading] spinner
├── [empty] icono shopping_bag + "No tienes canjes registrados aún."
└── [content] RefreshIndicator > ListView
    └── Items (inline, sin componente separado)
        ├── Círculo rojo con icono remove
        ├── Nombre recompensa (bold)
        ├── Fecha formateada
        ├── Badge de estado (PENDIENTE/APROBADO/RECHAZADO — color dinámico)
        └── Texto rojo "-X pts"
```

---

## 13. ADMIN PANEL (`/admin`)

**Archivo:** `lib/screens/admin/admin_screen.dart` + `admin_view.dart`

### Layout
```
Scaffold (bg #0F172A — dark)
├── AppBar: back arrow, "Panel de Administración"
└── Column (padding 24px)
    ├── _buildAdminCard("Gestión de Basureros", desc, icon delete, emerald)
    └── _buildAdminCard("Gestión de Puntos", desc, icon stars, emerald)
```

### Componente `_buildAdminCard`
- Container bg blanco 5%, borde blanco 10%, border radius 16px
- Icon container con bg emerald 20%
- Título blanco, subtítulo blanco 60%
- Chevron_right al final
- InkWell con border radius

---

## 14. ADMIN BASUREROS (`/admin/basureros`)

**Archivo:** `lib/screens/admin/admin_basureros_screen.dart` + `admin_basureros_view.dart`

### Layout
```
Scaffold (bg #0F172A — dark)
├── AppBar: back arrow, "Gestión de Basureros"
├── [loading] spinner
├── [empty] icono delete + "No hay basureros registrados."
├── [content] RefreshIndicator > ListView
│   └── _buildBasureroCard(b, isActive, status) × N
│       ├── Círculo: verde (activo libre), naranja (activo ocupado), rojo (inactivo)
│       ├── public_id (bold white)
│       ├── Ubicación (white 60%)
│       └── Row: badge "ACTIVO"/"INACTIVO" + badge "LIBRE"/"OCUPADO"
└── FAB "Nuevo Basurero" (emerald, + icon)
```

### Formulario Creación (BottomSheet)
- TextField para nombre/ID
- TextField para ubicación
- Botón "Crear Basurero" (emerald)

---

## PATRONES GLOBALES DE UI

### Paleta de Colores

| Token | Hex | Uso |
|-------|-----|-----|
| Emerald Primary | `#10B981` | Botones, links, acentos |
| Emerald Light | `#34D399` | Hover states |
| Emerald Dark | `#059669` | Gradientes oscuros |
| Emerald Deep | `#047857`, `#065F46` | Cards de puntos |
| Slate 900 | `#0F172A` | Texto principal, fondos dark |
| Slate 600 | `#475569` | Texto cuerpo |
| Slate 400 | `#64748B` | Texto secundario |
| Slate 200 | `#E2E8F0` | Bordes, divisores |
| Slate 100 | `#F1F5F9` | Input fill |
| BG Light | `#F8FAFC` | Fondos de pantalla |
| White | `#FFFFFF` | Cards, fondos |
| Blue | `#3B82F6` | IA, plástico, features |
| Purple | `#8B5CF6` | Papel, dashboard |
| Amber | `#F59E0B` | Metal, badges |
| Indigo | `#6366F1` | Admin |
| Cyan | `#06B6D4` | Vidrio |
| Red | `#EF4444` | Errores |

### Tipografía
- **Font Family:** Poppins (Google Fonts)
- **Escala:** display (56/42/32px), headline (28/22/18px), title (16px), body (16/14/12px), label (14px)
- **Weights:** 900 (black), 800 (extra-bold), 700 (bold), 600 (semibold), 500 (medium)

### Input Fields (patrón consistente)
```
filled: true
fillColor: #F1F5F9
borderRadius: 14px
enabledBorder: #E2E8F0
focusedBorder: #10B981 (1.5px)
errorBorder: redAccent
prefixIcon: color #475569
label: color #475569
```

### Cards (patrón consistente)
```
bg: white
borderRadius: 24px (a veces 20px, 16px)
border: 1px #E2E8F0
boxShadow: sutil (2-4% black)
```

### Botones
```
Primary: bg #10B981, white text, bold, radius 14-16px, padding vertical 16px
Outline: border #10B981, transparent bg
Hover: lift -2px, glow intensificado
Disabled: 50% opacity
Loading: CircularProgressIndicator white
```

### Animaciones
- **Package:** `flutter_animate` (default 400ms)
- **Hover:** translateY lift, shadow glow, border color change, bg opacidad
- **Entrada:** fadeIn + slideY/slideX con cascade delay
- **Éxito:** elasticIn scale
- **Pulsos:** scaleXY repeat (reverse)
- **Scanner:** laser line animado con Positioned + AnimationController

### Responsive Breakpoints
- **Desktop:** > 900px (layouts side-by-side, grid 2 cols)
- **Tablet:** 600-900px
- **Mobile:** < 600px (stacked, list 1 col)
- Cards de auth: maxWidth 450-500px centrados
