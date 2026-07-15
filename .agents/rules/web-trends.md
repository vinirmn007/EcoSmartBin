---
trigger: manual
---

---

# Modern Web Design Trends (Agent Guidelines)

These trends should inspire the UI, but **must always prioritize usability, accessibility, responsiveness, and performance**. Use them when they enhance the user experience—not simply because they are visually impressive.

---

## 1. 3D & Immersive Experiences

Create depth and immersion using modern rendering techniques.

Possible implementations:

- Interactive 3D objects
- Scroll-triggered animations
- Layered depth
- Perspective transforms
- Floating elements
- Interactive product previews
- Subtle parallax
- AR-inspired visualizations (when appropriate)

Guidelines:

- Never make the interface difficult to navigate.
- Keep frame rates smooth.
- Always provide a fallback for unsupported devices.
- Decorative 3D should never block content.
- Use only when it improves storytelling or product understanding.

Flutter techniques:

- Matrix4 transforms
- CustomPainter
- Rive
- Lottie
- Fragment shaders
- InteractiveViewer
- MouseRegion

---

## 2. Experimental Navigation

Navigation does not always need to follow a traditional navbar layout.

Possible navigation styles:

- Floating navigation
- Radial menus
- Sidebar drawers
- Section-based navigation
- Interactive maps
- Full-screen navigation
- Scroll-driven navigation
- Contextual menus

Guidelines:

- Users must never feel lost.
- Always provide a clear path back.
- Maintain discoverability.
- Navigation should prioritize usability over novelty.

---

## 3. Vibrant Color Palettes

Use bold, energetic color systems when appropriate.

Examples:

- Neon gradients
- High-contrast palettes
- Dopamine-inspired colors
- Retro-inspired colors
- Vibrant accent colors

Guidelines:

- Maintain accessibility.
- Preserve sufficient contrast.
- Use bright colors primarily as accents.
- Avoid overwhelming the interface.

---

## 4. Bold Typography

Typography should communicate personality.

Possible techniques:

- Oversized headlines
- Variable fonts
- Animated typography
- Kinetic typography
- Dynamic font pairing
- Layered text over imagery

Guidelines:

- Typography should remain readable.
- Maintain a clear visual hierarchy.
- Avoid excessive font families.
- Animation should support readability.

---

## 5. Dark Mode

Every application should support:

- Light Theme
- Dark Theme
- System Theme

Requirements:

- Maintain accessible contrast.
- Adapt illustrations and images.
- Ensure shadows and elevation work in both modes.
- Support smooth theme transitions.

---

## 6. Motion Design

Motion should guide users rather than distract them.

Recommended animations:

- Hover animations
- Page transitions
- Scroll reveals
- Fade
- Scale
- Slide
- Hero animations
- Microinteractions
- Loading animations
- State transitions

Animation principles:

- Ease in/out
- Natural timing
- Consistent duration
- Avoid excessive motion

Recommended packages:

- flutter_animate
- rive
- lottie

---

## 7. Gamification

Use gamification when it improves engagement.

Examples:

- Progress bars
- Achievement badges
- Streaks
- Rewards
- Levels
- Challenges
- Interactive onboarding
- Celebration animations

Guidelines:

- Never manipulate users.
- Rewards should feel meaningful.
- Gamification should enhance—not replace—good UX.

---

## 8. Neumorphism

Soft interfaces with subtle depth.

Characteristics:

- Soft shadows
- Raised surfaces
- Inset controls
- Rounded corners
- Minimal gradients

Use carefully.

Avoid reducing accessibility or button discoverability.

---

## 9. Retrofuturism

Blend nostalgic and futuristic aesthetics.

Possible elements:

- Chrome
- Neon
- Sci-fi gradients
- Pixel art
- Retro UI
- Futuristic fonts

Best suited for:

- Portfolios
- Entertainment
- Creative agencies
- Gaming
- Music

Avoid overusing decorative effects.

---

## 10. Maximalism

Rich visual storytelling through layered design.

Examples:

- Dense compositions
- Layered imagery
- Bold typography
- Rich color combinations
- Overlapping sections
- Decorative illustrations

Guidelines:

- Maintain strong hierarchy.
- Preserve whitespace where necessary.
- Organize complexity intentionally.

---

## 11. Collage Design

Creative scrapbook-inspired layouts.

Possible elements:

- Torn paper
- Stickers
- Handwritten notes
- Cutout photos
- Mixed media
- Layered graphics

Best suited for:

- Creative portfolios
- Lifestyle brands
- Editorial sites
- Fashion
- Art

Should appear intentional rather than chaotic.

---

# General Design Principles

Always prioritize:

- Visual hierarchy
- Readability
- Accessibility
- Responsiveness
- Performance
- Consistency
- Simplicity
- Smooth interactions

Every animation, visual effect, or experimental layout should have a purpose.

Avoid adding effects solely because they are visually impressive.

---

# Inspiration Sources

Draw inspiration from:

- Apple
- Stripe
- Vercel
- Linear
- Framer
- Notion
- OpenAI
- Raycast
- Arc Browser

Study:

- Layout
- Typography
- Motion
- Color
- Microinteractions
- Composition
- Navigation
- Spacing

Adapt their design principles rather than copying them.