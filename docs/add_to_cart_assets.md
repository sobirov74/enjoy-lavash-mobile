# Add-to-cart packaging

The menu uses built-in Flutter packaging animations by default. No downloaded
animation, extra package, product cutout, or packaging registry is needed. The
selected catalog image settles into paper or a container; the folds close, the
finished package pauses briefly, then flies into the actual cart icon.

The visual sequence follows the staging and closing motion in the supplied
[Pizza menu app reference](https://www.pinterest.com/pin/844493676209462/).
The packaging uses projected hinged folds, moving fold shadows, paper fibres,
crease highlights, rounded wrap shading and cardboard edge thickness. It uses
`assets/images/enjoy-logo.png` as a seal on the package; it is an app animation,
not a representation of an approved physical print design.

## Built-in presets

`PresetPackagingVisual` takes a `CartPackagingKind`, preparation `progress`
from 0 to 1, the displayed `product` widget, and its original `productSize`.
Optional `initialProductRect` (in the 320 × 320 canvas) and `entranceProgress`
let the controller move one photo continuously from its original bounds into
the package. There is no crossfade between differently sized photo copies.
The renderer has no timers, network calls or cart state; front layers physically
cover the photograph while preserving its proportions.

| Product | Preparation |
| --- | --- |
| Pizza | Kraft box base receives the photo; a rear-hinged lid closes over it |
| Burger | Black paper folds from the bottom, left, right, then top; a seal finishes the wrap |
| Lavash | Cream paper folds around the sides, followed by tucked ends and a seal |
| Fries | A dark carton front rises around the lower portion; the top remains visible |
| Hot dog | A paper tray folds up, then a dark wrap band closes over its middle |
| Cup drink | The photo settles into a takeaway cup; the sleeve closes and a dark lid snaps onto its opening |
| Bottled drink | The existing sealed product travels directly |
| Combo / unrecognized product | The image settles into a kraft takeaway bag; the front rises and closure folds shut |

Only packaging is illustrated. The food always comes from the selected product's
existing widget, including its loading/error fallback. The implementation does
not invent ingredients or substitute another SKU. Enclosed presets completely
hide the food after closing; the closed package is carried throughout flight.

## Timing and placement

The default sequence lasts **2,200 ms** and scales with
`CartAnimationController.duration`:

- 0–350 ms: lift the exact displayed photo into the packaging stage.
- 176–1,232 ms: settle the product and fold the packaging around it.
- 1,232–1,496 ms: hold the finished package with a restrained settling motion.
- 1,496–2,068 ms: follow a curved path into the cart, shrinking on approach.
- 2,068–2,200 ms: confirm arrival and finish cleanup.

The first two phases overlap. Packaging moves to the center of the visible view
and uses a 360 logical pixel stage in both the menu and product details. The
stage shrinks to fit small screens with 12 pixels of clearance on each side;
detail stages are centered between the header and the Add footer. The initial
photo starts at its captured bounds. The cart destination is measured again at
flight launch, after its layout has settled. Overlay transforms do not move the
menu or intercept touches. Reduced motion uses the existing 140 ms stationary
fade and cart highlight instead of wrapping or flight.

`MenuScreen` supplies `classifyCartPackaging(product)` on every add, so an empty
`packagingAssets` map still shows packaging. The classifier uses actual localized
catalog titles/categories, never decorative emojis. Explicit combos take
precedence over contained food names. Bottle and cup effects require an explicit
container clue; a soda brand or volume alone does not establish the container.
Unrecognized items use the generic takeaway bag rather than impersonating a
different food type.

## Optional product-specific artwork

`MenuScreen.packagingAssets` accepts `CartPackagingAssets` entries keyed by exact
product ID. Complete, matching and successfully preloaded artwork overrides the
built-in preset. Missing or failed artwork and custom modifier selections use
the built-in preset with the displayed image.

Each entry provides `kind`, `productId`, `layers`, `productCutout`, `productRect`,
`layerRects` and `lidPivot`. Use transparent PNG/WebP layers and an exact SKU
cutout. Rectangles are normalized to the composition; `lidPivot` is normalized
within the lid's own rectangle. Export independent layers in their closed
positions, with consistent lighting and enough opaque coverage to hide food
where the package is closed. Approximately 512 pixels on the longest edge is
sufficient; the runtime precaches configured assets.

| Runtime kind | Required `CartPackagingLayer` keys |
| --- | --- |
| `pizza` | `base`, `front`, `lid` |
| `burger` | `base`, `bottomFold`, `leftFold`, `rightFold`, `finalFold` |
| `lavash` | `sleeve`, `finalFold` |
| `fries` | `base`, `front` |
| `hotDog` | `base`, `sleeve` |
| `cup` | `lid` |
| `bottle` | None; exact selected product cutout travels directly |
| `combo` | `base`, `front` |

`rear` is an optional background layer. The pizza lid's top edge meets its rear
hinge. Brand artwork must be aligned with its physical surface. Validate exported
art against an open and closed reference before configuring the override.

## Cart behavior and verification

Cart mutations still commit immediately. Rapid taps retain every addition while
coalescing decoration. Success confirmation, quantities and retry handling are
independent of the animation. Leaving the route, app suspension, display changes,
or a failed cart operation clean up the effect. Product detail stays open after
adding, preserving selections and scroll position. When the detail photo is
partly clipped or fully scrolled away, the controller requests a fresh staged
copy of that same product inside the visible detail body. This also works when
the lazy list has disposed the original image. The copy fades in, gets packed
and flies to the detail header's cart icon without changing the scroll position.
Reduced motion keeps stationary confirmation. Clipped menu grid images continue
to use stationary confirmation.

Widget coverage checks the default menu preset, closing before flight, source
restoration, exact-once confirmation, quantities, options, failures, reduced
motion and cleanup. Raster checks cover every packaging kind and verify that
closed paper/box/bag presets occlude the food. Detail regressions cover clipped
and disposed hero images, repeated configured additions, the actual header cart
destination and route cleanup. Visual contact sheets are rendered
for fold inspection. Physical-device smoothness and haptics still require a
phone check.
