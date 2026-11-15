import {
  type CSSProperties,
  Fragment,
  type ReactNode,
  useEffect,
  useLayoutEffect,
  useRef,
  useState,
} from 'react';
import { Box, ByondUi, DmIcon, Icon } from 'tgui-core/components';

import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { dragStartHandler } from '../drag';
import { Window } from '../layouts';
import {
  type CharacterCreatorStrings,
  characterCreatorStrings,
} from './CharacterCreator.i18n';
import { LoadoutPanel } from './CharacterCreatorLoadout';
import {
  type ProstheticData,
  ProstheticsPanel,
} from './CharacterCreatorProsthetics';
import { PreferencesBadges } from './PreferencesBadges';

// ---------------------------------------------------------------------------
// Data contract: legacy character setup data (character_menu_tgui.dm) plus the
// cc_* additions from modular_rmh/modular/character_creator/character_creator.dm.
// ---------------------------------------------------------------------------

type Booleanish = boolean | number;

type SpeciesStat = { name: string; label: string; value: number };
type SpeciesEntry = {
  id: string;
  name: string;
  description: string;
  available: Booleanish;
  lock_reason: string;
  language: string;
  ancestry_label: string;
  ages: string;
  tags: string[];
  tag_descriptions?: Record<string, string>;
  stats: SpeciesStat[];
};
type PatronEntry = {
  id: string;
  name: string;
  domain: string;
  description: string;
  flaws: string;
  worshippers: string;
  sins: string;
  boons: string;
  available: Booleanish;
  selected: Booleanish;
};
type FaithEntry = {
  id: string;
  name: string;
  description: string;
  available: Booleanish;
  selected: Booleanish;
  patrons: PatronEntry[];
};
type AncestryOption = {
  name: string;
  value: string;
  color: string;
  selected: Booleanish;
};
type FeatureOption = {
  name: string;
  value: string;
  thumb?: string;
  coverage?: string;
};
type FeatureColor = { name: string; value: string; index: string };
type FeatureExtra = {
  task: string;
  label: string;
  kind: 'color' | 'text' | 'number';
  value: string | number;
  min?: number;
  max?: number;
  step?: number;
  unit?: string;
  readonly?: Booleanish;
};
type FeatureEntry = {
  key: string;
  name: string;
  enabled: Booleanish;
  can_disable: Booleanish;
  choice_name: string;
  choice_value?: string;
  choice_options?: FeatureOption[];
  accessory_name?: string;
  accessory_value?: string;
  accessory_options?: FeatureOption[];
  colors?: FeatureColor[];
  extras?: FeatureExtra[];
  erp?: Booleanish;
};
type SmallclothesCatalogEntry = {
  id: string;
  name: string;
  options: FeatureOption[];
};
type SmallclothesEntry = {
  id: string;
  value: string;
  name: string;
  color: string | null;
};
type LoadoutCatalogEntry = {
  name: string;
  desc: string;
  point_cost: number;
  typepath: string;
  icon: string;
  nobility_locked: Booleanish;
};
type LoadoutSlotData = {
  slot: number;
  item_name: string | null;
  typepath: string | null;
  point_cost: number;
  custom_name: string | null;
  custom_desc: string | null;
  custom_hex: string | null;
};
type JobChoice = { value: string };
type StatLine = { name: string; value: number };
type TraitLine = { name: string; desc: string };
type SubclassDetails = {
  title: string;
  tutorial: string;
  stats: StatLine[];
  spell_points: number;
  languages: string[];
  traits: TraitLine[];
  skills: { name: string; level: string }[];
};
type JobDetails = {
  stats: StatLine[];
  stat_limits: StatLine[];
  spell_points: number;
  traits: TraitLine[];
  subclasses: SubclassDetails[];
};
type JobEntry = {
  title: string;
  tutorial: string;
  slots: number;
  has_info?: Booleanish;
  title_choices: JobChoice[];
  honorary_choices: JobChoice[];
  details?: JobDetails;
  required_jobs?: string[];
};
type JobCategory = { name: string; color: string; jobs: JobEntry[] };
type JobState = {
  display_name: string;
  pref_level: number | null;
  status: 'available' | 'locked' | 'banned';
  lock_label?: string;
  lock_detail?: string[];
  current_title: string;
  current_honorary: string;
};
type ErpFlag = {
  name: string;
  bit: number;
  description: string;
  on: Booleanish;
};
type ErpPrefEntry = {
  type: string;
  name: string;
  description: string;
  kind: 'bool' | 'flags' | 'number' | 'choice';
  value?: unknown;
  flags?: ErpFlag[];
  min?: number;
  max?: number;
  choices?: string[];
  lock_reason?: string;
};
type ErpKink = {
  name: string;
  description: string;
  enabled: Booleanish;
  intensity: number;
  notes: string;
};
type OriginEntry = {
  id: string;
  name: string;
  description: string;
  group: string | null;
  map_x: number | null;
  map_y: number | null;
  accent: string | null;
};
type OriginGroup = { id: string; name: string };
type SubclassEntry = {
  id: string;
  title: string;
  tutorial: string;
  has_info: Booleanish;
};
type StatRow = {
  name: string;
  desc?: string;
  icon?: string | null;
  icon_state?: string | null;
  label: string;
  base: number;
  species: number;
  age: number;
  total: number;
};
type DescriptorEntry = {
  choice: string;
  name: string;
  value: string;
  value_name: string;
  options: { value: string; name: string }[];
};
type CustomDescriptor = {
  index: number;
  name?: string;
  prefix?: string | null;
  text: string;
  visible: Booleanish;
};
type MarkingZone = {
  id: string;
  name: string;
  entries: { name: string; color: string; emissive?: Booleanish }[];
  can_add: Booleanish;
};

type CreatorData = {
  real_name: string;
  initial_tab: string;
  open_sequence: number;
  preferences_fullscreen: Booleanish;
  preferences_scale: number;
  species_id: string;
  species_name: string;
  species_options: SpeciesEntry[];
  is_taur: Booleanish;
  taur_body: string;
  taur_color: string;
  taur_markings: string;
  taur_tertiary: string;
  gender: string;
  default_slot: number;
  patron_name: string;
  faith_name: string;
  selected_patron_id: string;
  selected_faith_id: string;
  faith_options: FaithEntry[];
  high_job: string;
  age: string;
  age_options: string[];
  age_tooltips: Record<string, string>;
  pronouns: string;
  domhand: string;
  ancestry_label: string;
  ancestry_value: string;
  ancestry_options: AncestryOption[];
  mutant_colors: { slot: number; color: string }[];
  use_skintones: Booleanish;
  use_titles: Booleanish;
  race_title: string;
  erp: {
    lock_reason: string | null;
    categories: { name: string; prefs: ErpPrefEntry[] }[];
    kink_categories: { name: string; kinks: ErpKink[] }[];
  };
  genital_set_label: string;
  genital_extra_unlock: Booleanish;
  headshot: string | null;
  nsfw_headshot: string | null;
  features: FeatureEntry[];
  smallclothes_catalog: SmallclothesCatalogEntry[];
  smallclothes: { random: Booleanish; entries: SmallclothesEntry[] };
  combat_music: string;
  defeat_mode: string;
  defeat_threshold: number;
  song_set: Booleanish;
  song_title: string;
  song_artist: string;
  preview_underwear: Booleanish;
  preview_clothes: Booleanish;
  background: string;
  background_options: FeatureOption[];
  thumbs?: Record<string, string>;
  preview_map: string | null;
  preview_bbox_w: number;
  preview_bbox_h: number;
  voice_type: string;
  voice_color: string;
  voice_pack: string;
  speech_bark: string;
  speech_moans: Booleanish;
  moan_selection: string;
  selected_accent: string;
  loadout_catalog: LoadoutCatalogEntry[];
  loadout_slots: LoadoutSlotData[];
  loadout_points: { total: number; spent: number; remaining: number };
  loadout_presets: { slot: number; summary: string }[];
  triumphs: number;
  body_build?: string | null;
  body_build_name?: string;
  body_build_options?: { id: string; name: string }[];
  round_action_label: string;
  round_action_icon: string;
  round_action_color: string | null;
  round_action_disabled: Booleanish;
  round_action_tooltip: string;
  round_ready_players?: number;
  round_total_players?: number;
  cc_unsaved?: Booleanish;
  game_prefs: Record<string, Booleanish | string>;
  job_categories?: JobCategory[];
  job_states?: Record<string, JobState>;
  jobless_role?: string;
  last_class?: string;
  job_changes_locked?: Booleanish;
  race_banned?: Booleanish;
  race_banned_name?: string;
  // Character Creator additions.
  cc_lang?: string;
  cc_origins?: { origins: OriginEntry[]; groups: OriginGroup[] };
  cc_subclasses?: Record<string, SubclassEntry[]>;
  cc_loadout_categories?: Record<string, string>;
  cc_culture?: string;
  cc_cultures_available?: string[];
  cc_subclass_prefs?: Record<string, string>;
  cc_stats?: StatRow[];
  cc_quirks?: {
    names: string[];
    entries?: { name: string; desc: string }[];
    balance: number;
  };
  cc_species_groups?: { id: string; name: string; species: string[] }[];
  cc_species_desc?: Record<string, string>;
  cc_texts?: Record<string, string>;
  // Sandbox editors (succubus disguise, ooze reshape)
  disguise_mode?: Booleanish;
  ooze_mode?: Booleanish;
  slots?: {
    slot: number;
    unlocked: Booleanish;
    occupied: Booleanish;
    name: string;
    active: Booleanish;
  }[];
  selected_slot?: number;
  contract_tier?: number;
  creation_cost?: number;
  essence?: number;
  commit_available?: Booleanish;
  commit_reason?: string;
  cc_ooc_media?: string;
  cc_descriptors?: { entries: DescriptorEntry[]; custom: CustomDescriptor[] };
  cc_markings?: MarkingZone[];
  cc_rivals?: number;
  cc_tattoo_count?: number;
  cc_tattoos?: TattooData;
  cc_prosthetics?: ProstheticData;
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

type Tab =
  | 'fate'
  | 'body'
  | 'loadout'
  | 'info'
  | 'gameplay'
  | 'intimacy'
  | 'settings';
type FateCat =
  | 'identity'
  | 'origin'
  | 'suborigin'
  | 'race'
  | 'subrace'
  | 'role'
  | 'subrole'
  | 'deity'
  | 'background'
  | 'ability';
type MirrorCat =
  | 'head'
  | 'markings'
  | 'body'
  | 'prosthetics'
  | 'taur'
  | 'genitals'
  | 'attire'
  | 'piercing';
type Overlay =
  | null
  | { kind: 'confirm_random' }
  | { kind: 'confirm_close' }
  | { kind: 'confirm_race'; id: string };

const FATE_ORDER: FateCat[] = [
  'identity',
  'origin',
  'suborigin',
  'race',
  'subrace',
  'role',
  'subrole',
  'deity',
  'background',
  'ability',
];
const MIRROR_ORDER: MirrorCat[] = [
  'head',
  'markings',
  'body',
  'taur',
  'genitals',
  'attire',
  'piercing',
  'prosthetics',
];

const HEAD_PATTERNS = [
  '/hair/head',
  '/hair/facial',
  'eyes',
  'face_detail',
  '/organ/ears',
  '/organ/horns',
  '/organ/snout',
  '/organ/frills',
  '/organ/antennas',
  'tusk',
];
const HAIR_PATTERNS = ['/hair/head', '/hair/facial'];
const ACCESSORY_PATTERNS = ['/accessory'];
const PIERCING_PATTERNS = ['/piercing'];

const matchRank = (key: string, patterns: string[]) =>
  patterns.findIndex((pattern) => key.includes(pattern));
const matches = (key: string, patterns: string[]) =>
  matchRank(key, patterns) !== -1;
const byPattern = (patterns: string[]) => (a: FeatureEntry, b: FeatureEntry) =>
  matchRank(a.key, patterns) - matchRank(b.key, patterns);

const asBool = (value: Booleanish | string | undefined | null) =>
  value === true || value === 1;
const text = (value: unknown, fallback = '') => {
  const shown = String(value ?? '').trim();
  return shown || fallback;
};
const swatch = (value: string | null | undefined) => {
  const shown = String(value || '').trim();
  if (!shown) {
    return '#888888';
  }
  return shown.startsWith('#') ? shown : `#${shown}`;
};
const clampScale = (value: unknown) => {
  const scale = Number(value);
  if (!Number.isFinite(scale)) {
    return 1;
  }
  return Math.max(0.8, Math.min(1.25, Math.round(scale * 20) / 20));
};
const monogram = (name: string) =>
  text(name, '?')
    .split(/[\s-]+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join('');
const cycle = <T,>(list: T[], current: T, step: number) => {
  if (!list.length) {
    return current;
  }
  const index = Math.max(0, list.indexOf(current));
  return list[(index + step + list.length) % list.length];
};

/** Vanderlin skill ranks, used to name proficiency levels in race descriptions. */
const SKILL_RANKS = [
  'None',
  'Novice',
  'Apprentice',
  'Journeyman',
  'Expert',
  'Master',
  'Legendary',
];

type ParsedSpecies = {
  body: string;
  stats: string[];
  traits: string[];
  proficiencies: { name: string; level: number }[];
  warning: string;
};

/**
 * Species descriptions end with "(+1 PER, Darkvision, ...)" and "Proficiencies: X(4), ...".
 * They are pulled out of the text and shown as bonus rows instead.
 */
const parseSpeciesDesc = (raw: string): ParsedSpecies => {
  let body = raw || '';
  let warning = '';
  const warnAt = body.search(/THIS IS A DISCRIMINATED SPECIES/i);
  if (warnAt >= 0) {
    warning = body.slice(warnAt).trim();
    body = body.slice(0, warnAt);
  }
  const proficiencies: { name: string; level: number }[] = [];
  const profMatch = body.match(/Proficiencies:\s*([^\n]*)/i);
  if (profMatch) {
    for (const part of profMatch[1].split(',')) {
      const item = part.match(/^\s*([^()]+?)\s*\((\d+)\)/);
      if (item) {
        proficiencies.push({ name: item[1].trim(), level: Number(item[2]) });
      }
    }
    body = body.replace(profMatch[0], '');
  }
  let stats: string[] = [];
  let traits: string[] = [];
  const groups = [...body.matchAll(/\(([^()]*[+-]\d[^()]*)\)\.?/g)];
  const last = groups[groups.length - 1];
  if (last) {
    const tokens = last[1]
      .split(',')
      .map((token) => token.trim())
      .filter(Boolean);
    stats = tokens.filter((token) => /^[+-]\d/.test(token));
    traits = tokens.filter((token) => !/^[+-]\d/.test(token));
    body = body.replace(last[0], '');
  }
  body = body.replace(/\n{3,}/g, '\n\n').trim();
  return { body, stats, traits, proficiencies, warning };
};

/** Job category icons until real role art exists. */
const CATEGORY_ICONS: Record<string, string> = {
  Lords: 'crown',
  'The Keep': 'chess-rook',
  'Town Hall': 'landmark',
  'Town Watch': 'shield-alt',
  Chapel: 'place-of-worship',
  Scholars: 'book',
  Traders: 'coins',
  Tavern: 'beer',
  Towners: 'home',
  Outsiders: 'hiking',
  Adventurers: 'compass',
  Villains: 'skull',
};

const PRIORITY_COLORS: Record<number, string> = {
  3: '#e8c547',
  2: '#e08a2e',
  1: '#c4452f',
};

// ---------------------------------------------------------------------------
// Styles. Everything is scoped under .cc so the shared theme stays untouched.
// The layout is a CSS grid whose columns shrink with the window; media queries
// fold the summary card under the doll and turn the rail into icons on small
// windows, the same approach as the responsive lobby in BandaTroopers.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Small building blocks
// ---------------------------------------------------------------------------

type BtnProps = {
  children?: ReactNode;
  icon?: string;
  onClick?: () => void;
  className?: string;
  title?: string;
  disabled?: boolean;
  style?: CSSProperties;
};

export const Btn = (props: BtnProps) => {
  const { children, icon, onClick, className, title, disabled, style } = props;
  return (
    <div
      className={`cc-btn ${className || ''} ${disabled ? 'disabled' : ''}`}
      title={title}
      style={style}
      onClick={disabled ? undefined : onClick}
    >
      {icon ? <Icon name={icon} /> : null}
      {children}
    </div>
  );
};

export const Frame = (props: {
  className?: string;
  title?: ReactNode;
  children?: ReactNode;
  style?: CSSProperties;
}) => (
  <div className={`cc-frame ${props.className || ''}`} style={props.style}>
    {props.title ? <div className="cc-frame-title">{props.title}</div> : null}
    {props.children}
  </div>
);

export const Ornament = (props: { children?: ReactNode }) => (
  <div className="cc-ornament">{props.children}</div>
);

type TileProps = {
  name: string;
  icon?: string;
  selected?: boolean;
  inspected?: boolean;
  locked?: boolean;
  badge?: string;
  title?: string;
  mark?: string;
  controls?: ReactNode;
  onClick?: () => void;
  onMiddle?: () => void;
  onRight?: () => void;
};

/** Dynamic icon tile. Real art replaces the glyph once icons exist. */
const Tile = (props: TileProps) => {
  const { name, icon, selected, inspected, locked, badge, title, mark } =
    props;
  return (
    <div
      className={`cc-tile ${selected ? 'selected' : ''} ${inspected ? 'inspected' : ''} ${locked ? 'locked' : ''}`}
      title={title || name}
      onClick={props.onClick}
      onMouseDown={(event) => {
        if (event.button === 1 && props.onMiddle) {
          event.preventDefault();
          props.onMiddle();
        }
      }}
      onContextMenu={(event) => {
        if (props.onRight) {
          event.preventDefault();
          props.onRight();
        }
      }}
    >
      {badge ? (
        <div className="cc-tile-badge" style={{ backgroundColor: badge }} />
      ) : null}
      {locked ? (
        <Icon className="cc-tile-lock" name="lock" />
      ) : mark ? (
        <Icon className="cc-tile-mark" name={mark} />
      ) : null}
      {icon ? (
        <Icon className="cc-tile-icon" name={icon} />
      ) : (
        <div className="cc-tile-mono">{monogram(name)}</div>
      )}
      <div className="cc-tile-name">{name}</div>
      {props.controls ? (
        <div
          className="cc-tile-ctl"
          onClick={(event) => event.stopPropagation()}
          onContextMenu={(event) => {
            event.preventDefault();
            event.stopPropagation();
          }}
        >
          {props.controls}
        </div>
      ) : null}
    </div>
  );
};

const Switcher = (props: {
  name: string;
  onPrev: () => void;
  onNext: () => void;
  options?: { value: string; label: string }[];
  onPick?: (value: string) => void;
}) => (
  <div className="cc-switcher">
    <Btn className="square" icon="chevron-left" onClick={props.onPrev} />
    {props.options && props.onPick ? (
      <div className="cc-switcher-pick">
        <Select
          value={props.name}
          options={props.options}
          onChange={props.onPick}
        />
      </div>
    ) : (
      <div className="cc-switcher-name">{props.name}</div>
    )}
    <Btn className="square" icon="chevron-right" onClick={props.onNext} />
  </div>
);

const Bonus = (props: { title: string; children?: ReactNode }) => (
  <div className="cc-bonus">
    <div className="cc-bonus-title">{props.title}</div>
    {props.children}
  </div>
);

export const Placeholder = (props: { children?: ReactNode }) => (
  <div className="cc-placeholder">
    <Icon name="hammer" mr={0.5} />
    {props.children}
  </div>
);

// Tooltips in the Examine Closer style. Hovering shows one; Shift, S or T pins it in
// place, and a pinned tooltip blocks the editor until the player clicks outside it.
// The doll is a native map control drawn above the page, so tooltips are placed
// on whichever side of their anchor does not cover it.
export type TermTip = {
  title: ReactNode;
  subtitle?: ReactNode;
  body: ReactNode;
  anchor: { left: number; top: number; right: number; bottom: number };
  pinned: boolean;
};

let setTermTipGlobal: ((tip: TermTip | null) => void) | null = null;
let currentTermTip: TermTip | null = null;
/** Area tooltips must not cover (the doll), set by the window that has one. */
let avoidRectGetter: () => DOMRect | null = () => null;

export const showTip = (
  element: HTMLElement,
  title: ReactNode,
  body: ReactNode,
  subtitle?: ReactNode,
) => {
  if (currentTermTip?.pinned) {
    return;
  }
  const rect = element.getBoundingClientRect();
  setTermTipGlobal?.({
    title,
    subtitle,
    body,
    anchor: {
      left: rect.left,
      top: rect.top,
      right: rect.right,
      bottom: rect.bottom,
    },
    pinned: false,
  });
};

export const hideTip = () => {
  if (!currentTermTip?.pinned) {
    setTermTipGlobal?.(null);
  }
};

/** Any element with a rich tooltip. */
export const Tip = (props: {
  title: ReactNode;
  subtitle?: ReactNode;
  body: ReactNode;
  children?: ReactNode;
  className?: string;
  style?: CSSProperties;
  onClick?: () => void;
}) => (
  <span
    className={props.className}
    style={props.style}
    onClick={props.onClick}
    onMouseEnter={(event) =>
      showTip(event.currentTarget, props.title, props.body, props.subtitle)
    }
    onMouseLeave={hideTip}
  >
    {props.children}
  </span>
);

/** Underlined term with a plain text tooltip. */
const Term = (props: { label: string; title?: string; body: ReactNode }) => (
  <Tip className="cc-link" title={props.title || props.label} body={props.body}>
    {props.label}
  </Tip>
);

/** Renders the active tooltip and keeps it off the doll and inside the window. */
export const TipLayer = (props: { pinHint: string }) => {
  const [tip, setTip] = useState<TermTip | null>(null);
  const [pos, setPos] = useState<{ left: number; top: number } | null>(null);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    setTermTipGlobal = (next) => {
      currentTermTip = next;
      setPos(null);
      setTip(next);
    };
    const onKey = (event: KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      if (
        target &&
        (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA')
      ) {
        return;
      }
      const pinKey = ['Shift', 's', 'S', 't', 'T', 'ы', 'Ы', 'е', 'Е'];
      if (
        pinKey.includes(event.key) &&
        currentTermTip &&
        !currentTermTip.pinned
      ) {
        const pinned = { ...currentTermTip, pinned: true };
        currentTermTip = pinned;
        setTip(pinned);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => {
      window.removeEventListener('keydown', onKey);
      setTermTipGlobal = null;
      currentTermTip = null;
    };
  }, []);

  useLayoutEffect(() => {
    const el = ref.current;
    if (!tip || !el) {
      return;
    }
    const width = el.offsetWidth;
    const height = el.offsetHeight;
    const anchor = tip.anchor;
    const margin = 6;
    const maxLeft = window.innerWidth - width - margin;
    const maxTop = window.innerHeight - height - margin;
    const clampPos = (left: number, top: number) => ({
      left: Math.max(margin, Math.min(left, maxLeft)),
      top: Math.max(margin, Math.min(top, maxTop)),
    });
    const candidates = [
      clampPos(anchor.right + margin, anchor.top),
      clampPos(anchor.left - width - margin, anchor.top),
      clampPos(anchor.left, anchor.bottom + margin),
      clampPos(anchor.left, anchor.top - height - margin),
    ];
    const avoid = avoidRectGetter();
    const overlaps = (
      box: { left: number; top: number },
      rect: { left: number; top: number; right: number; bottom: number },
    ) =>
      !(
        box.left + width <= rect.left ||
        box.left >= rect.right ||
        box.top + height <= rect.top ||
        box.top >= rect.bottom
      );
    const best =
      candidates.find(
        (box) => !(avoid && overlaps(box, avoid)) && !overlaps(box, anchor),
      ) ||
      candidates.find((box) => !(avoid && overlaps(box, avoid))) ||
      candidates[0];
    setPos(best);
  }, [tip]);

  if (!tip) {
    return null;
  }
  // Next to the doll there is little room, so the tooltip narrows to the free side.
  const avoid = avoidRectGetter();
  let maxWidth = 330;
  if (avoid && tip.anchor.left >= avoid.right) {
    maxWidth = Math.max(
      180,
      Math.min(330, window.innerWidth - avoid.right - 12),
    );
  }
  return (
    <>
      {tip.pinned ? (
        <div
          className="cc-pin-catcher"
          onClick={() => {
            currentTermTip = null;
            setTip(null);
          }}
        />
      ) : null}
      <div
        ref={ref}
        className={`cc-term-tip ${tip.pinned ? 'pinned' : ''}`}
        style={{
          left: pos ? pos.left : -9999,
          top: pos ? pos.top : -9999,
          maxWidth,
        }}
      >
        {!tip.pinned ? (
          <div className="cc-term-tip-key">{props.pinHint}</div>
        ) : null}
        <div className="cc-term-tip-title">{tip.title}</div>
        {tip.subtitle ? (
          <div className="cc-term-tip-sub">{tip.subtitle}</div>
        ) : null}
        <div className="cc-term-tip-body">{tip.body}</div>
      </div>
    </>
  );
};

export const setTipAvoidRect = (getter: () => DOMRect | null) => {
  avoidRectGetter = getter;
};

export type SelectOption = { value: string; label: string };

/** Dropdown drawn in the page. Native selects misbehave in the BYOND browser. */
export const Select = (props: {
  value: string;
  options: SelectOption[];
  onChange: (value: string) => void;
  disabled?: boolean;
  title?: string;
  placeholder?: string;
  style?: CSSProperties;
}) => {
  const [open, setOpen] = useState(false);
  const [dropUp, setDropUp] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const listRef = useRef<HTMLDivElement>(null);
  // Opens upward when the window edge would cut the list off, as in a footer.
  useLayoutEffect(() => {
    if (!open) {
      setDropUp(false);
      return;
    }
    const head = ref.current?.getBoundingClientRect();
    const list = listRef.current?.getBoundingClientRect();
    if (
      head &&
      list &&
      list.bottom > window.innerHeight &&
      head.top > window.innerHeight - head.bottom
    ) {
      setDropUp(true);
    }
  }, [open]);
  useEffect(() => {
    if (!open) {
      return;
    }
    const close = (event: MouseEvent) => {
      if (ref.current && !ref.current.contains(event.target as Node)) {
        setOpen(false);
      }
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [open]);
  const current = props.options.find((option) => option.value === props.value);
  return (
    <div
      ref={ref}
      className={`cc-dd ${open ? 'open' : ''} ${props.disabled ? 'disabled' : ''}`}
      title={props.title}
      style={props.style}
    >
      <div
        className="cc-dd-head"
        onClick={() => !props.disabled && setOpen(!open)}
      >
        <span className="cc-dd-label">
          {current?.label ?? props.placeholder ?? ''}
        </span>
        <Icon name={open ? 'caret-up' : 'caret-down'} />
      </div>
      {open ? (
        <div
          ref={listRef}
          className={`cc-dd-list cc-scroll ${dropUp ? 'up' : ''}`}
        >
          {props.options.map((option) => (
            <div
              key={option.value}
              className={`cc-dd-item ${option.value === props.value ? 'selected' : ''}`}
              onClick={() => {
                setOpen(false);
                if (option.value !== props.value) {
                  props.onChange(option.value);
                }
              }}
            >
              {option.label}
            </div>
          ))}
        </div>
      ) : null}
    </div>
  );
};

export const Swatch = (props: { color?: string | null; width?: number }) => (
  <span
    className="cc-sw"
    style={{
      backgroundColor: swatch(props.color),
      width: props.width ? `${props.width}px` : undefined,
    }}
  />
);

const swapAll = (source: string, from: string, to: string) =>
  source.split(from).join(to);

const escapeHtml = (source: string) =>
  source
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

/**
 * Port of parsemarkdown_basic() as the server renders flavour text.
 * The text is escaped first, so the result only holds tags made here.
 */
const renderFlavourMarkup = (raw: string) => {
  let t = escapeHtml(raw || '');
  if (!t) {
    return '';
  }
  const escapes: [string, string][] = [
    ['$', '$-'],
    ['\\\\', '$1'],
    ['\\**', '$2'],
    ['\\*', '$3'],
    ['\\__', '$4'],
    ['\\_', '$5'],
    ['\\^', '$6'],
    ['\\((', '$7'],
    ['\\))', '$8'],
    ['\\|', '$9'],
    ['\\%', '$0'],
    ['!', '$a'],
  ];
  for (const [from, to] of escapes) {
    t = swapAll(t, from, to);
  }
  t = t.replace(
    /-=([0-9a-fA-F]{6})([\s\S]*?)=-/g,
    '<span style="color:#$1">$2</span>',
  );
  t = swapAll(t, '((', '<span class="cc-md-small">');
  t = swapAll(t, '))', '</span>');
  t = t.replace(/-{3,}/g, '<hr>');
  // Lists: a line that starts with an odd asterisk becomes an item.
  const lines = t.split('\n');
  let level = -1;
  let singleSpace = -1;
  for (let index = 0; index < lines.length; index++) {
    let line = lines[index];
    const stars = (line.match(/\*/g) || []).length;
    if (stars % 2 === 1 && /^\s*\*/.test(line)) {
      let depth = line.match(/^( *)\*/)?.[1].length ?? 0;
      line = line.replace(/^ *(\*.*)$/, '$1');
      if (singleSpace === -1 && depth === 2) {
        singleSpace = level === 0 ? 0 : 1;
      }
      if (singleSpace === 0) {
        depth = depth % 2 ? Math.floor(depth / 2 + 0.25) : depth / 2;
      }
      line = line.replace('*', '<li>');
      while (level < depth) {
        line = `<ul>${line}`;
        level++;
      }
      while (level > depth) {
        line = `</ul>${line}`;
        level--;
      }
    } else {
      while (level >= 0) {
        line = `</ul>${line}`;
        level--;
      }
    }
    lines[index] = line;
  }
  t = lines.join('\n');
  while (level >= 0) {
    t += '</ul>';
    level--;
  }
  t = t.replace(/^#(?!#) ?(.+)$/gm, '<h2>$1</h2>');
  t = t.replace(/^##(?!#) ?(.+)$/gm, '<h3>$1</h3>');
  t = t.replace(/^###(?!#) ?(.+)$/gm, '<h4>$1</h4>');
  t = t.replace(/^#### ?(.+)$/gm, '<h5>$1</h5>');
  t = t.replace(/\*([^*]*)\*/g, '<i>$1</i>');
  t = t.replace(/_([^_]*)_/g, '<i>$1</i>');
  t = swapAll(t, '<i></i>', '!');
  t = swapAll(t, '</i><i>', '!');
  t = t.replace(/!([^!]+)!/g, '<b>$1</b>');
  t = t.replace(/\^([^^]+)\^/g, '<span class="cc-md-large">$1</span>');
  t = t.replace(/\|([^|]+)\|/g, '<div style="text-align:center">$1</div>');
  t = swapAll(t, '!', '</i><i>');
  const restores: [string, string][] = [
    ['$a', '!'],
    ['$1', '\\'],
    ['$2', '**'],
    ['$3', '*'],
    ['$4', '__'],
    ['$5', '_'],
    ['$6', '^'],
    ['$7', '(('],
    ['$8', '))'],
    ['$9', '|'],
    ['$0', '%'],
    ['$-', '$'],
  ];
  for (const [from, to] of restores) {
    t = swapAll(t, from, to);
  }
  return swapAll(t, '\n', '<br>');
};

type MarkupTool = {
  icon: string;
  title: (labels: CharacterCreatorStrings) => string;
  before: string;
  after: string;
  line?: boolean;
};

const MARKUP_TOOLS: MarkupTool[] = [
  { icon: 'bold', title: (L) => L.fmtBold, before: '**', after: '**' },
  { icon: 'italic', title: (L) => L.fmtItalic, before: '*', after: '*' },
  { icon: 'text-height', title: (L) => L.fmtLarge, before: '^', after: '^' },
  { icon: 'align-center', title: (L) => L.fmtCenter, before: '|', after: '|' },
  {
    icon: 'heading',
    title: (L) => L.fmtHeader,
    before: '# ',
    after: '',
    line: true,
  },
  {
    icon: 'list-ul',
    title: (L) => L.fmtList,
    before: '* ',
    after: '',
    line: true,
  },
  { icon: 'minus', title: (L) => L.fmtLine, before: '\n---\n', after: '' },
];

const TEXT_LIMIT = 8192;

/** Long character text edited in place, saved on demand like the Azure Peak blocks. */
const TextEditor = (props: {
  value: string;
  hint: string;
  labels: CharacterCreatorStrings;
  onSave: (value: string) => void;
}) => {
  const L = props.labels;
  const [draft, setDraft] = useState(props.value);
  const [dirty, setDirty] = useState(false);
  const [preview, setPreview] = useState(false);
  const area = useRef<HTMLTextAreaElement>(null);
  useEffect(() => {
    if (!dirty) {
      setDraft(props.value);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [props.value]);

  const change = (next: string) => {
    setDraft(next.slice(0, TEXT_LIMIT));
    setDirty(true);
  };

  // Wraps the selection in markup, or puts a prefix at the start of the line.
  const applyTool = (tool: MarkupTool) => {
    const element = area.current;
    const start = element ? element.selectionStart : draft.length;
    const end = element ? element.selectionEnd : draft.length;
    let next: string;
    let caretStart: number;
    let caretEnd: number;
    if (tool.line) {
      const lineStart = draft.lastIndexOf('\n', start - 1) + 1;
      next = draft.slice(0, lineStart) + tool.before + draft.slice(lineStart);
      caretStart = start + tool.before.length;
      caretEnd = end + tool.before.length;
    } else {
      next =
        draft.slice(0, start) +
        tool.before +
        draft.slice(start, end) +
        tool.after +
        draft.slice(end);
      caretStart = start + tool.before.length;
      caretEnd = end + tool.before.length;
    }
    change(next);
    setPreview(false);
    window.setTimeout(() => {
      area.current?.focus();
      area.current?.setSelectionRange(caretStart, caretEnd);
    }, 0);
  };

  return (
    <div className="cc-text-editor">
      <div className="cc-hint" style={{ textAlign: 'left' }}>
        {props.hint}
      </div>
      <div className="cc-row cc-md-tools">
        {MARKUP_TOOLS.map((tool) => (
          <Btn
            key={tool.icon}
            className="square"
            icon={tool.icon}
            title={tool.title(L)}
            onClick={() => applyTool(tool)}
          />
        ))}
        <div className="cc-grow" />
        <Btn
          icon={preview ? 'pen' : 'eye'}
          className={preview ? 'on' : ''}
          onClick={() => setPreview(!preview)}
        >
          {preview ? L.edit : L.preview}
        </Btn>
      </div>
      {preview ? (
        <div
          className="cc-md-preview cc-scroll"
          // Built from escaped text by renderFlavourMarkup, so only its own tags remain.
          dangerouslySetInnerHTML={{
            __html:
              renderFlavourMarkup(draft) ||
              `<i>${escapeHtml(L.nothingWritten)}</i>`,
          }}
        />
      ) : (
        <textarea
          ref={area}
          className="cc-textarea"
          value={draft}
          maxLength={TEXT_LIMIT}
          placeholder={L.nothingWritten}
          onChange={(event) => change(event.target.value)}
        />
      )}
      <div className="cc-row">
        <span className="cc-muted" style={{ fontSize: 10 }}>
          {draft.length} / {TEXT_LIMIT} ·{' '}
          {dirty ? L.unsavedChanges : L.savedText}
        </span>
        <div className="cc-grow" />
        <Btn
          icon="undo"
          disabled={!dirty}
          onClick={() => {
            setDraft(props.value);
            setDirty(false);
          }}
        >
          {L.revert}
        </Btn>
        <Btn
          className="primary"
          icon="save"
          disabled={!dirty}
          onClick={() => {
            props.onSave(draft);
            setDirty(false);
          }}
        >
          {L.save}
        </Btn>
      </div>
    </div>
  );
};

// ---------------------------------------------------------------------------
// Skin marks: tattoos, brands and body writing, edited under the markings list
// ---------------------------------------------------------------------------

type TattooEntry = {
  index: number;
  text: string;
  style: string;
  color: string;
  pigment: string;
  medium: string;
};
type TattooZone = {
  id: string;
  name: string;
  intimate: Booleanish;
  present: Booleanish;
  ink: number;
  brands: number;
  writing: number;
  entries: TattooEntry[];
};
type MarkColor = { name: string; color: string };
type TattooData = {
  limbs: { id: string; name: string; zones: TattooZone[] }[];
  styles: string[];
  pigments: MarkColor[];
  glows: MarkColor[];
  writing: { id: string; colors: MarkColor[] }[];
  brand_color: string;
  max_per_zone: number;
  max_brands: number;
  max_length: number;
  brand_max_length: number;
};

const TATTOO_LETTERING = 'lettering';
type MarkKind = 'ink' | 'brand' | 'arcane' | 'writing';
const MARK_KINDS: MarkKind[] = ['ink', 'brand', 'arcane', 'writing'];
const KIND_ICONS: Record<MarkKind, string> = {
  ink: 'pen-nib',
  brand: 'fire',
  arcane: 'wand-magic-sparkles',
  writing: 'paintbrush',
};
const WRITING_MEDIA = ['charcoal', 'paint', 'lipstick', 'quill'];

const markKind = (medium: string): MarkKind =>
  medium === 'brand' || medium === 'arcane' || medium === 'ink'
    ? medium
    : 'writing';

const markIcon = (medium: string) =>
  medium === 'quill' ? 'feather' : KIND_ICONS[markKind(medium)];

/** Text colour and glow of a mark, as close to its look in chat as the editor allows. */
const markTextStyle = (entry: TattooEntry): CSSProperties | undefined => {
  if (entry.medium === 'arcane') {
    return {
      color: entry.color,
      textShadow: `0 0 3px ${entry.color}, 0 0 7px ${entry.color}`,
    };
  }
  if (entry.medium === 'brand') {
    return { color: entry.color };
  }
  return undefined;
};

/** Skin mark zones grouped by limb; the tool row picks what Add makes. */
const TattooEditor = (props: {
  tattoos: TattooData;
  count: number;
  labels: CharacterCreatorStrings;
  onAct: (task: string, params: Record<string, unknown>) => void;
}) => {
  const { tattoos, count, onAct } = props;
  const L = props.labels;
  const [kind, setKind] = useState<MarkKind>('ink');
  const [inkStyle, setInkStyle] = useState(TATTOO_LETTERING);
  const [inkColor, setInkColor] = useState(tattoos.pigments[0]?.color ?? '');
  const [glowColor, setGlowColor] = useState(tattoos.glows[0]?.color ?? '');
  const [writingMedium, setWritingMedium] = useState('charcoal');
  const [writingColor, setWritingColor] = useState('');

  const writing = tattoos.writing.find((media) => media.id === writingMedium);
  const writingColors = writing?.colors ?? [];
  const shownWritingColor = writingColors.some(
    (option) => option.color === writingColor,
  )
    ? writingColor
    : (writingColors[0]?.color ?? '');

  const toOptions = (colors: MarkColor[]): SelectOption[] =>
    colors.map((option) => ({ value: option.color, label: option.name }));
  const styleOptions: SelectOption[] = tattoos.styles.map((style) => ({
    value: style,
    label:
      style === TATTOO_LETTERING
        ? L.tattooStyleLettering
        : L.tattooStyleDesign,
  }));
  const pigmentOptions = toOptions(tattoos.pigments);
  const glowOptions = toOptions(tattoos.glows);
  const lipstickOptions = toOptions(
    tattoos.writing.find((media) => media.id === 'lipstick')?.colors ?? [],
  );
  const writingOptions: SelectOption[] = WRITING_MEDIA.map((id) => ({
    value: id,
    label: L.markWritingMedia[id] ?? id,
  }));

  const newMedium = kind === 'writing' ? writingMedium : kind;
  const newColor =
    kind === 'ink'
      ? inkColor
      : kind === 'arcane'
        ? glowColor
        : kind === 'writing'
          ? shownWritingColor
          : tattoos.brand_color;
  // Paint asks for its colour on Add; every other tool needs one chosen here.
  const newColorReady =
    kind !== 'writing' || writingMedium === 'paint' || !!shownWritingColor;

  const hasRoom = (zone: TattooZone) =>
    kind === 'ink'
      ? zone.ink < tattoos.max_per_zone
      : kind === 'writing'
        ? zone.writing < 1
        : zone.brands < tattoos.max_brands;

  /** Colour control for an existing entry; fixed colours show only a swatch. */
  const entryColor = (zone: TattooZone, entry: TattooEntry, present: boolean) => {
    const recolor = (color: string) =>
      onAct('set_color', { zone: zone.id, index: entry.index, color });
    const options =
      entry.medium === 'ink'
        ? pigmentOptions
        : entry.medium === 'arcane'
          ? glowOptions
          : entry.medium === 'lipstick'
            ? lipstickOptions
            : null;
    if (options) {
      return (
        <>
          <Swatch color={entry.color} />
          <Select
            value={entry.color}
            options={options}
            placeholder={entry.pigment}
            title={L.tattooPigment}
            disabled={!present}
            onChange={recolor}
          />
        </>
      );
    }
    if (entry.medium === 'paint') {
      return (
        <div
          title={L.markRepaint}
          style={{ cursor: present ? 'pointer' : undefined }}
          onClick={present ? () => recolor('') : undefined}
        >
          <Swatch color={entry.color} />
        </div>
      );
    }
    return (
      <span title={entry.pigment}>
        <Swatch color={entry.color} />
      </span>
    );
  };

  return (
    <>
      <Ornament>
        {L.skinMarks} ({count})
      </Ornament>
      <div className="cc-hint">{L.markKindHints[kind]}</div>
      <div className="cc-row cc-tat-kinds">
        {MARK_KINDS.map((option) => (
          <Btn
            key={option}
            icon={KIND_ICONS[option]}
            className={kind === option ? 'gold' : ''}
            onClick={() => setKind(option)}
          >
            {L.markKinds[option]}
          </Btn>
        ))}
      </div>
      <div className="cc-row cc-tat-ink">
        <span className="cc-muted">{L.tattooNewInk}</span>
        <Select
          value={inkStyle}
          options={styleOptions}
          title={L.tattooStyle}
          onChange={setInkStyle}
        />
        {kind === 'writing' ? (
          <Select
            value={writingMedium}
            options={writingOptions}
            title={L.markWritingWith}
            onChange={setWritingMedium}
          />
        ) : null}
        {kind === 'ink' ? (
          <>
            <Swatch color={inkColor} />
            <Select
              value={inkColor}
              options={pigmentOptions}
              title={L.tattooPigment}
              onChange={setInkColor}
            />
          </>
        ) : null}
        {kind === 'arcane' ? (
          <>
            <Swatch color={glowColor} />
            <Select
              value={glowColor}
              options={glowOptions}
              title={L.markGlow}
              onChange={setGlowColor}
            />
          </>
        ) : null}
        {kind === 'brand' ? <Swatch color={tattoos.brand_color} /> : null}
        {kind === 'writing' && writingMedium === 'paint' ? (
          <span className="cc-muted">{L.markPaintOnAdd}</span>
        ) : null}
        {kind === 'writing' && writingColors.length > 1 ? (
          <>
            <Swatch color={shownWritingColor} />
            <Select
              value={shownWritingColor}
              options={toOptions(writingColors)}
              title={L.tattooPigment}
              onChange={setWritingColor}
            />
          </>
        ) : null}
        {kind === 'writing' && writingColors.length === 1 ? (
          <Swatch color={writingColors[0].color} />
        ) : null}
      </div>
      <div className="cc-marking-zones">
        {tattoos.limbs.map((limb) => (
          <div className="cc-marking-zone" key={limb.id}>
            <div className="cc-marking-zone-head">{limb.name}</div>
            {limb.zones.map((zone) => {
              const present = asBool(zone.present);
              const room = hasRoom(zone);
              return (
                <div className="cc-tat-zone" key={zone.id}>
                  <div className="cc-tat-zone-head">
                    <span className="cc-grow">{zone.name}</span>
                    {asBool(zone.intimate) ? (
                      <span
                        className="cc-tat-intimate"
                        title={L.tattooIntimate}
                      >
                        <Icon name="heart" />
                      </span>
                    ) : null}
                    <span
                      className={`cc-tat-count ${zone.ink >= tattoos.max_per_zone ? 'full' : ''}`}
                      title={L.markKinds.ink}
                    >
                      <Icon name={KIND_ICONS.ink} /> {zone.ink}/
                      {tattoos.max_per_zone}
                    </span>
                    <span
                      className={`cc-tat-count ${zone.brands >= tattoos.max_brands ? 'full' : ''}`}
                      title={L.markBrandCount}
                    >
                      <Icon name={KIND_ICONS.brand} /> {zone.brands}/
                      {tattoos.max_brands}
                    </span>
                    <Btn
                      className="cc-toggle"
                      icon="plus"
                      title={room ? L.markAdd[kind] : L.tattooFull}
                      disabled={!present || !room || !newColorReady}
                      onClick={() =>
                        onAct('add', {
                          zone: zone.id,
                          medium: newMedium,
                          style: inkStyle,
                          color: newColor,
                        })
                      }
                    >
                      {L.add}
                    </Btn>
                  </div>
                  {present ? null : (
                    <div className="cc-tat-missing">{L.tattooMissing}</div>
                  )}
                  {zone.entries.map((entry) => (
                    <div
                      className={`cc-tat-entry cc-tat-${markKind(entry.medium)}`}
                      key={entry.index}
                    >
                      <div className="cc-marking-row">
                        <span
                          className="cc-tat-medium"
                          title={L.markKinds[markKind(entry.medium)]}
                        >
                          <Icon name={markIcon(entry.medium)} />
                        </span>
                        <div
                          className={`cc-marking-name ${present ? 'cc-tat-text' : ''}`}
                          style={markTextStyle(entry)}
                          title={
                            present
                              ? `${entry.text}\n${L.tattooEditHint}`
                              : entry.text
                          }
                          onClick={
                            present
                              ? () =>
                                  onAct('edit', {
                                    zone: zone.id,
                                    index: entry.index,
                                  })
                              : undefined
                          }
                        >
                          {entry.style === TATTOO_LETTERING
                            ? `"${entry.text}"`
                            : entry.text}
                        </div>
                        <Btn
                          className="square danger"
                          icon="times"
                          title={L.remove}
                          onClick={() =>
                            onAct('remove', {
                              zone: zone.id,
                              index: entry.index,
                            })
                          }
                        />
                      </div>
                      <div className="cc-row cc-tat-controls">
                        <Select
                          value={entry.style}
                          options={styleOptions}
                          title={L.tattooStyle}
                          disabled={!present}
                          onChange={(style) =>
                            onAct('set_style', {
                              zone: zone.id,
                              index: entry.index,
                              style,
                            })
                          }
                        />
                        {entryColor(zone, entry, present)}
                        {markKind(entry.medium) === 'writing' ? (
                          <span className="cc-muted cc-tat-note">
                            {L.markWashes}
                          </span>
                        ) : null}
                      </div>
                    </div>
                  ))}
                </div>
              );
            })}
          </div>
        ))}
      </div>
    </>
  );
};

// ---------------------------------------------------------------------------
// Main window
// ---------------------------------------------------------------------------

export const CharacterCreator = () => {
  const { act, data } = useBackend<CreatorData>();
  const lang = data.cc_lang === 'ru' ? 'ru' : 'en';
  const L: CharacterCreatorStrings = characterCreatorStrings[lang];

  const initialTab = (): Tab =>
    data.initial_tab === 'game' ? 'settings' : 'fate';
  const [tab, setTab] = useState<Tab>(initialTab());
  const [fateCat, setFateCat] = useState<FateCat>('origin');
  const [mirrorCat, setMirrorCat] = useState<MirrorCat>('head');
  const [overlay, setOverlay] = useState<Overlay>(null);
  // Sandbox editors show only appearance; this picks their left column entry.
  const [sandboxView, setSandboxView] = useState<
    'identity' | 'fate' | 'mirror'
  >('identity');
  const sandbox = asBool(data.disguise_mode);
  const oozeMode = asBool(data.ooze_mode);
  const [originPopup, setOriginPopup] = useState(false);
  const [picker, setPicker] = useState<string | null>(null);
  const [pickerSearch, setPickerSearch] = useState('');
  const [search, setSearch] = useState('');
  const [searchOpen, setSearchOpen] = useState(false);
  const [menuScale, setMenuScaleState] = useState(
    clampScale(data.preferences_scale),
  );

  const [inspectOrigin, setInspectOrigin] = useState<string | null>(null);
  const [pendingGroup, setPendingGroup] = useState<string | null>(null);
  const [inspectSpecies, setInspectSpecies] = useState<string | null>(null);
  const [pendingRaceGroup, setPendingRaceGroup] = useState<string | null>(null);
  const [roleCategory, setRoleCategory] = useState<string | null>(null);
  const [inspectJob, setInspectJob] = useState<string | null>(null);
  const [inspectSubclass, setInspectSubclass] = useState<string | null>(null);
  const [faithView, setFaithView] = useState<string | null>(null);
  const [inspectPatron, setInspectPatron] = useState<string | null>(null);
  const [collapsed, setCollapsed] = useState<Record<string, boolean>>({});
  const [openText, setOpenText] = useState<string | null>('flavortext');
  const [helpOpen, setHelpOpen] = useState(false);
  const [erpTab, setErpTab] = useState<'general' | 'kinks' | 'badges'>(
    'general',
  );

  const hoverTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const dollBoxRef = useRef<HTMLDivElement>(null);

  // ---- Effects ----

  useEffect(() => {
    setTab(initialTab());
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data.open_sequence]);

  useEffect(() => {
    setTipAvoidRect(() => dollBoxRef.current?.getBoundingClientRect() || null);
    return () => setTipAvoidRect(() => null);
  }, []);

  // A picked style list belongs to the category it was opened from.
  useEffect(() => {
    setPicker(null);
  }, [mirrorCat, tab]);

  // The doll is a native map control. It stays mounted the whole time: remounting
  // it makes the window flash, so modals open inside the content frame instead.
  const [dollPx, setDollPx] = useState({ w: 0, h: 0 });
  useEffect(() => {
    const measure = () => {
      const dpr = window.devicePixelRatio || 1;
      const rect = dollBoxRef.current?.getBoundingClientRect();
      const w = Math.floor((rect?.width ?? 0) * dpr);
      const h = Math.floor((rect?.height ?? 0) * dpr);
      setDollPx((prev) => (prev.w === w && prev.h === h ? prev : { w, h }));
    };
    measure();
    const settle = setTimeout(measure, 300);
    window.addEventListener('resize', measure);
    return () => {
      clearTimeout(settle);
      window.removeEventListener('resize', measure);
    };
  }, []);

  // When the layout moves the doll box, the map control follows on one resize event.
  const layoutKey = `${tab}|${menuScale}|${data.preferences_fullscreen}`;
  const firstLayout = useRef(true);
  useEffect(() => {
    if (firstLayout.current) {
      firstLayout.current = false;
      return;
    }
    const timer = setTimeout(
      () => window.dispatchEvent(new Event('resize')),
      60,
    );
    return () => clearTimeout(timer);
  }, [layoutKey]);

  const bboxW = Math.max(16, Number(data.preview_bbox_w) || 0);
  const bboxH = Math.max(16, Number(data.preview_bbox_h) || 0);
  const dollZoom =
    dollPx.w && dollPx.h
      ? Math.max(
          1,
          Math.floor(
            Math.min((dollPx.w * 0.95) / bboxW, (dollPx.h * 0.88) / bboxH),
          ),
        )
      : 0;

  // The server zoom is only touched when the zoom actually changes.
  const reportedZoom = useRef(0);
  useEffect(() => {
    if (!dollZoom || reportedZoom.current === dollZoom) {
      return;
    }
    const timer = setTimeout(() => {
      reportedZoom.current = dollZoom;
      const rect = dollBoxRef.current?.getBoundingClientRect();
      act('pref', {
        preference: 'character_setup_report_geometry',
        main_w: Math.round(rect?.width ?? 0),
        main_h: Math.round(rect?.height ?? 0),
        win_w: Math.round(window.innerWidth),
        win_h: Math.round(window.innerHeight),
        dpr: window.devicePixelRatio,
        menu_scale: menuScale,
        zoom_main: dollZoom,
        zoom_mini: 0,
      });
    }, 250);
    return () => clearTimeout(timer);
  }, [dollZoom]);

  // ---- Actions ----

  const doPref = (
    preference: string,
    task?: string,
    extra?: Record<string, unknown>,
  ) => act('pref', { preference, ...(task ? { task } : {}), ...(extra || {}) });

  const customizerAct = (
    key: string,
    task: string,
    extra?: Record<string, unknown>,
  ) =>
    doPref('character_setup_customizer', undefined, {
      customizer: key,
      customizer_task: task,
      ...(extra || {}),
    });

  const requestHover = (
    value: string | null,
    color?: string,
    customizer?: string,
  ) => {
    if (hoverTimer.current) {
      clearTimeout(hoverTimer.current);
      hoverTimer.current = null;
    }
    hoverTimer.current = setTimeout(
      () =>
        doPref('character_setup_hover', undefined, {
          acc: value || '',
          color: value ? color || '' : '',
          customizer: value ? customizer || '' : '',
        }),
      value ? 320 : 260,
    );
  };

  const setMenuScale = (scale: number) => {
    const clamped = clampScale(scale);
    setMenuScaleState(clamped);
    doPref('character_setup_preferences_scale', undefined, { scale: clamped });
  };

  // ---- Derived data ----

  const features = data.features || [];
  const featureCat = (feature: FeatureEntry): MirrorCat => {
    if (asBool(feature.erp)) {
      return 'genitals';
    }
    if (matches(feature.key, PIERCING_PATTERNS)) {
      return 'piercing';
    }
    if (matches(feature.key, ACCESSORY_PATTERNS)) {
      return 'attire';
    }
    if (matches(feature.key, HEAD_PATTERNS)) {
      return 'head';
    }
    return 'body';
  };

  const origins = data.cc_origins?.origins || [];
  const originGroups = data.cc_origins?.groups || [];
  const availableCultures = data.cc_cultures_available || [];
  const currentOrigin = origins.find((origin) => origin.id === data.cc_culture);
  const groupName = (id: string | null | undefined) =>
    originGroups.find((group) => group.id === id)?.name || '';
  const activeGroup = pendingGroup || currentOrigin?.group || null;

  const species = data.species_options || [];
  const speciesGroups = data.cc_species_groups || [];
  const groupOfSpecies = (id: string | null | undefined) =>
    speciesGroups.find((entry) => entry.species.includes(id || ''));
  const activeRaceGroup =
    pendingRaceGroup || groupOfSpecies(data.species_id)?.id || null;
  const raceGroupName = (id: string | null) =>
    speciesGroups.find((entry) => entry.id === id)?.name || '';
  const jobCategories = data.job_categories || [];
  const jobStates = data.job_states || {};
  const allJobs = jobCategories.flatMap((category) => category.jobs);
  const highJobTitle =
    Object.keys(jobStates).find(
      (title) => jobStates[title]?.pref_level === 3,
    ) || null;
  const highSubclasses = highJobTitle
    ? data.cc_subclasses?.[highJobTitle] || []
    : [];
  const preferredSubclass = highJobTitle
    ? data.cc_subclass_prefs?.[highJobTitle]
    : undefined;

  const fateVisible: FateCat[] = FATE_ORDER.filter((cat) => {
    if (cat === 'suborigin') {
      return !!activeGroup;
    }
    if (cat === 'subrace') {
      return !!activeRaceGroup;
    }
    if (cat === 'subrole') {
      return highSubclasses.length > 0;
    }
    return true;
  });
  const mirrorVisible: MirrorCat[] = MIRROR_ORDER.filter(
    (cat) =>
      (cat !== 'taur' || asBool(data.is_taur)) &&
      (cat !== 'prosthetics' || !!data.cc_prosthetics),
  );
  // A category that disappeared (no sub-origin, no taur body) falls back to the one above it.
  const fallback = <T,>(order: T[], visible: T[], current: T) => {
    if (visible.includes(current)) {
      return current;
    }
    for (let index = order.indexOf(current); index >= 0; index--) {
      if (visible.includes(order[index])) {
        return order[index];
      }
    }
    return visible[0];
  };
  const activeFate = fallback(FATE_ORDER, fateVisible, fateCat);
  const activeMirror = fallback(MIRROR_ORDER, mirrorVisible, mirrorCat);

  const openCharacter = (next: 'fate' | 'body' = 'fate') => {
    setTab(next);
    setPicker(null);
  };

  const raisePriority = (job: string) => {
    const level = jobStates[job]?.pref_level ?? null;
    const next = level === null ? 1 : Math.min(3, level + 1);
    if (next !== level) {
      act('job_set_pref_level', { job, level: next });
    }
  };
  const lowerPriority = (job: string) => {
    const level = jobStates[job]?.pref_level ?? null;
    if (level === null) {
      return;
    }
    act('job_set_pref_level', { job, level: level <= 1 ? null : level - 1 });
  };

  // ---------------------------------------------------------------------------
  // Fate windows (left rail of the main screen)
  // ---------------------------------------------------------------------------

  // Keyed by title so switching categories never reuses the previous window's parts.
  const windowShell = (title: string, body: ReactNode, footer?: ReactNode) => (
    <div className="cc-window" key={title}>
      <div className="cc-frame-title">{title}</div>
      <div className="cc-window-body cc-scroll">{body}</div>
      {footer ? <div className="cc-window-foot">{footer}</div> : null}
    </div>
  );

  const originAvailable = (id: string) => availableCultures.includes(id);

  const renderOriginDetails = (origin: OriginEntry | undefined) =>
    origin ? (
      <>
        <div className="cc-name">{origin.name}</div>
        <div className="cc-desc">
          {text(origin.description, L.noDescription)}
        </div>
        <Bonus title={L.bonuses}>
          <div className="cc-chips">
            {origin.accent ? (
              <span className="cc-chip good">
                <Term label={L.accent} body={L.accentHint} />
              </span>
            ) : (
              <span className="cc-chip">{L.noBonuses}</span>
            )}
          </div>
        </Bonus>
        {!originAvailable(origin.id) ? (
          <div className="cc-hint" style={{ color: 'var(--cc-bad)' }}>
            {L.originLocked}
          </div>
        ) : null}
      </>
    ) : (
      <div className="cc-hint">{L.pickPin}</div>
    );

  const renderOrigin = () => {
    const mapOrigins = origins.filter(
      (origin) => origin.map_x !== null && !origin.group,
    );
    const inspected =
      origins.find((origin) => origin.id === inspectOrigin) ||
      (currentOrigin && !currentOrigin.group ? currentOrigin : undefined);
    const canSave =
      !!inspected &&
      originAvailable(inspected.id) &&
      inspected.id !== data.cc_culture;
    const otherOrigins = origins.filter(
      (origin) => origin.map_x === null && !origin.group,
    );
    return (
      <div className="cc-window" style={{ position: 'relative' }}>
        <div className="cc-frame-title">{L.originTitle}</div>
        <div className="cc-window-body cc-scroll">
          <div
            className="cc-map"
            style={{
              backgroundImage: `url(${resolveAsset('cc_origin_map.jpg')})`,
            }}
          >
            {mapOrigins.map((origin) => (
              <div
                key={origin.id}
                className={`cc-pin ${inspected?.id === origin.id ? 'active' : ''} ${originAvailable(origin.id) ? '' : 'locked'}`}
                style={{ left: `${origin.map_x}%`, top: `${origin.map_y}%` }}
                onClick={() => {
                  setInspectOrigin(origin.id);
                  setPendingGroup(null);
                }}
              >
                <div className="cc-pin-dot" />
                <div className="cc-pin-label">{origin.name}</div>
              </div>
            ))}
          </div>
          {renderOriginDetails(inspected)}
        </div>
        <div className="cc-row" style={{ padding: '6px 12px 10px' }}>
          <Btn
            className="fluid"
            icon="globe"
            onClick={() => setOriginPopup(true)}
          >
            {L.otherOrigins}
          </Btn>
          <Btn
            className="primary"
            icon="check"
            disabled={!canSave}
            onClick={() =>
              inspected && act('cc_set_culture', { id: inspected.id })
            }
          >
            {L.chooseOrigin}
          </Btn>
        </div>
        {originPopup ? (
          <div className="cc-overlay cc-overlay-full">
            <div className="cc-overlay-head">
              <div
                className="cc-grow cc-frame-title"
                style={{ padding: 0, textAlign: 'left' }}
              >
                {L.otherOrigins}
              </div>
              <Btn
                className="square"
                icon="times"
                onClick={() => setOriginPopup(false)}
              />
            </div>
            <div className="cc-scroll" style={{ padding: 10, flex: 1 }}>
              <div className="cc-tiles">
                {originGroups.map((group) => (
                  <Tile
                    key={group.id}
                    name={group.name}
                    icon="users"
                    selected={activeGroup === group.id}
                    locked={
                      !origins.some(
                        (origin) =>
                          origin.group === group.id &&
                          originAvailable(origin.id),
                      )
                    }
                    onClick={() => {
                      setPendingGroup(group.id);
                      setInspectOrigin(null);
                      setOriginPopup(false);
                      setFateCat('suborigin');
                    }}
                  />
                ))}
                {otherOrigins.map((origin) => (
                  <Tile
                    key={origin.id}
                    name={origin.name}
                    icon="map-signs"
                    selected={origin.id === data.cc_culture}
                    inspected={origin.id === inspectOrigin}
                    locked={!originAvailable(origin.id)}
                    onClick={() => {
                      setInspectOrigin(origin.id);
                      setPendingGroup(null);
                      setOriginPopup(false);
                    }}
                  />
                ))}
              </div>
            </div>
          </div>
        ) : null}
      </div>
    );
  };

  const renderSubOrigin = () => {
    const children = origins.filter((origin) => origin.group === activeGroup);
    const inspected =
      children.find((origin) => origin.id === inspectOrigin) ||
      children.find((origin) => origin.id === data.cc_culture) ||
      children[0];
    return windowShell(
      groupName(activeGroup) || L.subOrigin,
      <>
        <div className="cc-tiles">
          {children.map((origin) => (
            <Tile
              key={origin.id}
              name={origin.name}
              icon="campground"
              selected={origin.id === data.cc_culture}
              inspected={origin.id === inspected?.id}
              locked={!originAvailable(origin.id)}
              onClick={() => setInspectOrigin(origin.id)}
            />
          ))}
        </div>
        {renderOriginDetails(inspected)}
      </>,
      <Btn
        className="primary fluid"
        icon="check"
        disabled={
          !inspected ||
          !originAvailable(inspected.id) ||
          inspected.id === data.cc_culture
        }
        onClick={() => {
          if (inspected) {
            act('cc_set_culture', { id: inspected.id });
            setPendingGroup(null);
          }
        }}
      >
        {L.chooseOrigin}
      </Btn>,
    );
  };

  const speciesDesc = (entry: SpeciesEntry) =>
    data.cc_species_desc?.[entry.id] || entry.description || '';

  const renderSpeciesDetails = (entry: SpeciesEntry) => {
    const parsed = parseSpeciesDesc(speciesDesc(entry));
    // A disguise or reshape copies only the look, so racial stats and skills do not apply.
    if (sandbox) {
      return (
        <>
          <div className="cc-name">{entry.name}</div>
          <div className="cc-desc">{text(parsed.body, L.noDescription)}</div>
        </>
      );
    }
    return (
      <>
        <div className="cc-name">{entry.name}</div>
        <div className="cc-desc">{text(parsed.body, L.noDescription)}</div>
        <Bonus title={L.statModifiers}>
          <div className="cc-chips">
            {entry.stats?.length ? (
              entry.stats.map((stat) => (
                <Tip
                  key={stat.label}
                  className={`cc-chip ${stat.value > 0 ? 'good' : 'bad'}`}
                  title={`${stat.name} ${stat.value > 0 ? '+' : ''}${stat.value}`}
                  body={
                    data.cc_stats?.find((row) => row.label === stat.label)
                      ?.desc || stat.name
                  }
                >
                  {stat.label} {stat.value > 0 ? '+' : ''}
                  {stat.value}
                </Tip>
              ))
            ) : (
              <span className="cc-chip">{L.noStatModifiers}</span>
            )}
          </div>
        </Bonus>
        {parsed.traits.length ? (
          <Bonus title={L.raceTraits}>
            <div className="cc-chips">
              {parsed.traits.map((trait) => (
                <Tip
                  key={trait}
                  className="cc-chip"
                  title={trait}
                  subtitle={L.raceTrait}
                  body={entry.tag_descriptions?.[trait] || L.traitHint}
                >
                  <span className="cc-link">{trait}</span>
                </Tip>
              ))}
            </div>
          </Bonus>
        ) : null}
        {parsed.proficiencies.length ? (
          <Bonus title={L.proficiencies}>
            <div className="cc-chips">
              {parsed.proficiencies.map((skill) => (
                <Tip
                  key={skill.name}
                  className="cc-chip good"
                  title={skill.name}
                  subtitle={L.skill}
                  body={`${L.startsAt}: ${SKILL_RANKS[skill.level] || skill.level} (${skill.level})`}
                >
                  {skill.name} {skill.level}
                </Tip>
              ))}
            </div>
          </Bonus>
        ) : null}
        <Bonus title={L.language}>
          <div className="cc-chips">
            <span className="cc-chip">
              <Term
                label={entry.language}
                title={L.language}
                body={L.languageHint}
              />
            </span>
            <span className="cc-chip">
              {L.ages}: {entry.ages}
            </span>
            {(entry.tags || []).map((tag) => (
              <span key={tag} className="cc-chip">
                <Term label={tag} body={entry.tag_descriptions?.[tag] || tag} />
              </span>
            ))}
          </div>
        </Bonus>
        {parsed.warning ? (
          <div className="cc-hint" style={{ color: 'var(--cc-bad)' }}>
            {parsed.warning}
          </div>
        ) : null}
      </>
    );
  };

  const chooseRaceButton = (entry: SpeciesEntry | undefined) => {
    const canApply =
      !!entry && asBool(entry.available) && entry.id !== data.species_id;
    return (
      <Btn
        className="primary fluid"
        icon="check"
        disabled={!canApply}
        title={canApply ? L.raceApplyHint : entry?.lock_reason}
        onClick={() =>
          entry && setOverlay({ kind: 'confirm_race', id: entry.id })
        }
      >
        {entry?.id === data.species_id ? L.currentRace : L.chooseRace}
      </Btn>
    );
  };

  const renderRace = () => {
    // Subrace members collapse into one tile per race.
    const grouped = new Set(speciesGroups.flatMap((entry) => entry.species));
    type RaceTile = {
      id: string;
      name: string;
      group?: string;
      available: boolean;
    };
    const tiles: RaceTile[] = [
      ...speciesGroups.map((entry) => ({
        id: `group:${entry.id}`,
        name: entry.name,
        group: entry.id,
        available: entry.species.some((id) =>
          asBool(species.find((row) => row.id === id)?.available),
        ),
      })),
      ...species
        .filter((entry) => !grouped.has(entry.id))
        .map((entry) => ({
          id: entry.id,
          name: entry.name,
          available: asBool(entry.available),
        })),
    ].sort(
      (a, b) =>
        Number(b.available) - Number(a.available) ||
        a.name.localeCompare(b.name),
    );
    const currentTile =
      groupOfSpecies(data.species_id)?.id !== undefined
        ? `group:${groupOfSpecies(data.species_id)?.id}`
        : data.species_id;
    const inspectedTile = inspectSpecies || currentTile;
    const inspectedGroup = inspectedTile?.startsWith('group:')
      ? speciesGroups.find((entry) => `group:${entry.id}` === inspectedTile)
      : undefined;
    const inspected = inspectedGroup
      ? undefined
      : species.find((entry) => entry.id === inspectedTile);
    const groupLead = inspectedGroup
      ? species.find(
          (entry) =>
            inspectedGroup.species.includes(entry.id) &&
            entry.id === data.species_id,
        ) || species.find((entry) => entry.id === inspectedGroup.species[0])
      : undefined;
    return windowShell(
      L.raceTitle,
      <>
        <div className="cc-tiles">
          {tiles.map((tile) => (
            <Tile
              key={tile.id}
              name={tile.name}
              selected={tile.id === currentTile}
              inspected={tile.id === inspectedTile}
              locked={!tile.available}
              title={tile.group ? `${tile.name} · ${L.hasSubraces}` : tile.name}
              onClick={() => setInspectSpecies(tile.id)}
            />
          ))}
        </div>
        {inspectedGroup ? (
          <>
            <div className="cc-name">{inspectedGroup.name}</div>
            <div className="cc-hint">
              {L.subraces}:{' '}
              {inspectedGroup.species
                .map((id) => species.find((entry) => entry.id === id)?.name)
                .filter(Boolean)
                .join(', ')}
            </div>
            {groupLead ? (
              <div className="cc-desc">
                {text(
                  parseSpeciesDesc(speciesDesc(groupLead)).body,
                  L.noDescription,
                )}
              </div>
            ) : null}
          </>
        ) : inspected ? (
          renderSpeciesDetails(inspected)
        ) : null}
      </>,
      inspectedGroup ? (
        <Btn
          className="primary fluid"
          icon="arrow-right"
          onClick={() => {
            setPendingRaceGroup(inspectedGroup.id);
            setInspectSpecies(null);
            setFateCat('subrace');
          }}
        >
          {L.chooseSubrace}
        </Btn>
      ) : (
        chooseRaceButton(inspected)
      ),
    );
  };

  const renderSubRace = () => {
    const groupEntry = speciesGroups.find(
      (entry) => entry.id === activeRaceGroup,
    );
    const members = species.filter((entry) =>
      groupEntry?.species.includes(entry.id),
    );
    const inspected =
      members.find((entry) => entry.id === inspectSpecies) ||
      members.find((entry) => entry.id === data.species_id) ||
      members[0];
    return windowShell(
      `${L.rail.subrace}: ${groupEntry?.name || ''}`,
      <>
        <div className="cc-tiles">
          {members.map((entry) => (
            <Tile
              key={entry.id}
              name={entry.name}
              selected={entry.id === data.species_id}
              inspected={entry.id === inspected?.id}
              locked={!asBool(entry.available)}
              onClick={() => setInspectSpecies(entry.id)}
            />
          ))}
        </div>
        {inspected ? renderSpeciesDetails(inspected) : null}
      </>,
      chooseRaceButton(inspected),
    );
  };

  const renderRole = () => {
    if (asBool(data.race_banned)) {
      return windowShell(
        L.roleTitle,
        <div className="cc-hint" style={{ color: 'var(--cc-bad)' }}>
          {L.raceBanned} {data.race_banned_name}
        </div>,
      );
    }
    const highCategory = jobCategories.find((category) =>
      category.jobs.some((job) => job.title === highJobTitle),
    )?.name;
    const categoryName =
      roleCategory || highCategory || jobCategories[0]?.name || '';
    const category =
      jobCategories.find((entry) => entry.name === categoryName) ||
      jobCategories[0];
    const names = jobCategories.map((entry) => entry.name);
    const inspectedTitle =
      inspectJob && allJobs.some((job) => job.title === inspectJob)
        ? inspectJob
        : highJobTitle || category?.jobs[0]?.title;
    const inspected = allJobs.find((job) => job.title === inspectedTitle);
    const inspectedState = inspected ? jobStates[inspected.title] : undefined;
    const chosen = Object.keys(jobStates)
      .filter((title) => jobStates[title]?.pref_level)
      .sort(
        (a, b) =>
          (jobStates[b].pref_level || 0) - (jobStates[a].pref_level || 0),
      );
    const locked = asBool(data.job_changes_locked);
    const roleFooter = (
      <>
        <div className="cc-hint">{L.priorityHint}</div>
        <div className="cc-strip-row">
          <span className="cc-muted" style={{ fontSize: 10 }}>
            {L.priorityStrip}:
          </span>
          {chosen.length ? (
            chosen.map((title) => (
              <Tip
                key={title}
                className="cc-strip-item"
                style={{
                  borderLeftColor:
                    PRIORITY_COLORS[jobStates[title].pref_level || 1],
                }}
                title={jobStates[title].current_title || title}
                body={`${L.priority}: ${L.priorityNames[jobStates[title].pref_level || 1]}`}
                onClick={() => {
                  setRoleCategory(
                    jobCategories.find((entry) =>
                      entry.jobs.some((job) => job.title === title),
                    )?.name || null,
                  );
                  setInspectJob(title);
                }}
              >
                {jobStates[title].current_title || title}
              </Tip>
            ))
          ) : (
            <span className="cc-muted" style={{ fontSize: 11 }}>
              {L.noPriorities}
            </span>
          )}
        </div>
        <div
          className="cc-row"
          style={{ flexWrap: 'wrap', justifyContent: 'center' }}
        >
          <Btn
            icon="random"
            disabled={locked}
            onClick={() => act('job_toggle_unavailable')}
          >
            {L.ifUnavailable}: {text(data.jobless_role, L.returnToLobby)}
          </Btn>
          <Btn
            icon="undo"
            disabled={locked}
            onClick={() => act('job_reset_priorities')}
          >
            {L.resetPriorities}
          </Btn>
          <Btn icon="list" onClick={() => doPref('role_settings')}>
            {L.roleSettings}
          </Btn>
          {data.last_class ? (
            <Btn
              icon="history"
              disabled={locked}
              onClick={() => act('job_play_last_class')}
            >
              {L.playAgain} {data.last_class}
            </Btn>
          ) : null}
        </div>
      </>
    );
    return windowShell(
      L.roleTitle,
      <>
        <Switcher
          name={category?.name || ''}
          options={names.map((entry) => ({ value: entry, label: entry }))}
          onPick={(value) => setRoleCategory(value)}
          onPrev={() => setRoleCategory(cycle(names, category?.name || '', -1))}
          onNext={() => setRoleCategory(cycle(names, category?.name || '', 1))}
        />
        <div className="cc-tiles">
          {(category?.jobs || []).map((job) => {
            const state = jobStates[job.title];
            const available = state?.status === 'available';
            const tileName = available
              ? state.current_title
              : state?.display_name || job.title;
            return (
              <Tile
                key={job.title}
                name={tileName}
                title={
                  job.required_jobs?.length
                    ? `${tileName}\n${L.requiredJobs}: ${job.required_jobs.join(', ')}`
                    : undefined
                }
                icon={CATEGORY_ICONS[category?.name || ''] || 'user'}
                inspected={job.title === inspectedTitle}
                selected={state?.pref_level === 3}
                locked={!available}
                badge={
                  state?.pref_level
                    ? PRIORITY_COLORS[state.pref_level]
                    : undefined
                }
                mark={
                  (data.cc_subclasses?.[job.title] || []).length
                    ? 'chess-knight'
                    : undefined
                }
                controls={
                  available && !locked ? (
                    <>
                      <span
                        className={`cc-tile-arrow ${state?.pref_level === 3 ? 'disabled' : ''}`}
                        title={L.raisePriority}
                        onClick={() => raisePriority(job.title)}
                      >
                        <Icon name="caret-up" />
                      </span>
                      <span className="cc-tile-prio">
                        {state?.pref_level
                          ? L.priorityNames[state.pref_level]
                          : '·'}
                      </span>
                      <span
                        className={`cc-tile-arrow ${state?.pref_level ? '' : 'disabled'}`}
                        title={L.lowerPriority}
                        onClick={() => lowerPriority(job.title)}
                      >
                        <Icon name="caret-down" />
                      </span>
                    </>
                  ) : null
                }
                onClick={() => setInspectJob(job.title)}
                onMiddle={() => !locked && raisePriority(job.title)}
                onRight={() => !locked && lowerPriority(job.title)}
              />
            );
          })}
        </div>
        {inspected && inspectedState ? (
          <>
            <div className="cc-name">
              {inspectedState.status === 'available'
                ? inspectedState.current_title
                : inspectedState.display_name}
            </div>
            <div className="cc-hint">
              {L.slots}: {inspected.slots}
              {inspectedState.pref_level
                ? ` · ${L.priority}: ${L.priorityNames[inspectedState.pref_level]}`
                : ''}
            </div>
            {inspected.required_jobs?.length ? (
              <div className="cc-hint">
                <Tip
                  className="cc-link"
                  title={L.requiredJobs}
                  body={L.requiredJobsHint}
                >
                  <Icon name="link" mr={0.5} />
                  {L.requiredJobs}: {inspected.required_jobs.join(', ')}
                </Tip>
              </div>
            ) : null}
            {inspectedState.status !== 'available' ? (
              <div className="cc-hint" style={{ color: 'var(--cc-bad)' }}>
                {inspectedState.status === 'banned'
                  ? L.banned
                  : inspectedState.lock_label}
                {(inspectedState.lock_detail || []).map((line) => (
                  <div key={line}>{line}</div>
                ))}
              </div>
            ) : null}
            {inspectedState.status === 'available' ? (
              <div
                className="cc-row"
                style={{ justifyContent: 'center', margin: '4px 0 8px' }}
              >
                <span className="cc-muted" style={{ fontSize: 11 }}>
                  {L.priority}:
                </span>
                {[0, 1, 2, 3].map((level) => (
                  <Btn
                    key={level}
                    className={
                      (inspectedState.pref_level || 0) === level ? 'gold' : ''
                    }
                    disabled={locked}
                    onClick={() =>
                      act('job_set_pref_level', {
                        job: inspected.title,
                        level: level || null,
                      })
                    }
                  >
                    {level ? L.priorityNames[level] : L.none}
                  </Btn>
                ))}
              </div>
            ) : null}
            <div className="cc-desc">
              {text(inspected.tutorial, L.noDescription)}
            </div>
            {(data.cc_subclasses?.[inspected.title] || []).length ? (
              <Bonus title={L.subRoleTitle}>
                <div className="cc-hint">{L.subrolesAvailable}</div>
                <div className="cc-chips">
                  {(data.cc_subclasses?.[inspected.title] || []).map((sub) => (
                    <span key={sub.id} className="cc-chip">
                      {sub.title}
                    </span>
                  ))}
                </div>
                {inspected.title === highJobTitle ? (
                  <Btn
                    icon="chess-knight"
                    style={{ marginTop: 6 }}
                    onClick={() => setFateCat('subrole')}
                  >
                    {L.chooseSubrole}
                  </Btn>
                ) : (
                  <div className="cc-hint">{L.subroleNeedsHigh}</div>
                )}
              </Bonus>
            ) : null}
            {inspectedState.status === 'available' &&
            (inspected.title_choices.length > 1 ||
              inspected.honorary_choices.length > 1) ? (
              <Bonus title={L.titles}>
                <div className="cc-kv">
                  {inspected.title_choices.length > 1 ? (
                    <>
                      <div className="cc-kv-label">{L.altTitle}</div>
                      <Select
                        disabled={locked}
                        value={inspectedState.current_title}
                        options={inspected.title_choices.map((choice) => ({
                          value: choice.value,
                          label: choice.value,
                        }))}
                        onChange={(value) =>
                          act('job_set_alt', {
                            job: inspected.title,
                            category: 'title',
                            value,
                          })
                        }
                      />
                    </>
                  ) : null}
                  {inspected.honorary_choices.length > 1 ? (
                    <>
                      <div className="cc-kv-label">{L.honorary}</div>
                      <Select
                        disabled={locked}
                        value={inspectedState.current_honorary}
                        options={inspected.honorary_choices.map((choice) => ({
                          value: choice.value,
                          label: choice.value || L.none,
                        }))}
                        onChange={(value) =>
                          act('job_set_alt', {
                            job: inspected.title,
                            category: 'honorary',
                            value,
                          })
                        }
                      />
                    </>
                  ) : null}
                </div>
              </Bonus>
            ) : null}
            {renderJobDetails(inspected.title, inspected.details)}
          </>
        ) : null}
      </>,
      roleFooter,
    );
  };

  const statChips = (stats: StatLine[]) =>
    stats.map((stat) => (
      <span
        key={stat.name}
        className={`cc-chip ${stat.value < 0 ? 'bad' : 'good'}`}
      >
        {stat.name} {stat.value > 0 ? '+' : ''}
        {stat.value}
      </span>
    ));
  const traitTerms = (traits: TraitLine[]) =>
    traits.map((trait) => (
      <span key={trait.name} className="cc-chip">
        <Term label={trait.name} body={trait.desc || L.noDescription} />
      </span>
    ));
  const fact = (label: string, body: ReactNode) => (
    <div className="cc-fact">
      <span className="cc-kv-label">{label}</span>
      {body}
    </div>
  );

  const subclassFacts = (sub: SubclassDetails) => (
    <div className="cc-jobsub">
      {sub.stats.length ? (
        <div className="cc-chips">{statChips(sub.stats)}</div>
      ) : null}
      {sub.traits.length ? (
        <div className="cc-chips">{traitTerms(sub.traits)}</div>
      ) : null}
      {sub.spell_points ? (
        <div className="cc-muted">
          {L.spellPoints}: <b>{sub.spell_points}</b>
        </div>
      ) : null}
      {sub.skills.length ? (
        <div className="cc-muted">
          {L.notableSkills}:{' '}
          {sub.skills
            .map((skill) => `${skill.name} — ${skill.level}`)
            .join(' · ')}
        </div>
      ) : null}
      {sub.languages.length ? (
        <div className="cc-muted">
          {L.languages}: {sub.languages.join(', ')}
        </div>
      ) : null}
    </div>
  );

  // Facts for the sub-role window, taken from the High role's details.
  const renderSubclassDetails = (subTitle: string) => {
    const sub = allJobs
      .find((job) => job.title === highJobTitle)
      ?.details?.subclasses.find((entry) => entry.title === subTitle);
    if (
      !sub ||
      !(
        sub.stats.length ||
        sub.traits.length ||
        sub.spell_points ||
        sub.skills.length ||
        sub.languages.length
      )
    ) {
      return null;
    }
    return (
      <div className="cc-jobdetails">
        <Ornament>{L.subclassDetails}</Ornament>
        {subclassFacts(sub)}
        <div className="cc-hint">{L.detailsNote}</div>
      </div>
    );
  };

  // Class facts and subclass cards, in place of the old explain popup.
  const renderJobDetails = (jobTitle: string, details?: JobDetails) => {
    if (!details) {
      return null;
    }
    const classFacts =
      details.stats.length ||
      details.stat_limits.length ||
      details.spell_points ||
      details.traits.length;
    if (!classFacts && !details.subclasses.length) {
      return null;
    }
    return (
      <div className="cc-jobdetails">
        <Ornament>{L.classDetails}</Ornament>
        {details.stats.length
          ? fact(
              L.startingStats,
              <div className="cc-chips">{statChips(details.stats)}</div>,
            )
          : null}
        {details.stat_limits.length
          ? fact(
              L.statLimits,
              <div>
                <div className="cc-chips">{statChips(details.stat_limits)}</div>
                <div className="cc-muted" style={{ fontSize: 10 }}>
                  {L.statLimitsHint}
                </div>
              </div>,
            )
          : null}
        {details.spell_points
          ? fact(L.spellPoints, <b>{details.spell_points}</b>)
          : null}
        {details.traits.length
          ? fact(
              L.classTraits,
              <div className="cc-chips">{traitTerms(details.traits)}</div>,
            )
          : null}
        {details.subclasses.length ? (
          <>
            <div className="cc-kv-label" style={{ margin: '8px 0 4px' }}>
              {L.subclassList} ({details.subclasses.length})
            </div>
            {details.subclasses.map((sub) =>
              group(
                `help_sub_${jobTitle}_${sub.title}`,
                sub.title,
                'chess-knight',
                <>
                  <div
                    className="cc-desc"
                    style={{ textAlign: 'left', padding: '4px 8px 0' }}
                  >
                    {sub.tutorial}
                  </div>
                  {subclassFacts(sub)}
                </>,
              ),
            )}
          </>
        ) : null}
        <div className="cc-hint">{L.detailsNote}</div>
      </div>
    );
  };

  const renderSubRole = () => {
    const inspected =
      highSubclasses.find((entry) => entry.id === inspectSubclass) ||
      highSubclasses.find((entry) => entry.id === preferredSubclass) ||
      highSubclasses[0];
    const locked = asBool(data.job_changes_locked);
    return windowShell(
      `${L.subRoleTitle}: ${jobStates[highJobTitle || '']?.current_title || highJobTitle || ''}`,
      <>
        <div className="cc-hint">{L.subRoleHint}</div>
        <div className="cc-tiles">
          {highSubclasses.map((entry) => (
            <Tile
              key={entry.id}
              name={entry.title}
              icon="chess-knight"
              selected={entry.id === preferredSubclass}
              inspected={entry.id === inspected?.id}
              onClick={() => setInspectSubclass(entry.id)}
            />
          ))}
        </div>
        {inspected ? (
          <>
            <div className="cc-name">{inspected.title}</div>
            <div className="cc-desc">
              {text(inspected.tutorial, L.noDescription)}
            </div>
            {renderSubclassDetails(inspected.title)}
          </>
        ) : null}
      </>,
      inspected ? (
        <Btn
          className={`fluid ${inspected.id === preferredSubclass ? 'gold' : 'primary'}`}
          icon={inspected.id === preferredSubclass ? 'star' : 'check'}
          disabled={locked}
          onClick={() =>
            act('cc_set_subclass', { job: highJobTitle, id: inspected.id })
          }
        >
          {inspected.id === preferredSubclass
            ? L.preferredClear
            : L.preferredSet}
        </Btn>
      ) : undefined,
    );
  };

  const renderDeity = () => {
    const faiths = (data.faith_options || []).filter(
      (faith) => asBool(faith.available) || asBool(faith.selected),
    );
    const faithId = faithView || data.selected_faith_id || faiths[0]?.id;
    const faith = faiths.find((entry) => entry.id === faithId) || faiths[0];
    const patrons = faith?.patrons || [];
    const inspected =
      patrons.find((patron) => patron.id === inspectPatron) ||
      patrons.find((patron) => asBool(patron.selected)) ||
      patrons[0];
    return windowShell(
      L.deityTitle,
      <>
        <Switcher
          name={faith?.name || ''}
          onPrev={() =>
            setFaithView(
              cycle(
                faiths.map((entry) => entry.id),
                faith?.id || '',
                -1,
              ),
            )
          }
          onNext={() =>
            setFaithView(
              cycle(
                faiths.map((entry) => entry.id),
                faith?.id || '',
                1,
              ),
            )
          }
        />
        {faith?.description ? (
          <div
            className="cc-hint"
            style={{ maxHeight: 54, overflow: 'hidden' }}
          >
            {faith.description}
          </div>
        ) : null}
        <div className="cc-tiles">
          {patrons.map((patron) => (
            <Tile
              key={patron.id}
              name={patron.name}
              icon="sun"
              selected={asBool(patron.selected)}
              inspected={patron.id === inspected?.id}
              locked={!asBool(patron.available)}
              onClick={() => {
                setInspectPatron(patron.id);
                if (asBool(patron.available) && !asBool(patron.selected)) {
                  doPref('character_setup_select_patron', undefined, {
                    patron_id: patron.id,
                  });
                }
              }}
            />
          ))}
        </div>
        {inspected ? (
          <>
            <div className="cc-name">{inspected.name}</div>
            <div className="cc-hint">{inspected.domain}</div>
            <div className="cc-desc">
              {text(inspected.description, L.noDescription)}
            </div>
            {inspected.boons ? (
              <Bonus title={L.boons}>
                <div className="cc-desc" style={{ color: '#a9d68a' }}>
                  {inspected.boons}
                </div>
              </Bonus>
            ) : null}
            {inspected.sins ? (
              <Bonus title={L.sins}>
                <div className="cc-desc" style={{ color: '#e9a497' }}>
                  {inspected.sins}
                </div>
              </Bonus>
            ) : null}
            {inspected.flaws || inspected.worshippers ? (
              <Bonus title={L.followers}>
                <div className="cc-desc">
                  {inspected.worshippers}
                  {inspected.flaws ? `\n${L.flaws}: ${inspected.flaws}` : ''}
                </div>
              </Bonus>
            ) : null}
          </>
        ) : null}
      </>,
    );
  };

  const renderBackground = () =>
    windowShell(
      L.backgroundTitle,
      <>
        <div className="cc-tiles">
          {[1, 2, 3, 4, 5, 6].map((index) => (
            <Tile key={index} name={L.soon} icon="scroll" locked />
          ))}
        </div>
        <div className="cc-desc" style={{ marginTop: 10 }}>
          {L.backgroundSoon}
        </div>
        <div className="cc-hint">
          {L.skills}: <Term label={L.soon} body={L.backgroundSkillsHint} />
        </div>
      </>,
    );

  const renderIdentityWindow = () =>
    windowShell(
      L.rail.identity,
      <div className="cc-kv">
        <div className="cc-kv-label">{L.nameLabel}</div>
        <Btn
          className="fluid"
          icon="pen"
          style={{ justifyContent: 'flex-start' }}
          onClick={() => doPref('name', 'input')}
        >
          {text(data.real_name, L.unnamed)}
        </Btn>
        <div className="cc-kv-label">{L.bodyType}</div>
        <Btn
          className="fluid"
          style={{ justifyContent: 'flex-start' }}
          onClick={() => doPref('gender')}
        >
          {data.gender}
        </Btn>
        {buildRow()}
        <div className="cc-kv-label">{L.pronouns}</div>
        <Btn
          className="fluid"
          style={{ justifyContent: 'flex-start' }}
          onClick={() => doPref('pronouns', 'input')}
        >
          {text(data.pronouns, L.none)}
        </Btn>
        <div className="cc-kv-label">{L.age}</div>
        <Select
          title={data.age_tooltips?.[data.age] || ''}
          value={data.age}
          options={(data.age_options || []).map((option) => ({
            value: option,
            label: option,
          }))}
          onChange={(value) =>
            act('set_age', {
              value: (data.age_options || []).indexOf(value) + 1,
            })
          }
        />
      </div>,
      <Btn className="fluid" icon="users" onClick={() => doPref('family')}>
        {L.familyBonds}
      </Btn>,
    );

  const renderAbility = () =>
    windowShell(
      L.abilityTitle,
      <>
        <Ornament>{L.abilityScores}</Ornament>
        <div
          className="cc-kv"
          style={{ gridTemplateColumns: 'minmax(90px, 1fr) auto auto' }}
        >
          {(data.cc_stats || []).map((stat) => (
            <Fragment key={stat.label}>
              <div>{stat.name}</div>
              <div className="cc-muted" style={{ fontSize: 10 }}>
                10
                {stat.species
                  ? ` ${stat.species > 0 ? '+' : ''}${stat.species} ${L.raceShort}`
                  : ''}
                {stat.age
                  ? ` ${stat.age > 0 ? '+' : ''}${stat.age} ${L.ageShort}`
                  : ''}
              </div>
              <div className="cc-stat-value" style={{ textAlign: 'right' }}>
                {stat.total}
              </div>
            </Fragment>
          ))}
        </div>
        <Placeholder>{L.pointBuySoon}</Placeholder>
        <Ornament>{L.quirks}</Ornament>
        <div className="cc-chips">
          {(data.cc_quirks?.names || []).length ? (
            (data.cc_quirks?.names || []).map((name) => (
              <span key={name} className="cc-chip">
                {name}
              </span>
            ))
          ) : (
            <span className="cc-chip">{L.noQuirks}</span>
          )}
        </div>
        <div className="cc-hint">
          {L.quirkBalance}: {data.cc_quirks?.balance ?? 0}
        </div>
      </>,
      <Btn
        className="primary fluid"
        icon="theater-masks"
        onClick={() => doPref('select_quirks')}
      >
        {L.changeQuirks}
      </Btn>,
    );

  const renderFate = () => {
    switch (activeFate) {
      case 'identity':
        return renderIdentityWindow();
      case 'suborigin':
        return renderSubOrigin();
      case 'race':
        return renderRace();
      case 'subrace':
        return renderSubRace();
      case 'role':
        return renderRole();
      case 'subrole':
        return renderSubRole();
      case 'deity':
        return renderDeity();
      case 'background':
        return renderBackground();
      case 'ability':
        return renderAbility();
      default:
        return renderOrigin();
    }
  };

  // ---------------------------------------------------------------------------
  // Appearance editor (the A toggle on the doll)
  // ---------------------------------------------------------------------------

  // Text sections start folded; everything else starts open.
  const isCollapsed = (id: string) =>
    collapsed[id] ?? (id.startsWith('text_') || id.startsWith('help_'));
  const toggleGroup = (id: string) =>
    setCollapsed({ ...collapsed, [id]: !isCollapsed(id) });

  const group = (
    id: string,
    title: string,
    icon: string,
    children: ReactNode,
    extra?: ReactNode,
  ) => (
    <div className="cc-group" key={id}>
      <div className="cc-group-head" onClick={() => toggleGroup(id)}>
        <Icon name={isCollapsed(id) ? 'caret-right' : 'caret-down'} />
        <Icon name={icon} />
        <span className="cc-grow">{title}</span>
        <span onClick={(event) => event.stopPropagation()}>{extra}</span>
      </div>
      {isCollapsed(id) ? null : children}
    </div>
  );

  const stepStyle = (feature: FeatureEntry, step: number) => {
    const options = feature.accessory_options || [];
    if (options.length < 2) {
      return;
    }
    const index = options.findIndex(
      (option) => option.value === feature.accessory_value,
    );
    const next =
      options[(Math.max(0, index) + step + options.length) % options.length];
    customizerAct(feature.key, 'select_acc', { acc_type: next.value });
  };

  const renderExtras = (feature: FeatureEntry) => {
    const extras = feature.extras || [];
    const rows: ReactNode[] = [];
    for (let index = 0; index < extras.length; index++) {
      const extra = extras[index];
      if (
        extra.kind === 'number' &&
        extra.min !== undefined &&
        extra.max !== undefined
      ) {
        const value = Number(extra.value) || 0;
        const step = extra.step ?? 1;
        const min = extra.min;
        const max = extra.max;
        rows.push(
          <Fragment key={extra.task}>
            <div className="cc-field-label">{extra.label}</div>
            <div className="cc-row">
              <Btn
                className="square"
                icon="chevron-left"
                disabled={value <= min}
                onClick={() =>
                  customizerAct(feature.key, extra.task, {
                    value: Math.max(min, value - step),
                  })
                }
              />
              {/* Without a value the server asks for one in an input box. */}
              <Btn
                className="fluid"
                onClick={() => customizerAct(feature.key, extra.task)}
              >
                {value}
                {extra.unit ? ` ${extra.unit}` : ''}
              </Btn>
              <Btn
                className="square"
                icon="chevron-right"
                disabled={value >= max}
                onClick={() =>
                  customizerAct(feature.key, extra.task, {
                    value: Math.min(max, value + step),
                  })
                }
              />
            </div>
          </Fragment>,
        );
        continue;
      }
      if (asBool(extra.readonly)) {
        rows.push(
          <Fragment key={extra.task}>
            <div className="cc-field-label">{extra.label}</div>
            <div className="cc-muted">{text(extra.value, L.none)}</div>
          </Fragment>,
        );
        continue;
      }
      if (extra.kind === 'text') {
        const next = extras[index + 1];
        const pairedColor = next && next.kind === 'color' ? next : null;
        rows.push(
          <Fragment key={extra.task}>
            <div className="cc-field-label">{extra.label}</div>
            <div className="cc-style-row">
              <div
                className="cc-style-name"
                onClick={() => customizerAct(feature.key, extra.task)}
              >
                {text(extra.value, L.none)}
              </div>
              {pairedColor ? (
                <div
                  className="cc-palette"
                  style={{ flex: '0 0 auto', padding: '0 8px' }}
                  title={pairedColor.label}
                  onClick={() => customizerAct(feature.key, pairedColor.task)}
                >
                  <Swatch color={String(pairedColor.value)} />
                </div>
              ) : null}
            </div>
          </Fragment>,
        );
        if (pairedColor) {
          index++;
        }
        continue;
      }
      rows.push(
        <div className="cc-style-row" key={extra.task}>
          <div
            className="cc-palette"
            title={extra.label}
            onClick={() => customizerAct(feature.key, extra.task)}
          >
            <span
              className="cc-grow"
              style={{ textAlign: 'left', paddingLeft: 6 }}
            >
              {extra.label}
            </span>
            <Swatch color={String(extra.value)} />
            <span style={{ width: 4 }} />
          </div>
        </div>,
      );
    }
    return rows;
  };

  const renderFeatureCard = (feature: FeatureEntry) => {
    const enabled = asBool(feature.enabled);
    const options = feature.accessory_options || [];
    const colors = feature.colors || [];
    return (
      <div className="cc-card-feature" key={feature.key}>
        <div className="cc-card-feature-head">
          <span className="cc-grow">{feature.name}</span>
          {asBool(feature.can_disable) ? (
            <Btn
              className={`cc-toggle ${enabled ? 'on' : 'off'}`}
              title={L.toggleHint}
              onClick={() => customizerAct(feature.key, 'toggle_missing')}
            >
              {enabled ? L.on : L.off}
            </Btn>
          ) : null}
        </div>
        {!enabled ? (
          <div className="cc-disabled-body">{L.disabled}</div>
        ) : (
          <>
            {feature.choice_options && feature.choice_options.length > 1 ? (
              <>
                <div className="cc-field-label">{L.type}</div>
                <Select
                  value={feature.choice_value || ''}
                  options={feature.choice_options.map((option) => ({
                    value: option.value,
                    label: option.name,
                  }))}
                  onChange={(value) =>
                    doPref('character_setup_set_choice', undefined, {
                      key: feature.key,
                      choice_type: value,
                    })
                  }
                />
              </>
            ) : null}
            {feature.accessory_name ? (
              <div className="cc-style-row" style={{ marginTop: 4 }}>
                {options.length > 1 ? (
                  <Btn
                    className="square"
                    icon="chevron-left"
                    onClick={() => stepStyle(feature, -1)}
                  />
                ) : null}
                <div
                  className="cc-style-name"
                  title={
                    options.length > 1 ? L.openStyles : feature.accessory_name
                  }
                  onClick={() => {
                    if (options.length > 1) {
                      setPicker(feature.key);
                      setPickerSearch('');
                    }
                  }}
                >
                  {feature.accessory_name}
                </div>
                {options.length > 1 ? (
                  <Btn
                    className="square"
                    icon="chevron-right"
                    onClick={() => stepStyle(feature, 1)}
                  />
                ) : null}
              </div>
            ) : null}
            {colors.length ? (
              <div className="cc-style-row">
                {colors.map((color) => (
                  <div
                    key={color.index}
                    className="cc-palette"
                    title={color.name}
                    onClick={() =>
                      customizerAct(feature.key, 'acc_color', {
                        color_index: color.index,
                      })
                    }
                  >
                    <Swatch color={color.value} />
                    {colors.length === 1 ? L.colorPalette : null}
                  </div>
                ))}
              </div>
            ) : null}
            {renderExtras(feature)}
            {colors.length ? (
              <div
                className="cc-reset"
                onClick={() => customizerAct(feature.key, 'reset_colors')}
              >
                {L.resetColors}
              </div>
            ) : null}
          </>
        )}
      </div>
    );
  };

  const cards = (list: FeatureEntry[]) =>
    list.length ? (
      <div className="cc-cards">{list.map(renderFeatureCard)}</div>
    ) : (
      <div className="cc-hint">{L.nothingForSpecies}</div>
    );

  const mirrorFeatures = (cat: MirrorCat) =>
    features.filter((feature) => featureCat(feature) === cat);

  const renderHead = () => {
    const head = mirrorFeatures('head').sort(byPattern(HEAD_PATTERNS));
    const hair = head.filter((feature) => matches(feature.key, HAIR_PATTERNS));
    const face = head.filter((feature) => !matches(feature.key, HAIR_PATTERNS));
    return windowShell(
      L.mirror.head,
      <>
        {group('hair', L.hairs, 'cut', cards(hair))}
        {group('face', L.face, 'eye', cards(face))}
      </>,
    );
  };

  const renderTattoos = () =>
    data.cc_tattoos ? (
      <TattooEditor
        tattoos={data.cc_tattoos}
        count={data.cc_tattoo_count ?? 0}
        labels={L}
        onAct={(task, params) => act('cc_tattoo', { task, ...params })}
      />
    ) : null;

  const renderMarkings = () => {
    const markingAct = (marking_action: string, zone?: string, name?: string) =>
      doPref('character_setup_body_marking', undefined, {
        marking_action,
        ...(zone ? { zone } : {}),
        ...(name ? { name } : {}),
      });
    return windowShell(
      L.mirror.markings,
      <>
        <div
          className="cc-row"
          style={{ justifyContent: 'flex-end', margin: '8px 0' }}
        >
          <Btn icon="layer-group" onClick={() => markingAct('use_preset')}>
            {L.presets}
          </Btn>
          <Btn icon="undo" onClick={() => markingAct('reset_all_colors')}>
            {L.resetColors}
          </Btn>
        </div>
        <div className="cc-marking-zones">
          {(data.cc_markings || []).map((zone) => (
            <div className="cc-marking-zone" key={zone.id}>
              <div className="cc-marking-zone-head">
                <span className="cc-grow">{zone.name}</span>
                <Btn
                  className="cc-toggle"
                  icon="plus"
                  disabled={!asBool(zone.can_add)}
                  onClick={() => markingAct('add', zone.id)}
                >
                  {L.add}
                </Btn>
              </div>
              {zone.entries.length ? (
                zone.entries.map((marking, index) => (
                  <div className="cc-marking-row" key={marking.name}>
                    <div
                      className="cc-marking-name"
                      title={L.replace}
                      onClick={() =>
                        markingAct('replace', zone.id, marking.name)
                      }
                    >
                      {marking.name}
                    </div>
                    <div
                      title={L.changeColor}
                      style={{ cursor: 'pointer' }}
                      onClick={() =>
                        markingAct('change_color', zone.id, marking.name)
                      }
                    >
                      <Swatch color={marking.color} width={22} />
                    </div>
                    <Btn
                      className="square"
                      title={L.resetColor}
                      onClick={() =>
                        markingAct('reset_color', zone.id, marking.name)
                      }
                    >
                      R
                    </Btn>
                    {sandbox ? null : (
                      <Btn
                        className={`square ${asBool(marking.emissive) ? 'gold' : ''}`}
                        title={L.glowToggle}
                        onClick={() =>
                          act('cc_marking_emissive', {
                            zone: zone.id,
                            name: marking.name,
                          })
                        }
                      >
                        E
                      </Btn>
                    )}
                    <Btn
                      className="square"
                      icon="arrow-up"
                      disabled={index === 0}
                      onClick={() =>
                        markingAct('move_up', zone.id, marking.name)
                      }
                    />
                    <Btn
                      className="square"
                      icon="arrow-down"
                      disabled={index === zone.entries.length - 1}
                      onClick={() =>
                        markingAct('move_down', zone.id, marking.name)
                      }
                    />
                    <Btn
                      className="square danger"
                      icon="times"
                      onClick={() =>
                        markingAct('remove', zone.id, marking.name)
                      }
                    />
                  </div>
                ))
              ) : (
                <div
                  className="cc-muted"
                  style={{ fontStyle: 'italic', fontSize: 11 }}
                >
                  {L.noMarkings}
                </div>
              )}
            </div>
          ))}
        </div>
        {sandbox ? null : <div className="cc-hint">{L.glowHint}</div>}
        {sandbox ? null : renderTattoos()}
      </>,
    );
  };

  const renderBody = () => {
    const body = mirrorFeatures('body');
    return windowShell(
      L.mirror.body,
      <>
        {asBool(data.use_skintones) && !sandbox ? (
          <Btn
            className="fluid"
            icon="list"
            onClick={() => doPref('skin_color_ref_list', 'input')}
          >
            {L.colorReference}
          </Btn>
        ) : null}
        {oozeMode && !data.mutant_colors?.length
          ? null
          : group(
              'skin',
              text(data.ancestry_label, L.skin),
              'tint',
              data.mutant_colors?.length ? (
                <div className="cc-swatch-list" style={{ marginTop: 6 }}>
                  {data.mutant_colors.map((entry) => (
                    <div
                      key={entry.slot}
                      className="cc-swatch-row"
                      onClick={() =>
                        doPref('character_setup_mutant_color', undefined, {
                          slot: entry.slot,
                        })
                      }
                    >
                      {L.mutantColor} #{entry.slot}
                      <Swatch color={entry.color} />
                    </div>
                  ))}
                </div>
              ) : (
                <div
                  className="cc-swatch-list cc-scroll"
                  style={{ marginTop: 6 }}
                >
                  {(data.ancestry_options || []).map((option) => (
                    <div
                      key={option.value}
                      className={`cc-swatch-row ${asBool(option.selected) ? 'selected' : ''}`}
                      onClick={() =>
                        doPref('character_setup_select_ancestry', undefined, {
                          ancestry: option.value,
                        })
                      }
                    >
                      {option.name}
                      <Swatch color={option.color} />
                    </div>
                  ))}
                </div>
              ),
            )}
        {asBool(data.use_titles) ? (
          <div className="cc-kv" style={{ margin: '6px 0' }}>
            <div className="cc-kv-label">{L.raceTitleLabel}</div>
            <Btn onClick={() => doPref('race_title', 'input')}>
              {text(data.race_title, L.none)}
            </Btn>
          </div>
        ) : null}
        {group('features', L.bodyFeatures, 'paw', cards(body))}
      </>,
    );
  };

  const renderTaur = () =>
    windowShell(
      L.mirror.taur,
      <>
        <Btn
          className="fluid"
          icon="horse"
          onClick={() => doPref('character_setup_taur_body')}
        >
          {L.bodyType}: {data.taur_body}
        </Btn>
        <div className="cc-swatch-list" style={{ marginTop: 8 }}>
          {(
            [
              ['base', L.taurColor, data.taur_color],
              ['markings', L.taurMarkings, data.taur_markings],
              ['tertiary', L.taurTertiary, data.taur_tertiary],
            ] as const
          ).map(([which, label, color]) => (
            <div
              key={which}
              className="cc-swatch-row"
              onClick={() =>
                doPref('character_setup_taur_color', undefined, { which })
              }
            >
              {label}
              <span className="cc-muted" style={{ marginLeft: 'auto' }}>
                {color}
              </span>
              <Swatch color={color} />
            </div>
          ))}
        </div>
      </>,
    );

  const renderGenitals = () =>
    windowShell(
      L.mirror.genitals,
      <>
        <div className="cc-row" style={{ marginBottom: 6 }}>
          <div className="cc-grow">
            <span className="cc-muted">{L.genitalSet}: </span>
            {text(data.genital_set_label)}
            {asBool(data.genital_extra_unlock) ? (
              <div className="cc-muted" style={{ fontSize: 10 }}>
                {L.genitalMix}
              </div>
            ) : null}
          </div>
          <Btn
            icon="exchange-alt"
            onClick={() => doPref('character_setup_toggle_genital_set')}
          >
            {L.toggleGenitals}
          </Btn>
        </div>
        {(() => {
          // Plan layout: General, then Masculine and Feminine sets in folding lists.
          const erpFeatures = mirrorFeatures('genitals');
          const setOf = (feature: FeatureEntry) => {
            if (/\/(penis|testicles)/.test(feature.key)) {
              return 'masculine';
            }
            if (/\/(breasts|vagina)/.test(feature.key)) {
              return 'feminine';
            }
            return 'general';
          };
          return (
            <>
              {group(
                'genitals_general',
                L.genitalsGeneral,
                'circle',
                cards(erpFeatures.filter((f) => setOf(f) === 'general')),
              )}
              {group(
                'genitals_masculine',
                L.genitalsMasculine,
                'mars',
                cards(erpFeatures.filter((f) => setOf(f) === 'masculine')),
              )}
              {group(
                'genitals_feminine',
                L.genitalsFeminine,
                'venus',
                cards(erpFeatures.filter((f) => setOf(f) === 'feminine')),
              )}
            </>
          );
        })()}
      </>,
    );

  const renderAttire = () => {
    const catalog = data.smallclothes_catalog || [];
    const state = data.smallclothes || { random: false, entries: [] };
    const random = asBool(state.random);
    const entryOf = (id: string) =>
      (state.entries || []).find((entry) => entry.id === id);
    const stepSmall = (category: SmallclothesCatalogEntry, step: number) => {
      const current = entryOf(category.id)?.value || '';
      const values = ['', ...category.options.map((option) => option.value)];
      const next = cycle(values, current, step);
      doPref('character_setup_smallclothes_set', undefined, {
        category: category.id,
        value: next,
      });
    };
    return windowShell(
      L.mirror.attire,
      <>
        <Btn
          className="primary fluid"
          icon="box-open"
          onClick={() => setTab('loadout')}
        >
          {L.chooseLoadout}
        </Btn>
        <div style={{ height: 8 }} />
        {group(
          'accessory',
          L.accessories,
          'gem',
          cards(mirrorFeatures('attire')),
        )}
        {group(
          'underwear',
          L.underwear,
          'tshirt',
          random ? (
            <div className="cc-hint">{L.underwearRandom}</div>
          ) : (
            <div className="cc-cards">
              {catalog.map((category) => {
                const entry = entryOf(category.id);
                return (
                  <div className="cc-card-feature" key={category.id}>
                    <div className="cc-card-feature-head">{category.name}</div>
                    <div className="cc-style-row">
                      <Btn
                        className="square"
                        icon="chevron-left"
                        onClick={() => stepSmall(category, -1)}
                      />
                      <div
                        className="cc-style-name"
                        title={L.openStyles}
                        onClick={() => {
                          setPicker(`small:${category.id}`);
                          setPickerSearch('');
                        }}
                      >
                        {text(entry?.name, L.none)}
                      </div>
                      <Btn
                        className="square"
                        icon="chevron-right"
                        onClick={() => stepSmall(category, 1)}
                      />
                    </div>
                    <div
                      className="cc-palette"
                      onClick={() =>
                        act('cc_smallclothes_color', { category: category.id })
                      }
                    >
                      {entry?.color ? <Swatch color={entry.color} /> : null}
                      {L.colorPreset}
                    </div>
                  </div>
                );
              })}
            </div>
          ),
          <Btn
            className={`cc-toggle ${random ? 'gold' : ''}`}
            icon={random ? 'dice' : 'hand-pointer'}
            title={random ? L.randomized : L.manual}
            onClick={() => doPref('character_setup_smallclothes_random')}
          >
            {random ? L.randomized : L.manual}
          </Btn>,
        )}
      </>,
    );
  };

  const renderPiercing = () =>
    windowShell(L.mirror.piercing, cards(mirrorFeatures('piercing')));

  const renderSmallclothesPicker = (categoryId: string) => {
    const category = (data.smallclothes_catalog || []).find(
      (entry) => entry.id === categoryId,
    );
    if (!category) {
      return null;
    }
    const current = (data.smallclothes?.entries || []).find(
      (entry) => entry.id === categoryId,
    );
    const lowered = pickerSearch.trim().toLowerCase();
    const options = [
      { name: L.none, value: '', thumb: undefined as string | undefined },
      ...category.options,
    ].filter(
      (option) => !lowered || option.name.toLowerCase().includes(lowered),
    );
    return (
      <div className="cc-overlay cc-overlay-full">
        <div className="cc-overlay-head">
          <div className="cc-frame-title" style={{ padding: 0 }}>
            {L.select} {category.name}
          </div>
          <div
            className="cc-palette"
            style={{ flex: '0 0 auto', padding: '0 10px' }}
            onClick={() =>
              act('cc_smallclothes_color', { category: category.id })
            }
          >
            {current?.color ? <Swatch color={current.color} /> : null}
            {L.colorPalette}
          </div>
          <div className="cc-search">
            <Icon className="cc-search-icon" name="search" />
            <input
              value={pickerSearch}
              placeholder={L.searchStyles}
              onChange={(event) => setPickerSearch(event.target.value)}
            />
          </div>
          <Btn
            className="square"
            icon="times"
            onClick={() => setPicker(null)}
          />
        </div>
        <div className="cc-scroll" style={{ flex: 1 }}>
          <div className="cc-picker-grid">
            {options.map((option) => (
              <div
                key={option.value || 'none'}
                className={`cc-picker-item ${option.value === (current?.value || '') ? 'selected' : ''}`}
                title={option.name}
                onClick={() => {
                  doPref('character_setup_smallclothes_set', undefined, {
                    category: category.id,
                    value: option.value,
                  });
                  setPicker(null);
                }}
              >
                <div className="cc-picker-thumb">
                  {option.thumb ? (
                    <img
                      src={option.thumb}
                      alt=""
                      style={{
                        width: 48,
                        height: 48,
                        imageRendering: 'pixelated',
                      }}
                    />
                  ) : (
                    <Icon
                      name={option.value ? 'tshirt' : 'ban'}
                      color="label"
                    />
                  )}
                </div>
                <div className="cc-picker-name">{option.name}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  };

  const renderStylePicker = () => {
    if (picker?.startsWith('small:')) {
      return renderSmallclothesPicker(picker.slice(6));
    }
    const feature = features.find((entry) => entry.key === picker);
    if (!feature) {
      return null;
    }
    const lowered = pickerSearch.trim().toLowerCase();
    const options = (feature.accessory_options || []).filter(
      (option) => !lowered || option.name.toLowerCase().includes(lowered),
    );
    const firstColor = feature.colors?.[0];
    const hoverColor =
      firstColor?.value ??
      feature.extras
        ?.find((extra) => extra.kind === 'color')
        ?.value?.toString();
    return (
      <div className="cc-overlay cc-overlay-full">
        <div className="cc-overlay-head">
          <div className="cc-frame-title" style={{ padding: 0 }}>
            {L.select} {feature.name}
          </div>
          {firstColor ? (
            <div
              className="cc-palette"
              style={{ flex: '0 0 auto', padding: '0 10px' }}
              onClick={() =>
                customizerAct(feature.key, 'acc_color', {
                  color_index: firstColor.index,
                })
              }
            >
              <Swatch color={firstColor.value} />
              {L.colorPalette}
            </div>
          ) : null}
          <div className="cc-search">
            <Icon className="cc-search-icon" name="search" />
            <input
              value={pickerSearch}
              placeholder={L.searchStyles}
              onChange={(event) => setPickerSearch(event.target.value)}
            />
          </div>
          <Btn
            className="square"
            icon="times"
            onClick={() => {
              setPicker(null);
              requestHover(null);
            }}
          />
        </div>
        <div className="cc-scroll" style={{ flex: 1 }}>
          <div className="cc-picker-grid">
            {options.map((option) => {
              const thumb = option.thumb || data.thumbs?.[option.value];
              return (
                <div
                  key={option.value}
                  className={`cc-picker-item ${option.value === feature.accessory_value ? 'selected' : ''}`}
                  title={option.name}
                  onMouseEnter={() =>
                    requestHover(option.value, hoverColor, feature.key)
                  }
                  onMouseLeave={() => requestHover(null)}
                  onClick={() => {
                    customizerAct(feature.key, 'select_acc', {
                      acc_type: option.value,
                    });
                    requestHover(null);
                    setPicker(null);
                  }}
                >
                  <div className="cc-picker-thumb">
                    {thumb ? (
                      thumb.startsWith('data:') ? (
                        <img
                          src={thumb}
                          alt=""
                          style={{
                            width: 48,
                            height: 48,
                            imageRendering: 'pixelated',
                          }}
                        />
                      ) : (
                        <Box
                          className={`character_setup_chargen48x48 ${thumb}`}
                          style={{
                            width: '48px',
                            height: '48px',
                            imageRendering: 'pixelated',
                          }}
                        />
                      )
                    ) : (
                      <Icon name="ban" color="label" />
                    )}
                  </div>
                  <div className="cc-picker-name">{option.name}</div>
                </div>
              );
            })}
          </div>
          {!options.length ? (
            <div className="cc-hint">{L.noMatches}</div>
          ) : null}
        </div>
      </div>
    );
  };

  const renderMirror = () => {
    switch (activeMirror) {
      case 'markings':
        return renderMarkings();
      case 'body':
        return renderBody();
      case 'prosthetics':
        return windowShell(
          L.mirror.prosthetics,
          data.cc_prosthetics ? (
            <ProstheticsPanel
              data={data.cc_prosthetics}
              labels={L}
              onPick={(slot, option) => act('cc_prosthetic', { slot, option })}
              onImplant={(slot, implant) => act('cc_implant', { slot, implant })}
            />
          ) : null,
        );
      case 'taur':
        return renderTaur();
      case 'genitals':
        return renderGenitals();
      case 'attire':
        return renderAttire();
      case 'piercing':
        return renderPiercing();
      default:
        return renderHead();
    }
  };

  // ---------------------------------------------------------------------------
  // Wide pages: Character Info, Gameplay, Intimacy, Settings
  // ---------------------------------------------------------------------------

  const kvButton = (
    label: string,
    value: ReactNode,
    onClick: () => void,
    title?: string,
  ) => (
    <Fragment key={label}>
      <div className="cc-kv-label" title={label}>
        {label}
      </div>
      <Btn
        className="fluid"
        title={title}
        onClick={onClick}
        style={{ justifyContent: 'flex-start' }}
      >
        {value}
      </Btn>
    </Fragment>
  );

  const infoBlock = (title: string, children: ReactNode) => (
    <div className="cc-info-block" key={title}>
      <div className="cc-info-title">{title}</div>
      {children}
    </div>
  );

  const textFields: {
    field: string;
    label: string;
    hint: string;
    nsfw?: boolean;
  }[] = [
    { field: 'flavortext', label: L.flavourText, hint: L.flavourHint },
    { field: 'ooc_notes', label: L.oocNotes, hint: L.oocNotesHint },
    {
      field: 'nsfwflavortext',
      label: L.nsfwFlavourText,
      hint: L.nsfwFlavourHint,
      nsfw: true,
    },
    {
      field: 'erpprefs_flavor',
      label: L.erpPreferencesText,
      hint: L.erpPreferencesHint,
      nsfw: true,
    },
  ];

  const playButton = (title: string, onClick: () => void) => (
    <Btn className="square" icon="play" title={title} onClick={onClick} />
  );

  const renderInfo = () => {
    const descriptors = data.cc_descriptors || { entries: [], custom: [] };
    const texts = data.cc_texts || {};
    const rivals = data.cc_rivals ?? 0;
    return windowShell(
      L.tabs.info,
      <>
        <div className="cc-info-grid cc-info-three">
          {infoBlock(
            L.mechanical,
            <div className="cc-kv">
              {descriptors.entries.map((entry) => (
                <Fragment key={entry.choice}>
                  <div className="cc-kv-label" title={entry.name}>
                    {entry.name}
                  </div>
                  <Select
                    value={entry.value}
                    options={entry.options.map((option) => ({
                      value: option.value,
                      label: option.name,
                    }))}
                    onChange={(value) =>
                      act('cc_set_descriptor', { choice: entry.choice, value })
                    }
                  />
                </Fragment>
              ))}
              {descriptors.custom
                .filter((custom) => asBool(custom.visible))
                .map((custom) => (
                  <Fragment key={custom.index}>
                    <div className="cc-kv-label" title={custom.name}>
                      {custom.name || `${L.custom} #${custom.index}`}
                    </div>
                    <div className="cc-row">
                      {custom.prefix ? (
                        <Btn
                          onClick={() =>
                            doPref(
                              'custom_descriptor_prefix',
                              'change_descriptor',
                              { index: custom.index },
                            )
                          }
                        >
                          {custom.prefix}
                        </Btn>
                      ) : null}
                      <Btn
                        className="fluid"
                        onClick={() =>
                          doPref(
                            'custom_descriptor_content',
                            'change_descriptor',
                            { index: custom.index },
                          )
                        }
                      >
                        {custom.text}
                      </Btn>
                    </div>
                  </Fragment>
                ))}
            </div>,
          )}
          {infoBlock(
            L.otherInfo,
            <>
              <div className="cc-kv">
                {kvButton(
                  L.dominantHand,
                  data.domhand === 'Left' ? L.left : L.right,
                  () => doPref('domhand'),
                )}
                {kvButton(L.foodPreferences, L.edit, () =>
                  doPref('culinary', 'menu'),
                )}
                {kvButton(
                  L.songLink,
                  asBool(data.song_set) ? L.urlSet : L.noUrl,
                  () => doPref('song_link', 'input'),
                )}
                {kvButton(L.songTitle, text(data.song_title), () =>
                  doPref('change_title', 'input'),
                )}
                {kvButton(L.songArtist, text(data.song_artist), () =>
                  doPref('change_artist', 'input'),
                )}
                {kvButton(
                  L.oocMedia,
                  data.cc_ooc_media ? L.urlSet : L.noUrl,
                  () => act('cc_ooc_media'),
                  L.oocMediaHint,
                )}
                <div className="cc-kv-label">{L.nsfwOocMedia}</div>
                <Placeholder>{L.soon}</Placeholder>
              </div>
              <Ornament>{L.portraits}</Ornament>
              <div className="cc-kv">
                {kvButton(
                  L.headshot,
                  data.headshot ? L.urlSet : L.noUrl,
                  () => doPref('headshot', 'input'),
                )}
                {kvButton(
                  L.nsfwHeadshot,
                  data.nsfw_headshot ? L.urlSet : L.noUrl,
                  () => doPref('nsfw_headshot', 'input'),
                )}
                {kvButton(L.gallery, L.open, () =>
                  doPref('gallery', 'menu', { tab: 'regular' }),
                )}
                {kvButton(L.nsfwGallery, L.open, () =>
                  doPref('gallery', 'menu', { tab: 'nsfw' }),
                )}
              </div>
              <div className="cc-grow" />
              <div className="cc-info-foot">
                <Tip
                  className="cc-link cc-grow"
                  title={L.rivals}
                  body={L.rivalsHint}
                >
                  {L.rivals}
                </Tip>
                <Btn
                  className="square"
                  icon="minus"
                  disabled={rivals <= 0}
                  onClick={() => act('cc_set_rivals', { value: rivals - 1 })}
                />
                <div className="cc-stat-value cc-rivals-count">{rivals}</div>
                <Btn
                  className="square"
                  icon="plus"
                  disabled={rivals >= 5}
                  onClick={() => act('cc_set_rivals', { value: rivals + 1 })}
                />
              </div>
            </>,
          )}
          {infoBlock(
            L.voice,
            <>
              <div className="cc-kv">
                {kvButton(L.voiceType, text(data.voice_type), () =>
                  doPref('voicetype', 'input'),
                )}
                {kvButton(L.voiceAccent, text(data.selected_accent), () =>
                  doPref('selected_accent', 'input'),
                )}
                {kvButton(
                  L.voiceColor,
                  <>
                    <Swatch color={data.voice_color} /> {data.voice_color}
                  </>,
                  () => doPref('voice', 'input'),
                )}
                {kvButton(L.speechBark, text(data.speech_bark), () =>
                  doPref('speech_bark', 'input'),
                )}
                <div className="cc-kv-label">{L.voicePack}</div>
                <div className="cc-row">
                  <Btn
                    className="fluid"
                    style={{ justifyContent: 'flex-start' }}
                    onClick={() => doPref('voicepack', 'input')}
                  >
                    {text(data.voice_pack)}
                  </Btn>
                  {playButton(L.packPreview, () =>
                    doPref('voicepreview', 'input'),
                  )}
                </div>
                <div className="cc-kv-label">{L.moans}</div>
                <div className="cc-row">
                  <Btn
                    className="fluid"
                    style={{ justifyContent: 'flex-start' }}
                    onClick={() => doPref('moanselection', 'input')}
                  >
                    {text(data.moan_selection)}
                  </Btn>
                  {playButton(L.moanPreview, () =>
                    doPref('moanpreview', 'input'),
                  )}
                </div>
                {kvButton(
                  L.speechMoans,
                  data.speech_moans ? L.on : L.off,
                  () => doPref('speech_moans', 'input'),
                )}
              </div>
              <div className="cc-grow" />
              <Btn
                className="fluid"
                icon="feather"
                onClick={() => doPref('relations_gossip')}
              >
                {L.rumours}
              </Btn>
            </>,
          )}
        </div>
        <div className="cc-info-block" style={{ marginTop: 8 }}>
          <div className="cc-info-title cc-row">
            <span className="cc-grow">{L.textDescriptions}</span>
            <span
              className={`cc-help-toggle ${helpOpen ? 'on' : ''}`}
              onClick={() => setHelpOpen(!helpOpen)}
            >
              <Icon name="question-circle" /> {L.formattingHelp}
            </span>
          </div>
          {helpOpen ? (
            <div className="cc-help-grid">
              {L.formattingText.split('\n').map((line) => {
                const parts = line.match(/^(.*\S)\s[-—]\s(.+)$/);
                return (
                  <div key={line}>
                    <b>{parts ? parts[1] : line}</b>
                    {parts ? ` ${parts[2]}` : ''}
                  </div>
                );
              })}
            </div>
          ) : null}
          {textFields.map((entry) => {
            const value = texts[entry.field] || '';
            const isOpen = openText === entry.field;
            return (
              <div className="cc-acc" key={entry.field}>
                <div
                  className={`cc-acc-head ${isOpen ? 'open' : ''}`}
                  onClick={() => setOpenText(isOpen ? null : entry.field)}
                >
                  <Icon name={isOpen ? 'chevron-down' : 'chevron-right'} />
                  <span className="cc-acc-label">{entry.label}</span>
                  {entry.nsfw ? (
                    <span className="cc-acc-badge">18+</span>
                  ) : null}
                  <span className="cc-acc-preview">
                    {isOpen ? '' : value.split('\n')[0] || L.emptyText}
                  </span>
                  <span className="cc-acc-count">
                    {value.length} / {TEXT_LIMIT}
                  </span>
                </div>
                {/* Closed editors stay mounted so an unsaved draft survives. */}
                <div
                  className="cc-acc-body"
                  style={{ display: isOpen ? undefined : 'none' }}
                >
                  <TextEditor
                    value={value}
                    hint={entry.hint}
                    labels={L}
                    onSave={(next) =>
                      act('cc_set_text', { field: entry.field, value: next })
                    }
                  />
                </div>
              </div>
            );
          })}
        </div>
      </>,
    );
  };

  const renderGameplay = () =>
    windowShell(
      L.tabs.gameplay,
      <>
        <div className="cc-info-grid">
          {infoBlock(
            L.classAndRoles,
            <div className="cc-kv">
              {kvButton(L.role, text(data.high_job, L.none), () => {
                openCharacter('fate');
                setFateCat('role');
              })}
              {kvButton(L.readyOrder, L.edit, () => doPref('multi', 'menu'))}
            </div>,
          )}
          {infoBlock(
            L.triumphs,
            <div className="cc-kv">
              <div className="cc-kv-label">{L.triumphBalance}</div>
              <div className="cc-stat-value" style={{ padding: '0 4px' }}>
                {data.triumphs ?? 0}
              </div>
              {kvButton(L.triumphList, L.open, () => doPref('triumphs'))}
              <div className="cc-kv-label" title={L.triumphShop}>
                {L.triumphShop}
              </div>
              <Btn
                className="fluid"
                disabled
                style={{ justifyContent: 'flex-start' }}
              >
                {L.notInUse}
              </Btn>
            </div>,
          )}
          {infoBlock(
            L.combatDefeat,
            <div className="cc-kv">
              {kvButton(L.combatMusic, text(data.combat_music), () =>
                doPref('combat_music', 'input'),
              )}
              {kvButton(
                L.defeatMode,
                text(data.defeat_mode),
                () => doPref('defeat_mode', 'input'),
                L.defeatModeHint,
              )}
              {kvButton(
                L.defeatThreshold,
                String(data.defeat_threshold ?? ''),
                () => doPref('defeat_threshold', 'input'),
                L.defeatThresholdHint,
              )}
              {kvButton(L.defeatGuide, L.read, () =>
                doPref('defeat_guide', 'input'),
              )}
            </div>,
          )}
          {infoBlock(
            L.playerRecord,
            <div className="cc-kv">
              {kvButton(
                L.playerQuality,
                L.open,
                () => doPref('playerquality'),
                L.playerQualityHint,
              )}
            </div>,
          )}
        </div>
      </>,
    );

  const erpAct = (
    pref_type: string,
    action: string,
    extra?: Record<string, unknown>,
  ) =>
    act('pref', {
      preference: 'erp_pref_native',
      task: 'erp_pref',
      native: 1,
      pref_type,
      action,
      ...(extra || {}),
    });
  const kinkAct = (
    kink_name: string,
    action: string,
    extra?: Record<string, unknown>,
  ) =>
    act('pref', {
      preference: 'kink',
      task: 'erp_pref',
      native: 1,
      kink_name,
      action,
      ...(extra || {}),
    });

  const renderErpControl = (pref: ErpPrefEntry, locked: boolean) => {
    if (pref.kind === 'flags') {
      return (
        <div className="cc-row" style={{ flexWrap: 'wrap' }}>
          {(pref.flags || []).map((flag) => (
            <Btn
              key={flag.bit}
              className={asBool(flag.on) ? 'on' : 'off'}
              disabled={locked}
              title={flag.description || flag.name}
              onClick={() =>
                erpAct(pref.type, 'toggle_flag', { flag: flag.bit })
              }
            >
              {flag.name}
            </Btn>
          ))}
        </div>
      );
    }
    if (pref.kind === 'number' || pref.kind === 'choice') {
      const isNumber = pref.kind === 'number';
      return (
        <div className="cc-row">
          <Btn
            className="square"
            icon="chevron-left"
            disabled={locked}
            onClick={() => erpAct(pref.type, isNumber ? 'decrease' : 'prev')}
          />
          <Btn
            disabled={locked}
            onClick={() => erpAct(pref.type, isNumber ? 'set' : 'choose')}
          >
            {text(pref.value, isNumber ? '0' : L.none)}
          </Btn>
          <Btn
            className="square"
            icon="chevron-right"
            disabled={locked}
            onClick={() => erpAct(pref.type, isNumber ? 'increase' : 'next')}
          />
        </div>
      );
    }
    const on = asBool(pref.value as Booleanish);
    return (
      <Btn
        className={on ? 'on' : 'off'}
        disabled={locked}
        onClick={() => erpAct(pref.type, 'toggle')}
      >
        {on ? L.enabled : L.disabledShort}
      </Btn>
    );
  };

  const renderIntimacy = () => {
    const erp = data.erp || {
      lock_reason: null,
      categories: [],
      kink_categories: [],
    };
    const locked = !!erp.lock_reason;
    return windowShell(
      L.tabs.intimacy,
      <>
        <div className="cc-row" style={{ marginBottom: 8 }}>
          {(['general', 'kinks', 'badges'] as const).map((id) => (
            <Btn
              key={id}
              className={erpTab === id ? 'selected' : ''}
              onClick={() => setErpTab(id)}
            >
              {L.erpTabs[id]}
            </Btn>
          ))}
        </div>
        {erpTab === 'general' && erp.lock_reason ? (
          <div className="cc-hint" style={{ color: 'var(--cc-bad)' }}>
            {erp.lock_reason}
          </div>
        ) : null}
        {erpTab === 'badges' ? (
          <PreferencesBadges />
        ) : erpTab === 'general' ? (
          erp.categories.map((category) =>
            infoBlock(
              category.name,
              (category.prefs || []).map((pref) => (
                <div
                  key={pref.type}
                  className="cc-row"
                  style={{ alignItems: 'flex-start', marginBottom: 8 }}
                >
                  <div className="cc-grow">
                    <div>{pref.name}</div>
                    <div className="cc-muted" style={{ fontSize: 10 }}>
                      {pref.description}
                    </div>
                    {pref.lock_reason ? (
                      <div style={{ color: 'var(--cc-bad)', fontSize: 10 }}>
                        {pref.lock_reason}
                      </div>
                    ) : null}
                  </div>
                  <div style={{ maxWidth: '55%' }}>
                    {renderErpControl(pref, locked || !!pref.lock_reason)}
                  </div>
                </div>
              )),
            ),
          )
        ) : (
          erp.kink_categories.map((category) =>
            infoBlock(
              category.name,
              (category.kinks || []).map((kink) => {
                const enabled = asBool(kink.enabled);
                return (
                  <div
                    key={kink.name}
                    className="cc-row"
                    style={{ alignItems: 'flex-start', marginBottom: 8 }}
                  >
                    <div className="cc-grow">
                      <div>{kink.name}</div>
                      <div className="cc-muted" style={{ fontSize: 10 }}>
                        {kink.description}
                      </div>
                    </div>
                    <div
                      className="cc-row"
                      style={{ flexWrap: 'wrap', maxWidth: '55%' }}
                    >
                      <Btn
                        className={enabled ? 'on' : 'off'}
                        onClick={() => kinkAct(kink.name, 'toggle_enabled')}
                      >
                        {enabled ? L.yes : L.no}
                      </Btn>
                      {enabled ? (
                        <>
                          <Btn
                            className="square"
                            icon="chevron-left"
                            disabled={kink.intensity <= 1}
                            onClick={() =>
                              kinkAct(kink.name, 'set_intensity', {
                                intensity: kink.intensity - 1,
                              })
                            }
                          />
                          <div className="cc-row" style={{ gap: 2 }}>
                            {[1, 2, 3, 4, 5].map((level) => (
                              <Icon
                                key={level}
                                name="circle"
                                style={{
                                  fontSize: 8,
                                  opacity: level <= kink.intensity ? 1 : 0.25,
                                }}
                              />
                            ))}
                          </div>
                          <Btn
                            className="square"
                            icon="chevron-right"
                            disabled={kink.intensity >= 5}
                            onClick={() =>
                              kinkAct(kink.name, 'set_intensity', {
                                intensity: kink.intensity + 1,
                              })
                            }
                          />
                        </>
                      ) : null}
                      {enabled ? (
                        <Btn
                          icon="pen"
                          title={kink.notes || L.noNotes}
                          onClick={() => kinkAct(kink.name, 'set_notes')}
                        >
                          {L.notes}
                        </Btn>
                      ) : null}
                    </div>
                  </div>
                );
              }),
            ),
          )
        )}
      </>,
    );
  };

  const SETTINGS_TOGGLES: {
    key: string;
    action: string;
    label: keyof CharacterCreatorStrings['settingsLabels'];
    inverted?: boolean;
  }[] = [
    { key: 'hotkeys', action: 'hotkeys', label: 'hotkeys' },
    {
      key: 'buttons_locked',
      action: 'action_buttons',
      label: 'buttons_locked',
    },
    { key: 'tgui_fancy', action: 'tgui_fancy', label: 'tgui_fancy' },
    { key: 'tgui_lock', action: 'tgui_lock', label: 'tgui_lock' },
    { key: 'windowflashing', action: 'winflash', label: 'windowflashing' },
    {
      key: 'see_chat_non_mob',
      action: 'see_chat_non_mob',
      label: 'see_chat_non_mob',
    },
    {
      key: 'ambientocclusion',
      action: 'ambientocclusion',
      label: 'ambientocclusion',
    },
    {
      key: 'auto_fit_viewport',
      action: 'auto_fit_viewport',
      label: 'auto_fit_viewport',
    },
    {
      key: 'balloon_alerts',
      action: 'balloon_alerts',
      label: 'balloon_alerts',
    },
    { key: 'runechat', action: 'runechat', label: 'runechat' },
    {
      key: 'descriptor_color',
      action: 'descriptor_color',
      label: 'descriptor_color',
    },
    { key: 'lobby_music', action: 'lobby_music', label: 'lobby_music' },
    { key: 'hear_midis', action: 'hear_midis', label: 'hear_midis' },
    {
      key: 'hear_speech_barks',
      action: 'hear_speech_barks',
      label: 'hear_speech_barks',
    },
    { key: 'ambience', action: 'ambience', label: 'ambience' },
    {
      key: 'background_music',
      action: 'background_music',
      label: 'background_music',
    },
    {
      key: 'allow_midround_antag',
      action: 'allow_midround_antag',
      label: 'allow_midround_antag',
    },
    { key: 'be_voice', action: 'be_voice', label: 'be_voice' },
  ];

  const SETTINGS_GROUPS: {
    title: keyof CharacterCreatorStrings['settingsGroups'];
    keys: string[];
  }[] = [
    {
      title: 'interface',
      keys: [
        'hotkeys',
        'buttons_locked',
        'tgui_fancy',
        'tgui_lock',
        'windowflashing',
      ],
    },
    {
      title: 'display',
      keys: [
        'see_chat_non_mob',
        'ambientocclusion',
        'auto_fit_viewport',
        'balloon_alerts',
        'runechat',
        'descriptor_color',
      ],
    },
    {
      title: 'audio',
      keys: [
        'lobby_music',
        'hear_midis',
        'hear_speech_barks',
        'ambience',
        'background_music',
      ],
    },
    { title: 'round', keys: ['allow_midround_antag', 'be_voice'] },
  ];

  const renderSettings = () => {
    const game = data.game_prefs || {};
    const toggleRow = (toggle: (typeof SETTINGS_TOGGLES)[number]) => {
      const on = asBool(game[toggle.key] as Booleanish);
      return (
        <Fragment key={toggle.key}>
          <div className="cc-kv-label">{L.settingsLabels[toggle.label]}</div>
          <Btn
            className={on ? 'on' : 'off'}
            onClick={() => doPref(toggle.action)}
          >
            {on ? L.on : L.off}
          </Btn>
        </Fragment>
      );
    };
    return windowShell(
      L.tabs.settings,
      <>
        <div className="cc-info-grid cc-settings-grid">
          {SETTINGS_GROUPS.map((settingsGroup) =>
            infoBlock(
              L.settingsGroups[settingsGroup.title],
              <div className="cc-kv">
                {SETTINGS_TOGGLES.filter((toggle) =>
                  settingsGroup.keys.includes(toggle.key),
                ).map(toggleRow)}
                {settingsGroup.title === 'display' ? (
                  <>
                    {kvButton(L.pixelSize, text(game.pixel_size), () =>
                      doPref('pixel_size'),
                    )}
                    {kvButton(L.scalingMethod, text(game.scaling_method), () =>
                      doPref('scaling_method'),
                    )}
                  </>
                ) : null}
              </div>,
            ),
          )}
        </div>
        <div className="cc-info-grid" style={{ marginTop: 8 }}>
          {infoBlock(
            L.editor,
            <div className="cc-kv">
              <div className="cc-kv-label">{L.language}</div>
              <Select
                value={lang}
                options={[
                  { value: 'en', label: 'English' },
                  { value: 'ru', label: 'Русский' },
                ]}
                onChange={(value) => act('cc_set_lang', { lang: value })}
              />
              <div className="cc-kv-label">{L.backdrop}</div>
              <Select
                value={data.background}
                options={(data.background_options || []).map((option) => ({
                  value: option.value,
                  label: option.name,
                }))}
                onChange={(value) =>
                  doPref('character_setup_preview_background', undefined, {
                    bg: value,
                  })
                }
              />
            </div>,
          )}
          {infoBlock(
            L.tools,
            <div className="cc-kv">
              {kvButton(L.playerLanguage, L.set, () =>
                doPref('player_language', 'input'),
              )}
              {kvButton(L.keybinds, L.edit, () => doPref('keybinds', 'menu'))}
              {kvButton(L.savePreferences, L.save, () => doPref('save'))}
            </div>,
          )}
        </div>
      </>,
    );
  };

  // ---------------------------------------------------------------------------
  // Doll, card, rail, top bar, bottom bar
  // ---------------------------------------------------------------------------

  const backdropColor =
    data.background === 'white'
      ? '#d8d8d8'
      : data.background === 'dark'
        ? '#0a0a0a'
        : '#0d0d0d';

  const renderDoll = () => (
    <Frame
      className="cc-doll-frame"
      style={{
        flex: 1,
        minHeight: 0,
        display: 'flex',
        flexDirection: 'column',
      }}
    >
      {sandbox ? null : (
        <>
          <div className="cc-doll-corner bl">
            <div
              className={`cc-corner-btn ${asBool(data.preview_clothes) ? 'on' : 'off'}`}
              title={L.clothesLayer}
              onClick={() =>
                doPref('character_setup_preview_layer', undefined, {
                  layer: 'clothes',
                })
              }
            >
              <Icon name="tshirt" />
            </div>
          </div>
          <div className="cc-doll-corner br">
            <div
              className={`cc-corner-btn ${asBool(data.preview_underwear) ? 'on' : 'off'}`}
              title={L.underwearLayer}
              onClick={() =>
                doPref('character_setup_preview_layer', undefined, {
                  layer: 'underwear',
                })
              }
            >
              <Icon name="socks" />
            </div>
          </div>
        </>
      )}
      <div className="cc-doll">
        <div
          ref={dollBoxRef}
          className="cc-doll-box"
          style={{ backgroundColor: backdropColor }}
        >
          {data.preview_map && dollZoom > 0 ? (
            // ByondUi re-applies the params of its first render on every resize,
            // so a changed backdrop must remount it or a tab switch restores the old one.
            <ByondUi
              key={`${data.preview_map}|${backdropColor}`}
              width="100%"
              height="100%"
              params={{
                id: data.preview_map,
                type: 'map',
                zoom: dollZoom,
                'zoom-mode': 'distort',
                'background-color': backdropColor,
              }}
            />
          ) : (
            <div
              style={{
                position: 'absolute',
                inset: 0,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
              }}
            >
              <Icon name="user" size={5} color="label" />
            </div>
          )}
        </div>
        <div className="cc-rotate">
          <Btn
            className="square"
            icon="arrow-left"
            title={L.rotateLeft}
            onClick={() =>
              doPref('character_setup_preview_rotate', undefined, {
                rotate: 'left',
              })
            }
          />
          <span className="cc-muted">{L.rotate}</span>
          <Btn
            className="square"
            icon="arrow-right"
            title={L.rotateRight}
            onClick={() =>
              doPref('character_setup_preview_rotate', undefined, {
                rotate: 'right',
              })
            }
          />
        </div>
      </div>
    </Frame>
  );

  const portraitBox = (
    src: string | null,
    label: string,
    hint: string,
    pref: string,
  ) => (
    <div
      className="cc-headshot"
      title={hint}
      onClick={() => doPref(pref, 'input')}
    >
      {src ? <img src={src} alt="" /> : <Icon name="portrait" size={2} />}
      <div className="cc-headshot-label">{label}</div>
    </div>
  );

  // Both portraits sit under the doll on every tab; a click sets the URL.
  const renderGallery = () => (
    <Frame className="cc-gallery">
      {portraitBox(data.headshot, L.headshot, L.setHeadshot, 'headshot')}
      {portraitBox(
        data.nsfw_headshot,
        L.nsfwHeadshot,
        L.setNsfwHeadshot,
        'nsfw_headshot',
      )}
    </Frame>
  );

  // Hidden when the species offers fewer than two builds for this body type.
  const buildRow = () =>
    (data.body_build_options || []).length > 1 ? (
      <>
        <div className="cc-kv-label">{L.bodyBuild}</div>
        <Select
          value={data.body_build || ''}
          options={(data.body_build_options || []).map((option) => ({
            value: option.id,
            label: option.name,
          }))}
          onChange={(value) =>
            doPref('character_setup_select_body_build', undefined, {
              body_build: value,
            })
          }
        />
      </>
    ) : null;

  const speciesEntry = species.find((entry) => entry.id === data.species_id);

  // Summary card in the BG3 style: one column on one surface, every line with a tooltip.
  const renderCard = () => {
    const parsed = parseSpeciesDesc(
      speciesEntry ? speciesDesc(speciesEntry) : '',
    );
    const raceGroup = groupOfSpecies(data.species_id);
    const subclassTitle = highSubclasses.find(
      (entry) => entry.id === preferredSubclass,
    )?.title;
    const patron = (data.faith_options || [])
      .flatMap((faith) => faith.patrons)
      .find((entry) => asBool(entry.selected));
    const quirkEntries = data.cc_quirks?.entries || [];
    const statBreakdown = (stat: StatRow) => (
      <>
        {stat.desc ? <div style={{ marginBottom: 6 }}>{stat.desc}</div> : null}
        <div className="cc-tip-label">{L.statParts}:</div>
        <div>
          {stat.base} {L.statBase}
        </div>
        {stat.species ? (
          <div>
            {stat.species > 0 ? '+' : ''}
            {stat.species} {L.statRace}
          </div>
        ) : null}
        {stat.age ? (
          <div>
            {stat.age > 0 ? '+' : ''}
            {stat.age} {L.statAge}
          </div>
        ) : null}
      </>
    );
    return (
      <Frame className="cc-card">
        <div className="cc-card-scroll cc-scroll">
          <Tip
            className="cc-portrait"
            title={L.headshot}
            body={L.setHeadshot}
            onClick={() => doPref('headshot', 'input')}
          >
            {data.headshot ? (
              <img src={data.headshot} alt="" />
            ) : (
              monogram(data.real_name)
            )}
          </Tip>
          <div className="cc-card-race">
            {raceGroup && raceGroup.name !== data.species_name
              ? `${raceGroup.name} · `
              : ''}
            {data.species_name}
          </div>
          <Tip
            className="cc-card-name"
            title={text(data.real_name, L.unnamed)}
            body={L.renameHint}
            onClick={() => doPref('name', 'input')}
          >
            {text(data.real_name, L.unnamed)}
          </Tip>
          <div className="cc-card-role">
            {text(data.high_job, L.none)}
            {subclassTitle ? ` · ${subclassTitle}` : ''}
          </div>
          <div className="cc-stats">
            {(data.cc_stats || []).map((stat) => (
              <Tip
                key={stat.label}
                className="cc-stat"
                title={`${stat.name} (${stat.total})`}
                subtitle={L.ability}
                body={statBreakdown(stat)}
              >
                {stat.icon && stat.icon_state ? (
                  <DmIcon
                    icon={stat.icon}
                    icon_state={stat.icon_state}
                    width="18px"
                    height="18px"
                    fallback={<span />}
                  />
                ) : null}
                <div className="cc-stat-label">{stat.label}</div>
                <div className="cc-stat-value">{stat.total}</div>
              </Tip>
            ))}
          </div>
          <div className="cc-badges">
            <Tip className="cc-badge" title={L.triumphs} body={L.triumphsHint}>
              <Icon name="trophy" />
              <span>{data.triumphs ?? 0}</span>
            </Tip>
            <Tip
              className="cc-badge"
              title={L.quirkBalance}
              body={L.quirkBalanceHint}
              onClick={() => doPref('select_quirks')}
            >
              <Icon name="theater-masks" />
              <span>{data.cc_quirks?.balance ?? 0}</span>
            </Tip>
          </div>
          <Ornament>{L.rail.origin}</Ornament>
          <div className="cc-card-line">
            {currentOrigin ? (
              <Tip
                className="cc-link"
                title={currentOrigin.name}
                subtitle={groupName(currentOrigin.group) || L.rail.origin}
                body={currentOrigin.description}
              >
                {currentOrigin.name}
              </Tip>
            ) : (
              L.none
            )}
          </div>
          <Ornament>{L.rail.deity}</Ornament>
          <div className="cc-card-line">
            {patron ? (
              <Tip
                className="cc-link"
                title={patron.name}
                subtitle={patron.domain}
                body={
                  <>
                    <div>{patron.description}</div>
                    {patron.boons ? (
                      <div style={{ color: '#a9d68a', marginTop: 6 }}>
                        {L.boons}: {patron.boons}
                      </div>
                    ) : null}
                    {patron.sins ? (
                      <div style={{ color: '#e9a497', marginTop: 4 }}>
                        {L.sins}: {patron.sins}
                      </div>
                    ) : null}
                  </>
                }
              >
                {patron.name}
              </Tip>
            ) : (
              text(data.patron_name, L.none)
            )}
          </div>
          <Ornament>{L.raceTraits}</Ornament>
          <div className="cc-card-line">
            <span className="cc-card-key">{L.language} - </span>
            <Tip
              className="cc-link"
              title={text(speciesEntry?.language)}
              body={L.languageHint}
            >
              {text(speciesEntry?.language)}
            </Tip>
          </div>
          {parsed.stats.length || speciesEntry?.stats?.length ? (
            <div className="cc-card-line">
              <span className="cc-card-key">{L.statModifiers} - </span>
              {(speciesEntry?.stats || []).map((stat, index) => (
                <Fragment key={stat.label}>
                  {index ? ', ' : ''}
                  <Tip
                    className="cc-link"
                    title={stat.name}
                    body={
                      data.cc_stats?.find((row) => row.label === stat.label)
                        ?.desc || stat.name
                    }
                  >
                    {stat.label} {stat.value > 0 ? '+' : ''}
                    {stat.value}
                  </Tip>
                </Fragment>
              ))}
            </div>
          ) : null}
          {parsed.traits.length ? (
            <div className="cc-card-line">
              <span className="cc-card-key">{L.traits} - </span>
              {parsed.traits.map((trait, index) => (
                <Fragment key={trait}>
                  {index ? ', ' : ''}
                  <Tip
                    className="cc-link"
                    title={trait}
                    subtitle={L.raceTrait}
                    body={L.traitHint}
                  >
                    {trait}
                  </Tip>
                </Fragment>
              ))}
            </div>
          ) : null}
          {parsed.proficiencies.length ? (
            <>
              <Ornament>{L.proficiencies}</Ornament>
              <div className="cc-card-line">
                <span className="cc-card-key">{L.skills} - </span>
                {parsed.proficiencies.map((skill, index) => (
                  <Fragment key={skill.name}>
                    {index ? ', ' : ''}
                    <Tip
                      className="cc-link"
                      title={skill.name}
                      subtitle={L.skill}
                      body={`${L.startsAt}: ${SKILL_RANKS[skill.level] || skill.level} (${skill.level})`}
                    >
                      {skill.name}
                    </Tip>
                  </Fragment>
                ))}
              </div>
            </>
          ) : null}
          {quirkEntries.length ? (
            <>
              <Ornament>{L.quirks}</Ornament>
              <div className="cc-card-line">
                {quirkEntries.map((quirk, index) => (
                  <Fragment key={quirk.name}>
                    {index ? ', ' : ''}
                    <Tip
                      className="cc-link"
                      title={quirk.name}
                      subtitle={L.quirk}
                      body={quirk.desc}
                    >
                      {quirk.name}
                    </Tip>
                  </Fragment>
                ))}
              </div>
            </>
          ) : null}
        </div>
        <Btn
          className="fluid"
          icon="eye"
          onClick={() => doPref('ooc_preview', 'input')}
        >
          {L.characterPreview}
        </Btn>
      </Frame>
    );
  };

  const railValue: Record<FateCat, string> = {
    identity: text(data.real_name, L.unnamed),
    origin: activeGroup
      ? groupName(activeGroup)
      : text(currentOrigin?.name, L.none),
    suborigin:
      currentOrigin?.group === activeGroup
        ? text(currentOrigin?.name)
        : L.notChosen,
    race: activeRaceGroup
      ? raceGroupName(activeRaceGroup)
      : text(data.species_name),
    subrace:
      groupOfSpecies(data.species_id)?.id === activeRaceGroup
        ? text(data.species_name)
        : L.notChosen,
    role: text(data.high_job, L.none),
    subrole:
      highSubclasses.find((entry) => entry.id === preferredSubclass)?.title ||
      L.anySubclass,
    deity: text(data.patron_name, L.none),
    background: L.soon,
    ability: `${L.quirkBalance}: ${data.cc_quirks?.balance ?? 0}`,
  };
  const FATE_ICONS: Record<FateCat, string> = {
    identity: 'id-card',
    origin: 'globe-europe',
    suborigin: 'campground',
    race: 'users',
    subrace: 'user-tag',
    role: 'shield-alt',
    subrole: 'chess-knight',
    deity: 'sun',
    background: 'scroll',
    ability: 'dice-d20',
  };
  const MIRROR_ICONS: Record<MirrorCat, string> = {
    head: 'smile',
    markings: 'paint-brush',
    body: 'child',
    prosthetics: 'cogs',
    taur: 'horse',
    genitals: 'venus-mars',
    attire: 'tshirt',
    piercing: 'ring',
  };
  const SUB_CATS: string[] = ['suborigin', 'subrace', 'subrole'];

  const renderRail = () => (
    <Frame className="cc-rail cc-scroll">
      {tab === 'fate'
        ? fateVisible.map((cat) => (
            <div
              key={cat}
              className={`cc-rail-item ${cat === activeFate ? 'active' : ''} ${SUB_CATS.includes(cat) ? 'sub' : ''}`}
              title={L.rail[cat]}
              onClick={() => {
                setFateCat(cat);
                setOriginPopup(false);
              }}
            >
              <div className="cc-rail-icon">
                <Icon name={FATE_ICONS[cat]} />
              </div>
              <div className="cc-grow">
                <div className="cc-rail-label">{L.rail[cat]}</div>
                <div className="cc-rail-value">{railValue[cat]}</div>
              </div>
            </div>
          ))
        : mirrorVisible.map((cat) => (
            <div
              key={cat}
              className={`cc-rail-item ${cat === activeMirror ? 'active' : ''}`}
              title={L.mirror[cat]}
              onClick={() => {
                setMirrorCat(cat);
                setPicker(null);
              }}
            >
              <div className="cc-rail-icon">
                <Icon name={MIRROR_ICONS[cat]} />
              </div>
              <div className="cc-grow">
                <div className="cc-rail-label">{L.mirror[cat]}</div>
              </div>
            </div>
          ))}
      {tab === 'body' ? (
        <div className="cc-rail-foot">
          <Btn
            className="fluid"
            icon="dice"
            title={L.randomAppearance}
            onClick={() => setOverlay({ kind: 'confirm_random' })}
          >
            <span className="cc-rail-label">{L.randomAppearance}</span>
          </Btn>
        </div>
      ) : null}
    </Frame>
  );

  const isFullscreen = asBool(data.preferences_fullscreen);
  const unsaved = asBool(data.cc_unsaved);
  // DONE and the close button ask first while the character has unsaved changes.
  const requestClose = () => {
    if (unsaved) {
      setOverlay({ kind: 'confirm_close' });
    } else {
      doPref('finished');
    }
  };
  const readyText = data.round_total_players
    ? `${data.round_ready_players ?? 0}/${data.round_total_players} ${L.roundReady}`
    : '';

  // Empty parts of the top bar move the window, like the title bar it replaces.
  const startDrag = (event: React.MouseEvent<HTMLDivElement>) => {
    const target = event.target as HTMLElement;
    if (
      event.button !== 0 ||
      target.closest('.cc-btn, .cc-round, .cc-corner-btn, input, select')
    ) {
      return;
    }
    dragStartHandler(event);
  };

  const renderTopBar = () => (
    <div className="cc-topbar" onMouseDown={startDrag}>
      <Btn icon="history" disabled title={L.soon}>
        <span className="cc-topbar-extra">{L.creatorLogs}</span>
      </Btn>
      <Btn
        icon="file-export"
        title={L.exportHint}
        onClick={() => act('cc_export')}
      >
        <span className="cc-topbar-extra">{L.exportSave}</span>
      </Btn>
      <Btn
        icon="file-import"
        title={L.importHint}
        onClick={() => act('cc_import')}
      >
        <span className="cc-topbar-extra">{L.importSave}</span>
      </Btn>
      <Btn
        icon="users"
        title={L.characterListHint}
        onClick={() => doPref('changeslot')}
      >
        <span className="cc-topbar-extra">{L.characterList}</span>
      </Btn>
      <div className="cc-grow" />
      <Btn
        icon={data.round_action_icon || 'user-check'}
        className={
          data.round_action_color === 'bad'
            ? 'danger'
            : data.round_action_color
              ? 'on'
              : ''
        }
        title={data.round_action_tooltip}
        disabled={asBool(data.round_action_disabled)}
        onClick={() => doPref('character_setup_round_action')}
      >
        {text(data.round_action_label)}
      </Btn>
      {readyText ? (
        <div className="cc-round-line cc-topbar-extra">
          <span className="cc-round-ready">{readyText}</span>
        </div>
      ) : null}
      <div className="cc-grow" />
      <Btn
        className="square"
        title={L.smaller}
        disabled={menuScale <= 0.8}
        onClick={() => setMenuScale(menuScale - 0.05)}
      >
        −
      </Btn>
      <Btn title={L.resetScale} onClick={() => setMenuScale(1)}>
        {Math.round(menuScale * 100)}
      </Btn>
      <Btn
        className="square"
        title={L.larger}
        disabled={menuScale >= 1.25}
        onClick={() => setMenuScale(menuScale + 0.05)}
      >
        +
      </Btn>
      <Btn
        className="square"
        icon={isFullscreen ? 'compress' : 'expand'}
        title={isFullscreen ? L.collapseWindow : L.expandWindow}
        onClick={() => doPref('character_setup_preferences_fullscreen')}
      />
      <Btn
        className="square danger"
        icon="times"
        title={L.close}
        onClick={requestClose}
      />
    </div>
  );

  // Search finds windows, categories, appearance parts and catalog entries.
  // The index is only built while the player is typing.
  type SearchHit = { label: string; path: string; run: () => void };
  const buildSearchIndex = (): SearchHit[] => {
    const hits: SearchHit[] = [];
    for (const id of Object.keys(L.tabs) as Tab[]) {
      hits.push({ label: L.tabs[id], path: L.window, run: () => setTab(id) });
    }
    for (const cat of fateVisible) {
      hits.push({
        label: L.rail[cat],
        path: L.tabs.fate,
        run: () => {
          openCharacter('fate');
          setFateCat(cat);
        },
      });
    }
    for (const cat of mirrorVisible) {
      hits.push({
        label: L.mirror[cat],
        path: L.tabs.body,
        run: () => {
          openCharacter('body');
          setMirrorCat(cat);
        },
      });
    }
    // Body type, build, pronouns and age live in the Identity window.
    const identity = [L.bodyType, L.pronouns, L.age];
    if ((data.body_build_options || []).length > 1) {
      identity.push(L.bodyBuild);
    }
    for (const label of identity) {
      hits.push({
        label,
        path: L.rail.identity,
        run: () => {
          openCharacter('fate');
          setFateCat('identity');
        },
      });
    }
    hits.push(
      {
        label: L.nameLabel,
        path: L.tabs.fate,
        run: () => doPref('name', 'input'),
      },
      {
        label: L.headshot,
        path: L.tabs.fate,
        run: () => doPref('headshot', 'input'),
      },
      {
        label: L.gallery,
        path: L.tabs.fate,
        run: () => doPref('gallery', 'menu', { tab: 'regular' }),
      },
      {
        label: L.nsfwGallery,
        path: L.tabs.fate,
        run: () => doPref('gallery', 'menu', { tab: 'nsfw' }),
      },
    );
    for (const feature of features) {
      hits.push({
        label: feature.name,
        path: `${L.tabs.body} › ${L.mirror[featureCat(feature)]}`,
        run: () => {
          openCharacter('body');
          setMirrorCat(featureCat(feature));
        },
      });
    }
    for (const entry of species) {
      hits.push({
        label: entry.name,
        path: L.rail.race,
        run: () => {
          openCharacter('fate');
          setFateCat('race');
          setInspectSpecies(entry.id);
        },
      });
    }
    for (const origin of origins) {
      hits.push({
        label: origin.name,
        path: L.rail.origin,
        run: () => {
          openCharacter('fate');
          setPendingGroup(origin.group || null);
          setFateCat(origin.group ? 'suborigin' : 'origin');
          setInspectOrigin(origin.id);
        },
      });
    }
    for (const category of jobCategories) {
      for (const job of category.jobs) {
        hits.push({
          label: jobStates[job.title]?.current_title || job.title,
          path: `${L.rail.role} › ${category.name}`,
          run: () => {
            openCharacter('fate');
            setFateCat('role');
            setRoleCategory(category.name);
            setInspectJob(job.title);
          },
        });
      }
    }
    for (const faith of data.faith_options || []) {
      for (const patron of faith.patrons) {
        hits.push({
          label: patron.name,
          path: `${L.rail.deity} › ${faith.name}`,
          run: () => {
            openCharacter('fate');
            setFateCat('deity');
            setFaithView(faith.id);
            setInspectPatron(patron.id);
          },
        });
      }
    }
    for (const label of [
      L.language,
      L.backdrop,
      ...Object.values(L.settingsLabels),
    ]) {
      hits.push({
        label,
        path: L.tabs.settings,
        run: () => setTab('settings'),
      });
    }
    for (const label of [
      L.flavourText,
      L.oocNotes,
      L.nsfwFlavourText,
      L.foodPreferences,
      L.dominantHand,
      L.voice,
      L.voiceType,
      L.voiceAccent,
      L.voiceColor,
      L.voicePack,
      L.moans,
      L.rumours,
      L.rivals,
    ]) {
      hits.push({ label, path: L.tabs.info, run: () => setTab('info') });
    }
    hits.push({
      label: L.chooseLoadout,
      path: L.mirror.attire,
      run: () => setTab('loadout'),
    });
    return hits;
  };

  const searchHits = search.trim()
    ? buildSearchIndex()
        .filter((hit) =>
          hit.label.toLowerCase().includes(search.trim().toLowerCase()),
        )
        .slice(0, 12)
    : [];

  const renderNav = () => (
    <Frame className="cc-nav">
      {(Object.keys(L.tabs) as Tab[]).map((id) => (
        <div
          key={id}
          className={`cc-nav-tab ${tab === id ? 'active' : ''}`}
          onClick={() => {
            setTab(id);
            setPicker(null);
          }}
        >
          {L.tabs[id]}
        </div>
      ))}
      <div className="cc-search">
        <Icon className="cc-search-icon" name="search" />
        <input
          value={search}
          placeholder={L.searchPlaceholder}
          onChange={(event) => {
            setSearch(event.target.value);
            setSearchOpen(true);
          }}
          onFocus={() => setSearchOpen(true)}
          onBlur={() => setTimeout(() => setSearchOpen(false), 150)}
        />
        {searchOpen && searchHits.length ? (
          <div className="cc-search-results cc-scroll">
            {searchHits.map((hit) => (
              <div
                key={`${hit.path}-${hit.label}`}
                className="cc-search-result"
                onMouseDown={(event) => {
                  event.preventDefault();
                  hit.run();
                  setSearch('');
                  setSearchOpen(false);
                }}
              >
                <span className="cc-grow">{hit.label}</span>
                <span className="cc-search-path">{hit.path}</span>
              </div>
            ))}
          </div>
        ) : null}
      </div>
    </Frame>
  );

  const renderDone = () => (
    <Frame className="cc-done">
      <div className="cc-done-small">
        <Btn
          className={`cc-done-side ${unsaved ? 'gold' : ''}`}
          icon="save"
          title={L.saveHint}
          onClick={() => doPref('save')}
        >
          {L.save}
        </Btn>
        <Btn
          className="cc-done-side"
          icon="undo"
          title={L.undoHint}
          onClick={() => doPref('load')}
        >
          {L.revert}
        </Btn>
      </div>
      <div
        className="cc-done-main"
        title={unsaved ? L.unsavedMark : undefined}
        onClick={requestClose}
      >
        <span>{L.done}</span>
        {unsaved ? (
          <span className="cc-done-unsaved">{L.unsavedMark}</span>
        ) : null}
      </div>
    </Frame>
  );

  const renderModal = () => {
    if (!overlay) {
      return null;
    }
    if (overlay.kind === 'confirm_close') {
      return (
        <div className="cc-modal-back">
          <Frame className="cc-modal" title={L.unsavedTitle}>
            <div className="cc-desc" style={{ marginBottom: 12 }}>
              {L.unsavedWarning}
            </div>
            <div className="cc-row" style={{ justifyContent: 'center' }}>
              <Btn onClick={() => setOverlay(null)}>{L.cancel}</Btn>
              <Btn
                className="danger"
                onClick={() => {
                  setOverlay(null);
                  doPref('finished');
                }}
              >
                {L.closeNoSave}
              </Btn>
              <Btn
                className="primary"
                onClick={() => {
                  setOverlay(null);
                  doPref('save');
                  doPref('finished');
                }}
              >
                {L.saveAndClose}
              </Btn>
            </div>
          </Frame>
        </div>
      );
    }
    const isRandom = overlay.kind === 'confirm_random';
    const target =
      overlay.kind === 'confirm_race'
        ? species.find((entry) => entry.id === overlay.id)
        : undefined;
    return (
      <div className="cc-modal-back">
        <Frame
          className="cc-modal"
          title={
            isRandom
              ? L.randomAppearance
              : `${L.chooseRace}: ${target?.name || ''}`
          }
        >
          <div className="cc-desc" style={{ marginBottom: 12 }}>
            {isRandom
              ? sandbox
                ? L.disguiseRandomWarning
                : L.randomWarning
              : sandbox
                ? L.disguiseRaceWarning
                : L.raceWarning}
          </div>
          <div className="cc-row" style={{ justifyContent: 'center' }}>
            <Btn onClick={() => setOverlay(null)}>{L.cancel}</Btn>
            <Btn
              className="primary"
              onClick={() => {
                if (isRandom) {
                  doPref('randomiseappearanceprefs');
                } else if (target) {
                  doPref('character_setup_select_species', undefined, {
                    species_id: target.id,
                  });
                  setPendingRaceGroup(null);
                  setInspectSpecies(null);
                }
                setOverlay(null);
              }}
            >
              {L.confirm}
            </Btn>
          </div>
        </Frame>
      </div>
    );
  };

  // ---------------------------------------------------------------------------
  // Sandbox editors: succubus disguise and ooze reshape
  // ---------------------------------------------------------------------------

  const sandboxTitle = oozeMode ? L.reshapeTitle : L.disguiseTitle;
  const sandboxCancel = () => act(oozeMode ? 'ooze_cancel' : 'disguise_cancel');

  const renderIdentity = () =>
    windowShell(
      L.identity,
      <>
        <div
          className="cc-hint"
          style={{ textAlign: 'left', marginBottom: 10 }}
        >
          {oozeMode ? L.oozeIdentityHint : L.identityHint}
        </div>
        <div className="cc-kv cc-sandbox-kv">
          <div className="cc-kv-label">{L.nameLabel}</div>
          {oozeMode ? (
            <div className="cc-sandbox-static">
              {text(data.real_name, L.unnamed)}
            </div>
          ) : (
            <Btn
              className="fluid"
              icon="pen"
              style={{ justifyContent: 'flex-start' }}
              onClick={() => doPref('name', 'input')}
            >
              {text(data.real_name, L.unnamed)}
            </Btn>
          )}
          <div className="cc-kv-label">{L.bodyType}</div>
          <Btn
            className="fluid"
            style={{ justifyContent: 'flex-start' }}
            onClick={() => doPref('gender')}
          >
            {data.gender}
          </Btn>
          {buildRow()}
          {oozeMode ? null : (
            <>
              <div className="cc-kv-label">{L.pronouns}</div>
              <Btn
                className="fluid"
                style={{ justifyContent: 'flex-start' }}
                onClick={() => doPref('pronouns', 'input')}
              >
                {text(data.pronouns, L.none)}
              </Btn>
              <div className="cc-kv-label">{L.age}</div>
              <Select
                title={data.age_tooltips?.[data.age] || ''}
                value={data.age}
                options={(data.age_options || []).map((option) => ({
                  value: option,
                  label: option,
                }))}
                onChange={(value) =>
                  act('set_age', {
                    value: (data.age_options || []).indexOf(value) + 1,
                  })
                }
              />
            </>
          )}
          <div className="cc-kv-label">{L.voiceType}</div>
          <Btn
            className="fluid"
            style={{ justifyContent: 'flex-start' }}
            onClick={() => doPref('voicetype', 'input')}
          >
            {text(data.voice_type)}
          </Btn>
          <div className="cc-kv-label">{L.voiceColor}</div>
          <Btn
            className="fluid"
            style={{ justifyContent: 'flex-start' }}
            onClick={() => doPref('voice', 'input')}
          >
            <Swatch color={data.voice_color} /> {data.voice_color}
          </Btn>
        </div>
        {oozeMode ? null : (
          <Btn
            className="fluid"
            icon="dice"
            style={{ marginTop: 12 }}
            onClick={() => setOverlay({ kind: 'confirm_random' })}
          >
            {L.randomAppearance}
          </Btn>
        )}
      </>,
    );

  type SandboxItem = {
    key: string;
    label: string;
    icon: string;
    value?: string;
    sub?: boolean;
    active: boolean;
    run: () => void;
  };

  const sandboxItems = (): SandboxItem[] => {
    const items: SandboxItem[] = [
      {
        key: 'identity',
        label: L.identity,
        icon: 'id-card',
        value: text(data.real_name, L.unnamed),
        active: sandboxView === 'identity',
        run: () => setSandboxView('identity'),
      },
    ];
    if (!oozeMode) {
      for (const cat of ['race', 'subrace'] as FateCat[]) {
        if (!fateVisible.includes(cat)) {
          continue;
        }
        items.push({
          key: cat,
          label: L.rail[cat],
          icon: FATE_ICONS[cat],
          value: railValue[cat],
          sub: cat === 'subrace',
          active:
            sandboxView === 'fate' &&
            (activeFate === cat ||
              (cat === 'race' && activeFate !== 'subrace')),
          run: () => {
            setSandboxView('fate');
            setFateCat(cat);
          },
        });
      }
    }
    for (const cat of mirrorVisible) {
      // Attire and prosthetics belong to the real character; the ooze keeps its own body plan.
      if (
        cat === 'attire' ||
        cat === 'prosthetics' ||
        (oozeMode && cat === 'taur')
      ) {
        continue;
      }
      items.push({
        key: cat,
        label: L.mirror[cat],
        icon: MIRROR_ICONS[cat],
        active: sandboxView === 'mirror' && activeMirror === cat,
        run: () => {
          setSandboxView('mirror');
          setMirrorCat(cat);
        },
      });
    }
    return items;
  };

  const renderSandboxTop = () => (
    <div className="cc-topbar" onMouseDown={startDrag}>
      <Icon
        className="cc-sandbox-icon"
        name={oozeMode ? 'tint' : 'theater-masks'}
      />
      <div className="cc-topbar-title">{sandboxTitle}</div>
      <span className="cc-muted cc-sandbox-sub cc-topbar-extra">
        {text(data.real_name, L.unnamed)} · {text(data.species_name)}
      </span>
      <div className="cc-grow" />
      {oozeMode ? null : (
        <div className="cc-round">
          <span className="cc-muted">
            {L.contractTier} {data.contract_tier ?? 0}
          </span>
          <span className="cc-muted">{L.essence}</span>
          <span className="cc-round-time">{data.essence ?? 0}</span>
          <span className="cc-muted">
            {data.creation_cost
              ? `${L.cost}: ${data.creation_cost}`
              : L.freeInLair}
          </span>
        </div>
      )}
      <div className="cc-grow" />
      <Btn
        className="square danger"
        icon="times"
        title={L.discardDraft}
        onClick={sandboxCancel}
      />
    </div>
  );

  const renderSandboxFoot = () => {
    const ready = asBool(data.commit_available);
    const reason = ready
      ? oozeMode
        ? L.readyReshape
        : L.readyBind
      : text(data.commit_reason);
    return (
      <Frame>
        <div className="cc-sandbox-foot">
          {oozeMode ? null : (
            <div className="cc-sandbox-slots">
              <Tip
                className="cc-sandbox-slots-label"
                title={L.wardrobe}
                body={L.wardrobeHint}
              >
                {L.wardrobe}
              </Tip>
              {(data.slots || []).map((slot) => {
                const unlocked = asBool(slot.unlocked);
                const worn = asBool(slot.active);
                const occupied = asBool(slot.occupied);
                const selected = slot.slot === data.selected_slot;
                return (
                  <Tip
                    key={slot.slot}
                    className={`cc-sandbox-slot ${selected ? 'selected' : ''} ${unlocked ? '' : 'locked'} ${worn ? 'worn' : ''}`}
                    title={`${L.wardrobe} ${slot.slot}`}
                    body={
                      !unlocked
                        ? L.slotLocked
                        : worn
                          ? `${slot.name} · ${L.slotWorn}`
                          : occupied
                            ? slot.name
                            : L.slotEmpty
                    }
                    onClick={() =>
                      unlocked && !selected
                        ? act('disguise_select_slot', { slot: slot.slot })
                        : undefined
                    }
                  >
                    <span className="cc-sandbox-slot-num">
                      {unlocked ? slot.slot : <Icon name="lock" />}
                    </span>
                    <span
                      className={`cc-sandbox-slot-name ${occupied ? '' : 'empty'}`}
                    >
                      {occupied ? slot.name : L.slotEmpty}
                    </span>
                    {worn ? (
                      <Icon
                        className="cc-sandbox-slot-worn"
                        name="user-check"
                      />
                    ) : null}
                  </Tip>
                );
              })}
            </div>
          )}
          <div className="cc-sandbox-actions">
            <div className={`cc-sandbox-status ${ready ? 'ok' : 'bad'}`}>
              {reason}
            </div>
            {oozeMode ? (
              <Btn
                icon="history"
                title={L.restoreSavedHint}
                onClick={() => act('ooze_reset')}
              >
                {L.restoreSaved}
              </Btn>
            ) : null}
            <Btn onClick={sandboxCancel}>{L.cancel}</Btn>
            <Btn
              className="primary cc-sandbox-commit"
              icon={oozeMode ? 'check' : 'link'}
              disabled={!ready}
              onClick={() => act(oozeMode ? 'ooze_commit' : 'disguise_commit')}
            >
              {oozeMode ? L.reshapeAction : L.bindIdentity}
              {!oozeMode && data.creation_cost
                ? ` (−${data.creation_cost})`
                : ''}
            </Btn>
          </div>
        </div>
      </Frame>
    );
  };

  const renderSandbox = () => {
    let sandboxContent: ReactNode;
    if (sandboxView === 'identity' || (oozeMode && sandboxView === 'fate')) {
      sandboxContent = renderIdentity();
    } else if (sandboxView === 'fate') {
      sandboxContent =
        activeFate === 'subrace' ? renderSubRace() : renderRace();
    } else {
      sandboxContent = renderMirror();
    }
    return (
      <Window title={sandboxTitle} width={1180} height={800} theme="vanderlin">
        <Window.Content fitted>
          <div className="cc cc-sandbox">
            <div className="cc-area-top">{renderSandboxTop()}</div>
            <div className="cc-area-rail">
              <Frame className="cc-rail cc-scroll">
                {sandboxItems().map((item) => (
                  <div
                    key={item.key}
                    className={`cc-rail-item ${item.active ? 'active' : ''} ${item.sub ? 'sub' : ''}`}
                    title={item.label}
                    onClick={() => {
                      item.run();
                      setPicker(null);
                    }}
                  >
                    <div className="cc-rail-icon">
                      <Icon name={item.icon} />
                    </div>
                    <div className="cc-grow">
                      <div className="cc-rail-label">{item.label}</div>
                      {item.value ? (
                        <div className="cc-rail-value">{item.value}</div>
                      ) : null}
                    </div>
                  </div>
                ))}
              </Frame>
            </div>
            <div className="cc-area-content">
              <Frame style={{ height: '100%' }}>
                {sandboxContent}
                {picker && sandboxView === 'mirror'
                  ? renderStylePicker()
                  : null}
                {renderModal()}
              </Frame>
            </div>
            <div className="cc-area-doll">{renderDoll()}</div>
            <div className="cc-area-foot">{renderSandboxFoot()}</div>
            <TipLayer pinHint={L.pinHint} />
          </div>
        </Window.Content>
      </Window>
    );
  };

  // ---------------------------------------------------------------------------
  // Layout
  // ---------------------------------------------------------------------------

  if (sandbox) {
    return renderSandbox();
  }

  let layoutClass = 'cc-wide';
  let content: ReactNode;
  if (tab === 'fate') {
    layoutClass = 'cc-fate';
    content = renderFate();
  } else if (tab === 'body') {
    layoutClass = 'cc-fate';
    content = renderMirror();
  } else if (tab === 'loadout') {
    layoutClass = 'cc-loadout';
    content = <LoadoutPanel />;
  } else if (tab === 'info') {
    content = renderInfo();
  } else if (tab === 'gameplay') {
    content = renderGameplay();
  } else if (tab === 'intimacy') {
    content = renderIntimacy();
  } else {
    content = renderSettings();
  }
  const showRail = tab === 'fate' || tab === 'body';

  const scaledStyle: CSSProperties | undefined =
    menuScale === 1
      ? undefined
      : {
          transform: `scale(${menuScale})`,
          transformOrigin: 'top left',
          width: `${100 / menuScale}%`,
          height: `${100 / menuScale}%`,
        };

  return (
    <Window
      title={L.windowTitle}
      width={isFullscreen ? 7680 : 1360}
      height={isFullscreen ? 4320 : 800}
      theme="vanderlin"
    >
      <Window.Content fitted>
        <div style={{ height: '100%', ...scaledStyle }}>
          <div className={`cc ${layoutClass}`}>
            <div className="cc-area-top">{renderTopBar()}</div>
            {showRail ? (
              <div className="cc-area-rail">{renderRail()}</div>
            ) : null}
            <div className="cc-area-content">
              <Frame style={{ height: '100%' }}>
                {content}
                {picker && tab === 'body' ? renderStylePicker() : null}
                {renderModal()}
              </Frame>
            </div>
            <div className="cc-area-doll">
              {renderDoll()}
              {renderGallery()}
            </div>
            {tab === 'loadout' ? null : (
              <div className="cc-area-card">{renderCard()}</div>
            )}
            <div className="cc-area-nav">{renderNav()}</div>
            <div className="cc-area-done">{renderDone()}</div>
            <TipLayer pinHint={L.pinHint} />
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};

export default CharacterCreator;
