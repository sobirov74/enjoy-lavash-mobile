/* @ds-bundle: {"format":4,"namespace":"PaceDesignSystem_e4e315","components":[{"name":"Button","sourcePath":"components/core/Button.jsx"},{"name":"Chip","sourcePath":"components/core/Chip.jsx"},{"name":"Icon","sourcePath":"components/core/Icon.jsx"},{"name":"Input","sourcePath":"components/core/Input.jsx"},{"name":"SegmentedControl","sourcePath":"components/core/SegmentedControl.jsx"},{"name":"Stepper","sourcePath":"components/core/Stepper.jsx"},{"name":"Text","sourcePath":"components/core/Text.jsx"},{"name":"Banner","sourcePath":"components/feedback/Banner.jsx"},{"name":"Dialog","sourcePath":"components/feedback/Dialog.jsx"},{"name":"Skeleton","sourcePath":"components/feedback/Skeleton.jsx"},{"name":"Toast","sourcePath":"components/feedback/Toast.jsx"},{"name":"Card","sourcePath":"components/surfaces/Card.jsx"},{"name":"Sheet","sourcePath":"components/surfaces/Sheet.jsx"}],"sourceHashes":{"components/core/Button.jsx":"9fa3ab57a20d","components/core/Chip.jsx":"5098ad56551a","components/core/Icon.jsx":"73ffde961b09","components/core/Input.jsx":"a81bc9587763","components/core/SegmentedControl.jsx":"21ce3957d9ff","components/core/Stepper.jsx":"42fe7bfe257f","components/core/Text.jsx":"888357b02ab8","components/feedback/Banner.jsx":"f5588eca7402","components/feedback/Dialog.jsx":"9fa453a0b994","components/feedback/Skeleton.jsx":"2e56fd387d24","components/feedback/Toast.jsx":"d773eb9051fd","components/surfaces/Card.jsx":"f046c8ead080","components/surfaces/Sheet.jsx":"937bafaebbe1","ui_kits/pace-app/app.js":"6fd894220881","ui_kits/pace-app/data.js":"1eb0511d4518","ui_kits/pace-app/kit.js":"78d849890212","ui_kits/pace-app/screens-catalog.js":"e85150e58f94","ui_kits/pace-app/screens-order.js":"0ce27ac0b0a4"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.PaceDesignSystem_e4e315 = window.PaceDesignSystem_e4e315 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// components/core/Button.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Pace pill button. Fully-rounded, single-action indigo by default, with the
 * design's press-scale (0.95) + overshoot release. Colored glow via `glow`.
 */
const VARIANTS = {
  primary: {
    bg: "var(--pace-action)",
    color: "var(--pace-white)",
    pressBg: "var(--pace-action-pressed)"
  },
  dark: {
    bg: "var(--pace-ink)",
    color: "var(--pace-white)",
    pressBg: "#100F1C"
  },
  soft: {
    bg: "var(--pace-action-soft)",
    color: "var(--pace-action)",
    pressBg: "var(--pace-action-muted)"
  },
  outline: {
    bg: "var(--pace-white)",
    color: "var(--pace-ink)",
    border: "var(--border-control)",
    pressBg: "var(--pace-ink-04)"
  },
  ghost: {
    bg: "var(--pace-ink-08)",
    color: "var(--pace-ink)",
    pressBg: "var(--pace-ink-12)"
  },
  text: {
    bg: "transparent",
    color: "var(--pace-action)",
    pressBg: "var(--pace-action-10)"
  },
  danger: {
    bg: "var(--pace-danger)",
    color: "var(--pace-white)",
    pressBg: "var(--pace-danger-deep)"
  }
};
const TYPE = {
  large: "var(--type-button-large)",
  medium: "var(--type-button-medium)",
  small: "var(--type-button-small)"
};
function Button({
  children,
  label,
  variant = "primary",
  size = "medium",
  height,
  disabled = false,
  glow = false,
  block = false,
  icon,
  iconRight,
  textColor,
  onClick,
  style,
  ...rest
}) {
  const [pressed, setPressed] = React.useState(false);
  const [hover, setHover] = React.useState(false);
  const v = VARIANTS[variant] || VARIANTS.primary;
  const h = height ?? (size === "large" ? 54 : size === "small" ? 40 : 52);
  const content = children ?? label;
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    disabled: disabled,
    onClick: onClick,
    onMouseDown: () => setPressed(true),
    onMouseUp: () => setPressed(false),
    onMouseEnter: () => setHover(true),
    onMouseLeave: () => {
      setHover(false);
      setPressed(false);
    },
    style: {
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      gap: 7,
      width: block ? "100%" : undefined,
      height: h,
      padding: variant === "text" ? "0 4px" : "0 16px",
      border: v.border ? `1px solid ${v.border}` : "none",
      borderRadius: "var(--radius-pill)",
      background: (hover || pressed) && !disabled ? v.pressBg : v.bg,
      color: textColor ?? v.color,
      font: TYPE[size] || TYPE.medium,
      cursor: disabled ? "default" : "pointer",
      opacity: disabled ? 0.4 : 1,
      boxShadow: glow && !disabled ? "var(--shadow-cta)" : "none",
      transform: pressed && !disabled ? "scale(0.95)" : "scale(1)",
      transition: "transform var(--motion-press-cta) var(--ease-cta), background var(--motion-press) ease",
      WebkitTapHighlightColor: "transparent",
      whiteSpace: "nowrap",
      ...style
    }
  }, rest), icon, content, iconRight);
}
Object.assign(__ds_scope, { Button });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Button.jsx", error: String((e && e.message) || e) }); }

// components/core/Icon.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Pace's bespoke line-icon set — the exact inline-SVG glyphs from the app
 * (icons.tsx), reproduced so recreations use the real shapes, not substitutes.
 * Rounded caps/joins; nav/action strokes 1.9–2px on a 24px grid.
 */
function Icon({
  name,
  size = 22,
  color = "var(--pace-ink)",
  fill = "transparent",
  strokeWidth,
  style,
  ...rest
}) {
  const common = {
    width: size,
    height: size,
    style: {
      display: "block",
      flexShrink: 0,
      ...style
    },
    "aria-hidden": true,
    ...rest
  };
  switch (name) {
    case "home":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 24 24",
        fill: "none"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M4 10.5L12 4l8 6.5V20h-5.5v-5h-5v5H4z",
        stroke: color,
        strokeWidth: strokeWidth ?? 1.9,
        strokeLinecap: "round",
        strokeLinejoin: "round"
      }));
    case "menu":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 24 24"
      }), /*#__PURE__*/React.createElement("circle", {
        cx: "7",
        cy: "7",
        r: "2.6",
        fill: color
      }), /*#__PURE__*/React.createElement("circle", {
        cx: "17",
        cy: "7",
        r: "2.6",
        fill: color
      }), /*#__PURE__*/React.createElement("circle", {
        cx: "7",
        cy: "17",
        r: "2.6",
        fill: color
      }), /*#__PURE__*/React.createElement("circle", {
        cx: "17",
        cy: "17",
        r: "2.6",
        fill: color
      }));
    case "orders":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 24 24",
        fill: "none"
      }), /*#__PURE__*/React.createElement("rect", {
        x: "5",
        y: "3.5",
        width: "14",
        height: "17",
        rx: "3",
        stroke: color,
        strokeWidth: strokeWidth ?? 1.9
      }), /*#__PURE__*/React.createElement("path", {
        d: "M9 9h6M9 13h6",
        stroke: color,
        strokeWidth: strokeWidth ?? 1.9,
        strokeLinecap: "round"
      }));
    case "profile":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 24 24",
        fill: "none"
      }), /*#__PURE__*/React.createElement("circle", {
        cx: "12",
        cy: "8",
        r: "3.6",
        stroke: color,
        strokeWidth: strokeWidth ?? 1.9
      }), /*#__PURE__*/React.createElement("path", {
        d: "M4.5 20c1.6-3.4 4.3-5 7.5-5s5.9 1.6 7.5 5",
        stroke: color,
        strokeWidth: strokeWidth ?? 1.9,
        strokeLinecap: "round"
      }));
    case "chevron-down":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 10 7",
        width: size,
        height: size * 0.7,
        fill: "none"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M1 1.5l4 4 4-4",
        stroke: color,
        strokeWidth: strokeWidth ?? 1.8,
        strokeLinecap: "round"
      }));
    case "chevron-right":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 7 12",
        width: size,
        height: size * 1.7,
        fill: "none"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M1 1l5 5-5 5",
        stroke: color,
        strokeWidth: strokeWidth ?? 1.8,
        strokeLinecap: "round"
      }));
    case "back":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 8 14",
        width: size,
        height: size * 1.6,
        fill: "none"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M7 1L1 7l6 6",
        stroke: color,
        strokeWidth: strokeWidth ?? 2,
        strokeLinecap: "round"
      }));
    case "close":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 14 14"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M1 1l12 12M13 1L1 13",
        stroke: color,
        strokeWidth: strokeWidth ?? 2,
        strokeLinecap: "round"
      }));
    case "plus":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 11 11"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M5.5 1v9M1 5.5h9",
        stroke: color,
        strokeWidth: strokeWidth ?? 2,
        strokeLinecap: "round"
      }));
    case "heart":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 20 18",
        width: size,
        height: size * 0.94
      }), /*#__PURE__*/React.createElement("path", {
        d: "M10 17S1.5 11.7 1.5 6.3C1.5 3.4 3.7 1.5 6.2 1.5 8 1.5 9.4 2.5 10 4c.6-1.5 2-2.5 3.8-2.5 2.5 0 4.7 1.9 4.7 4.8C18.5 11.7 10 17 10 17z",
        fill: fill,
        stroke: color,
        strokeWidth: strokeWidth ?? 1.6
      }));
    case "check":
      return /*#__PURE__*/React.createElement("svg", _extends({}, common, {
        viewBox: "0 0 34 26",
        width: size,
        height: size * 0.76,
        fill: "none"
      }), /*#__PURE__*/React.createElement("path", {
        d: "M2 14l10 9L32 2",
        stroke: color,
        strokeWidth: strokeWidth ?? 4,
        strokeLinecap: "round",
        strokeLinejoin: "round"
      }));
    default:
      return null;
  }
}
Object.assign(__ds_scope, { Icon });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Icon.jsx", error: String((e && e.message) || e) }); }

// components/core/Input.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Text input — the app's one consistent field treatment: 1.5px ink-12 border,
 * 14px radius, Instrument Sans Medium, ink-45 placeholder. `trailing` slots a
 * button (e.g. Apply) beside a promo field.
 */
function Input({
  value,
  onChange,
  placeholder,
  trailing,
  height = 44,
  autoCapitalize,
  style,
  ...rest
}) {
  const field = /*#__PURE__*/React.createElement("input", _extends({
    value: value,
    onChange: e => onChange && onChange(e.target.value),
    placeholder: placeholder,
    autoCapitalize: autoCapitalize,
    style: {
      flex: 1,
      width: "100%",
      height,
      boxSizing: "border-box",
      border: "1.5px solid var(--border-control)",
      borderRadius: "var(--radius-input)",
      background: "var(--pace-white)",
      padding: "0 14px",
      font: "var(--type-body-medium)",
      color: "var(--pace-ink)",
      outline: "none",
      ...(trailing ? {} : style)
    }
  }, rest));
  if (!trailing) return field;
  return /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 8,
      alignItems: "stretch",
      ...style
    }
  }, field, trailing);
}
Object.assign(__ds_scope, { Input });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Input.jsx", error: String((e && e.message) || e) }); }

// components/core/Stepper.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * −/＋ stepper. Outline minus, lavender (action-soft) plus — the design's
 * shot / pump / quantity rows. Disables at min/max.
 */
function Stepper({
  value,
  onChange,
  min = 0,
  max = 9,
  size = 38,
  style,
  ...rest
}) {
  const half = size / 2;
  const dec = () => value > min && onChange && onChange(value - 1);
  const inc = () => value < max && onChange && onChange(value + 1);
  const btn = (kind, disabled) => ({
    width: size,
    height: size,
    borderRadius: half,
    display: "grid",
    placeItems: "center",
    cursor: disabled ? "default" : "pointer",
    opacity: disabled ? 0.45 : 1,
    font: "var(--type-section-title)",
    lineHeight: 1,
    userSelect: "none",
    WebkitTapHighlightColor: "transparent",
    border: kind === "minus" ? "1.5px solid var(--pace-ink-15)" : "none",
    background: kind === "minus" ? "var(--pace-white)" : "var(--pace-action-soft)",
    color: kind === "minus" ? "var(--pace-ink)" : "var(--pace-action)"
  });
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 14,
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": "Fewer",
    disabled: value <= min,
    onClick: dec,
    style: btn("minus", value <= min)
  }, "\u2212"), /*#__PURE__*/React.createElement("span", {
    style: {
      minWidth: 14,
      textAlign: "center",
      font: "var(--type-section-title)",
      color: "var(--pace-ink)"
    },
    "aria-live": "polite"
  }, value), /*#__PURE__*/React.createElement("button", {
    type: "button",
    "aria-label": "More",
    disabled: value >= max,
    onClick: inc,
    style: btn("plus", value >= max)
  }, "+"));
}
Object.assign(__ds_scope, { Stepper });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Stepper.jsx", error: String((e && e.message) || e) }); }

// components/core/Text.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Typed text. `variant` maps to a named Pace text style (Clash Display for
 * display roles, Instrument Sans for UI). Renders a <span> by default.
 */
const FONT = {
  "display-shelf": "var(--type-display-shelf)",
  "display-product": "var(--type-display-product)",
  "display-hero": "var(--type-display-hero)",
  "display-title": "var(--type-display-title)",
  "display-status": "var(--type-display-status)",
  "display-section": "var(--type-display-section)",
  "display-sheet": "var(--type-display-sheet)",
  "display-total": "var(--type-display-total)",
  "display-card": "var(--type-display-card)",
  "display-empty": "var(--type-display-empty)",
  "section-title": "var(--type-section-title)",
  "item-title": "var(--type-item-title)",
  "body-semibold": "var(--type-body-semibold)",
  body: "var(--type-body)",
  "body-medium": "var(--type-body-medium)",
  sub: "var(--type-sub)",
  "sub-medium": "var(--type-sub-medium)",
  small: "var(--type-small)",
  "small-medium": "var(--type-small-medium)",
  "small-semibold": "var(--type-small-semibold)",
  caption: "var(--type-caption)",
  "caption-semibold": "var(--type-caption-semibold)",
  micro: "var(--type-micro)",
  "micro-semibold": "var(--type-micro-semibold)",
  badge: "var(--type-badge)",
  "badge-small": "var(--type-badge-small)",
  "nav-label": "var(--type-nav-label)"
};
function Text({
  children,
  variant = "body",
  as: Tag = "span",
  color = "var(--text-primary)",
  align,
  numberOfLines,
  style,
  ...rest
}) {
  const clamp = numberOfLines ? {
    display: "-webkit-box",
    WebkitLineClamp: numberOfLines,
    WebkitBoxOrient: "vertical",
    overflow: "hidden"
  } : null;
  return /*#__PURE__*/React.createElement(Tag, _extends({
    style: {
      margin: 0,
      font: FONT[variant] || FONT.body,
      color,
      textAlign: align,
      textWrap: "pretty",
      ...clamp,
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Text });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Text.jsx", error: String((e && e.message) || e) }); }

// components/core/Chip.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Pace chip. `solid` = category pill (white / lavender-selected), `dashed` =
 * filter chip (dashed ink border until selected), `darkSelected` = ink pill
 * when active (menu categories).
 */
function Chip({
  label,
  children,
  selected = false,
  kind = "solid",
  height = 38,
  onClick,
  style,
  ...rest
}) {
  const dashed = kind === "dashed";
  const darkWhenSelected = kind === "darkSelected";
  let background = dashed ? "transparent" : "var(--pace-white)";
  let borderColor = dashed ? "var(--pace-ink-20)" : "var(--border-control)";
  let color = dashed ? "var(--pace-ink-70)" : "var(--pace-ink)";
  if (selected) {
    if (darkWhenSelected) {
      background = "var(--pace-ink)";
      borderColor = "var(--pace-ink)";
      color = "var(--pace-white)";
    } else {
      background = "var(--pace-action-soft)";
      borderColor = "var(--pace-action)";
      color = "var(--pace-action)";
    }
  }
  return /*#__PURE__*/React.createElement("button", _extends({
    type: "button",
    onClick: onClick,
    "aria-pressed": selected,
    style: {
      display: "inline-flex",
      alignItems: "center",
      justifyContent: "center",
      height,
      padding: dashed ? "0 13px" : "0 15px",
      borderRadius: "var(--radius-pill)",
      borderWidth: dashed ? 1.5 : 1,
      borderStyle: dashed && !selected ? "dashed" : "solid",
      borderColor,
      background,
      color,
      font: dashed ? "var(--type-chip-small)" : "var(--type-chip)",
      cursor: "pointer",
      WebkitTapHighlightColor: "transparent",
      whiteSpace: "nowrap",
      ...style
    }
  }, rest), children ?? label);
}
Object.assign(__ds_scope, { Chip });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/Chip.jsx", error: String((e && e.message) || e) }); }

// components/core/SegmentedControl.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Segmented control — ink-06 track, a white selected pill with a soft shadow.
 * Options can carry a `sub` line (e.g. size + price delta).
 */
function SegmentedControl({
  options = [],
  value,
  onChange,
  height = 46,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    role: "radiogroup",
    style: {
      display: "flex",
      background: "var(--pace-ink-06)",
      borderRadius: "var(--radius-tile)",
      padding: 4,
      ...style
    }
  }, rest), options.map(opt => {
    const selected = opt.id === value;
    return /*#__PURE__*/React.createElement("button", {
      key: opt.id,
      type: "button",
      role: "radio",
      "aria-checked": selected,
      onClick: () => onChange && onChange(opt.id),
      style: {
        flex: 1,
        height,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        gap: 1,
        border: "none",
        borderRadius: "var(--radius-inner)",
        background: selected ? "var(--pace-white)" : "transparent",
        boxShadow: selected ? "var(--shadow-segment)" : "none",
        cursor: "pointer",
        transition: "background var(--motion-segment) var(--ease-standard)",
        WebkitTapHighlightColor: "transparent"
      }
    }, /*#__PURE__*/React.createElement(__ds_scope.Text, {
      variant: "item-title",
      color: selected ? "var(--pace-ink)" : "var(--pace-ink-60)"
    }, opt.label), opt.sub ? /*#__PURE__*/React.createElement(__ds_scope.Text, {
      variant: "badge-small",
      color: selected ? "var(--pace-ink-70)" : "var(--pace-ink-45)"
    }, opt.sub) : null);
  }));
}
Object.assign(__ds_scope, { SegmentedControl });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/core/SegmentedControl.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Banner.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Contextual banner — a tinted panel (status wash + matching ink) with an
 * optional inline action. Fades up on mount. Order-screen + cart warnings.
 */
function Banner({
  bg = "var(--pace-info-wash)",
  ink = "var(--pace-info-ink)",
  title,
  body,
  action,
  onAction,
  compact = false,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    role: "alert",
    style: {
      background: bg,
      borderRadius: "var(--radius-tile)",
      padding: "13px 15px",
      marginBottom: compact ? 0 : 12,
      animation: "pace-fade-up var(--motion-fade-up) var(--ease-standard) both",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Text, {
    as: "div",
    variant: "button-small",
    color: ink
  }, title), body ? /*#__PURE__*/React.createElement(__ds_scope.Text, {
    as: "div",
    variant: "small",
    color: ink,
    style: {
      marginTop: 3,
      opacity: 0.92
    }
  }, body) : null, action && onAction ? /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      marginTop: 9
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Button, {
    label: action,
    onClick: onAction,
    height: 32,
    size: "small",
    style: {
      background: ink
    },
    textColor: bg
  })) : null);
}
Object.assign(__ds_scope, { Banner });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Banner.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Dialog.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Centered dialog — cream card over an ink scrim, with primary / secondary /
 * tertiary actions. Zooms in on mount. Render when `open`.
 */
function Dialog({
  open = true,
  title,
  body,
  primary,
  onPrimary,
  primaryDanger = false,
  secondary,
  onSecondary,
  tertiary,
  onTertiary,
  onDismiss,
  style,
  ...rest
}) {
  if (!open) return null;
  return /*#__PURE__*/React.createElement("div", _extends({
    style: {
      position: "absolute",
      inset: 0,
      display: "grid",
      placeItems: "center",
      padding: 36,
      background: "rgba(29,27,44,.45)",
      zIndex: 92,
      animation: "pace-fade-in var(--motion-tab-fade) ease both",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    onClick: onDismiss,
    style: {
      position: "absolute",
      inset: 0
    },
    "aria-hidden": true
  }), /*#__PURE__*/React.createElement("div", {
    role: "dialog",
    "aria-modal": "true",
    style: {
      position: "relative",
      width: "100%",
      maxWidth: 310,
      borderRadius: "var(--radius-card-lg)",
      background: "var(--pace-ground)",
      padding: "22px 20px",
      animation: "pace-fade-up var(--motion-fade-up) var(--ease-sheet) both"
    }
  }, /*#__PURE__*/React.createElement(__ds_scope.Text, {
    as: "div",
    variant: "display-card"
  }, title), body ? /*#__PURE__*/React.createElement(__ds_scope.Text, {
    as: "div",
    variant: "sub",
    color: "var(--pace-ink-70)",
    style: {
      marginTop: 8
    }
  }, body) : null, primary ? /*#__PURE__*/React.createElement(__ds_scope.Button, {
    block: true,
    label: primary,
    variant: primaryDanger ? "danger" : "primary",
    height: 48,
    onClick: onPrimary,
    style: {
      marginTop: 16
    }
  }) : null, secondary ? /*#__PURE__*/React.createElement(__ds_scope.Button, {
    block: true,
    label: secondary,
    variant: "ghost",
    height: 44,
    onClick: onSecondary,
    style: {
      marginTop: 8
    }
  }) : null, tertiary ? /*#__PURE__*/React.createElement(__ds_scope.Button, {
    block: true,
    label: tertiary,
    variant: "text",
    height: 38,
    size: "small",
    textColor: "var(--pace-ink-55)",
    onClick: onTertiary,
    style: {
      marginTop: 8
    }
  }) : null));
}
Object.assign(__ds_scope, { Dialog });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Dialog.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Skeleton.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Skeleton placeholder — ink-06 block with a soft left-to-right shimmer.
 * Match the shape of the content it stands in for.
 */
function Skeleton({
  width = "100%",
  height = 16,
  radius = "var(--radius-card-sm)",
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", _extends({
    "aria-hidden": true,
    style: {
      width,
      height,
      borderRadius: radius,
      background: "linear-gradient(100deg, var(--pace-ink-06) 30%, var(--pace-ink-10) 50%, var(--pace-ink-06) 70%)",
      backgroundSize: "200% 100%",
      animation: "pace-shimmer 1.4s ease-in-out infinite",
      ...style
    }
  }, rest));
}
Object.assign(__ds_scope, { Skeleton });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Skeleton.jsx", error: String((e && e.message) || e) }); }

// components/feedback/Toast.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Toast — dark ink panel with a soft glow, optional action link in light
 * indigo. Presentational: render when `message` is set; wire your own timer.
 */
function Toast({
  message,
  action,
  onAction,
  style,
  ...rest
}) {
  if (!message) return null;
  return /*#__PURE__*/React.createElement("div", _extends({
    role: "alert",
    style: {
      display: "flex",
      alignItems: "center",
      gap: 10,
      padding: "13px 16px",
      borderRadius: "var(--radius-tile)",
      background: "var(--pace-ink)",
      boxShadow: "var(--shadow-pill-dark)",
      animation: "pace-fade-up var(--motion-fade-up) var(--ease-standard) both",
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement(__ds_scope.Text, {
    variant: "body-medium",
    color: "var(--pace-white)",
    style: {
      flex: 1
    }
  }, message), action ? /*#__PURE__*/React.createElement("button", {
    type: "button",
    onClick: onAction,
    style: {
      border: "none",
      background: "transparent",
      padding: 0,
      cursor: "pointer",
      font: "var(--type-button-small)",
      color: "var(--pace-action-on-dark)"
    }
  }, action) : null);
}
Object.assign(__ds_scope, { Toast });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/feedback/Toast.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/Card.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Card — the white-on-cream surface used across every screen. Radius + one
 * soft shadow, no border. `selected` swaps the shadow for a 2px indigo border
 * (prep-mode cards). `interactive` adds a gentle hover lift.
 */
function Card({
  children,
  radius = "var(--radius-card)",
  padding = 16,
  selected = false,
  interactive = false,
  onClick,
  style,
  ...rest
}) {
  const [hover, setHover] = React.useState(false);
  return /*#__PURE__*/React.createElement("div", _extends({
    onClick: onClick,
    onMouseEnter: interactive ? () => setHover(true) : undefined,
    onMouseLeave: interactive ? () => setHover(false) : undefined,
    style: {
      background: "var(--surface-card)",
      borderRadius: radius,
      padding,
      border: selected ? "2px solid var(--pace-action)" : "none",
      boxShadow: selected ? "none" : "var(--shadow-card)",
      transform: interactive && hover ? "translateY(-1px)" : "none",
      transition: "transform var(--motion-press) ease",
      cursor: onClick ? "pointer" : "default",
      ...style
    }
  }, rest), children);
}
Object.assign(__ds_scope, { Card });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/Card.jsx", error: String((e && e.message) || e) }); }

// components/surfaces/Sheet.jsx
try { (() => {
function _extends() { return _extends = Object.assign ? Object.assign.bind() : function (n) { for (var e = 1; e < arguments.length; e++) { var t = arguments[e]; for (var r in t) ({}).hasOwnProperty.call(t, r) && (n[r] = t[r]); } return n; }, _extends.apply(null, arguments); }
/**
 * Bottom sheet — cream (or ink) panel with 28px top corners and a grabber,
 * over an ink scrim. Springs up on open. Absolutely fills the nearest
 * positioned ancestor (a phone frame). Render controlled via `open`.
 */
function Sheet({
  open = true,
  onDismiss,
  children,
  dark = false,
  style,
  ...rest
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      pointerEvents: open ? "auto" : "none",
      zIndex: 82
    }
  }, /*#__PURE__*/React.createElement("div", {
    onClick: onDismiss,
    "aria-hidden": true,
    style: {
      position: "absolute",
      inset: 0,
      background: "rgba(29,27,44,.4)",
      opacity: open ? 1 : 0,
      transition: "opacity var(--motion-fade-up) ease"
    }
  }), /*#__PURE__*/React.createElement("div", _extends({
    role: "dialog",
    "aria-modal": "true",
    style: {
      position: "absolute",
      left: 0,
      right: 0,
      bottom: 0,
      borderTopLeftRadius: "var(--radius-sheet)",
      borderTopRightRadius: "var(--radius-sheet)",
      background: dark ? "var(--pace-ink)" : "var(--surface-sheet)",
      boxShadow: "var(--shadow-sheet)",
      padding: "18px 20px 28px",
      transform: open ? "translateY(0)" : "translateY(100%)",
      transition: `transform var(--motion-sheet-in) var(--ease-sheet)`,
      ...style
    }
  }, rest), /*#__PURE__*/React.createElement("div", {
    style: {
      width: "var(--size-grabber-w)",
      height: "var(--size-grabber-h)",
      borderRadius: 3,
      margin: "0 auto 14px",
      background: dark ? "rgba(255,255,255,.25)" : "var(--pace-ink-15)"
    }
  }), children));
}
Object.assign(__ds_scope, { Sheet });
})(); } catch (e) { __ds_ns.__errors.push({ path: "components/surfaces/Sheet.jsx", error: String((e && e.message) || e) }); }

// ui_kits/pace-app/app.js
try { (() => {
/* Pace app — interactive shell. Wires the screens into a click-through:
   Home → product → add → cart → pay → live order. */
(function () {
  const DS = window.PaceDesignSystem_e4e315;
  const K = window.PaceKit;
  const D = window.PACE_DATA;
  const {
    Text,
    Button,
    Icon,
    Card,
    Toast,
    Sheet
  } = DS;
  const {
    PhoneFrame,
    TabBar,
    money
  } = K;
  const IMG = window.PACE_IMG;
  const defaultCfg = p => ({
    size: "M",
    temp: p.temps.includes("hot") ? "hot" : "iced",
    milk: p.milk ? "oat" : null,
    shots: 0,
    syrup: "none",
    qty: 1,
    unit: p.price
  });
  let keySeq = 1;
  function App() {
    const [tab, setTab] = React.useState("home");
    const [overlay, setOverlay] = React.useState(null); // {type, product?, total?}
    const [cart, setCart] = React.useState([]);
    const [prepMode, setPrepMode] = React.useState("now");
    const [shopIdx, setShopIdx] = React.useState(0);
    const [shopSheet, setShopSheet] = React.useState(false);
    const [toast, setToast] = React.useState(null);
    const [order, setOrder] = React.useState(null); // {items, total}
    const shop = D.shops[shopIdx];
    const cartCount = cart.reduce((n, it) => n + it.cfg.qty, 0);
    const cartTotal = cart.reduce((s, it) => s + it.cfg.unit * it.cfg.qty, 0);
    const fireToast = (message, action, onAction) => setToast({
      message,
      action,
      onAction,
      id: Date.now()
    });
    React.useEffect(() => {
      if (!toast) return;
      const t = setTimeout(() => setToast(null), 3400);
      return () => clearTimeout(t);
    }, [toast]);
    const addItem = (product, cfg) => {
      setCart(c => [...c, {
        key: keySeq++,
        product,
        cfg
      }]);
    };
    const quickAdd = product => {
      addItem(product, defaultCfg(product));
      fireToast("Added to your order", "View", () => setOverlay({
        type: "cart"
      }));
    };
    const addConfigured = (product, cfg) => {
      addItem(product, cfg);
      setOverlay(null);
      fireToast("Added to your order", "View", () => setOverlay({
        type: "cart"
      }));
    };
    const setQty = (key, n) => setCart(c => n <= 0 ? c.filter(it => it.key !== key) : c.map(it => it.key === key ? {
      ...it,
      cfg: {
        ...it.cfg,
        qty: n
      }
    } : it));
    const pay = total => {
      setOrder({
        items: cart,
        total
      });
      setOverlay({
        type: "order"
      });
    };
    const finishOrder = () => {
      setCart([]);
      setOrder(null);
      setOverlay(null);
      setTab("home");
      fireToast("Enjoy, Ana. That's the pace.");
    };
    const statusDark = tab === "home" && !overlay;
    let body;
    if (tab === "home") body = /*#__PURE__*/React.createElement(K.Home, {
      data: D,
      shop: shop,
      usual: {
        productId: "oatlatte"
      },
      onOpenProduct: p => setOverlay({
        type: "product",
        product: p
      }),
      onQuickAdd: quickAdd,
      onOpenShops: () => setShopSheet(true),
      onOpenMenu: () => setTab("menu")
    });else if (tab === "menu") body = /*#__PURE__*/React.createElement(MenuTab, {
      shop: shop,
      onOpenProduct: p => setOverlay({
        type: "product",
        product: p
      }),
      onQuickAdd: quickAdd
    });else if (tab === "orders") body = /*#__PURE__*/React.createElement(OrdersTab, {
      onBrowse: () => setTab("menu"),
      activeOrder: order,
      onOpenOrder: () => order && setOverlay({
        type: "order"
      }),
      shop: shop
    });else body = /*#__PURE__*/React.createElement(ProfileTab, null);
    return /*#__PURE__*/React.createElement(PhoneFrame, {
      statusDark: statusDark
    }, body, !overlay && (order || cartCount > 0) && /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 88,
        zIndex: 30,
        padding: "0 20px"
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => order ? setOverlay({
        type: "order"
      }) : setOverlay({
        type: "cart"
      }),
      style: {
        width: "100%",
        display: "flex",
        alignItems: "center",
        gap: 10,
        padding: "12px 16px",
        borderRadius: 999,
        background: "var(--pace-ink)",
        border: "none",
        cursor: "pointer",
        boxShadow: "var(--shadow-pill-dark)"
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 9,
        height: 9,
        borderRadius: 5,
        background: order ? "var(--pace-warning-dot)" : "var(--pace-action-on-dark)"
      }
    }), /*#__PURE__*/React.createElement(Text, {
      variant: "body-semibold",
      color: "#fff",
      style: {
        flex: 1,
        textAlign: "left"
      }
    }, order ? "Being made now" : "View order"), /*#__PURE__*/React.createElement(Text, {
      variant: "sub",
      color: "rgba(255,255,255,.65)"
    }, order ? "ready ~" + shop.prep[0] + " min" : cartCount + (cartCount === 1 ? " item · " : " items · ") + money(cartTotal)))), !overlay && /*#__PURE__*/React.createElement(TabBar, {
      active: tab,
      onTab: setTab
    }), overlay && overlay.type === "product" && /*#__PURE__*/React.createElement(K.Product, {
      product: overlay.product,
      onClose: () => setOverlay(null),
      onAdd: addConfigured
    }), overlay && overlay.type === "cart" && /*#__PURE__*/React.createElement(K.Cart, {
      items: cart,
      shop: shop,
      prepMode: prepMode,
      setPrepMode: setPrepMode,
      onBack: () => setOverlay(null),
      setQty: setQty,
      onEdit: it => setOverlay({
        type: "product",
        product: it.product
      }),
      onPay: pay
    }), overlay && overlay.type === "order" && order && /*#__PURE__*/React.createElement(K.Order, {
      items: order.items,
      shop: shop,
      total: order.total,
      onDone: finishOrder
    }), /*#__PURE__*/React.createElement(Sheet, {
      open: shopSheet,
      onDismiss: () => setShopSheet(false)
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "display-sheet"
    }, "Pick your shop"), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "caption",
      color: "var(--pace-ink-50)",
      style: {
        marginTop: 2,
        marginBottom: 14
      }
    }, "sorted by distance"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 10
      }
    }, D.shops.map((s, i) => /*#__PURE__*/React.createElement("button", {
      key: s.id,
      onClick: () => {
        setShopIdx(i);
        setShopSheet(false);
      },
      style: {
        textAlign: "left",
        display: "flex",
        alignItems: "center",
        gap: 12,
        padding: 14,
        borderRadius: 18,
        background: "var(--pace-white)",
        border: "2px solid " + (i === shopIdx ? "var(--pace-action)" : "transparent"),
        boxShadow: "var(--shadow-card)",
        cursor: "pointer"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "item-title"
    }, s.name), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "sub-medium",
      color: "var(--pace-ink-55)"
    }, s.address, " \xB7 ", s.dist, " \xB7 ready in ", s.prep[0], "\u2013", s.prep[1], " min")), /*#__PURE__*/React.createElement("span", {
      style: {
        width: 8,
        height: 8,
        borderRadius: 4,
        background: s.busy === "busy" ? "var(--pace-warning-dot)" : "var(--pace-success-dot)"
      }
    }))))), toast && /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 20,
        right: 20,
        bottom: 108,
        zIndex: 60
      }
    }, /*#__PURE__*/React.createElement(Toast, {
      message: toast.message,
      action: toast.action,
      onAction: () => {
        toast.onAction && toast.onAction();
        setToast(null);
      }
    })));
  }

  /* Menu tab wrapper (holds its own category/filter state) */
  function MenuTab({
    shop,
    onOpenProduct,
    onQuickAdd
  }) {
    const [cat, setCat] = React.useState("foryou");
    const [filters, setFilters] = React.useState({
      iced: false,
      hot: false,
      nocaf: false
    });
    return /*#__PURE__*/React.createElement(K.Menu, {
      data: D,
      shop: shop,
      cat: cat,
      setCat: setCat,
      filters: filters,
      setFilters: setFilters,
      onOpenProduct: onOpenProduct,
      onQuickAdd: onQuickAdd
    });
  }

  /* Orders tab */
  function OrdersTab({
    onBrowse,
    activeOrder,
    onOpenOrder,
    shop
  }) {
    const history = [{
      names: "Flat White · Sesame Croissant",
      total: 7.75,
      day: "Tue",
      shop: "Canal Street",
      time: "8:12"
    }, {
      names: "Oat Latte",
      total: 4.75,
      day: "Mon",
      shop: "Waterline Park",
      time: "9:03"
    }, {
      names: "Dark Mocha · Blueberry Danish",
      total: 8.75,
      day: "Sun",
      shop: "Canal Street",
      time: "10:20"
    }];
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        overflowY: "auto",
        paddingTop: 54
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "10px 20px 14px"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "display-title"
    }, "Orders")), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 20px 132px",
        display: "flex",
        flexDirection: "column",
        gap: 12
      }
    }, activeOrder && /*#__PURE__*/React.createElement("button", {
      onClick: onOpenOrder,
      style: {
        textAlign: "left",
        padding: 16,
        borderRadius: 22,
        background: "var(--pace-ink)",
        border: "none",
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 10,
        height: 10,
        borderRadius: 5,
        background: "var(--pace-warning-dot)"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "item-title",
      color: "#fff"
    }, "Being made now"), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "sub-medium",
      color: "rgba(255,255,255,.65)",
      style: {
        marginTop: 2
      }
    }, "ready ~", shop.prep[0], " min")), /*#__PURE__*/React.createElement(Icon, {
      name: "chevron-right",
      size: 7,
      color: "rgba(255,255,255,.7)"
    })), /*#__PURE__*/React.createElement(Text, {
      variant: "caption-semibold",
      color: "var(--pace-ink-50)",
      style: {
        marginTop: 6
      }
    }, "Earlier"), history.map((o, i) => /*#__PURE__*/React.createElement(Card, {
      key: i,
      padding: "14px 16px",
      radius: "var(--radius-card-sm)"
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        justifyContent: "space-between"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "body-semibold",
      numberOfLines: 1,
      style: {
        flex: 1,
        marginRight: 8
      }
    }, o.names), /*#__PURE__*/React.createElement(Text, {
      variant: "body-semibold"
    }, money(o.total))), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "small",
      color: "var(--pace-ink-55)",
      style: {
        marginTop: 3
      }
    }, o.day, " \xB7 ", o.shop, " \xB7 picked up ", o.time), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 8,
        marginTop: 10
      }
    }, /*#__PURE__*/React.createElement(Button, {
      variant: "soft",
      size: "small",
      height: 34,
      label: "Reorder"
    }), /*#__PURE__*/React.createElement(Button, {
      variant: "outline",
      size: "small",
      height: 34,
      label: "Receipt"
    })))), /*#__PURE__*/React.createElement("div", {
      style: {
        height: 4
      }
    }), /*#__PURE__*/React.createElement(Button, {
      variant: "text",
      label: "Browse the menu",
      onClick: onBrowse,
      style: {
        alignSelf: "center"
      }
    })));
  }

  /* Profile tab */
  function ProfileTab() {
    const rows = [["Saved recipes", "3"], ["Favorite shop", "Canal Street"], ["Payment", "Secure checkout"], ["Location & privacy", "While ordering"], ["Notifications", "Order updates only"]];
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        overflowY: "auto",
        paddingTop: 54
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "10px 20px 14px"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "display-title"
    }, "Profile")), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 20px 132px"
      }
    }, /*#__PURE__*/React.createElement(Card, {
      padding: 18
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 56,
        height: 56,
        borderRadius: 28,
        background: "var(--pace-action-soft)",
        display: "grid",
        placeItems: "center"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      style: {
        fontFamily: "var(--font-display)",
        fontWeight: 600,
        fontSize: 22,
        color: "var(--pace-action)"
      }
    }, "AN")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "display-card"
    }, "Ana Novak"), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "sub-medium",
      color: "var(--pace-ink-55)"
    }, "+998 90 123 45 67")))), /*#__PURE__*/React.createElement(Card, {
      padding: 0,
      style: {
        marginTop: 14,
        overflow: "hidden"
      }
    }, rows.map(([label, value], i) => /*#__PURE__*/React.createElement("div", {
      key: label,
      style: {
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        padding: "15px 16px",
        borderBottom: i < rows.length - 1 ? "1px solid var(--pace-ink-06)" : "none"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "body-medium"
    }, label), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 8
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "sub-medium",
      color: "var(--pace-ink-50)"
    }, value), /*#__PURE__*/React.createElement(Icon, {
      name: "chevron-right",
      size: 7,
      color: "var(--pace-ink-38)"
    }))))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        justifyContent: "center",
        marginTop: 18
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "small-medium",
      color: "var(--pace-ink-45)"
    }, "Help \xB7 Legal"))));
  }
  if (window.PaceKit && window.PaceKit.PhoneFrame && document.getElementById("root")) {
    ReactDOM.createRoot(document.getElementById("root")).render(/*#__PURE__*/React.createElement(App, null));
  }
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/pace-app/app.js", error: String((e && e.message) || e) }); }

// ui_kits/pace-app/data.js
try { (() => {
// Pace app — catalog + shop data (product names, prices, modifiers from the
// prototype's pace-data.js; images are the real local product photographs).
window.PACE_DATA = {
  brand: {
    name: "Safia",
    tagline: "Ready when you arrive"
  },
  currency: {
    symbol: "$",
    code: "USD"
  },
  shops: [{
    id: "canal",
    name: "Canal Street",
    address: "214 Canal St",
    hours: "7:00 – 19:00",
    prep: [6, 9],
    busy: "normal",
    dist: "0.3 mi",
    walk: 8,
    shelf: "B",
    zone: 120,
    fav: true
  }, {
    id: "waterline",
    name: "Waterline Park",
    address: "8 Pier Walk",
    hours: "7:30 – 18:00",
    prep: [4, 6],
    busy: "quiet",
    dist: "0.7 mi",
    walk: 15,
    shelf: "A",
    zone: 120,
    fav: false
  }, {
    id: "ninth",
    name: "Ninth & Oak",
    address: "901 Oak Ave",
    hours: "6:30 – 20:00",
    prep: [9, 14],
    busy: "busy",
    dist: "1.2 mi",
    walk: 24,
    shelf: "C",
    zone: 150,
    fav: false
  }],
  categories: [{
    id: "foryou",
    label: "For you"
  }, {
    id: "milk",
    label: "Milk coffee"
  }, {
    id: "black",
    label: "Black coffee"
  }, {
    id: "matcha",
    label: "Matcha & tea"
  }, {
    id: "food",
    label: "Pastries"
  }],
  sizes: [{
    id: "S",
    label: "S",
    oz: "8 oz",
    delta: -0.5
  }, {
    id: "M",
    label: "M",
    oz: "12 oz",
    delta: 0
  }, {
    id: "L",
    label: "L",
    oz: "16 oz",
    delta: 0.75
  }],
  milks: [{
    id: "whole",
    label: "Whole",
    delta: 0
  }, {
    id: "oat",
    label: "Oat",
    delta: 0.6
  }, {
    id: "almond",
    label: "Almond",
    delta: 0.6
  }, {
    id: "skim",
    label: "Skim",
    delta: 0
  }, {
    id: "lfree",
    label: "Lactose-free",
    delta: 0.4
  }],
  syrups: [{
    id: "none",
    label: "None",
    delta: 0
  }, {
    id: "vanilla",
    label: "Vanilla",
    delta: 0.5
  }, {
    id: "caramel",
    label: "Salted caramel",
    delta: 0.5
  }, {
    id: "maple",
    label: "Maple",
    delta: 0.5
  }, {
    id: "hazelnut",
    label: "Hazelnut",
    delta: 0.5
  }],
  products: [{
    id: "maple",
    img: "maple",
    name: "Iced Maple Latte",
    cat: "milk",
    price: 5.25,
    cal: 260,
    caf: 130,
    desc: "Double espresso poured over cold oat milk and dark amber maple.",
    backdrop: "#F3CD62",
    ink: "#5C4300",
    badges: ["Seasonal"],
    temps: ["iced"],
    milk: true,
    hero: true
  }, {
    id: "matchacloud",
    img: "matchacloud",
    name: "Matcha Cloud",
    cat: "matcha",
    price: 5.5,
    cal: 190,
    caf: 70,
    desc: "Ceremonial matcha whisked under a cold cream cloud.",
    backdrop: "#C4D6A8",
    ink: "#3F5C2E",
    badges: ["New"],
    temps: ["hot", "iced"],
    milk: true,
    hero: true
  }, {
    id: "flat",
    img: "flat",
    name: "Flat White",
    cat: "milk",
    price: 4.25,
    cal: 180,
    caf: 130,
    desc: "Double ristretto under silky micro-foam. Small on purpose.",
    backdrop: "#E9DAC6",
    ink: "#5A4128",
    badges: ["Best seller"],
    temps: ["hot"],
    milk: true,
    hero: true
  }, {
    id: "oatlatte",
    img: "oatlatte",
    name: "Oat Latte",
    cat: "milk",
    price: 4.75,
    cal: 210,
    caf: 130,
    desc: "House espresso with steamed oat milk, naturally sweet.",
    backdrop: "#CFC9EE",
    ink: "#453B85",
    badges: ["Your usual"],
    temps: ["hot", "iced"],
    milk: true
  }, {
    id: "capp",
    img: "capp",
    name: "Cappuccino",
    cat: "milk",
    price: 4.0,
    cal: 120,
    caf: 130,
    desc: "Classic thirds: espresso, steamed milk, deep foam.",
    backdrop: "#E9DAC6",
    ink: "#5A4128",
    badges: [],
    temps: ["hot"],
    milk: true
  }, {
    id: "mocha",
    img: "mocha",
    name: "Dark Mocha",
    cat: "milk",
    price: 5.0,
    cal: 290,
    caf: 135,
    desc: "70% dark chocolate melted into a double shot, finished with milk.",
    backdrop: "#6E4E36",
    ink: "#F1E4D6",
    badges: [],
    temps: ["hot", "iced"],
    milk: true
  }, {
    id: "esp",
    img: "esp",
    name: "Espresso",
    cat: "black",
    price: 3.0,
    cal: 5,
    caf: 128,
    desc: "Our seasonal blend, pulled short. Crema you can hear.",
    backdrop: "#D8D2E8",
    ink: "#3E3564",
    badges: [],
    temps: ["hot"],
    milk: false
  }, {
    id: "amer",
    img: "amer",
    name: "Americano",
    cat: "black",
    price: 3.5,
    cal: 10,
    caf: 128,
    desc: "Double espresso lengthened with hot water.",
    backdrop: "#E9DAC6",
    ink: "#5A4128",
    badges: [],
    temps: ["hot", "iced"],
    milk: false
  }, {
    id: "coldbrew",
    img: "coldbrew",
    name: "Slow Cold Brew",
    cat: "black",
    price: 4.5,
    cal: 15,
    caf: 200,
    desc: "18-hour steep. Round, chocolatey, zero bitterness.",
    backdrop: "#CFC9EE",
    ink: "#453B85",
    badges: ["Low stock"],
    temps: ["iced"],
    milk: false
  }, {
    id: "filter",
    img: "filter",
    name: "Batch Filter",
    cat: "black",
    price: 3.25,
    cal: 8,
    caf: 145,
    desc: "Single-origin filter, brewed every 30 minutes.",
    backdrop: "#F3CD62",
    ink: "#5C4300",
    badges: [],
    temps: ["hot"],
    milk: false
  }, {
    id: "danish",
    img: "danish",
    name: "Blueberry Danish",
    cat: "food",
    price: 3.75,
    cal: 340,
    caf: 0,
    desc: "Laminated 27 times. Baked at 7 am, gone by noon.",
    backdrop: "#EFC9BC",
    ink: "#7A4534",
    badges: ["Baked today"],
    temps: [],
    milk: false
  }, {
    id: "croiss",
    img: "croiss",
    name: "Sesame Croissant",
    cat: "food",
    price: 3.5,
    cal: 310,
    caf: 0,
    desc: "Butter croissant rolled in toasted black sesame.",
    backdrop: "#E9DAC6",
    ink: "#5A4128",
    badges: [],
    temps: [],
    milk: false
  }],
  loyalty: {
    cups: 7,
    goal: 9
  }
};
window.PACE_IMG = key => "../../assets/products/" + key + ".jpg";
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/pace-app/data.js", error: String((e && e.message) || e) }); }

// ui_kits/pace-app/kit.js
try { (() => {
/* Pace app UI kit — device frame, tab bar, and shared helpers.
   Reads design-system primitives from the compiled bundle. */
const DS = window.PaceDesignSystem_e4e315;
const PaceKit = window.PaceKit = window.PaceKit || {};
PaceKit.money = n => "$" + n.toFixed(2);
PaceKit.DS = DS;

/* iOS status bar — OS chrome (time + signal/wifi/battery). */
function StatusBar({
  dark
}) {
  const c = dark ? "#fff" : "var(--pace-ink)";
  return /*#__PURE__*/React.createElement("div", {
    style: {
      height: 54,
      display: "flex",
      alignItems: "flex-end",
      justifyContent: "space-between",
      padding: "0 30px 10px",
      flex: "0 0 auto"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      font: "var(--type-body-semibold)",
      color: c,
      letterSpacing: 0.2
    }
  }, "9:41"), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 6
    }
  }, /*#__PURE__*/React.createElement("svg", {
    width: "17",
    height: "11",
    viewBox: "0 0 17 11",
    fill: c
  }, /*#__PURE__*/React.createElement("rect", {
    x: "0",
    y: "7",
    width: "3",
    height: "4",
    rx: "1"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "4.5",
    y: "5",
    width: "3",
    height: "6",
    rx: "1"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "9",
    y: "2.5",
    width: "3",
    height: "8.5",
    rx: "1"
  }), /*#__PURE__*/React.createElement("rect", {
    x: "13.5",
    y: "0",
    width: "3",
    height: "11",
    rx: "1"
  })), /*#__PURE__*/React.createElement("svg", {
    width: "16",
    height: "11",
    viewBox: "0 0 16 12",
    fill: c
  }, /*#__PURE__*/React.createElement("path", {
    d: "M8 2.6c2 0 3.9.8 5.3 2.1l1.2-1.3A9.4 9.4 0 0 0 8 .8 9.4 9.4 0 0 0 1.5 3.4l1.2 1.3A7.4 7.4 0 0 1 8 2.6Zm0 3.4c1.1 0 2.1.4 2.8 1.2l1.2-1.3A6 6 0 0 0 8 5.2a6 6 0 0 0-4 1.7l1.2 1.3A4 4 0 0 1 8 6Zm0 3.3L9.8 8A2.6 2.6 0 0 0 8 8.6 2.6 2.6 0 0 0 6.2 8L8 9.3Z"
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 2
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 22,
      height: 11,
      borderRadius: 3,
      border: "1px solid " + (dark ? "rgba(255,255,255,.4)" : "var(--pace-ink-40)"),
      padding: 1.5,
      boxSizing: "border-box"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: "72%",
      height: "100%",
      borderRadius: 1,
      background: c
    }
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      width: 1.5,
      height: 4,
      borderRadius: 1,
      background: dark ? "rgba(255,255,255,.4)" : "var(--pace-ink-40)"
    }
  }))));
}

/* Phone bezel. Children fill the screen; `statusDark` for photo heroes. */
function PhoneFrame({
  children,
  statusDark
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      width: 390,
      height: 800,
      background: "#000",
      borderRadius: 54,
      padding: 11,
      boxShadow: "0 40px 90px rgba(29,27,44,.28), 0 0 0 1px rgba(0,0,0,.5)",
      flex: "0 0 auto"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      width: "100%",
      height: "100%",
      borderRadius: 44,
      overflow: "hidden",
      background: "var(--pace-ground)",
      display: "flex",
      flexDirection: "column"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      top: 12,
      left: "50%",
      transform: "translateX(-50%)",
      width: 118,
      height: 33,
      background: "#000",
      borderRadius: 20,
      zIndex: 50
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      top: 0,
      left: 0,
      right: 0,
      zIndex: 40,
      pointerEvents: "none"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      pointerEvents: "auto"
    }
  }, /*#__PURE__*/React.createElement(StatusBar, {
    dark: statusDark
  }))), children));
}

/* Bottom tab bar — frosted cream, four bespoke glyphs + an active-order pill. */
function TabBar({
  active,
  onTab,
  orderPill
}) {
  const {
    Icon,
    Text
  } = DS;
  const tabs = [["home", "Home"], ["menu", "Menu"], ["orders", "Orders"], ["profile", "Profile"]];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: 0,
      right: 0,
      bottom: 0,
      zIndex: 40
    }
  }, orderPill, /*#__PURE__*/React.createElement("div", {
    style: {
      background: "rgba(246,243,236,.92)",
      backdropFilter: "blur(18px)",
      WebkitBackdropFilter: "blur(18px)",
      borderTop: "1px solid var(--pace-ink-07)",
      padding: "8px 10px 20px",
      display: "flex"
    }
  }, tabs.map(([id, label]) => {
    const on = active === id;
    const color = on ? "var(--pace-ink)" : "var(--pace-ink-38)";
    return /*#__PURE__*/React.createElement("button", {
      key: id,
      onClick: () => onTab(id),
      style: {
        flex: 1,
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        gap: 3,
        padding: "6px 0",
        background: "none",
        border: "none",
        cursor: "pointer"
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: id,
      size: 22,
      color: color
    }), /*#__PURE__*/React.createElement(Text, {
      variant: "nav-label",
      color: color
    }, label));
  })));
}

/* Scrollable screen body with room for the tab bar. */
function ScreenScroll({
  children,
  pad = 132,
  style
}) {
  return /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      inset: 0,
      overflowY: "auto",
      overflowX: "hidden",
      WebkitOverflowScrolling: "touch",
      ...style
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      paddingBottom: pad
    }
  }, children));
}
Object.assign(PaceKit, {
  StatusBar,
  PhoneFrame,
  TabBar,
  ScreenScroll
});
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/pace-app/kit.js", error: String((e && e.message) || e) }); }

// ui_kits/pace-app/screens-catalog.js
try { (() => {
/* Pace app — catalog surfaces: Home, Menu, Product detail. */
(function () {
  const DS = window.PaceDesignSystem_e4e315;
  const PaceKit = window.PaceKit;
  const {
    Text,
    Button,
    Chip,
    SegmentedControl,
    Stepper,
    Icon,
    Card
  } = DS;
  const {
    money,
    ScreenScroll
  } = PaceKit;
  const IMG = window.PACE_IMG;
  const statusOf = shop => {
    const range = shop.prep[0] + "–" + shop.prep[1] + " min";
    if (shop.busy === "busy") return {
      dot: "var(--pace-warning-dot)",
      label: "busy · ~" + shop.prep[1] + " min"
    };
    if (shop.busy === "quiet") return {
      dot: "var(--pace-success-dot)",
      label: "quiet · " + range
    };
    return {
      dot: "var(--pace-success-dot)",
      label: "ready in " + range
    };
  };
  function Wordmark({
    size = "display-sheet",
    onLight
  }) {
    return /*#__PURE__*/React.createElement(Text, {
      variant: size,
      color: onLight ? "var(--pace-ink)" : "var(--pace-white)",
      style: {
        fontWeight: 600,
        letterSpacing: 0.8
      }
    }, "Safia", /*#__PURE__*/React.createElement(Text, {
      variant: size,
      color: "var(--pace-citrus)",
      style: {
        fontWeight: 600
      }
    }, "."));
  }

  /* ---------------- HOME ---------------- */
  function Home({
    data,
    shop,
    usual,
    onOpenProduct,
    onQuickAdd,
    onOpenShops,
    onOpenMenu
  }) {
    const heroes = data.products.filter(p => p.hero);
    const seasonal = data.products.find(p => p.badges.includes("Seasonal"));
    const st = statusOf(shop);
    const usualProduct = data.products.find(p => p.id === usual.productId);
    return /*#__PURE__*/React.createElement(ScreenScroll, null, /*#__PURE__*/React.createElement("div", {
      style: {
        height: 356,
        position: "relative",
        background: "var(--pace-hero-indigo)"
      }
    }, /*#__PURE__*/React.createElement("img", {
      src: IMG("hero"),
      alt: "",
      style: {
        position: "absolute",
        inset: 0,
        width: "100%",
        height: "100%",
        objectFit: "cover",
        objectPosition: "50% 30%"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        background: "linear-gradient(180deg, rgba(20,18,36,.55) 0%, rgba(20,18,36,0) 40%, rgba(20,18,36,0) 55%, rgba(29,27,44,.5) 100%)"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        top: 60,
        left: 20,
        right: 20,
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center"
      }
    }, /*#__PURE__*/React.createElement(Wordmark, null), /*#__PURE__*/React.createElement("div", {
      style: {
        width: 38,
        height: 38,
        borderRadius: 19,
        background: "rgba(255,255,255,.18)",
        display: "grid",
        placeItems: "center"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "sub-medium",
      color: "var(--pace-white)",
      style: {
        fontWeight: 600
      }
    }, "AN"))), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 20,
        right: 20,
        bottom: 46
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "display-hero",
      color: "var(--pace-white)"
    }, "Morning, Ana."), /*#__PURE__*/React.createElement("button", {
      onClick: onOpenShops,
      style: {
        marginTop: 12,
        display: "inline-flex",
        alignItems: "center",
        gap: 8,
        height: 40,
        padding: "0 14px",
        borderRadius: 999,
        background: "rgba(255,255,255,.16)",
        border: "none",
        cursor: "pointer"
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 8,
        height: 8,
        borderRadius: 4,
        background: st.dot
      }
    }), /*#__PURE__*/React.createElement(Text, {
      variant: "body-medium",
      color: "var(--pace-white)"
    }, shop.name), /*#__PURE__*/React.createElement(Text, {
      variant: "body-medium",
      color: "rgba(255,255,255,.75)"
    }, "\xB7 ", st.label), /*#__PURE__*/React.createElement(Icon, {
      name: "chevron-down",
      size: 10,
      color: "#fff"
    })))), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: -28,
        borderTopLeftRadius: 28,
        borderTopRightRadius: 28,
        background: "var(--pace-ground)",
        paddingTop: 24,
        position: "relative"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 20px 14px",
        display: "flex",
        justifyContent: "space-between",
        alignItems: "baseline"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "section-title"
    }, "On the bar this week"), /*#__PURE__*/React.createElement("button", {
      onClick: onOpenMenu,
      style: {
        background: "none",
        border: "none",
        padding: 0,
        cursor: "pointer"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "button-small",
      color: "var(--pace-action)"
    }, "Full menu"))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 12,
        overflowX: "auto",
        padding: "2px 20px",
        scrollbarWidth: "none"
      }
    }, heroes.map(p => /*#__PURE__*/React.createElement("div", {
      key: p.id,
      style: {
        width: 232,
        flex: "0 0 auto",
        borderRadius: 24,
        overflow: "hidden",
        background: p.backdrop,
        boxShadow: "var(--shadow-card)"
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => onOpenProduct(p),
      style: {
        display: "block",
        width: "100%",
        height: 252,
        padding: 0,
        border: "none",
        background: "none",
        cursor: "pointer",
        position: "relative"
      }
    }, /*#__PURE__*/React.createElement("img", {
      src: IMG(p.img),
      alt: p.name,
      style: {
        width: "100%",
        height: "100%",
        objectFit: "cover"
      }
    }), p.badges[0] && /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        top: 12,
        left: 12,
        padding: "5px 10px",
        borderRadius: 999,
        background: "rgba(255,255,255,.92)"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "micro-semibold"
    }, p.badges[0]))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "14px 16px 16px"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "display-card",
      color: p.ink
    }, p.name), /*#__PURE__*/React.createElement(Button, {
      size: "small",
      height: 36,
      label: money(p.price),
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "plus",
        size: 11,
        color: "#fff"
      }),
      onClick: () => onQuickAdd(p),
      style: {
        marginTop: 10
      }
    }))))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "20px 20px 0"
      }
    }, /*#__PURE__*/React.createElement(Card, {
      padding: 16
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 52,
        height: 52,
        borderRadius: 16,
        overflow: "hidden",
        background: usualProduct.backdrop,
        flex: "0 0 auto"
      }
    }, /*#__PURE__*/React.createElement("img", {
      src: IMG(usualProduct.img),
      alt: "",
      style: {
        width: "100%",
        height: "100%",
        objectFit: "cover"
      }
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        minWidth: 0
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "item-title"
    }, "Your usual"), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "sub-medium",
      color: "var(--text-secondary)",
      numberOfLines: 1
    }, usualProduct.name, " \xB7 M \xB7 oat")), /*#__PURE__*/React.createElement(Button, {
      variant: "soft",
      size: "small",
      height: 40,
      label: "Reorder " + money(usualProduct.price),
      onClick: () => onQuickAdd(usualProduct)
    })))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "14px 20px 0"
      }
    }, /*#__PURE__*/React.createElement(Card, {
      padding: "14px 16px"
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 4
      }
    }, Array.from({
      length: data.loyalty.goal
    }, (_, i) => /*#__PURE__*/React.createElement("span", {
      key: i,
      style: {
        width: 10,
        height: 10,
        borderRadius: 5,
        boxSizing: "border-box",
        background: i < data.loyalty.cups ? "var(--pace-action)" : "transparent",
        border: "1.5px solid " + (i < data.loyalty.cups ? "var(--pace-action)" : "var(--pace-ink-25)")
      }
    }))), /*#__PURE__*/React.createElement(Text, {
      variant: "sub-medium",
      color: "var(--pace-ink-65)"
    }, data.loyalty.goal - data.loyalty.cups, " cups to a free drink")))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 8,
        overflowX: "auto",
        padding: "20px 20px 0",
        scrollbarWidth: "none"
      }
    }, data.categories.filter(c => c.id !== "foryou").map(c => /*#__PURE__*/React.createElement(Chip, {
      key: c.id,
      label: c.label,
      onClick: onOpenMenu,
      style: {
        flex: "0 0 auto"
      }
    }))), seasonal && /*#__PURE__*/React.createElement("div", {
      style: {
        margin: "20px 20px 0",
        borderRadius: 24,
        overflow: "hidden",
        background: "var(--pace-citrus-deep)",
        padding: 20,
        minHeight: 150,
        position: "relative"
      }
    }, /*#__PURE__*/React.createElement("img", {
      src: IMG(seasonal.img),
      alt: "",
      style: {
        position: "absolute",
        right: -24,
        top: -10,
        width: 150,
        height: 190,
        objectFit: "cover",
        borderBottomLeftRadius: 60
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        maxWidth: 210,
        position: "relative"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "display-sheet",
      color: "var(--pace-citrus-ink)"
    }, "Seasonal at Safia"), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "sub-medium",
      color: "rgba(92,67,0,.8)",
      style: {
        marginTop: 6
      }
    }, seasonal.name, ", while available."), /*#__PURE__*/React.createElement(Button, {
      height: 36,
      size: "small",
      label: "Try it · " + money(seasonal.price),
      textColor: "var(--pace-citrus-wash)",
      onClick: () => onOpenProduct(seasonal),
      style: {
        marginTop: 12,
        background: "var(--pace-citrus-ink)"
      }
    })))));
  }

  /* ---------------- MENU ---------------- */
  function Menu({
    data,
    shop,
    cat,
    setCat,
    filters,
    setFilters,
    onOpenProduct,
    onQuickAdd
  }) {
    let list = cat === "foryou" ? data.products.filter(p => p.hero || p.badges.includes("Your usual")) : data.products.filter(p => p.cat === cat);
    if (filters.iced) list = list.filter(p => p.temps.includes("iced"));
    if (filters.hot) list = list.filter(p => p.temps.includes("hot"));
    if (filters.nocaf) list = list.filter(p => p.caf <= 20);
    const soldOut = p => p.badges.includes("Low stock") && false; // display only
    return /*#__PURE__*/React.createElement(ScreenScroll, {
      style: {
        paddingTop: 54
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "10px 20px 4px",
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "display-title"
    }, "Menu"), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "inline-flex",
        alignItems: "center",
        gap: 7,
        height: 36,
        padding: "0 13px",
        borderRadius: 999,
        background: "var(--pace-ink)"
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 7,
        height: 7,
        borderRadius: 4,
        background: "var(--pace-success-dot)"
      }
    }), /*#__PURE__*/React.createElement(Text, {
      variant: "sub-medium",
      color: "#fff"
    }, shop.name), /*#__PURE__*/React.createElement(Icon, {
      name: "chevron-down",
      size: 9,
      color: "#fff"
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 8,
        overflowX: "auto",
        padding: "12px 20px 4px",
        scrollbarWidth: "none"
      }
    }, data.categories.map(c => /*#__PURE__*/React.createElement(Chip, {
      key: c.id,
      label: c.label,
      kind: "darkSelected",
      selected: cat === c.id,
      onClick: () => setCat(c.id),
      style: {
        flex: "0 0 auto"
      }
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 8,
        padding: "8px 20px 6px"
      }
    }, [["iced", "Iced"], ["hot", "Hot"], ["nocaf", "Low caffeine"]].map(([k, label]) => /*#__PURE__*/React.createElement(Chip, {
      key: k,
      label: label,
      kind: "dashed",
      height: 32,
      selected: filters[k],
      onClick: () => setFilters({
        ...filters,
        [k]: !filters[k]
      })
    }))), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "grid",
        gridTemplateColumns: "1fr 1fr",
        gap: 12,
        padding: "10px 20px 0"
      }
    }, list.map(p => /*#__PURE__*/React.createElement("div", {
      key: p.id,
      style: {
        borderRadius: 20,
        background: "var(--pace-white)",
        overflow: "hidden",
        boxShadow: "var(--shadow-card)"
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => onOpenProduct(p),
      style: {
        display: "block",
        width: "100%",
        height: 158,
        padding: 0,
        border: "none",
        background: p.backdrop,
        cursor: "pointer",
        position: "relative"
      }
    }, /*#__PURE__*/React.createElement("img", {
      src: IMG(p.img),
      alt: p.name,
      style: {
        width: "100%",
        height: "100%",
        objectFit: "cover"
      }
    }), p.badges[0] && /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        top: 10,
        left: 10,
        padding: "4px 9px",
        borderRadius: 999,
        background: "rgba(255,255,255,.92)"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "badge-small"
    }, p.badges[0]))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "12px 13px 13px"
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: () => onOpenProduct(p),
      style: {
        display: "block",
        textAlign: "left",
        background: "none",
        border: "none",
        padding: 0,
        cursor: "pointer",
        width: "100%"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "body-semibold",
      numberOfLines: 2,
      style: {
        minHeight: 35
      }
    }, p.name), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "micro",
      color: "var(--pace-ink-50)",
      style: {
        marginTop: 2
      }
    }, p.caf > 0 ? p.cal + " cal · " + p.caf + " mg" : p.cal + " cal")), /*#__PURE__*/React.createElement(Button, {
      size: "small",
      height: 33,
      label: money(p.price),
      icon: /*#__PURE__*/React.createElement(Icon, {
        name: "plus",
        size: 10,
        color: "#fff"
      }),
      onClick: () => onQuickAdd(p),
      style: {
        marginTop: 10
      }
    }))))));
  }

  /* ---------------- PRODUCT ---------------- */
  function Product({
    product,
    onClose,
    onAdd
  }) {
    const p = product;
    const [size, setSize] = React.useState("M");
    const [temp, setTemp] = React.useState(p.temps.includes("hot") ? "hot" : "iced");
    const [milk, setMilk] = React.useState("oat");
    const [shots, setShots] = React.useState(0);
    const [syrup, setSyrup] = React.useState("none");
    const [qty, setQty] = React.useState(1);
    const [fav, setFav] = React.useState(false);
    const D = window.PACE_DATA;
    const sizeObj = D.sizes.find(s => s.id === size);
    const milkObj = D.milks.find(m => m.id === milk);
    const syrObj = D.syrups.find(s => s.id === syrup);
    const unit = p.price + sizeObj.delta + (p.milk ? milkObj.delta : 0) + shots * 1.0 + syrObj.delta;
    const total = unit * qty;
    const iced = temp === "iced";
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        background: p.backdrop,
        display: "flex",
        flexDirection: "column"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        overflowY: "auto"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        height: 442,
        position: "relative"
      }
    }, /*#__PURE__*/React.createElement("img", {
      src: IMG(p.img),
      alt: p.name,
      style: {
        position: "absolute",
        inset: 0,
        width: "100%",
        height: "100%",
        objectFit: "cover"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 0,
        height: 90,
        background: "linear-gradient(180deg, rgba(0,0,0,0), " + p.backdrop + ")"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        top: 58,
        left: 16,
        right: 16,
        display: "flex",
        justifyContent: "space-between"
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: onClose,
      style: {
        width: 40,
        height: 40,
        borderRadius: 20,
        background: "rgba(255,255,255,.75)",
        border: "none",
        display: "grid",
        placeItems: "center",
        cursor: "pointer"
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "close",
      size: 13
    })), /*#__PURE__*/React.createElement("button", {
      onClick: () => setFav(v => !v),
      style: {
        width: 40,
        height: 40,
        borderRadius: 20,
        background: "rgba(255,255,255,.75)",
        border: "none",
        display: "grid",
        placeItems: "center",
        cursor: "pointer"
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "heart",
      size: 17,
      fill: fav ? "var(--pace-danger)" : "transparent",
      color: fav ? "var(--pace-danger)" : "var(--pace-ink)"
    })))), /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "20px 22px 8px"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "display-product",
      color: p.ink
    }, p.name), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "body",
      color: p.ink,
      style: {
        marginTop: 8,
        opacity: 0.8,
        maxWidth: 320
      }
    }, p.desc), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 8,
        marginTop: 12,
        flexWrap: "wrap"
      }
    }, [p.cal + " cal", p.caf > 0 ? p.caf + " mg caffeine" : "caffeine-free"].map(t => /*#__PURE__*/React.createElement("span", {
      key: t,
      style: {
        padding: "6px 11px",
        borderRadius: 999,
        background: "rgba(255,255,255,.55)"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "caption-semibold"
    }, t))))), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 18,
        background: "var(--pace-ground)",
        borderTopLeftRadius: 28,
        borderTopRightRadius: 28,
        padding: "22px 20px 0",
        display: "flex",
        flexDirection: "column",
        gap: 22
      }
    }, /*#__PURE__*/React.createElement(Section, {
      title: "Size",
      trailing: sizeObj.oz
    }, /*#__PURE__*/React.createElement(SegmentedControl, {
      value: size,
      onChange: setSize,
      options: D.sizes.map(s => ({
        id: s.id,
        label: s.label,
        sub: s.delta === 0 ? "base" : (s.delta > 0 ? "+" : "−") + "$" + Math.abs(s.delta).toFixed(2)
      }))
    })), p.temps.length > 1 && /*#__PURE__*/React.createElement(Section, {
      title: "Temperature"
    }, /*#__PURE__*/React.createElement(SegmentedControl, {
      height: 42,
      value: temp,
      onChange: setTemp,
      options: p.temps.map(t => ({
        id: t,
        label: t === "hot" ? "Hot" : "Iced"
      }))
    })), p.milk && /*#__PURE__*/React.createElement(Section, {
      title: "Milk"
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 8,
        overflowX: "auto",
        scrollbarWidth: "none"
      }
    }, D.milks.map(m => /*#__PURE__*/React.createElement(OptionCard, {
      key: m.id,
      label: m.label,
      sub: m.delta === 0 ? "Included" : "+$" + m.delta.toFixed(2),
      on: milk === m.id,
      onClick: () => setMilk(m.id)
    })))), p.milk && /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center"
      }
    }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "section-title",
      style: {
        fontSize: 15
      }
    }, "Extra shots"), /*#__PURE__*/React.createElement(Text, {
      variant: "caption",
      color: "var(--pace-ink-50)"
    }, "+$1.00 \xB7 +65 mg each")), /*#__PURE__*/React.createElement(Stepper, {
      value: shots,
      min: 0,
      max: 3,
      onChange: setShots
    })), /*#__PURE__*/React.createElement(Section, {
      title: "Syrup",
      trailing: syrup !== "none" ? "1 of 3 pumps" : null
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 8,
        overflowX: "auto",
        scrollbarWidth: "none"
      }
    }, D.syrups.map(s => /*#__PURE__*/React.createElement(OptionCard, {
      key: s.id,
      label: s.label,
      sub: s.delta === 0 ? "As is" : "+$" + s.delta.toFixed(2),
      on: syrup === s.id,
      onClick: () => setSyrup(s.id)
    })))), iced && /*#__PURE__*/React.createElement(Section, {
      title: "Ice"
    }, /*#__PURE__*/React.createElement(SegmentedControl, {
      height: 42,
      value: "regular",
      onChange: () => {},
      options: [{
        id: "light",
        label: "Light"
      }, {
        id: "regular",
        label: "Regular"
      }, {
        id: "extra",
        label: "Extra"
      }]
    })), /*#__PURE__*/React.createElement("button", {
      style: {
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center",
        padding: "15px 16px",
        borderRadius: 18,
        border: "1.5px dashed var(--pace-ink-18)",
        background: "none",
        cursor: "pointer",
        marginBottom: 130
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "body-semibold",
      style: {
        fontSize: 14
      }
    }, "More options"), /*#__PURE__*/React.createElement(Icon, {
      name: "chevron-right",
      size: 7,
      color: "var(--pace-ink-50)"
    })))), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 0,
        padding: "12px 16px 22px",
        display: "flex",
        gap: 10,
        alignItems: "center",
        background: "linear-gradient(180deg, rgba(246,243,236,0), var(--pace-ground) 30%)"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 12,
        background: "var(--pace-white)",
        borderRadius: 999,
        height: 54,
        padding: "0 8px",
        boxShadow: "var(--shadow-card)"
      }
    }, /*#__PURE__*/React.createElement(Stepper, {
      value: qty,
      min: 1,
      max: 9,
      size: 40,
      onChange: setQty
    })), /*#__PURE__*/React.createElement(Button, {
      size: "large",
      glow: true,
      block: true,
      label: "Add · " + money(total),
      onClick: () => onAdd(p, {
        size,
        temp,
        milk: p.milk ? milk : null,
        shots,
        syrup,
        qty,
        unit
      }),
      style: {
        flex: 1
      }
    })));
  }
  function Section({
    title,
    trailing,
    children
  }) {
    return /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        justifyContent: "space-between",
        alignItems: "baseline",
        marginBottom: 10
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "section-title",
      style: {
        fontSize: 15
      }
    }, title), trailing ? /*#__PURE__*/React.createElement(Text, {
      variant: "caption",
      color: "var(--pace-ink-50)"
    }, trailing) : null), children);
  }
  function OptionCard({
    label,
    sub,
    on,
    onClick
  }) {
    return /*#__PURE__*/React.createElement("button", {
      onClick: onClick,
      style: {
        flex: "0 0 auto",
        textAlign: "left",
        padding: "10px 14px",
        borderRadius: 16,
        border: "1.5px solid " + (on ? "var(--pace-action)" : "var(--border-control)"),
        background: on ? "var(--pace-action-soft)" : "var(--pace-white)",
        cursor: "pointer"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "button-small"
    }, label), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "micro",
      color: "var(--pace-ink-50)",
      style: {
        marginTop: 2
      }
    }, sub));
  }
  Object.assign(window.PaceKit, {
    Home,
    Menu,
    Product,
    Wordmark
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/pace-app/screens-catalog.js", error: String((e && e.message) || e) }); }

// ui_kits/pace-app/screens-order.js
try { (() => {
/* Pace app — order surfaces: Cart (checkout) and Order tracking. */
(function () {
  const DS = window.PaceDesignSystem_e4e315;
  const PaceKit = window.PaceKit;
  const {
    Text,
    Button,
    SegmentedControl,
    Stepper,
    Input,
    Icon,
    Card
  } = DS;
  const {
    money
  } = PaceKit;
  const IMG = window.PACE_IMG;
  const modSummary = c => [c.size, c.temp === "iced" ? "iced" : null, c.milk, c.shots ? c.shots + " shot" : null, c.syrup !== "none" ? c.syrup : null].filter(Boolean).join(" · ");

  /* ---------------- CART ---------------- */
  function Cart({
    items,
    shop,
    onBack,
    setQty,
    onEdit,
    onPay,
    prepMode,
    setPrepMode
  }) {
    const [promo, setPromo] = React.useState("");
    const subtotal = items.reduce((s, it) => s + it.cfg.unit * it.cfg.qty, 0);
    const tax = subtotal * 0.08;
    const total = subtotal + tax;
    const readyAt = shop.prep[0];
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        background: "var(--pace-ground)"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        top: 0,
        left: 0,
        right: 0,
        zIndex: 5,
        paddingTop: 58,
        background: "var(--pace-ground)"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 16px 10px",
        display: "flex",
        alignItems: "center",
        gap: 10
      }
    }, /*#__PURE__*/React.createElement("button", {
      onClick: onBack,
      style: {
        width: 40,
        height: 40,
        borderRadius: 20,
        background: "var(--pace-white)",
        border: "none",
        display: "grid",
        placeItems: "center",
        cursor: "pointer",
        boxShadow: "var(--shadow-card)"
      }
    }, /*#__PURE__*/React.createElement(Icon, {
      name: "back",
      size: 8
    })), /*#__PURE__*/React.createElement(Text, {
      variant: "display-section"
    }, "Your order"))), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        overflowY: "auto",
        paddingTop: 112
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        padding: "0 20px 210px",
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement(Card, {
      padding: "13px 14px",
      radius: "var(--radius-panel)"
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 11
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 38,
        height: 38,
        borderRadius: 12,
        background: "var(--pace-ink)",
        display: "grid",
        placeItems: "center"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "sub-medium",
      color: "#fff",
      style: {
        fontFamily: "var(--font-display)",
        fontWeight: 600
      }
    }, "S")), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "body-semibold",
      style: {
        fontSize: 14
      }
    }, "Pickup at ", shop.name), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "caption",
      color: "var(--pace-ink-55)"
    }, shop.address, " \xB7 ", shop.hours)), /*#__PURE__*/React.createElement("button", {
      style: {
        background: "none",
        border: "none",
        cursor: "pointer",
        padding: 0
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "button-small",
      color: "var(--pace-action)"
    }, "Change")))), /*#__PURE__*/React.createElement(Card, {
      padding: 0,
      radius: "var(--radius-card)",
      style: {
        overflow: "hidden"
      }
    }, items.map((it, i) => /*#__PURE__*/React.createElement("div", {
      key: it.key,
      style: {
        display: "flex",
        gap: 12,
        padding: 14,
        borderBottom: i < items.length - 1 ? "1px solid var(--pace-ink-06)" : "none"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 52,
        height: 52,
        borderRadius: 14,
        overflow: "hidden",
        background: it.product.backdrop,
        flex: "0 0 auto"
      }
    }, /*#__PURE__*/React.createElement("img", {
      src: IMG(it.product.img),
      alt: "",
      style: {
        width: "100%",
        height: "100%",
        objectFit: "cover"
      }
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1,
        minWidth: 0
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        justifyContent: "space-between",
        gap: 8
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "body-semibold",
      numberOfLines: 1,
      style: {
        flex: 1
      }
    }, it.product.name), /*#__PURE__*/React.createElement(Text, {
      variant: "body-semibold"
    }, money(it.cfg.unit * it.cfg.qty))), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "small",
      color: "var(--pace-ink-55)",
      style: {
        marginTop: 2
      }
    }, modSummary(it.cfg)), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 12,
        marginTop: 9
      }
    }, /*#__PURE__*/React.createElement(Stepper, {
      size: 30,
      value: it.cfg.qty,
      min: 0,
      max: 9,
      onChange: n => setQty(it.key, n)
    }), /*#__PURE__*/React.createElement("button", {
      onClick: () => onEdit(it),
      style: {
        marginLeft: "auto",
        background: "none",
        border: "none",
        cursor: "pointer",
        padding: 0
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "small-medium",
      color: "var(--pace-ink-45)"
    }, "Edit"))))))), /*#__PURE__*/React.createElement(Input, {
      placeholder: "Promo code",
      autoCapitalize: "characters",
      value: promo,
      onChange: setPromo,
      trailing: /*#__PURE__*/React.createElement(Button, {
        variant: "ghost",
        height: 44,
        label: "Apply",
        style: {
          borderRadius: "var(--radius-input)"
        }
      })
    }), /*#__PURE__*/React.createElement(Card, {
      padding: "14px 16px",
      radius: "var(--radius-card-sm)"
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        flexDirection: "column",
        gap: 7
      }
    }, /*#__PURE__*/React.createElement(Row, {
      label: "Subtotal",
      value: money(subtotal)
    }), /*#__PURE__*/React.createElement(Row, {
      label: "Tax",
      value: money(tax)
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        justifyContent: "space-between",
        alignItems: "baseline",
        marginTop: 4,
        paddingTop: 10,
        borderTop: "1px solid var(--pace-ink-08)"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "section-title",
      style: {
        fontSize: 15
      }
    }, "Total"), /*#__PURE__*/React.createElement(Text, {
      variant: "display-total"
    }, money(total))))), /*#__PURE__*/React.createElement(Text, {
      variant: "section-title",
      style: {
        marginTop: 6
      }
    }, "When should we make it?"), /*#__PURE__*/React.createElement(ModeCard, {
      selected: prepMode === "now",
      onClick: () => setPrepMode("now"),
      title: "Now",
      trailing: /*#__PURE__*/React.createElement(Text, {
        variant: "small-semibold",
        color: "var(--pace-action)"
      }, "ready ~", readyAt, " min"),
      body: "The barista starts the moment you pay."
    }), /*#__PURE__*/React.createElement(ModeCard, {
      selected: prepMode === "close",
      onClick: () => setPrepMode("close"),
      title: "When I'm close",
      trailing: /*#__PURE__*/React.createElement("span", {
        style: {
          padding: "4px 9px",
          borderRadius: 999,
          background: "var(--pace-action-soft)"
        }
      }, /*#__PURE__*/React.createElement(Text, {
        variant: "badge",
        color: "var(--pace-action)"
      }, "Signature")),
      body: "We hold your paid order and start it at this branch's pickup zone. Location is used for this order only."
    }, prepMode === "close" && /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 11
      }
    }, /*#__PURE__*/React.createElement(SegmentedControl, {
      height: 34,
      value: "walking",
      onChange: () => {},
      options: [{
        id: "walking",
        label: "Walking"
      }, {
        id: "driving",
        label: "Driving"
      }, {
        id: "transit",
        label: "Transit"
      }]
    }), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "caption",
      color: "var(--pace-ink-50)",
      style: {
        marginTop: 8
      }
    }, "Zone armed after payment \xB7 you can always start it yourself"))), /*#__PURE__*/React.createElement(ModeCard, {
      selected: prepMode === "sched",
      onClick: () => setPrepMode("sched"),
      title: "Schedule a pickup time",
      body: "Kitchen needs a " + shop.prep[1] + "-minute head start. Last pickup 6:45 pm."
    }, prepMode === "sched" && /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        gap: 7,
        marginTop: 11,
        overflowX: "auto",
        scrollbarWidth: "none"
      }
    }, ["8:15", "8:30", "8:45", "9:00", "9:15"].map((tt, i) => /*#__PURE__*/React.createElement("div", {
      key: tt,
      style: {
        flex: "0 0 auto",
        height: 34,
        padding: "0 13px",
        display: "grid",
        placeItems: "center",
        borderRadius: 999,
        border: "1.5px solid " + (i === 1 ? "var(--pace-ink)" : "var(--pace-ink-14)"),
        background: i === 1 ? "var(--pace-ink)" : "var(--pace-white)"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "small-semibold",
      color: i === 1 ? "#fff" : "var(--pace-ink)"
    }, tt))))))), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 0,
        padding: "12px 20px 24px",
        background: "linear-gradient(180deg, rgba(246,243,236,0), var(--pace-ground) 26%)"
      }
    }, /*#__PURE__*/React.createElement(Button, {
      variant: "dark",
      block: true,
      size: "large",
      label: "Pay · " + money(total),
      onClick: () => onPay(total)
    }), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "caption",
      color: "var(--pace-ink-55)",
      align: "center",
      style: {
        marginTop: 9
      }
    }, "Secure payment methods will be shown by Stripe.")));
  }
  function Row({
    label,
    value
  }) {
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        justifyContent: "space-between"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "sub",
      color: "var(--pace-ink-70)"
    }, label), /*#__PURE__*/React.createElement(Text, {
      variant: "sub",
      color: "var(--pace-ink-70)"
    }, value));
  }
  function ModeCard({
    selected,
    onClick,
    title,
    trailing,
    body,
    children
  }) {
    return /*#__PURE__*/React.createElement("button", {
      onClick: onClick,
      style: {
        textAlign: "left",
        padding: 16,
        borderRadius: 20,
        background: "var(--pace-white)",
        border: "2px solid " + (selected ? "var(--pace-action)" : "var(--pace-ink-08)"),
        cursor: "pointer",
        width: "100%"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        justifyContent: "space-between",
        alignItems: "center"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      variant: "item-title"
    }, title), trailing), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "sub-medium",
      color: "var(--pace-ink-60)",
      style: {
        marginTop: 3,
        fontWeight: 400
      }
    }, body), children);
  }

  /* ---------------- ORDER TRACKING ---------------- */
  function Order({
    items,
    shop,
    total,
    onDone
  }) {
    const [stage, setStage] = React.useState("preparing"); // preparing -> ready
    React.useEffect(() => {
      const t = setTimeout(() => setStage("ready"), 2600);
      return () => clearTimeout(t);
    }, []);
    const names = items.map(it => it.product.name).join(" · ");
    const ready = stage === "ready";
    return /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        inset: 0,
        background: "var(--pace-ground-deep)",
        display: "flex",
        flexDirection: "column"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        top: 0,
        left: 0,
        right: 0,
        height: 300,
        overflow: "hidden",
        background: "var(--pace-map-field)"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: -40,
        top: 60,
        width: 220,
        height: 220,
        borderRadius: 40,
        background: "var(--pace-map-park)",
        transform: "rotate(12deg)"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        right: 30,
        top: -20,
        width: 160,
        height: 160,
        borderRadius: 30,
        background: "var(--pace-map-block)"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        right: -30,
        bottom: 20,
        width: 140,
        height: 140,
        borderRadius: 26,
        background: "var(--pace-map-block)"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: "-10%",
        top: 150,
        width: "120%",
        height: 26,
        background: "var(--pace-map-road)",
        transform: "rotate(-8deg)"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 120,
        top: -20,
        width: 26,
        height: 360,
        background: "var(--pace-map-road)",
        transform: "rotate(9deg)"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 150,
        top: 120,
        transform: "translate(-50%,-50%)"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: 46,
        height: 46,
        borderRadius: 23,
        background: "var(--pace-ink)",
        display: "grid",
        placeItems: "center",
        boxShadow: "var(--shadow-pill-dark)"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      color: "#fff",
      style: {
        fontFamily: "var(--font-display)",
        fontWeight: 600,
        fontSize: 18
      }
    }, "S")))), /*#__PURE__*/React.createElement("div", {
      style: {
        position: "absolute",
        left: 0,
        right: 0,
        bottom: 0,
        top: 240,
        background: "var(--pace-ground)",
        borderTopLeftRadius: 28,
        borderTopRightRadius: 28,
        boxShadow: "var(--shadow-sheet)",
        padding: "24px 20px",
        overflowY: "auto"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        display: "inline-flex",
        alignItems: "center",
        gap: 8,
        height: 32,
        padding: "0 12px",
        borderRadius: 999,
        background: "var(--pace-ink)",
        marginBottom: 18
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 8,
        height: 8,
        borderRadius: 4,
        background: ready ? "var(--pace-success-dot)" : "var(--pace-warning-dot)"
      }
    }), /*#__PURE__*/React.createElement(Text, {
      variant: "small-semibold",
      color: "#fff"
    }, "Order 24 \xB7 ", shop.name)), ready ? /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "display-status",
      color: "var(--pace-ink)"
    }, "It's on the shelf"), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "sub",
      color: "var(--pace-ink-60)",
      style: {
        marginTop: 6
      }
    }, names), /*#__PURE__*/React.createElement(Card, {
      padding: "20px",
      radius: "var(--radius-card)",
      style: {
        marginTop: 18,
        textAlign: "center"
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "caption-semibold",
      color: "var(--pace-ink-45)",
      style: {
        letterSpacing: ".08em",
        textTransform: "uppercase"
      }
    }, "Pickup shelf"), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "display-shelf",
      color: "var(--pace-action)",
      style: {
        margin: "6px 0 4px"
      }
    }, shop.shelf), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "sub-medium",
      color: "var(--pace-ink-60)"
    }, "Code 4127")), /*#__PURE__*/React.createElement(Button, {
      block: true,
      size: "large",
      glow: true,
      label: "I've got it",
      onClick: onDone,
      style: {
        marginTop: 18
      }
    })) : /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "display-status",
      color: "var(--pace-ink)"
    }, "Being made now"), /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "sub",
      color: "var(--pace-ink-60)",
      style: {
        marginTop: 6
      }
    }, "Ready around ", shop.prep[0], " min \xB7 ", names), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 14,
        height: 6,
        borderRadius: 3,
        background: "var(--pace-ink-07)",
        overflow: "hidden"
      }
    }, /*#__PURE__*/React.createElement("div", {
      style: {
        width: "45%",
        height: "100%",
        borderRadius: 3,
        background: "var(--pace-action)",
        animation: "pace-fade-in .4s ease"
      }
    })), /*#__PURE__*/React.createElement("div", {
      style: {
        marginTop: 22,
        display: "flex",
        flexDirection: "column",
        gap: 14
      }
    }, /*#__PURE__*/React.createElement(Timeline, {
      done: true,
      label: "Paid",
      sub: money(total)
    }), /*#__PURE__*/React.createElement(Timeline, {
      done: true,
      label: "Sent to barista",
      sub: "just now"
    }), /*#__PURE__*/React.createElement(Timeline, {
      active: true,
      label: "Being prepared",
      sub: "ready ~" + shop.prep[0] + " min"
    }), /*#__PURE__*/React.createElement(Timeline, {
      label: "On the shelf",
      sub: "shelf " + shop.shelf
    })))));
  }
  function Timeline({
    done,
    active,
    label,
    sub
  }) {
    const color = done ? "var(--pace-action)" : active ? "var(--pace-action)" : "var(--pace-ink-15)";
    return /*#__PURE__*/React.createElement("div", {
      style: {
        display: "flex",
        alignItems: "center",
        gap: 12
      }
    }, /*#__PURE__*/React.createElement("span", {
      style: {
        width: 12,
        height: 12,
        borderRadius: 6,
        background: done ? "var(--pace-action)" : "transparent",
        border: "2px solid " + color,
        boxSizing: "border-box"
      }
    }), /*#__PURE__*/React.createElement("div", {
      style: {
        flex: 1
      }
    }, /*#__PURE__*/React.createElement(Text, {
      as: "div",
      variant: "body-semibold",
      color: done || active ? "var(--pace-ink)" : "var(--pace-ink-45)",
      style: {
        fontSize: 14
      }
    }, label)), /*#__PURE__*/React.createElement(Text, {
      variant: "small",
      color: "var(--pace-ink-50)"
    }, sub));
  }
  Object.assign(window.PaceKit, {
    Cart,
    Order
  });
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/pace-app/screens-order.js", error: String((e && e.message) || e) }); }

__ds_ns.Button = __ds_scope.Button;

__ds_ns.Chip = __ds_scope.Chip;

__ds_ns.Icon = __ds_scope.Icon;

__ds_ns.Input = __ds_scope.Input;

__ds_ns.SegmentedControl = __ds_scope.SegmentedControl;

__ds_ns.Stepper = __ds_scope.Stepper;

__ds_ns.Text = __ds_scope.Text;

__ds_ns.Banner = __ds_scope.Banner;

__ds_ns.Dialog = __ds_scope.Dialog;

__ds_ns.Skeleton = __ds_scope.Skeleton;

__ds_ns.Toast = __ds_scope.Toast;

__ds_ns.Card = __ds_scope.Card;

__ds_ns.Sheet = __ds_scope.Sheet;

})();
