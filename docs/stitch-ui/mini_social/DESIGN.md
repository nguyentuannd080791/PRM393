---
name: Mini Social
colors:
  surface: '#f8f9ff'
  surface-dim: '#d0daee'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff3ff'
  surface-container: '#e6eeff'
  surface-container-high: '#dfe9fc'
  surface-container-highest: '#d9e3f6'
  on-surface: '#121c2a'
  on-surface-variant: '#424656'
  inverse-surface: '#273140'
  inverse-on-surface: '#ebf1ff'
  outline: '#727687'
  outline-variant: '#c2c6d8'
  surface-tint: '#0054d7'
  primary: '#0050cd'
  on-primary: '#ffffff'
  primary-container: '#0866ff'
  on-primary-container: '#f9f7ff'
  inverse-primary: '#b3c5ff'
  secondary: '#575f6a'
  on-secondary: '#ffffff'
  secondary-container: '#dbe3f0'
  on-secondary-container: '#5d6570'
  tertiary: '#006646'
  on-tertiary: '#ffffff'
  tertiary-container: '#00825a'
  on-tertiary-container: '#e1ffec'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b3c5ff'
  on-primary-fixed: '#00184a'
  on-primary-fixed-variant: '#003fa5'
  secondary-fixed: '#dbe3f0'
  secondary-fixed-dim: '#bfc7d4'
  on-secondary-fixed: '#141c25'
  on-secondary-fixed-variant: '#3f4752'
  tertiary-fixed: '#88f8c4'
  tertiary-fixed-dim: '#6bdba9'
  on-tertiary-fixed: '#002114'
  on-tertiary-fixed-variant: '#005137'
  background: '#f8f9ff'
  on-background: '#121c2a'
  surface-variant: '#d9e3f6'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.015em
  title-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  title-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 22px
  body-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 18px
  label-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
  caption-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 16px
  caption-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style
The design system establishes a distilled, text-first social networking experience on Android that balances speed, cognitive clarity, and premium feel. Rejecting sensory overload, visual clutter, and media feeds, the product foregrounds human ideas, discourse, and lightweight typography.

The aesthetic is Modern Clean Android: crisp system-aligned ergonomics, structured vertical rhythms, high contrast between foreground thought and ambient canvas, and tactile card modules. The emotional intent is clarity, focus, and quiet confidence—transforming rapid social interactions into an uncluttered, distraction-free reading and posting space.

## Colors
The palette relies on deliberate contrast between functional blue accents and a cool, soft-tinted foundation.

- **Primary (`#0866FF`)**: The signature action blue. Applied strictly to primary actions, interactive focus rings, active navigation states, unread indicators, and the core brand mark.
- **Secondary / Soft Blue Surface (`#EAF2FF`)**: A delicate, high-tint blue container fill. Used for subtle category chips, active tab badges, replying indicators, and avatar container fills.
- **Tertiary / Success (`#15966A`)**: Organic green for confirmation states, follow feedback, and system status indicators.
- **Destructive (`#D92D20`)**: Crisp semantic red for deletions, blocking, report pathways, and error messaging.
- **Canvas & Surfaces**:
  - Page Background: `#F6F8FC` (cool-tinted off-white reducing eye strain).
  - Surface: `#FFFFFF` (elevated cards, bottom sheets, input modules, and top app bars).
- **Text & Hierarchy**:
  - Primary / Deep Text: `#182230` (high-readability, deep slate for headlines, post authors, and post body text).
  - Secondary Text: `#667085` (metadata, timestamps, subtle engagement numbers, and placeholders).
- **Borders & Dividers**: `#E4EAF2` (crisp hair-line structure separating content blocks without harsh visual noise).

## Typography
Inter delivers systematic density and vertical balance tailored for Android device viewports.

- **Screen Titles**: Bound to `headline-lg` (`24px/32px Bold`) on prominent root destinations and `headline-md` (`22px/28px Bold`) within dynamic sub-views.
- **Section Titles**: Scaled using `title-md` (`18px Semibold`) and `title-sm` (`16px Semibold`) to frame thread sections, profile divisions, and modal sheets.
- **Author Identity & Buttons**: Author handles and interactive buttons share `label-lg` (`15px Semibold`) and `label-md` (`14px Medium`) to create immediate visual anchoring above feed text.
- **Post Body**: Handled via `body-lg` (`15px Regular`) and `body-md` (`14px Regular`) with 1.45× line heights to preserve scanning rhythm across pure text posts.
- **Metadata & Counters**: Expressed through `caption-md` (`13px`) and `caption-sm` (`12px`) in secondary gray `#667085` to remain supportive without competing against primary thoughts.

## Layout & Spacing
Built upon a strict 8pt grid with a 4pt sub-grid for internal micro-alignments:

- **Horizontal Margins**: A fixed 16px (`1rem`) outer margin anchors standard Android handheld layouts. Content modules span the single mobile column edge-to-edge within these margins.
- **Feed Stream**: Post cards stack vertically with a constant 12px (`0.75rem`) or 16px (`1rem`) gap against the `#F6F8FC` canvas.
- **Internal Card Paddings**: Cards use uniform 16px internal padding, aligning author avatars, body copy, and interaction bars.
- **Chrome Constraints**: Standard Android status bar buffer (top system insets), a 56px top app bar, and a 64px bottom navigation bar with elevation anchoring the bottom edge.

## Elevation & Depth
Depth is constructed through subtle ambient shadows paired with low-contrast structural borders:

- **Level 0 (Canvas)**: Background surface `#F6F8FC` with zero elevation.
- **Level 1 (Card & Containers)**: Pure white `#FFFFFF` paired with a 1px solid border in `#E4EAF2` and an ambient shadow: `0 1px 3px rgba(24, 34, 48, 0.04), 0 2px 6px rgba(24, 34, 48, 0.02)`.
- **Level 2 (Persistent Floating Actions & Overlays)**: Pure white `#FFFFFF` with `0 4px 12px rgba(8, 102, 255, 0.12), 0 2px 4px rgba(24, 34, 48, 0.06)` for elements like the floating composer button or active dropdown menus.
- **Level 3 (Modal Sheets & Snackbars)**: Pure white `#FFFFFF` layered over a 32% black backdrop scrim with `0 12px 32px rgba(24, 34, 48, 0.16)`.

## Shapes
Geometry uses clean, balanced radii (`roundedness: 2` base with contextual scaling):

- **Brand Mark**: A 40px × 40px solid blue (`#0866FF`) rounded square using a 10px radius, housing a centered, stylized white letter 'M'.
- **Post Cards**: Scaled to 14px–16px corner radius (`rounded-lg` to `rounded-xl`), creating distinct, tactile message modules.
- **Buttons & Chips**: Form-level inputs and primary buttons adopt a 10px–12px radius; selection chips utilize full pill contours (`9999px`).
- **Avatars**: Strictly circular (`radius: 50%`), containing clean bold initials over `#EAF2FF` backgrounds.

## Components

### Top Bar & Brand Identity
- **App Bar**: 56px tall, background `#FFFFFF`, border-bottom 1px `#E4EAF2`. Contains the brand mark (blue rounded square with white 'M') on the left, an optional screen title (`20px Bold`), and contextual action icons (notifications, compose) on the right.

### Avatars (Text-Only Identity)
- Strict circular shapes (`36px` for feed posts, `48px` for profiles, `28px` for replies).
- Background: Soft blue `#EAF2FF`.
- Content: User's 1-2 character initials rendered in `#0866FF` (`14px Semibold` for cards, `18px Bold` for profiles). No raster images.

### Post Card
- Background `#FFFFFF`, 14px border radius, 1px border `#E4EAF2`, ambient Level 1 shadow.
- Header: Row displaying the avatar, followed by author name (`15px Semibold`, `#182230`), handle (`13px`, `#667085`), timestamp, and an options icon (`...`).
- Body: 15px line-height 22px deep slate text `#182230`, padding vertical 8px.
- Action Bar: Bottom row featuring lightweight interaction buttons (Reply, Repost, Like, Share) with count labels in `13px Medium` `#667085`.

### Buttons
- **Primary**: Solid `#0866FF` fill, `#FFFFFF` text, `14px Semibold`, height 44px, 10px radius. Active press state shifts to `#0652CC`.
- **Secondary / Ghost**: Outline 1px `#E4EAF2` or transparent container with `#0866FF` or `#182230` text.
- **Destructive**: Solid `#D92D20` or red text variant on transparent base.

### Input Fields & Composer
- **Input Field**: Height 44px, background `#FFFFFF`, 1px solid border `#E4EAF2`, 10px radius, label `13px Medium` `#182230` resting above input. Focus transitions border to `#0866FF` with a 2px outer tint glow.
- **Quick Composer**: Anchored input at the top of the feed or modal sheet, displaying user avatar and a placeholder "What's happening?" in `#667085`.

### Chips & Filters
- Height 32px, pill shape (`9999px`).
- Default state: Background `#FFFFFF`, border 1px `#E4EAF2`, text `#667085` (`13px Medium`).
- Active state: Background `#EAF2FF`, border 1px `#0866FF`, text `#0866FF` (`13px Semibold`).

### Bottom Navigation Bar
- Fixed 64px height, background `#FFFFFF`, 1px top border `#E4EAF2`.
- Four persistent destinations: **Home**, **Search**, **Friends**, **Profile**.
- Default icon/label: `#667085` with `11px Medium`. Active state: `#0866FF` with `11px Semibold` and an active indicator dot.
