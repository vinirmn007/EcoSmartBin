---
trigger: always_on
---

# UI_IMPLEMENTATION_RULES.md

# Reglas de Implementación de la Interfaz - EcoSmartBin

## Objetivo

El objetivo es modernizar completamente la interfaz visual de **EcoSmartBin** utilizando el Design System generado en Stitch.

La arquitectura actual ya es funcional y estable.

**No se debe reconstruir la aplicación.**

La implementación debe limitarse exclusivamente a la capa de presentación (UI).

---

# Restricción Principal

La lógica del proyecto ya funciona correctamente.

**No modificar ninguna lógica de negocio.**

Toda modificación debe realizarse únicamente sobre la presentación visual.

---

# Arquitectura

Existe un único proyecto Flutter.

Existe una única implementación.

Existe una única lógica.

Existe un único flujo de navegación.

No crear una aplicación paralela.

No recrear pantallas desde cero.

La implementación debe integrarse sobre el proyecto existente.

---

# NO modificar

Bajo ninguna circunstancia modificar:

- Arquitectura del proyecto
- Organización de carpetas
- GoRouter
- Riverpod / Provider
- Services
- Repositories
- Models
- DTOs
- API
- HTTP Requests
- Supabase
- Firebase
- Controllers
- Estados
- Providers
- Business Logic
- Validaciones
- Autenticación
- Roles
- Permisos
- Dependencias existentes
- Flujo de datos
- Variables de negocio
- Funciones existentes
- Métodos públicos
- Endpoints
- Rutas
- Nombres de archivos
- Nombres de clases

La aplicación ya funciona.

No debe alterarse su comportamiento.

---

# Sí modificar

Está permitido modificar únicamente:

- Widgets
- Layouts
- Componentes visuales
- Colores
- Tipografía
- Espaciados
- Bordes
- Sombras
- Glassmorphism
- Gradientes
- Animaciones
- Iconografía
- ThemeData
- Componentes reutilizables
- Responsive visual

---

# Filosofía

La lógica existente debe verse como una API.

La nueva interfaz debe consumir exactamente esa misma lógica.

No cambiar el comportamiento.

Solo cambiar la experiencia visual.

---

# Regla de Oro

Si actualmente existe:

```dart
controller.login();
```

Debe seguir existiendo exactamente:

```dart
controller.login();
```

No modificar:

- parámetros
- callbacks
- nombres
- providers
- estados

Únicamente cambiar el Widget que ejecuta esa acción.

---

# Responsive

Toda la aplicación seguirá siendo un único proyecto Flutter.

El código ubicado en **lib/** será utilizado tanto para Android, iOS, Web y Desktop.

No crear proyectos separados.

No duplicar lógica.

No crear versiones independientes para móvil y escritorio.

Cuando una pantalla requiera adaptarse a un tamaño diferente, únicamente debe cambiar el **layout**, manteniendo exactamente los mismos Widgets funcionales, Providers, Controllers y lógica.

Ejemplo:

- Mobile → Layout tipo Stitch.
- Tablet → Reorganización del contenido.
- Desktop → Mayor aprovechamiento del espacio.

La lógica debe ser exactamente la misma.

---

# Adaptación de Layout

Las pantallas generadas en Stitch son la referencia para dispositivos móviles.

En escritorio NO copiar literalmente el diseño móvil.

Se debe conservar:

- identidad visual
- colores
- tipografía
- componentes
- animaciones
- glassmorphism

Pero reorganizando los elementos para aprovechar pantallas grandes.

Ejemplos:

- Grid responsive.
- Sidebar cuando aporte valor.
- Más columnas.
- Tarjetas más grandes.
- Tablas administrativas.
- Paneles laterales.

Nunca modificar la funcionalidad.

---

# Componentes reutilizables

Antes de modificar pantallas, construir un pequeño Design System reutilizable.

Ejemplos:

- GlassCard
- PosterCard
- PremiumButton
- FloatingBottomNavigation
- PremiumSearchBar
- GradientCard
- AnimatedStatCard
- StatusBadge
- SectionHeader
- FloatingActionButtonPremium
- BlurDialog
- PremiumBottomSheet
- MetricCard
- UserAvatar
- EmptyState
- LoadingView
- ErrorView

Todos los componentes deben reutilizarse.

Evitar duplicación de código.

---

# Theme

Centralizar todos los estilos.

Crear únicamente si aún no existen:

- AppColors
- AppGradients
- AppTypography
- AppSpacing
- AppRadius
- AppShadows
- AppAnimations

No repetir colores hardcodeados.

Todo debe provenir del Theme.

---

# Animaciones

Se permiten únicamente animaciones de interfaz.

Ejemplos:

- AnimatedContainer
- AnimatedSwitcher
- Hero
- Fade
- Scale
- Slide
- Blur
- Glow
- Ripple
- Implicit Animations

Las animaciones nunca deben modificar lógica.

---

# Código

Priorizar:

- Clean Code
- SOLID
- Componentización
- Reutilización
- Widgets pequeños
- Separación de responsabilidades

Evitar Widgets gigantes.

Evitar código duplicado.

---

# Refactorización Permitida

Está permitido:

- Extraer Widgets
- Crear Widgets reutilizables
- Reorganizar Layouts
- Mejorar nombres de variables locales de UI
- Unificar componentes repetidos
- Mejorar la estructura visual

No está permitido:

- Cambiar lógica
- Cambiar flujo de datos
- Cambiar Providers
- Cambiar Controllers
- Cambiar navegación
- Cambiar APIs

---

# Antes de implementar

Antes de escribir código:

1. Analizar completamente el proyecto.
2. Comprender la arquitectura existente.
3. Identificar componentes repetidos.
4. Detectar oportunidades de reutilización.
5. Revisar el Design System generado en Stitch.

Solo después comenzar la implementación.

---

# Flujo esperado

Para cada pantalla:

1. Analizar la implementación actual.
2. Comprender la lógica existente.
3. Mantener toda la lógica intacta.
4. Extraer componentes reutilizables si es necesario.
5. Reemplazar únicamente la interfaz por el nuevo diseño.
6. Adaptar el layout para Mobile, Tablet y Desktop cuando corresponda.
7. Verificar que la funcionalidad permanezca idéntica.

---

# Criterio de aceptación

La implementación será correcta únicamente si:

- La aplicación conserva exactamente el mismo comportamiento.
- Todas las funcionalidades siguen operativas.
- No cambia ninguna integración.
- No cambia ninguna API.
- No cambia ninguna navegación.
- No cambia ninguna lógica.
- Existe un único código fuente para todas las plataformas.
- La interfaz utiliza el Design System definido en Stitch.
- El layout se adapta correctamente a Mobile, Tablet y Desktop sin duplicar lógica.
- El resultado final transmite una experiencia visual moderna, premium y consistente en todas las plataformas.