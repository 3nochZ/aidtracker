# Contrast and responsiveness

You are improving the visual hierarchy and clarity of a dark-themed course dashboard UI.

## Problem

The following elements look dull and lack clear distinction:

* Page title ("Welcome to the Course")
* Subtitle ("5 min read")
* Sidebar course title ("Mastering MSME Growth")
* Sidebar description
* Section headings
* Lesson selections
* Current/active lesson state

The design must:

* Maintain the dark teal theme
* Improve clarity and crispness
* Strengthen hierarchy
* Make the active lesson immediately recognizable
* Avoid overusing bright colors
* Keep it elegant and modern (not flashy)

---

## Design Goals

### 1 Title & Subtitle (Main Content Area)

* Increase contrast and weight of the main title.
* Make it clearly dominant.
* Subtitle should be visually secondary but still readable.

**Adjustments:**

* Title: larger size, stronger weight (600–700), brighter foreground
* Subtitle: smaller, muted but higher contrast than current
* Add subtle letter-spacing for polish

---

### 2 Sidebar Course Title & Description

* Course title should be clearly distinguishable from section headings.
* Description should be muted but readable.

**Adjustments:**

* Course title: medium-bold, slightly brighter than body text
* Description: smaller font size, increased contrast from background

---

### 3 Section Headings

* Currently too similar to lessons.
* Should feel like dividers.

**Adjustments:**

* Smaller uppercase
* Increased letter-spacing
* Muted but distinct color
* Slight margin spacing above & below

---

### 4 Lesson Items (Critical Fix)

Improve:

* Hover state
* Default state
* Active state (very important)
* Icon visibility

#### Default lesson

* Medium contrast text
* Subtle hover background

#### Hover state

* Soft surface elevation (lighter dark shade)
* Slight left padding animation (2–4px shift)

#### Active lesson (must stand out clearly)

Use one of the following patterns:

Option A (Recommended – elegant and modern):

* Soft glowing left border (3px accent color)
* Slightly lighter background
* Stronger font weight (600)
* Accent-colored icon
* Subtle shadow or inset glow

Option B:

* Pill-style background highlight
* Accent text color
* Bold weight

Avoid:

* Harsh neon colors
* Full bright backgrounds
* Pure white text blocks

---

## Color Adjustments

Keep the dark teal palette but refine contrast levels:

* Background: keep base
* Surfaces: slightly lighter shade for hover
* Text hierarchy:

  * Primary: high contrast (near-white but not #fff)
  * Secondary: 70–80% opacity
  * Muted: 55–65% opacity
* Accent: use existing secondary color (orange tone) sparingly for active state and progress

---

## Micro-Interactions

Add subtle polish:

* Smooth transitions (150–200ms ease)
* Progress bar glow or gradient
* Slight scaling (1.01–1.02) on hover for lesson items

---

## Implementation Notes

* Use CSS variables where possible
* Maintain accessibility (minimum WCAG AA contrast)
* Do not change layout structure
* Only improve typography, spacing, color contrast, and state styling

Return:

1. Updated CSS
2. Any minimal JSX/HTML adjustments needed
3. A short explanation of why the hierarchy now works better




Implementation Plan - Course View Responsiveness Fixes
Address UI breakage on screens under 600px, specifically for quiz options and lesson navigation buttons.

Proposed Changes
[Quiz Block]
[MODIFY] 
quiz-block.tsx
Ensure quiz option text wraps correctly on narrow screens by refining the flex layout within the buttons.
Adjust padding and spacing to ensure icons don't squash the text.
[Lesson Viewer]
[MODIFY] 
lesson-viewer.tsx
Transform the bottom action bar into a responsive flex container.
On screens < 640px (sm), stack the buttons vertically with full width.
On larger screens, maintain the current horizontal "justify-between" layout.
Ensure proper margin/gap between stacked buttons.
Verification Plan
Manual Verification
Launch the browser and navigate to the Course Dashboard.
Open a lesson with a quiz and long option text.
Test Mobile View (e.g., 375px width):
Verify quiz options are fully visible and text wraps within the boxes.
Verify "Previous", "Mark as Complete", and "Next Lesson" buttons stack vertically and are full-width.
Verify there's no horizontal scroll.
Test Desktop View:
Verify layout remains horizontal and clean as before.


