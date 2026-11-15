import { useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import { Box, Button, Icon, Image, Section, Stack } from "tgui-core/components";

import { resolveAsset } from "../assets";
import { useBackend } from "../backend";
import type {
  ExamineItem,
  ExaminePanelData,
  HeldItem,
  WornSlot,
} from "./ExaminePanelData";

const DESC_TRUNCATE_AT = 120;
const SLOT = 44; // slot box size in px
const BOTTOM_ROW_TOP = 310; // Y of the bottom corner+hands row inside the box

// Edge-anchored slot positions. Each slot hugs a real container edge (left/right
// + top/bottom) so the layout stays glued to the frame no matter the container's
// actual size (the byond map can report ~408px, not the nominal 360px).
type SlotPos = {
  left?: number;
  right?: number;
  top?: number;
  bottom?: number;
};
const SLOT_POS: Record<string, SlotPos> = {
  // Symmetric layout about the box's vertical center (axis = 180px of 360px).
  // Left and right columns each have 6 rows at identical Y positions; the right
  // column's top row holds mask (outer) + mouth (inner). Bottom corners mirror.
  // left column (outer left edge), top -> bottom
  head: { left: 6, top: 6 },
  shirt: { left: 6, top: 57 },
  gloves: { left: 6, top: 108 },
  belt: { left: 6, top: 158 },
  pants: { left: 6, top: 209 },
  shoes: { left: 6, top: 260 },
  // right column (outer right edge), top -> bottom; mouth shares the top row inward
  mask: { right: 6, top: 6 },
  mouth: { right: 54, top: 6 },
  armor: { right: 6, top: 57 },
  neck: { right: 6, top: 108 },
  cloak: { right: 6, top: 158 },
  ring: { right: 6, top: 209 },
  wrists: { right: 6, top: 260 },
  // bottom corners on the SAME verticals as the columns, mirrored about center
  // bottom-left: right shoulder (outer), right hip (inner)
  backr: { left: 6, top: 310 },
  beltr: { left: 54, top: 310 },
  // bottom-right: left hip (inner), left shoulder (outer)
  beltl: { right: 54, top: 310 },
  backl: { right: 6, top: 310 },
};

// Order the tooltip should open toward (away from the panel edge).
const TOOLTIP_SIDE: Record<string, "left" | "right"> = {
  head: "right",
  shirt: "right",
  gloves: "right",
  belt: "right",
  pants: "right",
  shoes: "right",
  backr: "right",
  beltr: "right",
  mouth: "left",
  mask: "left",
  armor: "left",
  neck: "left",
  cloak: "left",
  ring: "left",
  wrists: "left",
  beltl: "left",
  backl: "left",
};

// Frame colors keyed by the backend quality index (0..6); -1 = neutral default.
const QUALITY_COLORS: Record<number, string> = {
  [-1]: "#5a4632",
  0: "#6b6b6b",
  1: "#8a7a5a",
  2: "#b8b8b8",
  3: "#e8e0d0",
  4: "#5fa8d3",
  5: "#a96fd6",
  6: "#e0a93b",
};

const qualityColor = (q: number): string =>
  QUALITY_COLORS[q] ?? QUALITY_COLORS[-1];

// Diagonal hatch fill for empty / hidden slots.
const HATCH =
  "repeating-linear-gradient(45deg, rgba(90,70,50,0.35) 0px, rgba(90,70,50,0.35) 2px, transparent 2px, transparent 6px)";

//RMH EDITED START - tooltip layering + frosted backdrop.
// The hovered slot is lifted to this layer so its tooltip escapes the grid; the
// slot frames themselves sit at 2 and the doll at 0.
const TOOLTIP_LAYER = 40;
// A slot whose tooltip is only lingering on the close bridge drops one layer, so
// a tooltip the user just opened is always painted over the one on its way out.
const TOOLTIP_LAYER_CLOSING = TOOLTIP_LAYER - 1;
// Translucent so the blur behind it is actually visible. backdrop-filter is a
// no-op on the legacy IE-based BYOND browser, which just leaves the flat tint -
// still readable, so no separate fallback is needed.
const TOOLTIP_SURFACE = {
  background: "rgba(22,16,9,0.72)",
  backdropFilter: "blur(6px) saturate(140%)",
  WebkitBackdropFilter: "blur(6px) saturate(140%)",
} as const;
//RMH EDITED END

// Names stay plain white until the quality tier is actually elevated.
const DEFAULT_NAME_COLOR = "#f0ece0";

// Quality tier (0..6, quality_frame_index()) -> a short display word, shown
// as the tooltip's subtitle for elevated tiers only (mirrors BG3 hiding the
// rarity subtitle entirely for Common items). Tiers below FINE show none.
const QUALITY_LABELS: Record<number, string> = {
  4: "Fine",
  5: "Flawless",
  6: "Masterwork",
};
const QUALITY_SUBTITLE_MIN_TIER = 4;

// Decorative/body font stack, matching the pair already established in
// Throne.tsx (SERIF/"MedievalSharp") rather than introducing a new one -
// both degrade to a plain serif if the named font isn't loaded, same as
// that existing usage.
const FONT_DISPLAY = '"MedievalSharp", Georgia, serif';
const FONT_BODY = '"Lora", Georgia, serif';

// Same disclaimer as above - guessed icon per weapon category.
const WEAPON_CATEGORY_ICONS: Record<string, string> = {
  // Swords
  Sword: "khanda",
  Longsword: "khanda",
  Shortsword: "khanda",
  Greatsword: "khanda",
  Scimitar: "khanda",
  Rapier: "khanda",
  Sabre: "khanda",
  Katana: "khanda",
  Khopesh: "khanda",
  Gladius: "khanda",
  // Axes
  Axe: "gavel",
  Greataxe: "gavel",
  // Blunt
  Mace: "hammer",
  Warhammer: "hammer",
  // Bladed sidearms
  Knife: "khanda",
  Dagger: "khanda",
  Sickle: "khanda",
  // Polearms
  Polearm: "khanda",
  Halberd: "khanda",
  Spear: "khanda",
  // Other melee
  Flail: "link",
  Whip: "grip-lines",
  Katar: "hand-fist",
  Knuckles: "hand-fist",
  "War Pick": "hammer",
  // Shields
  Shield: "shield",
  "Tower Shield": "shield",
  "Heater Shield": "shield-halved",
  // Ranged
  Bow: "bow-arrow",
  Longbow: "bow-arrow",
  Shortbow: "bow-arrow",
  Crossbow: "crosshairs",
  Musket: "crosshairs",
  Pistol: "crosshairs",
  Blowgun: "crosshairs",
  Airgun: "crosshairs",
  Firearm: "crosshairs",
};

// Same disclaimer - guessed icon per BG3-style property tag.
const TAG_ICONS: Record<string, string> = {
  Light: "feather",
  "Extra Reach": "arrows-left-right",
  "Two-Handed": "hands",
  Versatile: "shuffle",
};

// Same disclaimer - guessed icon per actual attack-intent name (the
// intent's own `name`, e.g. "chop"/"stab"/"pick" - see
// get_weapon_intent_names()). Unmapped names fall back to a generic blade.
const INTENT_ICONS: Record<string, string> = {
  chop: "khanda",
  cut: "khanda",
  hack: "khanda",
  rend: "khanda",
  "long rend": "khanda",
  "arc slash": "khanda",
  "precision cut": "khanda",
  stab: "arrow-right-long",
  thrust: "arrow-right-long",
  impale: "arrow-right-long",
  lunge: "arrow-right-long",
  spear: "arrow-right-long",
  pick: "location-crosshairs",
  drill: "location-crosshairs",
  strike: "hammer",
  smash: "hammer",
  bash: "hammer",
  "pommel strike": "hammer",
  "pommel bash": "hammer",
};
const DEFAULT_INTENT_ICON = "khanda";

// One colour per grip, so grip-exclusive attacks stand out.
const GRIP_COLOR: Record<string, string> = {
  normal: "#8fc97a", // same green as before
  gripped: "#5fa8d3", // two-handed/wielded-only intents
  alt: "#c98fd0", // alt-grip-only intents (right-click reversed grip, etc)
};

// Label only. The description popup is rendered by ItemTooltip on its outer
// wrapper instead of here: this badge sits in a row with overflow-x, and CSS
// resolves the other axis to auto too, so a popup anchored inside the row
// would be clipped by it regardless of z-index.
const SpecialAttackBadge = (props: {
  name: string;
  onEnter: () => void;
  onLeave: () => void;
}) => {
  const { name, onEnter, onLeave } = props;
  return (
    <Box
      as="span"
      style={{ display: "inline-block" }}
      onMouseOver={onEnter}
      onMouseLeave={onLeave}
    >
      <Icon name="burst" mr={0.5} />
      {name}
    </Box>
  );
};

const ItemTooltip = (props: {
  item: ExamineItem;
  label: string;
  side: "left" | "right";
  vAlign: "top" | "bottom";
  frameColor: string;
  onEnter: () => void;
  onLeave: () => void;
}) => {
  const { item, label, side, vAlign, frameColor, onEnter, onLeave } = props;
  const [expanded, setExpanded] = useState(false);
  const [specialHintOpen, setSpecialHintOpen] = useState(false);
  const expandTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  // Runtime edge clamp; see the layout effect below.
  const wrapperRef = useRef<HTMLDivElement | null>(null);
  const [clampOffsetX, setClampOffsetX] = useState(0);

  const longDesc = item.desc.length > DESC_TRUNCATE_AT;
  const hasTags = !!item.tags && item.tags.length > 0;
  const hasIntents = !!item.intents && item.intents.length > 0;
  const hasFooter = !!item.weight || !!item.price;
  const hasExtra =
    !!item.weaponDamage ||
    !!item.armorClassLabel ||
    !!item.weaponCategory ||
    hasTags ||
    hasIntents ||
    !!item.specialAttack ||
    hasFooter;

  // Quality tiers at or above the cutoff get a glow and a subtitle.
  const hasGlow = item.quality >= QUALITY_SUBTITLE_MIN_TIER;
  const qualityLabel = QUALITY_LABELS[item.quality];
  const nameColor = hasGlow ? frameColor : DEFAULT_NAME_COLOR;
  // Wider box when there are more badges to fit on the single tag row.
  const tagCount = (item.weaponCategory ? 1 : 0) + (item.tags?.length ?? 0);
  let expandedMaxWidth = "320px";
  if (tagCount >= 3) {
    expandedMaxWidth = "420px";
  } else if (tagCount >= 1) {
    expandedMaxWidth = "360px";
  }

  // Slot-anchored tooltips can extend past the window edge, and no fixed
  // width can account for where the panel sits on a given screen. Measure
  // the rendered box and nudge it back inside. The reset keeps successive
  // corrections from compounding.
  useLayoutEffect(() => {
    const el = wrapperRef.current;
    if (!el) {
      return;
    }
    el.style.transform = "";
    const rect = el.getBoundingClientRect();
    const margin = 8;
    let offset = 0;
    if (rect.left < margin) {
      offset = margin - rect.left;
    } else if (rect.right > window.innerWidth - margin) {
      offset = window.innerWidth - margin - rect.right;
    }
    setClampOffsetX(offset);
  }, [expanded, item.name, side, vAlign]);

  useEffect(() => {
    // Same "hold to see more" behavior as the old long-description-only
    // expand, now covering the whole stat block: a quick hover just shows
    // name + description, holding ~2s reveals damage/armor/proficiency/etc.
    if (!longDesc && !hasExtra) {
      return;
    }
    expandTimer.current = setTimeout(() => setExpanded(true), 2000);
    return () => {
      if (expandTimer.current) {
        clearTimeout(expandTimer.current);
      }
    };
  }, [longDesc, hasExtra]);

  const shownDesc =
    !longDesc || expanded
      ? item.desc
      : item.desc.slice(0, DESC_TRUNCATE_AT).trimEnd() + "...";

  return (
    <div
      ref={wrapperRef}
      onMouseEnter={onEnter}
      onMouseLeave={onLeave}
      style={{
        position: "absolute",
        // open toward panel center; bottom-row slots anchor their tooltip to
        // their own bottom edge so it grows upward and never clips past the box
        ...(vAlign === "top" ? { top: "0" } : { bottom: "0" }),
        [side === "right" ? "left" : "right"]: `${SLOT + 6}px`,
        zIndex: 1,
        transform: clampOffsetX ? `translateX(${clampOffsetX}px)` : undefined,
        // pointer events ON so the user can scroll long descriptions, and so
        // hovering the bleeding icon below still counts as hovering the tooltip
        pointerEvents: "auto",
        textAlign: "left",
      }}
    >
      {/* On the outer wrapper, not the scrolling box: an element that pokes
          past the border would otherwise force a permanent scrollbar, since
          overflow-x cannot stay visible while overflow-y scrolls. */}
      {!!item.icon && (
        <Image
          src={item.icon}
          width={expanded ? "72px" : "40px"}
          height={expanded ? "72px" : "40px"}
          style={{
            position: "absolute",
            top: "-8px",
            right: "-8px",
            zIndex: 1,
            imageRendering: "pixelated",
            filter: "drop-shadow(0 3px 5px rgba(0,0,0,0.7))",
          }}
        />
      )}
      <div
        style={{
          // An explicit width, not just a cap: a shrink-to-fit box collapses
          // around its content instead of using the room the cap allows.
          width: expanded ? expandedMaxWidth : "auto",
          minWidth: "190px",
          maxWidth: expanded ? expandedMaxWidth : "230px",
          maxHeight: "320px",
          overflowY: "auto",
          overflowX: "hidden",
          padding: "10px 12px",
          ...TOOLTIP_SURFACE,
          // Bottom vignette behind the stat block; only once expanded.
          backgroundImage: expanded
            ? "linear-gradient(180deg, rgba(0,0,0,0) 65%, rgba(74,26,74,0.4) 100%)"
            : "none",
          border: `2px solid ${frameColor}`,
          borderRadius: "4px",
          boxShadow: hasGlow
            ? `0 0 10px ${frameColor}, 0 2px 10px rgba(0,0,0,0.85)`
            : "0 2px 10px rgba(0,0,0,0.85)",
        }}
      >
      <Box
        bold
        style={{
          color: nameColor,
          fontFamily: FONT_DISPLAY,
          paddingRight: item.icon ? (expanded ? "76px" : "40px") : 0,
          letterSpacing: "0.02em",
          textTransform: "capitalize",
        }}
        fontSize="15px"
      >
        {item.name}
      </Box>
      {!!qualityLabel && (
        <Box fontSize="10px" italic style={{ color: "#9a8f80" }}>
          {qualityLabel}
        </Box>
      )}
      <Box color="#8a7a66" fontSize="10px" italic mb={0.25}>
        {label}
      </Box>
      <Box style={{ borderTop: "1px solid rgba(138,122,102,0.35)", margin: "4px 0" }} />
      {expanded && !!item.weaponDamage && (
        <Box bold fontSize="13px" style={{ color: "#8fc97a" }} mb={0.25}>
          {item.weaponDamage.force} Damage
        </Box>
      )}
      {expanded && hasIntents && (
        <>
          <Box fontSize="11px" style={{ color: "#7fa7c9" }}>
            <Icon name="award" mr={0.5} />
            Proficiency
          </Box>
          <Box style={{ display: "flex", flexWrap: "wrap", gap: "2px 10px" }} mb={0.25}>
            {item.intents!.map((intent) => (
              <Box
                key={intent.name}
                bold
                fontSize="10px"
                style={{ color: GRIP_COLOR[intent.grip] ?? GRIP_COLOR.normal }}
              >
                <Icon name={INTENT_ICONS[intent.name] ?? DEFAULT_INTENT_ICON} mr={0.5} />
                {intent.name.toUpperCase()}
              </Box>
            ))}
          </Box>
        </>
      )}
      {!!item.desc && (
        <Box
          color="#c7bba8"
          fontSize="11px"
          style={{ fontFamily: FONT_BODY, lineHeight: "1.4", whiteSpace: "pre-wrap" }}
          mb={1}
        >
          <Icon name="scroll" mr={0.5} style={{ opacity: 0.7 }} />
          {shownDesc}
        </Box>
      )}
      {expanded &&
        (!!item.armorClassLabel || !!item.weaponCategory || hasTags || !!item.specialAttack) && (
          <Box
            style={{
              display: "flex",
              // Single row; overflow only as a fallback for unusual tag counts.
              flexWrap: "nowrap",
              overflowX: "auto",
              gap: "2px 10px",
            }}
            mb={0.25}
          >
            {!!item.armorClassLabel && (
              <Box fontSize="11px" style={{ color: "#7fa7c9", whiteSpace: "nowrap" }}>
                <Icon name="shield-halved" mr={0.5} />
                {item.armorClassLabel}
              </Box>
            )}
            {!!item.weaponCategory && (
              <Box fontSize="11px" style={{ color: "#7fa7c9", whiteSpace: "nowrap" }}>
                <Icon name={WEAPON_CATEGORY_ICONS[item.weaponCategory] ?? "question"} mr={0.5} />
                {item.weaponCategory}
              </Box>
            )}
            {item.tags?.map((tag) => (
              <Box key={tag} fontSize="11px" style={{ color: "#8a7a66", whiteSpace: "nowrap" }}>
                <Icon name={TAG_ICONS[tag] ?? "question"} mr={0.5} />
                {tag}
              </Box>
            ))}
            {!!item.specialAttack && (
              <Box fontSize="11px" style={{ color: "#c9a76f", whiteSpace: "nowrap" }}>
                <SpecialAttackBadge
                  name={item.specialAttack.name}
                  onEnter={() => setSpecialHintOpen(true)}
                  onLeave={() => setSpecialHintOpen(false)}
                />
              </Box>
            )}
          </Box>
        )}
      {expanded && hasFooter && (
        <Box
          mt={0.25}
          pt={0.5}
          style={{
            borderTop: "1px solid rgba(138,122,102,0.35)",
            display: "flex",
            justifyContent: "flex-end",
            gap: "12px",
          }}
          fontSize="10px"
          color="#b8ae9c"
        >
          {!!item.weight && (
            <span>
              <Icon name="weight-hanging" mr={0.5} />
              {item.weight}
            </span>
          )}
          {!!item.price && (
            <span>
              <Icon name="coins" mr={0.5} />
              {item.price} amna
            </span>
          )}
        </Box>
      )}
      </div>
      {specialHintOpen && !!item.specialAttack && (
        <div
          style={{
            position: "absolute",
            bottom: "100%",
            left: 0,
            marginBottom: "4px",
            width: "220px",
            zIndex: 2,
            padding: "6px 8px",
            ...TOOLTIP_SURFACE,
            border: "1px solid rgba(201,167,111,0.6)",
            borderRadius: "4px",
            fontSize: "10px",
            color: "#c7bba8",
            lineHeight: 1.4,
            whiteSpace: "normal",
            pointerEvents: "none",
          }}
        >
          {item.specialAttack.desc}
        </div>
      )}
    </div>
  );
};

const SimpleTooltip = (props: {
  title: string;
  subtitle: string;
  side: "left" | "right";
  vAlign: "top" | "bottom";
}) => {
  const { title, subtitle, side, vAlign } = props;
  return (
    <div
      style={{
        position: "absolute",
        ...(vAlign === "top" ? { top: "0" } : { bottom: "0" }),
        [side === "right" ? "left" : "right"]: `${SLOT + 6}px`,
        zIndex: 1,
        width: "140px",
        padding: "6px 9px",
        ...TOOLTIP_SURFACE,
        border: "2px solid #5a4632",
        borderRadius: "4px",
        boxShadow: "0 2px 10px rgba(0,0,0,0.85)",
        pointerEvents: "none",
        textAlign: "left",
      }}
    >
      <Box bold style={{ color: "#9c8b73" }} fontSize="12px">
        {title}
      </Box>
      <Box color="#7a6a55" fontSize="10px" italic>
        {subtitle}
      </Box>
    </div>
  );
};

const GearSlot = (props: { slotId: string; slot: WornSlot }) => {
  const { slotId, slot } = props;
  const [hovered, setHovered] = useState(false);
  // RMH EDITED - true while the tooltip is only alive because of the close bridge
  const [closing, setClosing] = useState(false);
  const closeTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const pos = SLOT_POS[slotId];
  const side = TOOLTIP_SIDE[slotId] ?? "right";
  const filled = slot.status === "item" && slot.item;
  const frameColor = filled ? qualityColor(slot.item!.quality) : "#5a4632";
  // Only long descriptions need the hover bridge (cursor travels onto the
  // tooltip to scroll). Short/empty/hidden tooltips close instantly.
  const needsBridge = !!filled && slot.item!.desc.length > DESC_TRUNCATE_AT;
  // bottom corner slots open their tooltip upward
  const vAlign: "top" | "bottom" =
    slotId === "backr" ||
    slotId === "beltr" ||
    slotId === "beltl" ||
    slotId === "backl"
      ? "bottom"
      : "top";

  // Hover bridge: filled slots keep a short close delay so the cursor can travel
  // from the slot onto the tooltip to scroll a long description. Empty/hidden
  // slots have a non-interactive tooltip, so they close instantly - no lag.
  const open = () => {
    if (closeTimer.current) {
      clearTimeout(closeTimer.current);
      closeTimer.current = null;
    }
    setClosing(false); // RMH EDITED - back to the full layer, the cursor returned
    setHovered(true);
  };
  const scheduleClose = () => {
    if (closeTimer.current) {
      clearTimeout(closeTimer.current);
      closeTimer.current = null;
    }
    // Only long-description tooltips keep a tiny bridge so the cursor can travel
    // onto them to scroll. Everything else (short item, empty, hidden) closes
    // the instant the cursor leaves the icon - no perceptible lag.
    if (!needsBridge) {
      setHovered(false);
      return;
    }
    // RMH EDITED - step down a layer for the duration of the bridge so this
    // outgoing tooltip cannot cover one the cursor has already moved on to.
    setClosing(true);
    closeTimer.current = setTimeout(() => {
      setHovered(false);
      setClosing(false);
    }, 120);
  };

  const posStyle: Record<string, string> = {};
  if (pos.left !== undefined) posStyle.left = `${pos.left}px`;
  if (pos.right !== undefined) posStyle.right = `${pos.right}px`;
  if (pos.top !== undefined) posStyle.top = `${pos.top}px`;
  if (pos.bottom !== undefined) posStyle.bottom = `${pos.bottom}px`;

  return (
    <div
      style={{
        position: "absolute",
        ...posStyle,
        // RMH EDITED - a slot with a z-index is its own stacking context, so the
        // tooltip's own z-index could never lift it above sibling slots painted
        // later in DOM order. Raise the whole slot while it is hovered instead.
        zIndex: hovered ? (closing ? TOOLTIP_LAYER_CLOSING : TOOLTIP_LAYER) : 2,
        width: `${SLOT}px`,
        height: `${SLOT}px`,
        border: `2px solid ${frameColor}`,
        borderRadius: "3px",
        background: filled ? "rgba(0,0,0,0.45)" : HATCH,
        boxShadow:
          filled && slot.item!.quality >= 4
            ? `0 0 5px ${frameColor}99`
            : "none",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        cursor: "help",
      }}
      onMouseEnter={() => open()}
      onMouseLeave={() => scheduleClose()}
    >
      {filled && slot.item!.icon ? (
        <img
          src={slot.item!.icon}
          style={{ width: "32px", height: "32px", imageRendering: "pixelated" }}
        />
      ) : null}
      {hovered && filled && (
        <ItemTooltip
          item={slot.item!}
          label={slot.label}
          side={side}
          vAlign={vAlign}
          frameColor={frameColor}
          onEnter={open}
          onLeave={scheduleClose}
        />
      )}
      {hovered && !filled && (
        <SimpleTooltip
          title={slot.label}
          subtitle={slot.status === "hidden" ? "Hidden" : "Empty"}
          side={side}
          vAlign={vAlign}
        />
      )}
    </div>
  );
};

const HandSlot = (props: { item?: HeldItem; label: string; left: number }) => {
  const { item, label, left } = props;
  const [hovered, setHovered] = useState(false);
  const [closing, setClosing] = useState(false); // RMH EDITED - see GearSlot
  const closeTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const filled = !!item;
  const frameColor = filled ? qualityColor(item!.quality) : "#5a4632";
  const needsBridge = !!item && item.desc.length > DESC_TRUNCATE_AT;
  const open = () => {
    if (closeTimer.current) {
      clearTimeout(closeTimer.current);
      closeTimer.current = null;
    }
    setClosing(false); // RMH EDITED - see GearSlot
    setHovered(true);
  };
  const scheduleClose = () => {
    if (closeTimer.current) {
      clearTimeout(closeTimer.current);
      closeTimer.current = null;
    }
    if (!needsBridge) {
      setHovered(false);
      return;
    }
    // RMH EDITED - see GearSlot
    setClosing(true);
    closeTimer.current = setTimeout(() => {
      setHovered(false);
      setClosing(false);
    }, 120);
  };
  return (
    <div
      style={{
        position: "absolute",
        left: `${left}px`,
        top: `${BOTTOM_ROW_TOP}px`,
        // RMH EDITED - see GearSlot
        zIndex: hovered ? (closing ? TOOLTIP_LAYER_CLOSING : TOOLTIP_LAYER) : 2,
        width: `${SLOT}px`,
        height: `${SLOT}px`,
        border: `2px solid ${frameColor}`,
        borderRadius: "3px",
        background: filled ? "rgba(0,0,0,0.45)" : HATCH,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        cursor: filled ? "help" : "default",
      }}
      onMouseEnter={() => filled && open()}
      onMouseLeave={() => filled && scheduleClose()}
    >
      {filled && item!.icon ? (
        <img
          src={item!.icon}
          style={{ width: "32px", height: "32px", imageRendering: "pixelated" }}
        />
      ) : (
        <Box color="#5a4632" fontSize="9px">
          {label}
        </Box>
      )}
      {hovered && filled && (
        <ItemTooltip
          item={item!}
          label={item!.wielded ? "Wielded" : "In hand"}
          side="right"
          vAlign="bottom"
          frameColor={frameColor}
          onEnter={open}
          onLeave={scheduleClose}
        />
      )}
    </div>
  );
};

const CharacterPortrait = (props: { nsfw: boolean }) => {
  const { act, data } = useBackend<ExaminePanelData>();
  const {
    headshot,
    nsfw_headshot,
    has_headshot,
    has_nsfw_headshot,
    preview_image,
    worn_items,
    preview_available,
    preview_in_range,
  } = data;
  const hasShot = props.nsfw ? has_nsfw_headshot : has_headshot;
  const shot = props.nsfw
    ? nsfw_headshot || "headshot_red.png"
    : headshot || "headshot_red.png";
  // Default to the live character preview when no headshot is set
  const [showPreview, setShowPreview] = useState(!hasShot);
  const previewActive = showPreview || !hasShot;

  //RMH EDITED START - the backend now refuses to render the doll for a viewer
  // outside examine range, so treat an empty preview_image as a real state
  // rather than a perpetual "Loading character...", and don't keep asking the
  // server for a render it will never produce.
  // Undefined means the first payload hasn't landed yet - assume renderable.
  const canRender = preview_available !== false && preview_in_range !== false;

  // Ask the server to flatten the character the first time the preview is shown
  useEffect(() => {
    if (previewActive && canRender && !preview_image) {
      act("generate_preview");
    }
  }, [previewActive, canRender, preview_image]);
  //RMH EDITED END

  return (
    <Stack vertical g={0.5}>
      <Stack.Item>
        <div
          style={{
            position: "relative",
            width: "360px",
            height: "360px",
            flexShrink: 0,
            margin: "0 auto",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          {previewActive &&
            worn_items?.slots &&
            Object.keys(SLOT_POS).map((slotId) => {
              const slot = worn_items.slots[slotId];
              if (!slot) {
                return null;
              }
              return <GearSlot key={slotId} slotId={slotId} slot={slot} />;
            })}
          {previewActive && (
            <>
              <HandSlot
                item={worn_items?.hands?.[1] ?? undefined}
                label="R"
                left={132}
              />
              <HandSlot
                item={worn_items?.hands?.[0] ?? undefined}
                label="L"
                left={184}
              />
            </>
          )}
          {previewActive ? (
            preview_image ? (
              <img
                src={preview_image}
                style={{
                  // 1.5x size (360px) to fill the empty space between the doll
                  // and the edge slots. Absolutely centered and behind the slots
                  // (zIndex 0) so its transparent margins sit under them without
                  // covering or blocking the slot frames/tooltips.
                  position: "absolute",
                  top: "50%",
                  left: "50%",
                  transform: "translate(-50%, -50%)",
                  zIndex: 0,
                  width: "360px",
                  height: "360px",
                  imageRendering: "pixelated",
                  pointerEvents: "none",
                }}
              />
            ) : (
              //RMH EDITED START - distinguish the three empty states.
              <Box
                color="gray"
                italic
                textAlign="center"
                style={{ maxWidth: "240px" }}
              >
                {!preview_available
                  ? "No in-game character to show."
                  : !preview_in_range
                    ? "Too far away to make out any detail."
                    : "Loading character..."}
              </Box>
              //RMH EDITED END
            )
          ) : (
            <img
              src={resolveAsset(shot)}
              width="320px"
              height="320px"
              style={{ objectFit: "contain" }}
            />
          )}
        </div>
      </Stack.Item>
      <Stack.Item>
        <Stack align="center" justify="center">
          {previewActive && (
            <Stack.Item>
              <Button
                icon="rotate-left"
                // RMH EDITED - nothing to rotate when the doll isn't rendered
                disabled={!canRender}
                tooltip="Rotate counterclockwise"
                onClick={() => act("rotate", { clockwise: false })}
              />
            </Stack.Item>
          )}
          <Stack.Item>
            <Button
              icon={previewActive ? "image" : "user"}
              disabled={!hasShot}
              tooltip={
                hasShot
                  ? previewActive
                    ? "Show the headshot image"
                    : "Show the in-game character"
                  : "No headshot set"
              }
              onClick={() => setShowPreview(!previewActive)}
            >
              {previewActive ? "Headshot" : "Character Preview"}
            </Button>
          </Stack.Item>
          {previewActive && (
            <Stack.Item>
              <Button
                icon="rotate-right"
                // RMH EDITED - nothing to rotate when the doll isn't rendered
                disabled={!canRender}
                tooltip="Rotate clockwise"
                onClick={() => act("rotate", { clockwise: true })}
              />
            </Stack.Item>
          )}
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

export const FlavorTextPage = (props) => {
  const { data } = useBackend<ExaminePanelData>();
  const { flavor_text, flavor_text_nsfw, ooc_notes, ooc_notes_nsfw, is_naked } =
    data;
  const [oocNotesIndex, setOocNotesIndex] = useState("SFW");
  const [flavorTextIndex, setFlavorTextIndex] = useState("SFW");

  const flavorHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${flavor_text}</span>`,
    }),
    [flavor_text],
  );

  const nsfwHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${flavor_text_nsfw}</span>`,
    }),
    [flavor_text_nsfw],
  );

  const oocHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${ooc_notes}</span>`,
    }),
    [ooc_notes],
  );

  const oocnsfwHTML = useMemo(
    () => ({
      __html: `<span className='Chat'>${ooc_notes_nsfw}</span>`,
    }),
    [ooc_notes_nsfw],
  );

  return (
    <Stack fill>
      <div style={{ width: "372px", flexShrink: 0, flexGrow: 0 }}>
        <Stack fill vertical>
          <Stack.Item align="center">
            <CharacterPortrait nsfw={flavorTextIndex === "NSFW"} />
          </Stack.Item>
          <Stack.Item grow>
            <Stack fill>
              <Stack.Item grow width="300px">
                <Section
                  scrollable
                  fill
                  title="OOC Notes"
                  preserveWhitespace
                  buttons={
                    <>
                      <Button
                        selected={oocNotesIndex === "SFW"}
                        bold={oocNotesIndex === "SFW"}
                        onClick={() => {
                          setOocNotesIndex("SFW");
                        }}
                        textAlign="center"
                        minWidth="60px"
                      >
                        SFW
                      </Button>
                      <Button
                        selected={oocNotesIndex === "NSFW"}
                        disabled={!ooc_notes_nsfw}
                        bold={oocNotesIndex === "NSFW"}
                        onClick={() => {
                          setOocNotesIndex("NSFW");
                        }}
                        textAlign="center"
                        minWidth="60px"
                      >
                        NSFW
                      </Button>
                    </>
                  }
                >
                  {oocNotesIndex === "SFW" && (
                    <Box
                      dangerouslySetInnerHTML={{
                        __html: ooc_notes
                          ? `<span class='Chat'>${ooc_notes}</span>`
                          : "<i>No OOC notes provided.</i>",
                      }}
                    />
                  )}
                  {oocNotesIndex === "NSFW" && (
                    <Box dangerouslySetInnerHTML={oocnsfwHTML} />
                  )}
                </Section>
              </Stack.Item>
            </Stack>
          </Stack.Item>
        </Stack>
      </div>
      <Stack.Item grow>
        <Section
          scrollable
          fill
          preserveWhitespace
          title="Flavor Text"
          buttons={
            <>
              <Button
                selected={flavorTextIndex === "SFW"}
                bold={flavorTextIndex === "SFW"}
                onClick={() => setFlavorTextIndex("SFW")}
                textAlign="center"
                width="60px"
              >
                SFW
              </Button>
              <Button
                selected={flavorTextIndex === "NSFW"}
                disabled={!is_naked || !flavor_text_nsfw}
                bold={flavorTextIndex === "NSFW"}
                onClick={() => setFlavorTextIndex("NSFW")}
                textAlign="center"
                width="60px"
              >
                NSFW
              </Button>
            </>
          }
        >
          {flavorTextIndex === "SFW" && (
            <Box
              dangerouslySetInnerHTML={{
                __html: flavor_text
                  ? `<span class='Chat'>${flavor_text}</span>`
                  : "<i>No flavor text provided.</i>",
              }}
            />
          )}
          {flavorTextIndex === "NSFW" && (
            <Box dangerouslySetInnerHTML={nsfwHTML} />
          )}
        </Section>
      </Stack.Item>
    </Stack>
  );
};

export const ImageGalleryPage = () => {
  const { data } = useBackend<ExaminePanelData>();
  const { img_gallery, nsfw_img_gallery, is_naked } = data;
  const imgGallery = Array.isArray(img_gallery) ? img_gallery : [];
  const nsfwImgGallery = Array.isArray(nsfw_img_gallery)
    ? nsfw_img_gallery
    : [];

  const [galleryMode, setGalleryMode] = useState<"SFW" | "NSFW">("SFW");

  const images = galleryMode === "NSFW" ? nsfwImgGallery : imgGallery;

  return (
    <Section
      title="Image Gallery"
      fill
      scrollable
      buttons={
        <>
          <Button
            selected={galleryMode === "SFW"}
            bold={galleryMode === "SFW"}
            onClick={() => setGalleryMode("SFW")}
            textAlign="center"
            minWidth="60px"
          >
            SFW
          </Button>
          <Button
            selected={galleryMode === "NSFW"}
            disabled={!is_naked || nsfwImgGallery.length === 0}
            bold={galleryMode === "NSFW"}
            onClick={() => setGalleryMode("NSFW")}
            textAlign="center"
            minWidth="60px"
          >
            NSFW
          </Button>
        </>
      }
    >
      {images.length === 0 ? (
        <Box align="center" color="gray">
          No images available.
        </Box>
      ) : (
        <Stack fill justify="space-evenly">
          {images.map((val) => (
            <Stack.Item grow key={val}>
              <Section align="center">
                <Image
                  maxHeight="100%"
                  maxWidth="100%"
                  src={resolveAsset(val)}
                />
              </Section>
            </Stack.Item>
          ))}
        </Stack>
      )}
    </Section>
  );
};
