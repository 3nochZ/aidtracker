# Prompt: Qelem Training — Elegant MSME Skilling Marketplace (Frontend Only)

Create a **modern, elegant, mobile-first, production-ready frontend UI** for:

# **Qelem Training**

### *Ethiopia’s First Skill-Building Marketplace for MSMEs*

Qelem MSME Skilling and Literacy Marketplace connects small and medium-sized enterprises (MSMEs) with trusted experts.

This is **not a blog**.
This is a **premium skill-building platform landing page + authentication interface**.

The design must feel:

* Calm
* Refined
* Trustworthy
* Spacious
* Premium SaaS-level
* Typography-driven
* Illustration-enhanced
* Investment-ready

---

# 1 Core Requirements

* Frontend only (no backend logic required)
* Fully responsive
* **Mobile-first priority**
* Elegant SaaS aesthetic
* Clean whitespace-focused layout
* Professional but warm
* Designed for Ethiopian MSMEs but globally refined

---

# 2 Color System (STRICTLY BASED ON PROVIDED VARIABLES)

Use CSS variables and build a theme system from:

```css
:root {
  --background: hsl(0 0% 100%);
  --popover: hsl(0 0% 100%);
  --primary: hsl(192 93% 17%);
  --secondary: hsl(24 88% 54%);
  --muted: hsl(210 40% 96.1%);
  --accent: hsl(24 88% 54%);
  --destructive: hsl(0 84.2% 60.2%);
  --border: hsl(214.3 31.8% 91.4%);
}
```

### Background

* Majorly off-white between white and beige
* Soft warm tone allowed
* Very airy and calm

### Color Usage Rules

* Primary (deep teal) → main CTAs, logo emphasis, important elements
* Secondary/Accent (warm orange) → highlights, hover states, interactive emphasis
* Muted → subtle section backgrounds
* Border → subtle dividers only
* Destructive → form validation errors
* Avoid heavy gradients
* Avoid oversaturation
* Maintain WCAG contrast compliance

---

# 3 Dark Mode Support

Must include:

* Theme toggle in navbar
* Smooth 250ms transition
* Dark mode derived from primary hue (deep teal/navy background)
* Avoid pure black
* Accent remains warm orange
* Preserve elegance and readability
* Use CSS variables for switching

---

# 4 Typography (Google Fonts ONLY — Never system fonts)

Use refined, calm Google Fonts.

Headings:

* Elegant serif (e.g., Playfair Display, Cormorant Garamond, or similar premium serif)

Body:

* Clean modern sans-serif (e.g., Inter, Manrope, or similar)

Typography standards:

* Clear hierarchy
* Responsive scaling using clamp()
* Line height: 1.6–1.8
* Slight letter spacing for headings
* Max reading width 65–75 characters
* Typography is a core design element (minimal decorative elements)

---

# 5 Layout Structure (Mobile-First Priority)

Design mobile layout first, then enhance for tablet and desktop.

---

## Sticky Navbar

Mobile:

* Logo text: “Qelem Training”
* Hamburger menu
* Dark mode toggle icon
* Language selector icon

Desktop:

* Horizontal nav
* Links:

  * Home
  * Explore
  * About
  * Sign In
  * Sign Up (Primary CTA styled)
* Elegant language dropdown
* Theme toggle

Subtle shadow on scroll.

---

## Hero Section

Mobile:

* Centered layout
* Large refined headline
* Short compelling subtitle
* Primary CTA: “Explore Skills”
* Secondary CTA: “Become an Expert”
* Undraw illustration below text

Desktop:

* Split layout (text left, illustration right)

Illustration:

* From undraw.co
* Education / collaboration / business growth theme
* Soft modern vector
* Adjust colors to match primary & accent palette
* Lazy loaded

Spacing:

* Generous padding
* Calm composition

---

## How It Works Section

Three vertically stacked cards (mobile)
Three columns (desktop)

Each card includes:

* Small undraw-style illustration
* Short title
* Short refined description
* Subtle hover elevation
* Soft shadow
* Border radius 10–12px

Topics:

1. Discover Skills
2. Learn in Your Language
3. Connect with Trusted Experts

---

## Language Selection (Elegant Custom Dropdown)

Languages:

* ENGLISH
* AMHARIC
* AFAAN_OROMO
* TIGREGNA
* AF_SOMALI
* AFUU_SIDAMA

Requirements:

* Custom styled dropdown (NOT native select)
* Keyboard accessible
* Smooth animation
* Clean popover background
* Subtle border
* Elegant SVG arrow indicator
* Mobile-friendly tap targets
* Reflect selected language in UI state

---

## Courses Section

Include section container labeled:

“Courses”

Leave it intentionally empty.
No placeholders.
No dummy cards.
Clean spacing and structural layout only.

---

## Authentication Pages (Separate Layout)

### Login Page

Mobile-first design:

* Illustration at top
* Form below in soft card

Desktop:

* Split screen (illustration left, form right)

Fields:

* Email
* Password
* Forgot password link
* Login button
* Link to Sign Up

Design:

* Soft shadow
* Border radius 10–12px
* Focus animations
* Destructive color for validation errors
* Accessible labels

---

### Sign Up Page

Same layout pattern.

Fields:

* Full Name
* Email
* Password
* Confirm Password
* Language preference dropdown
* Create Account button
* Link to Sign In

Micro-interactions:

* Smooth focus transitions
* Subtle border glow on active input
* Accessible error states

Include undraw illustration related to:

* Growth
* Online learning
* Professional development

---

# 6 Design System Standards

Spacing:

* 8px grid system

Components:

* Button variants (primary, secondary, outline, ghost)
* Card component
* Input component
* Dropdown component
* Toggle switch
* Navigation component

UI Details:

* Border radius 8–12px
* Very subtle shadows
* 200–300ms ease transitions
* No flashy effects
* Minimal borders
* Inline SVG icons only

---

# 7 Accessibility

* Semantic HTML5
* ARIA attributes
* Keyboard navigable dropdown
* Visible focus states
* Proper contrast ratios
* Screen-reader friendly
* Alt attributes for illustrations

---

# 8 Performance & Best Practices

* Semantic HTML
* CSS variables
* CSS Grid + Flexbox
* Mobile-first media queries
* Lazy load illustrations
* Optimized SVGs
* Minimal JavaScript
* Lighthouse optimized
* SEO meta tags
* Clean folder structure
* Reusable components
* No unnecessary dependencies

---

# 9 Deliverables

Generate:

* Structured HTML
* Clean modular CSS
* Organized sections with comments
* Theme toggle logic
* Language dropdown logic
* Authentication layouts
* Responsive design
* Production-ready structure
* No placeholder course content

---

# Final Result Expectation

The final UI should feel like:

* A premium Ethiopian EdTech startup
* Elegant but not flashy
* Calm and trustworthy
* Illustration-enhanced but not cartoonish
* Mobile-first excellence
* Comparable in polish to modern SaaS platforms
* Ready for investor demo
