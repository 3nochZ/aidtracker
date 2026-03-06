```markdown
AI App Generator Prompt — Course Structure + Progress System

Design and implement a modular course learning interface that integrates into the existing elegant white/beige blog design system.

Focus strictly on:
- Course structure
- Lesson composition
- Quizzes and questions
- Flexible content blocks
- Progress tracking system
- Clean UX hierarchy

1 Course Architecture (Data & UI Model)
The course structure must support the following hierarchy:
Course
 ├── Sections (optional grouping)
 │     ├── Lessons
 │     ├── Quizzes
 │     ├── Standalone Questions
 │     └── Mixed Content Blocks

Section Core Rules
A course may contain:
- Sections (optional)
- Lessons
- Quizzes
- Standalone questions
- A section does NOT strictly require a title.
- A lesson does NOT strictly require a title.
- Only text explanation is mandatory.
- All other content types are optional and modular.

2 Lesson Content Block Structure
Each lesson must support flexible content composition.
Required:
- text explanation (rich formatted text)
Optional:
- Title
- Video (embedded or hosted)
- Audio
- Image / illustration
- Code snippet (if relevant)
- Downloadable resources
- Quiz
- Reflection questions
Lessons must allow:
- Any order of content blocks
- Any combination of optional elements
- Reusability of block components

3 Quiz & Question System
The course must support:
Quiz Structure
A quiz may contain:
- Optional title
- Multiple questions
- Instant feedback option
- Completion scoring
Question Types Supported:
- Multiple choice (single answer)
- Multiple select
- Short text answer
- True / False
Each question should support:
- Question prompt
- Optional explanation after answer
- Optional hint
- Correct answer indicator

4 Standalone Questions
Outside of quizzes, the course should support:
- Reflection questions
- Open-ended thinking prompts
- Practice exercises
These do not require scoring.

5 Progress Tracker (Elegant + Minimal)
Design a refined, modern progress tracking system:
Section Course-Level Progress
- Percentage completion
- Horizontal progress bar
- Smooth animation on update
- Subtle rounded edges
- Soft accent highlight (same brand accent)
Section Section-Level Progress
- Collapsible sidebar outline
- Visual indicators:
  - Completed
  - In progress
  - Not started
Section Lesson-Level Progress
- Auto-mark complete when:
  - User scrolls through content
  - Or clicks “Mark as Complete”
- Include:
  - Persistent progress (localStorage or backend-ready structure)
  - Elegant animated transitions
  - Micro-interactions on completion

6 UI Layout Structure
Desktop Layout
- Left Sidebar:
  - Course outline
  - Sections
  - Lessons
  - Quizzes
  - Visual progress indicators
- Main Content Area:
  - Clean reading container
  - 65–75ch readable width
  - Generous vertical rhythm
  - Elegant typography hierarchy
- Right Floating UI (optional):
  - Next lesson shortcut
  - Completion toggle
Mobile Layout
- Collapsible top progress bar
- Slide-in outline panel
- Sticky "Next" button
- Smooth transitions

7 Component Design Standards
Follow modern industry standards:
- Modular component architecture
- Reusable lesson block components
- Accessible semantic structure
- ARIA labels for quizzes
- Keyboard navigation
- Focus states
- Smooth motion (200–350ms easing)
- Avoid heavy shadows
- Use subtle depth only where necessary

8 UX Behavior Requirements
- Scroll-based progress detection
- Smooth animated transitions between lessons
- Preserve user scroll position when navigating
- Soft fade transitions for content
- Elegant empty states for:
  - No quiz
  - No media
  - No sections

9 Design Tone
Maintain:
- White or beige background
- Clean academic elegance
- Calm, focused reading experience
- Zero clutter
- Sophisticated micro-interactions
Think:
“Minimal learning platform built for clarity, not distraction.”

A user must access the courses after log in. So for now, make the page accessible using /courses endpoint only.
```