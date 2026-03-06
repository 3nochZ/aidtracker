add the proper illustations to the pages.
edit /home/enoch/kifiya/qelem-training/src/illustrations/undraw_career-progress_growth.svg to landing page
edit src/illustrations/undraw_sign-in.svg to sign in page
and src/illustrations/undraw_welcoming_sign-up.svg to sign up page

there's already dedicated space for them. you job is just to edit.

## Implemenation Plan

Implementation Plan - Add Illustrations to Pages
This plan outlines the steps to replace placeholder illustrations with professional SVG files on the landing, login, and signup pages.

Proposed Changes
Illustrations
[MODIFY] 
landing-page.tsx
Import 
undraw_career-progress_growth.svg
 from @/illustrations/undraw_career-progress_growth.svg.
Replace the placeholder https://placehold.co/... image with the imported illustration.
Ensure the styling remains consistent with the "Undraw" aesthetic.
[MODIFY] 
login-page.tsx
Import 
undraw_sign-in.svg
 from @/illustrations/undraw_sign-in.svg.
Replace the placeholder with an img tag using the imported illustration.
Style the image to fit the container while maintaining its aspect ratio.
[MODIFY] 
signup-page.tsx
Import 
undraw_welcoming_sign-up.svg
 from @/illustrations/undraw_welcoming_sign-up.svg.
Replace the placeholder with an img tag using the imported illustration.
Style the image to fit the container while maintaining its aspect ratio.
Verification Plan
Manual Verification
Landing Page: Open the landing page in the browser and verify that the "Growth Illustration" is displayed correctly in the hero section.
Login Page: Navigate to the login page and verify that the "Sign In" illustration is visible on the left side (on large screens).
Signup Page: Navigate to the signup page and verify that the "Sign Up" illustration is visible on the left side (on large screens).
Responsiveness: Verify that the illustrations scale correctly or are hidden appropriately on smaller screens as per the existing layout.