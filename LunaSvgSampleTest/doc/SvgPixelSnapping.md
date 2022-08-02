# SVG Pixel Snapping / Grid Fitting

Dwayne Robinson 2022-07-28

## What

This document extends the SVG specification with elements and attributes for grid fitting/pixel snapping to improve rendering on low-resolution devices where details can become blurry and messy in toolbars, menus, and webpages. SVG is increasingly being used for iconography and smaller symbols, and despite tales of the demise of 96 DPI, such monitors persist to this day, with 1920x1080 being the most common monitor size in 2022. This specification is freely available to adopt without patent or copyright concern, but beware it's currently subject to change while I validate on the implementation details.

## Why

A picture speaks a thousand words...

TODO: Insert image showing problems. Include cases of: blurry lines, excess detail which becomes a blurry mess, detail collapse, minimum pixel distance, contour offset.

## How

SVG had some [previous pondering](https://www.w3.org/Graphics/SVG/WG/wiki/Proposals/SVG_hinting) on the problem, and [OpenType/TrueType typography](https://docs.microsoft.com/en-us/typography/opentype/spec/ttch01) already solved these problems decades ago for glyphs, but implementing a complex Turing complete programming language is overkill here (which would hamper adoption and likely increase software security risks), as the problems can be satisfied by a set of new elements and attributes for the following aspects:

1. Rounding points to pixels (e.g. rounding to nearest, floor, ceil)
2. Microadjustment transforms constructed from anchor points (e.g. translating and stretching entire shapes to the pixel grid)
3. Contour displaced offsets (e.g. thickening a path edge to whole pixels)
4. Geometric constraints between components (e.g. keeping two lines at least 1 pixel apart)
5. Shape visibility based on pixel density (e.g. selectively hiding complex geometry at low pixel resolutions)

- `<rounding/>` - controls how to round points, defined in `<defs>` and used later in adjustment attributes via `id`.
- `<anchor/>` - an invisible point to help align shapes to and construct microtransforms to adjust shapes. Anchors coordinates can be individually rounded and shared by multiple geometries for tiny translations and scaling. Anchors are typically defined soon before the shape they apply to via `id` in an adjustment attribute or an `anchorTransform`. 
- `<anchorTransform/>` - microtransform to nudge shapes or entire groups of shapes to the pixel grid, used in adjustment attributes via `id`. They can be built from 1 to 3 anchor points, depending on the type, and unlike ordinary transform attributes, they cannot accept arbitrary translation, scale, or rotation operations, as they are implicitly constructed by the small rounding adjustments to anchors.
- `<contourOffset/>` - displaces individual points along their normal vectors to expand or contract the contour. The new point is at the intersection of their displaced parallel lines/curves (usually along the angle bisector, not expansion of the less useful form here https://en.wikipedia.org/wiki/Expansion_(geometry) which just inserts new edge segments).
- `<constraint/>` - a minimum/maximum geometric relative distance from another point. Each axis can range independently, and the vector can be reoriented to other angles such as 45 degrees.
- `<transform/>` - defines a named transform for reuse by `id`, including the standard `scale`, `translate`, `rotate`, and `shear` operations, plus the new `origin` which is equivalent to `transform-origin` folded directly into the `transform`. Defined transforms may be used in any `transform` attribute, including those on normal geometry along with those in rounding and constraints.
- `<adjustments/>` - a reusable series of adjustments, including rounding, anchor transforms, contour offsets, and contraints, with each adjustment executed in order. Multiple adjustments can be separated by semicolons to form a list of adjustment groups, useful for `<path>` where each group of adjustments is referenced by index 0 to n-1. 

# Terms for bikeshed naming

- adjustment - Small alteration or movement made to achieve a desired fit, appearance, or result. (see [font-size-adjust](https://developer.mozilla.org/en-US/docs/Web/CSS/font-size-adjust))
- alignment - arrangement in a straight line, or in correct or appropriate relative positions. (see [text-align](https://developer.mozilla.org/en-US/docs/Web/CSS/text-align))
- anchor - Provide with a firm basis or foundation. A heavy object attached to a rope or chain and used to moor a vessel to the sea bottom. (see [text-anchor](https://developer.mozilla.org/en-US/docs/Web/SVG/Attribute/text-anchor)). *One downside is that Adobe Illustrator uses anchor point to mean *any* point along a curve, which could confuse graphic designers. -_-
- arrangement - Action, process, or result of arranging or being arranged.
- attachment - An extra part or extension that is or can be attached to something to perform a particular function.
- ballast - Heavy material, such as gravel, sand, iron, or lead, placed low in a vessel to improve its stability.
- binding - Material or device used to bind such as the cover and materials that hold a book together.
- buttress - Architectural structure built against or projecting from a wall which serves to support or reinforce the wall.
- contract - decrease in size, number, or range.
- constraint - geometric constraints specify a direction or a distance relative to existing geometry.
- contour - an outline, especially one representing or bounding the shape or form of something.
- delta - Difference between two things or values.
- difference - difference in mathis the result of subtracting one number from another.
- dilate - make or become wider, larger, or more open. (common binary image operation https://hcimage.com/help/Content/Quantitation/Measurements/Processing%20and%20Analysis/Modify/Copy%20of%20Binary_Operations.htm)
- displace - Cause (something) to move from its proper or usual place.
- displacement - The moving of something from its place or position. A vector whose length is the shortest distance from the initial to the final position of a point P. https://en.wikipedia.org/wiki/Displacement_(geometry)
- distance - numerical measurement of how far apart objects or points are.
- erode - gradually destroy or be gradually destroyed. (common binary image operation https://hcimage.com/help/Content/Quantitation/Measurements/Processing%20and%20Analysis/Modify/Copy%20of%20Binary_Operations.htm)
- expand - become or make larger or more extensive.
- fastener - Device that closes or secures something. Any of various devices, as a snap or hook and eye, for holding together two objects.
- fit - Fix or put (something) into place. be of the right shape and size for.
- fitment - Thing fitted to another in order to accomplish a specific purpose. The proper positioning and orientation of a thing for it to serve its designed purpose.
- fixture - Piece of equipment or furniture which is fixed in position in a building or vehicle.
- frame - Rigid structure that surrounds or encloses something such as a door or window.
- grapnel - Device consisting essentially of one or more hooks or clamps, for grasping or holding something.
- grow - become larger or greater over a period of time; increase.
- hook - Piece of metal or other material, curved or bent back at an angle, for catching hold of or hanging things on.
- interval - a space between two things; a gap.
- keypoint - Characteristic point of interest.
- node - Point at which lines or pathways intersect or branch; a central or connecting point.
- nudge - a light touch or push.
- orthogonal - of or involving right angles; at right angles.
- pillar - Tall vertical structure of stone, wood, or metal, used as a support for a building, or as an ornament or monument.
- project - Extend outward beyond something else; protrude.
- protrude - Extend beyond or above a surface.
- rig - Particular way in which a sailboat's masts, sails, and rigging are arranged.
- rigging - Network used for support and manipulation (as in theater scenery). The system of ropes, cables, or chains employed to support a ship's masts.
- shift - move or cause to move from one place to another, especially over a small distance. a slight change in position, direction, or tendency.
- shrink - become or make smaller in size or amount.
- support - Thing that bears the weight of something or keeps it upright.
- tweak - improve (a mechanism or system) by making fine adjustments to it.
- warp - Twist or distortion in the shape or form of something.

## Related

- SVG
    - SVG specification - https://github.com/w3c/svgwg/tree/master, https://www.w3.org/TR/SVG2/
    - SVG Hinting Proposals - https://www.w3.org/Graphics/SVG/WG/wiki/Proposals/SVG_hinting
    - SVG Native - https://svgwg.org/specs/svg-native/
    - SVG secure static mode - https://svgwg.org/svg2-draft/conform.html#secure-static-mode
- TrueType hinting
    - OpenType specification - https://docs.microsoft.com/en-us/typography/opentype/spec/ttch01
- Libraries and tools
    - LunaSVG - https://github.com/sammycage/lunasvg
    - Inkscape SVG editor - https://inkscape.org/
    - Cairo based convertor for SVG to PNG - https://cairosvg.org/
    - Cairo rendering API - https://cairographics.org/download/
    - SVG Path Visualizer webpage - https://svg-path-visualizer.netlify.app/
    - SVG Native Viewer - https://github.com/adobe/svg-native-viewer
