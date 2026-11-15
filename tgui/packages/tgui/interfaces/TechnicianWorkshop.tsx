import { useEffect, useState } from 'react';
import { useBackend, useLocalState } from '../backend';
import { DmIcon } from 'tgui-core/components';
import type { BooleanLike } from 'tgui-core/react';
import { Window } from '../layouts';

type WorkshopResource = {
  id: string;
  name: string;
  amount: number;
  icon: string;
  icon_state: string;
  can_withdraw: BooleanLike;
};

type RecipeRequirement = {
  id: string;
  name: string;
  required: number;
  available: number;
  missing: number;
  icon: string;
  icon_state: string;
};

type WorkshopRecipe = {
  ref: string;
  name: string;
  category: string;
  desc: string;
  output_name: string;
  output_icon: string;
  output_state: string;
  output_amount: number;
  requirements: RecipeRequirement[];
  service_fee: number;
  craft_time: number;
  resources_sufficient: BooleanLike;
  can_craft: BooleanLike;
};

type StagedItem = {
  name: string;
  desc?: string;
  icon: string;
  icon_state: string;
  type?: string;
};

type WorkshopUpgradeRecipe = {
  ref: string;
  name: string;
  category: string;
  desc: string;
  output_name: string;
  output_icon: string;
  output_state: string;
  item_requirements: RecipeRequirement[];
  resource_requirements: RecipeRequirement[];
  items_sufficient: BooleanLike;
  resources_sufficient: BooleanLike;
  service_fee: number;
  craft_time: number;
  can_upgrade: BooleanLike;
};

type TechnicianFixingData = {
  show_tab: BooleanLike;
  eligible: BooleanLike;
  supported: BooleanLike;
  repair_method: string;
  material_name: string;
  integrity_percent: number;
  missing_percent: number;
  service_fee: number;
  resource_requirements: RecipeRequirement[];
  item_requirements?: RecipeRequirement[];
  resources_sufficient: BooleanLike;
  items_sufficient: BooleanLike;
  has_damage: BooleanLike;
  can_fix: BooleanLike;
  fix_reason?: string;
};

type TechnicianSmeltData = {
  supported: BooleanLike;
  reason?: string;
  result_type?: string;
  output_name?: string;
  output_icon?: string;
  output_state?: string;
  service_fee?: number;
  work_time?: number;
  can_smelt?: BooleanLike;
};

type TechnicianEquipmentSlot = {
  id: string;
  name: string;
  installed: BooleanLike;
  item_name: string;
  tier: number;
  icon: string;
  icon_state: string;
  enabled: BooleanLike;
};

type TechnicianServiceStatus = {
  id: string;
  name: string;
  enabled: BooleanLike;
  available: BooleanLike;
  required: string[];
  missing: string[];
};

type TechnicianWorkshopData = {
  mode: 'craft' | 'upgrade' | 'smelt' | 'busy';
  access_denied?: BooleanLike;
  budget: number;
  mammon_icon: string;
  mammon_icon_state: string;
  can_withdraw_mammons: BooleanLike;
  is_crafting: BooleanLike;
  active_recipe_name: string;
  active_recipe_ref: string;
  active_operation_kind: string;
  craft_time_remaining: number;
  craft_total_time: number;
  craft_time_snapshot: number;
  technician_icon: string;
  technician_state: string;
  target_item?: StagedItem | null;
  staged_item_count: number;
  surface_items: StagedItem[];
  resources: WorkshopResource[];
  station_equipment: TechnicianEquipmentSlot[];
  station_services: TechnicianServiceStatus[];
  categories: string[];
  recipes: WorkshopRecipe[];
  upgrade_categories: string[];
  upgrade_recipes: WorkshopUpgradeRecipe[];
  fixing?: TechnicianFixingData | null;
  smelting?: TechnicianSmeltData | null;
  admin?: AdminWorkshopData;
};

type AdminRecipeData = {
  ref: string;
  name: string;
  category: string;
  desc: string;
  output_item_type: string;
  output_name: string;
  output_desc: string;
  output_icon: string;
  output_state: string;
  output_amount: number;
  resource_costs_text: string;
  service_fee: number;
  craft_time: number;
  required_service: string;
  enabled: BooleanLike;
  custom: BooleanLike;
  force: number;
  throwforce: number;
  weight_class: number;
  max_integrity: number;
  slowdown: number;
  armor_penetration: number;
};

type AdminToggleEntry = {
  id: string;
  name: string;
  enabled: BooleanLike;
  available?: BooleanLike;
  missing?: string[];
};

type AdminPresetEntry = { name: string };

type AdminWorkshopData = {
  can_edit: BooleanLike;
  recipes?: AdminRecipeData[];
  services?: AdminToggleEntry[];
  equipment_slots?: AdminToggleEntry[];
  fee_scopes?: AdminToggleEntry[];
  technician_icon?: string;
  presets?: AdminPresetEntry[];
  profile_name?: string;
};

type AdminRecipeForm = {
  ref: string;
  name: string;
  category: string;
  desc: string;
  output_item_type: string;
  output_name: string;
  output_desc: string;
  output_state: string;
  output_amount: string;
  resource_costs_text: string;
  service_fee: string;
  craft_time: string;
  required_service: string;
  force: string;
  throwforce: string;
  weight_class: string;
  max_integrity: string;
  slowdown: string;
  armor_penetration: string;
  custom: boolean;
  enabled: boolean;
};

type AdminRecipeTextField = Exclude<keyof AdminRecipeForm, 'custom' | 'enabled'>;

const formatTime = (seconds: number) => {
  const safeSeconds = Math.max(0, Math.floor(seconds));
  const minutes = Math.floor(safeSeconds / 60);
  const remainingSeconds = safeSeconds % 60;
  return `${minutes}:${remainingSeconds.toString().padStart(2, '0')}`;
};

const Sprite = (props: { icon?: string; iconState?: string; size?: number }) => {
  const { icon, iconState, size = 18 } = props;
  if (!icon) {
    return <span className="TechnicianWorkshop__sprite is-empty" aria-hidden="true" />;
  }
  return (
    <span
      className="TechnicianWorkshop__sprite"
      style={{ width: size, height: size }}
      aria-hidden="true">
      <DmIcon
        icon={icon}
        icon_state={iconState ?? ''}
        height={`${size}px`}
        width={`${size}px`}
      />
    </span>
  );
};

const ResourceHeader = (props: {
  resources: WorkshopResource[];
  budget: number;
  mammonIcon: string;
  mammonIconState: string;
  canWithdrawMammons: boolean;
  onWithdrawResource: (resourceId: string) => void;
  onWithdrawMammons: () => void;
}) => {
  const {
    resources,
    budget,
    mammonIcon,
    mammonIconState,
    canWithdrawMammons,
    onWithdrawResource,
    onWithdrawMammons,
  } = props;

  return (
    <div className="TechnicianWorkshop__resource-header">
      <div className="TechnicianWorkshop__resource-heading">Deposited resources</div>
      <div className="TechnicianWorkshop__resource-values">
        {resources.map((resource) => (
          <button
            type="button"
            className="TechnicianWorkshop__resource-value"
            key={resource.id}
            disabled={!resource.can_withdraw || resource.amount <= 0}
            title={`Withdraw all ${resource.amount} ${resource.name} onto the workbench`}
            onClick={() => onWithdrawResource(resource.id)}>
            <Sprite icon={resource.icon} iconState={resource.icon_state} size={20} />
            <span className="TechnicianWorkshop__resource-copy">
              <span className="TechnicianWorkshop__resource-name">{resource.name}:</span>
              <b>{resource.amount}</b>
            </span>
          </button>
        ))}
        <button
          type="button"
          className="TechnicianWorkshop__resource-value TechnicianWorkshop__resource-money"
          disabled={!canWithdrawMammons || budget <= 0}
          title={`Withdraw all ${budget} amnas as coin change`}
          onClick={onWithdrawMammons}>
          <Sprite icon={mammonIcon} iconState={mammonIconState} size={20} />
          <span className="TechnicianWorkshop__resource-copy">
            <span className="TechnicianWorkshop__resource-name">Amnas depot:</span>
            <b>{budget} a</b>
          </span>
        </button>
      </div>
      <div className="TechnicianWorkshop__deposit-hint">
        Insert resources or coins to deposit them. Place ores on the workbench and smelt them for a fee. Click stocked resources or the amnas depot to withdraw the full balance.
      </div>
    </div>
  );
};

const EquipmentStrip = (props: {
  equipment: TechnicianEquipmentSlot[];
  services: TechnicianServiceStatus[];
}) => {
  const { equipment, services } = props;
  return (
    <div className="TechnicianWorkshop__equipment-strip">
      <div className="TechnicianWorkshop__equipment-slots">
        {equipment.map((slot) => (
          <div
            key={slot.id}
            className={`TechnicianWorkshop__equipment-slot ${slot.installed ? 'is-installed' : 'is-empty'} ${!slot.enabled ? 'is-disabled' : ''}`}
            title={`${slot.name}: ${slot.installed ? `${slot.item_name} (tier ${slot.tier})` : 'Not installed'}${!slot.enabled ? ' · Disabled by station profile' : ''}`}>
            {slot.installed ? <Sprite icon={slot.icon} iconState={slot.icon_state} size={18} /> : <span className="TechnicianWorkshop__equipment-placeholder">—</span>}
            <span>{slot.name}</span>
            {slot.installed && <b>T{slot.tier}</b>}
          </div>
        ))}
      </div>
      <div className="TechnicianWorkshop__service-statuses">
        {services.map((service) => (
          <span
            key={service.id}
            className={`TechnicianWorkshop__service-status ${service.available ? 'is-available' : service.enabled ? 'is-locked' : 'is-disabled'}`}
            title={service.available ? `${service.name} available` : service.enabled ? `${service.name} requires: ${(service.missing || []).join(', ') || 'additional equipment'}` : `${service.name} disabled by station profile`}>
            {service.available ? '●' : '○'} {service.name}
          </span>
        ))}
      </div>
    </div>
  );
};

const RecipeEntry = (props: {
  recipe: WorkshopRecipe;
  selected: boolean;
  onSelect: () => void;
}) => {
  const { recipe, selected, onSelect } = props;
  const affordable = !!recipe.can_craft;
  const missingResources = !recipe.resources_sufficient;
  return (
    <button
      type="button"
      className={`TechnicianWorkshop__recipe-entry ${selected ? 'is-selected' : ''}`}
      onClick={onSelect}>
      <Sprite icon={recipe.output_icon} iconState={recipe.output_state} size={22} />
      <span className="TechnicianWorkshop__recipe-entry-name">{recipe.name}</span>
      <span className={`TechnicianWorkshop__recipe-status ${missingResources ? 'is-missing' : affordable ? 'is-ready' : ''}`}>
        {missingResources ? 'Missing materials' : affordable ? 'Available' : 'Unavailable'}
      </span>
    </button>
  );
};

const UpgradeEntry = (props: {
  recipe: WorkshopUpgradeRecipe;
  selected: boolean;
  onSelect: () => void;
}) => {
  const { recipe, selected, onSelect } = props;
  const missing = !recipe.items_sufficient || !recipe.resources_sufficient;
  return (
    <button
      type="button"
      className={`TechnicianWorkshop__recipe-entry ${selected ? 'is-selected' : ''}`}
      onClick={onSelect}>
      <Sprite icon={recipe.output_icon} iconState={recipe.output_state} size={22} />
      <span className="TechnicianWorkshop__recipe-entry-name">{recipe.name}</span>
      <span className={`TechnicianWorkshop__recipe-status ${missing ? 'is-missing' : recipe.can_upgrade ? 'is-ready' : ''}`}>
        {missing ? 'Missing inputs' : recipe.can_upgrade ? 'Available' : 'Unavailable'}
      </span>
    </button>
  );
};

const RequirementRows = (props: { requirements: RecipeRequirement[]; emptyText?: string }) => {
  const { requirements, emptyText = 'No requirements.' } = props;
  if (!requirements?.length) {
    return <div className="TechnicianWorkshop__empty-cost">{emptyText}</div>;
  }
  return (
    <div className="TechnicianWorkshop__requirements">
      {requirements.map((requirement) => {
        const missing = requirement.missing > 0;
        return (
          <div
            className={`TechnicianWorkshop__requirement ${missing ? 'is-missing' : ''}`}
            key={requirement.id}>
            <Sprite icon={requirement.icon} iconState={requirement.icon_state} size={22} />
            <span className="TechnicianWorkshop__requirement-name">{requirement.name}</span>
            <b>{requirement.available} / {requirement.required}</b>
            {missing && <span className="TechnicianWorkshop__missing-count">-{requirement.missing}</span>}
          </div>
        );
      })}
    </div>
  );
};

const TechnicianPortrait = (props: {
  icon: string;
  state: string;
  busy: boolean;
  remaining: number;
  total: number;
  activeName?: string;
  snapshot: number;
}) => {
  const { icon, state, busy, remaining, total, activeName, snapshot } = props;
  const [snapshotReceivedAt, setSnapshotReceivedAt] = useState(() => Date.now());
  const [clientNow, setClientNow] = useState(() => Date.now());

  useEffect(() => {
    const receivedAt = Date.now();
    setSnapshotReceivedAt(receivedAt);
    setClientNow(receivedAt);
  }, [busy, remaining, snapshot]);

  useEffect(() => {
    if (!busy) {
      return;
    }
    const interval = window.setInterval(() => setClientNow(Date.now()), 1000);
    return () => window.clearInterval(interval);
  }, [busy, remaining, snapshot]);

  const elapsedSeconds = Math.floor(Math.max(0, clientNow - snapshotReceivedAt) / 1000);
  const currentRemaining = Math.max(0, remaining - elapsedSeconds);
  const progress = busy ? Math.min(1, Math.max(0, 1 - currentRemaining / Math.max(1, total))) : 0;
  return (
    <div className={`TechnicianWorkshop__technician ${busy ? 'is-busy' : 'is-idle'}`}>
      <div className="TechnicianWorkshop__time-label">
        {busy ? 'Time remaining' : 'Technician'}
        <b>{busy ? formatTime(currentRemaining) : 'Ready'}</b>
      </div>
      <div className="TechnicianWorkshop__portrait-stage">
        <div className="TechnicianWorkshop__portrait-sprite">
          <Sprite icon={icon} iconState={state} size={80} />
        </div>
        {busy && <div className="TechnicianWorkshop__busy-label">Working on {activeName || 'an order'}</div>}
      </div>
      {busy && (
        <div className="TechnicianWorkshop__progress-track">
          <div className="TechnicianWorkshop__progress-fill" style={{ width: `${progress * 100}%` }} />
        </div>
      )}
    </div>
  );
};

const emptyAdminRecipeForm = (): AdminRecipeForm => ({
  ref: '',
  name: 'New workshop recipe',
  category: 'Miscellaneous',
  desc: '',
  output_item_type: '',
  output_name: '',
  output_desc: '',
  output_state: '',
  output_amount: '1',
  resource_costs_text: '',
  service_fee: '0',
  craft_time: '30',
  required_service: 'crafting',
  force: '',
  throwforce: '',
  weight_class: '',
  max_integrity: '',
  slowdown: '',
  armor_penetration: '',
  custom: true,
  enabled: true,
});

const recipeToForm = (recipe: AdminRecipeData): AdminRecipeForm => ({
  ref: recipe.ref,
  name: recipe.name || '',
  category: recipe.category || 'Miscellaneous',
  desc: recipe.desc || '',
  output_item_type: recipe.output_item_type || '',
  output_name: recipe.output_name || '',
  output_desc: recipe.output_desc || '',
  output_state: recipe.output_state || '',
  output_amount: String(recipe.output_amount ?? 1),
  resource_costs_text: recipe.resource_costs_text || '',
  service_fee: String(recipe.service_fee ?? 0),
  craft_time: String(recipe.craft_time ?? 30),
  required_service: recipe.required_service || 'crafting',
  force: recipe.force === undefined ? '' : String(recipe.force),
  throwforce: recipe.throwforce === undefined ? '' : String(recipe.throwforce),
  weight_class: recipe.weight_class === undefined ? '' : String(recipe.weight_class),
  max_integrity: recipe.max_integrity === undefined ? '' : String(recipe.max_integrity),
  slowdown: recipe.slowdown === undefined ? '' : String(recipe.slowdown),
  armor_penetration: recipe.armor_penetration === undefined ? '' : String(recipe.armor_penetration),
  custom: !!recipe.custom,
  enabled: !!recipe.enabled,
});

const AdminWorkshopPanel = (props: {
  admin: AdminWorkshopData;
  act: (action: string, params?: any) => void;
  onClose: () => void;
}) => {
  const { admin, act, onClose } = props;
  const [tab, setTab] = useState<'recipes' | 'services' | 'technician' | 'presets' | 'custom'>('recipes');
  const recipes = admin.recipes || [];
  const [selectedRef, setSelectedRef] = useState(recipes[0]?.ref || '');
  const selectedRecipe = recipes.find((recipe) => recipe.ref === selectedRef);
  const [recipeDraft, setRecipeDraft] = useState<AdminRecipeForm>(
    selectedRecipe ? recipeToForm(selectedRecipe) : emptyAdminRecipeForm(),
  );
  const [customDraft, setCustomDraft] = useState<AdminRecipeForm>(emptyAdminRecipeForm());
  const [portraitPath, setPortraitPath] = useState(admin.technician_icon || '');
  const [presetName, setPresetName] = useState('');
  const [confirmDeleteRecipeRef, setConfirmDeleteRecipeRef] = useState('');
  const [pendingPresetAction, setPendingPresetAction] = useState<{ name: string; action: 'load' | 'delete' } | null>(null);

  useEffect(() => {
    if (selectedRecipe) {
      setRecipeDraft(recipeToForm(selectedRecipe));
    } else if (recipes.length) {
      setSelectedRef(recipes[0].ref);
    }
  }, [selectedRecipe]);

  useEffect(() => setPortraitPath(admin.technician_icon || ''), [admin.technician_icon]);

  const updateRecipe = (field: AdminRecipeTextField, value: string) => {
    setRecipeDraft((current) => ({ ...current, [field]: value }));
  };
  const updateCustom = (field: AdminRecipeTextField, value: string) => {
    setCustomDraft((current) => ({ ...current, [field]: value }));
  };
  const toBackendParams = (draft: AdminRecipeForm) => ({
    name: draft.name,
    category: draft.category,
    desc: draft.desc,
    output_item_type: draft.output_item_type,
    output_name: draft.output_name,
    output_desc: draft.output_desc,
    output_state: draft.output_state,
    output_amount: draft.output_amount,
    resource_costs_text: draft.resource_costs_text,
    service_fee: draft.service_fee,
    craft_time: draft.craft_time,
    required_service: draft.required_service,
    force: draft.force,
    throwforce: draft.throwforce,
    weight_class: draft.weight_class,
    max_integrity: draft.max_integrity,
    slowdown: draft.slowdown,
    armor_penetration: draft.armor_penetration,
  });

  const field = (label: string, key: AdminRecipeTextField, draft: AdminRecipeForm, update: (key: AdminRecipeTextField, value: string) => void, multiline = false) => (
    <label className={`TechnicianWorkshop__admin-field ${multiline ? 'is-wide' : ''}`} key={key}>
      <span>{label}</span>
      {multiline ? (
        <textarea value={String(draft[key] ?? '')} rows={3} onChange={(event) => update(key, event.target.value)} />
      ) : (
        <input value={String(draft[key] ?? '')} onChange={(event) => update(key, event.target.value)} />
      )}
    </label>
  );

  const recipeEditor = (draft: AdminRecipeForm, update: (key: AdminRecipeTextField, value: string) => void, isCustom: boolean) => (
    <div className="TechnicianWorkshop__admin-editor-scroll">
      <div className="TechnicianWorkshop__admin-fields">
        {field('Recipe name', 'name', draft, update)}
        {field('Category', 'category', draft, update)}
        {field('Description', 'desc', draft, update, true)}
        {field('Output item type path', 'output_item_type', draft, update)}
        {field('Output item name', 'output_name', draft, update)}
        {field('Output description', 'output_desc', draft, update, true)}
        {field('Output icon state', 'output_state', draft, update)}
        {field('Resource costs (id=amount)', 'resource_costs_text', draft, update)}
        {field('Output quantity (1–20)', 'output_amount', draft, update)}
        {field('Service fee (amnas)', 'service_fee', draft, update)}
        {field('Craft time (seconds)', 'craft_time', draft, update)}
        <label className="TechnicianWorkshop__admin-field">
          <span>Required service</span>
          <select value={draft.required_service} onChange={(event) => update('required_service', event.target.value)}>
            <option value="crafting">General crafting</option>
            <option value="metalworking">Metalworking</option>
            <option value="smelting">Smelting</option>
            <option value="sewing">Sewing</option>
          </select>
        </label>
      </div>
      <div className="TechnicianWorkshop__admin-section-title">Output item properties</div>
      <div className="TechnicianWorkshop__admin-fields">
        {field('Force', 'force', draft, update)}
        {field('Throw force', 'throwforce', draft, update)}
        {field('Weight class (1–6)', 'weight_class', draft, update)}
        {field('Maximum integrity', 'max_integrity', draft, update)}
        {field('Movement slowdown', 'slowdown', draft, update)}
        {field('Armor penetration', 'armor_penetration', draft, update)}
      </div>
      <div className="TechnicianWorkshop__admin-help">
        Item type paths must reference an existing, concrete /obj/item subtype. Empty property fields preserve the item's type defaults. Properties are clamped and maximum integrity is only applied to items that use integrity.
      </div>
      <div className="TechnicianWorkshop__admin-actions">
        {isCustom ? (
          <button type="button" className="is-primary" onClick={() => act('admin_add_custom_recipe', toBackendParams(draft))}>Add custom recipe</button>
        ) : (
          <>
            <button type="button" className="is-primary" onClick={() => act('admin_save_recipe', { recipe: draft.ref, ...toBackendParams(draft) })}>Save recipe</button>
            <button type="button" onClick={() => act('admin_toggle_recipe', { recipe: draft.ref })}>{draft.enabled ? 'Disable recipe' : 'Enable recipe'}</button>
            {draft.custom && (confirmDeleteRecipeRef === draft.ref ? (
              <>
                <span className="TechnicianWorkshop__admin-confirm-copy">Delete this custom recipe?</span>
                <button type="button" className="is-danger" onClick={() => { act('admin_delete_custom_recipe', { recipe: draft.ref }); setConfirmDeleteRecipeRef(''); }}>Confirm delete</button>
                <button type="button" onClick={() => setConfirmDeleteRecipeRef('')}>Cancel</button>
              </>
            ) : (
              <button type="button" className="is-danger" onClick={() => setConfirmDeleteRecipeRef(draft.ref)}>Delete custom recipe</button>
            ))}
          </>
        )}
      </div>
    </div>
  );

  return (
    <div className="TechnicianWorkshop__admin-panel">
      <div className="TechnicianWorkshop__admin-header">
        <div>
          <b>Workshop administration</b>
          <small>{admin.profile_name || 'Station profile'} · changes apply to this workstation instance</small>
        </div>
        <button type="button" onClick={onClose}>Return to workshop</button>
      </div>
      <div className="TechnicianWorkshop__admin-tabs">
        <button type="button" className={tab === 'recipes' ? 'is-active' : ''} onClick={() => setTab('recipes')}>Recipes</button>
        <button type="button" className={tab === 'custom' ? 'is-active' : ''} onClick={() => setTab('custom')}>Custom item</button>
        <button type="button" className={tab === 'services' ? 'is-active' : ''} onClick={() => setTab('services')}>Services & fees</button>
        <button type="button" className={tab === 'technician' ? 'is-active' : ''} onClick={() => setTab('technician')}>Technician icon</button>
        <button type="button" className={tab === 'presets' ? 'is-active' : ''} onClick={() => setTab('presets')}>Presets</button>
      </div>

      {tab === 'recipes' && (
        <div className="TechnicianWorkshop__admin-workspace">
          <div className="TechnicianWorkshop__admin-recipe-list">
            <div className="TechnicianWorkshop__admin-section-title">Registered recipes ({recipes.length})</div>
            {recipes.map((recipe) => (
              <button key={recipe.ref} type="button" className={selectedRef === recipe.ref ? 'is-selected' : ''} onClick={() => setSelectedRef(recipe.ref)}>
                <span>{recipe.name}</span>
                <small>{recipe.custom ? 'Custom' : recipe.category}{!recipe.enabled ? ' · Disabled' : ''}</small>
              </button>
            ))}
            {!recipes.length && <div className="TechnicianWorkshop__admin-help">No recipe definitions found.</div>}
          </div>
          <div className="TechnicianWorkshop__admin-editor">
            {selectedRecipe ? recipeEditor(recipeDraft, updateRecipe, false) : <div className="TechnicianWorkshop__admin-help">Select a recipe to edit.</div>}
          </div>
        </div>
      )}

      {tab === 'custom' && (
        <div className="TechnicianWorkshop__admin-single">
          <div className="TechnicianWorkshop__admin-help">
            This creates a station-local recipe for an existing item type. It does not define a new DM type; output name, description, icon state, and supported item variables are applied to each produced instance.
          </div>
          {recipeEditor(customDraft, updateCustom, true)}
        </div>
      )}

      {tab === 'services' && (
        <div className="TechnicianWorkshop__admin-service-grid">
          <section>
            <div className="TechnicianWorkshop__admin-section-title">Service availability</div>
            {(admin.services || []).map((service) => (
              <button type="button" className="TechnicianWorkshop__admin-toggle" key={service.id} onClick={() => act('admin_toggle_service', { service: service.id })}>
                <span><b>{service.name}</b><small>{service.missing?.length ? `Missing: ${service.missing.join(', ')}` : service.available ? 'Equipment gate satisfied' : 'Currently unavailable'}</small></span>
                <strong className={service.enabled ? 'is-enabled' : 'is-disabled'}>{service.enabled ? 'Enabled' : 'Disabled'}</strong>
              </button>
            ))}
            <div className="TechnicianWorkshop__admin-section-title">Equipment slots</div>
            {(admin.equipment_slots || []).map((slot) => (
              <button type="button" className="TechnicianWorkshop__admin-toggle" key={slot.id} onClick={() => act('admin_toggle_equipment_slot', { slot: slot.id })}>
                <span><b>{slot.name}</b><small>Controls whether this slot can provide its service effects</small></span>
                <strong className={slot.enabled ? 'is-enabled' : 'is-disabled'}>{slot.enabled ? 'Enabled' : 'Disabled'}</strong>
              </button>
            ))}
          </section>
          <section>
            <div className="TechnicianWorkshop__admin-section-title">Service fee switches</div>
            {(admin.fee_scopes || []).map((scope) => (
              <button type="button" className="TechnicianWorkshop__admin-toggle" key={scope.id} onClick={() => act('admin_toggle_fee_scope', { scope: scope.id })}>
                <span><b>{scope.name}</b><small>{scope.id === 'all' ? 'Master switch for every service fee' : 'Only affects the selected service scope'}</small></span>
                <strong className={scope.enabled ? 'is-enabled' : 'is-disabled'}>{scope.enabled ? 'Fee on' : 'Free'}</strong>
              </button>
            ))}
          </section>
        </div>
      )}

      {tab === 'technician' && (
        <div className="TechnicianWorkshop__admin-single">
          <div className="TechnicianWorkshop__admin-section-title">Technician DMI path</div>
          <div className="TechnicianWorkshop__admin-icon-controls">
            <input value={portraitPath} placeholder="modular_rmh/icons/machines/technician.dmi" onChange={(event) => setPortraitPath(event.target.value)} />
            <button type="button" className="is-primary" onClick={() => act('admin_set_technician_icon', { icon_path: portraitPath })}>Apply icon</button>
          </div>
          <div className="TechnicianWorkshop__admin-help">The DMI must exist in the project resources and contain these states. The archive supplied for this patch does not contain a technician portrait DMI, so add your art file before expecting the preview to render.</div>
          <div className="TechnicianWorkshop__admin-portrait-grid">
            {(['idle', 'crafting', 'upgrading', 'fixing', 'smelting'] as const).map((state) => (
              <div key={state}>
                <Sprite icon={portraitPath} iconState={state} size={64} />
                <b>{state}</b>
              </div>
            ))}
          </div>
        </div>
      )}

      {tab === 'presets' && (
        <div className="TechnicianWorkshop__admin-single">
          <div className="TechnicianWorkshop__admin-help">
            Presets persist to data/technician_workshop_presets.json and can be loaded into any workstation. Loading replaces its service gates, fee switches, recipe overrides, custom recipes, fee modifiers, and portrait path. It does not replace physical stock or installed tools.
          </div>
          <div className="TechnicianWorkshop__admin-icon-controls">
            <input value={presetName} placeholder="Preset name" maxLength={48} onChange={(event) => setPresetName(event.target.value)} />
            <button type="button" className="is-primary" disabled={!presetName.trim()} onClick={() => act('admin_save_preset', { name: presetName.trim() })}>Save current setup</button>
          </div>
          <div className="TechnicianWorkshop__admin-preset-list">
            {(admin.presets || []).map((preset) => (
              <div key={preset.name}>
                <b>{preset.name}</b>
                <span>
                  {pendingPresetAction?.name === preset.name ? (
                    <>
                      <button
                        type="button"
                        className={pendingPresetAction.action === 'delete' ? 'is-danger' : 'is-primary'}
                        onClick={() => {
                          act(pendingPresetAction.action === 'delete' ? 'admin_delete_preset' : 'admin_load_preset', { name: preset.name });
                          setPendingPresetAction(null);
                        }}>
                        Confirm {pendingPresetAction.action}
                      </button>
                      <button type="button" onClick={() => setPendingPresetAction(null)}>Cancel</button>
                    </>
                  ) : (
                    <>
                      <button type="button" onClick={() => setPendingPresetAction({ name: preset.name, action: 'load' })}>Load</button>
                      <button type="button" className="is-danger" onClick={() => setPendingPresetAction({ name: preset.name, action: 'delete' })}>Delete</button>
                    </>
                  )}
                </span>
              </div>
            ))}
            {!(admin.presets || []).length && <div className="TechnicianWorkshop__admin-help">No saved presets.</div>}
          </div>
        </div>
      )}
    </div>
  );
};

export const TechnicianWorkshop = () => {
  const { act, data } = useBackend<TechnicianWorkshopData>();
  const categories = data.categories || [];
  const recipes = data.recipes || [];
  const upgradeCategories = data.upgrade_categories || [];
  const upgradeRecipes = data.upgrade_recipes || [];
  const fixing = data.fixing || undefined;
  const smelting = data.smelting || undefined;
  const busy = !!data.is_crafting;
  const smeltMode = !busy && data.mode === 'smelt';
  const targetMode = !busy && data.mode === 'upgrade';
  const showUpgradeTab = targetMode && upgradeRecipes.length > 0;
  const showFixTab = targetMode && !!fixing?.show_tab;

  const [storedCategory, setStoredCategory] = useLocalState<string>(
    'technician-workshop-category', categories[0] || '',
  );
  const [selectedRecipeRef, setSelectedRecipeRef] = useLocalState<string>(
    'technician-workshop-recipe', '',
  );
  const [storedUpgradeCategory, setStoredUpgradeCategory] = useLocalState<string>(
    'technician-workshop-upgrade-category', upgradeCategories[0] || '',
  );
  const [selectedUpgradeRef, setSelectedUpgradeRef] = useLocalState<string>(
    'technician-workshop-upgrade-recipe', '',
  );
  const [storedServiceTab, setStoredServiceTab] = useLocalState<string>(
    'technician-workshop-service-tab', 'upgrades',
  );
  const [adminOpen, setAdminOpen] = useState(false);

  const activeCategory = categories.includes(storedCategory) ? storedCategory : categories[0] || '';
  const visibleRecipes = recipes.filter((recipe) => recipe.category === activeCategory);
  const activeRecipe = busy && data.active_operation_kind === 'craft'
    ? recipes.find((recipe) => recipe.ref === data.active_recipe_ref)
    : undefined;
  const selectedRecipe = activeRecipe
    || visibleRecipes.find((recipe) => recipe.ref === selectedRecipeRef)
    || visibleRecipes[0];

  const activeUpgradeCategory = upgradeCategories.includes(storedUpgradeCategory)
    ? storedUpgradeCategory
    : upgradeCategories[0] || '';
  const visibleUpgradeRecipes = upgradeRecipes.filter((recipe) => recipe.category === activeUpgradeCategory);
  const selectedUpgrade = visibleUpgradeRecipes.find((recipe) => recipe.ref === selectedUpgradeRef)
    || visibleUpgradeRecipes[0];

  const serviceTab = storedServiceTab === 'fix' && showFixTab
    ? 'fix'
    : storedServiceTab === 'upgrades' && showUpgradeTab
      ? 'upgrades'
      : showUpgradeTab
        ? 'upgrades'
        : showFixTab
          ? 'fix'
          : 'none';

  const remaining = Math.max(0, data.craft_time_remaining || 0);
  const total = Math.max(1, data.craft_total_time || 1);
  const enoughCraftMaterials = !!selectedRecipe?.resources_sufficient;
  const enoughCraftMoney = !!selectedRecipe && data.budget >= selectedRecipe.service_fee;
  const canCraft = !!selectedRecipe && !!selectedRecipe.can_craft && !busy;
  const enoughUpgradeInputs = !!selectedUpgrade
    && !!selectedUpgrade.items_sufficient
    && !!selectedUpgrade.resources_sufficient;
  const enoughUpgradeMoney = !!selectedUpgrade && data.budget >= selectedUpgrade.service_fee;
  const canUpgrade = !!selectedUpgrade && !!selectedUpgrade.can_upgrade && !busy;
  const enoughFixMoney = !!fixing && data.budget >= fixing.service_fee;
  const canFix = !!fixing?.can_fix && !busy;
  const canSmelt = !!smelting?.can_smelt && !busy;

  if (data.access_denied) {
    return (
      <Window width={900} height={650}>
        <Window.Content>
          <div className="TechnicianWorkshop__access-denied">
            <b>Restricted workstation</b>
            <span>This workshop is reserved for members of its configured faction.</span>
          </div>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window width={900} height={650}>
      <Window.Content scrollable={false}>
        <div className="TechnicianWorkshop">
          <ResourceHeader
            resources={data.resources || []}
            budget={data.budget || 0}
            mammonIcon={data.mammon_icon}
            mammonIconState={data.mammon_icon_state}
            canWithdrawMammons={!!data.can_withdraw_mammons}
            onWithdrawResource={(resourceId) => act('withdraw_resource', { resource_id: resourceId })}
            onWithdrawMammons={() => act('withdraw_mammons')}
          />

          <EquipmentStrip
            equipment={data.station_equipment || []}
            services={data.station_services || []}
          />

          {data.admin?.can_edit && !adminOpen && (
            <div className="TechnicianWorkshop__admin-bar">
              <span>Administrator controls are available for this station.</span>
              <button type="button" onClick={() => setAdminOpen(true)}>Configure station</button>
            </div>
          )}

          {adminOpen && data.admin?.can_edit ? (
            <AdminWorkshopPanel admin={data.admin} act={act} onClose={() => setAdminOpen(false)} />
          ) : (
            <>
          {busy ? (
            <div className="TechnicianWorkshop__main">
              <section className="TechnicianWorkshop__recipe-pane">
                <div className="TechnicianWorkshop__pane-heading">
                  Current operation
                  <span>{data.active_operation_kind === 'upgrade' ? 'Upgrade' : data.active_operation_kind === 'fix' ? 'Fixing' : data.active_operation_kind === 'smelt' ? 'Smelting' : 'Crafting'}</span>
                </div>
                <div className="TechnicianWorkshop__target-summary">
                  <Sprite icon={data.target_item?.icon} iconState={data.target_item?.icon_state} size={30} />
                  <div>
                    <b>{data.target_item?.name || data.active_recipe_name || 'Production order'}</b>
                    <small>{data.active_recipe_name || 'The technician is carrying out this operation.'}</small>
                  </div>
                </div>
                <div className="TechnicianWorkshop__surface-items">
                  {(data.surface_items || []).map((item, index) => (
                    <div className={`TechnicianWorkshop__surface-item ${index === 0 ? 'is-target' : ''}`} key={`${item.type || item.name}-${index}`}>
                      <Sprite icon={item.icon} iconState={item.icon_state} size={18} />
                      <span>{item.name}</span>
                      <small>{index === 0 ? 'Workpiece' : 'On table'}</small>
                    </div>
                  ))}
                </div>
                <div className="TechnicianWorkshop__operation-note">
                  {data.active_operation_kind === 'fix'
                    ? 'The registered item is being restored to full integrity.'
                    : data.active_operation_kind === 'smelt'
                      ? 'The ore is reserved while its configured ingot is being produced.'
                      : data.active_operation_kind === 'upgrade'
                        ? 'The target and required components are reserved for this upgrade.'
                        : 'The station has reserved the recipe inputs and is producing the selected item.'}
                </div>
              </section>

              <section className="TechnicianWorkshop__detail-pane">
                <TechnicianPortrait
                  icon={data.technician_icon}
                  state={data.technician_state}
                  busy
                  remaining={remaining}
                  total={total}
                  activeName={data.active_recipe_name}
                  snapshot={data.craft_time_snapshot || 0}
                />
                <div className="TechnicianWorkshop__selected-recipe">
                  <div className="TechnicianWorkshop__selected-title">{data.active_recipe_name || 'Work in progress'}</div>
                  <div className="TechnicianWorkshop__output-description">
                    {data.active_operation_kind === 'fix' ? 'Repairing equipment' : data.active_operation_kind === 'smelt' ? 'Smelting material' : data.active_operation_kind === 'upgrade' ? 'Applying an upgrade' : 'Producing an item'}
                  </div>
                </div>
                <div className="TechnicianWorkshop__cost-row">
                  <div className="TechnicianWorkshop__material-cost">
                    <div className="TechnicianWorkshop__cost-heading">Operation status</div>
                    <div className="TechnicianWorkshop__empty-cost">Inputs and fee reserved</div>
                    <div className="TechnicianWorkshop__empty-cost">The operation is independent of the initiating player.</div>
                  </div>
                  <div className="TechnicianWorkshop__fee-cost">
                    <div className="TechnicianWorkshop__cost-heading">Time remaining</div>
                    <div className="TechnicianWorkshop__fee-value">{formatTime(remaining)}</div>
                    <div className="TechnicianWorkshop__depot-value">of {formatTime(total)}</div>
                  </div>
                </div>
              </section>
            </div>
          ) : targetMode || smeltMode ? (
            <>
              <div className="TechnicianWorkshop__main">
                <section className="TechnicianWorkshop__recipe-pane">
                  <div className="TechnicianWorkshop__pane-heading">
                    {smeltMode ? 'Smelting workpiece' : serviceTab === 'fix' ? 'Fixing workpiece' : serviceTab === 'upgrades' ? 'Upgrade catalogue' : 'Registered workpiece'}
                    <span>{smeltMode ? '1 ore selected' : serviceTab === 'upgrades' ? `${visibleUpgradeRecipes.length} upgrades` : `${data.staged_item_count || 0} items on table`}</span>
                  </div>
                  <div className="TechnicianWorkshop__target-summary">
                    <Sprite icon={data.target_item?.icon} iconState={data.target_item?.icon_state} size={26} />
                    <div>
                      <b>{data.target_item?.name || 'Unregistered item'}</b>
                      <small>{smeltMode ? 'First ore placed is the smelting target.' : 'First item placed is the active workpiece.'}</small>
                    </div>
                  </div>
                  <div className="TechnicianWorkshop__surface-items">
                    {(data.surface_items || []).map((item, index) => (
                      <div className={`TechnicianWorkshop__surface-item ${index === 0 ? 'is-target' : ''}`} key={`${item.type || item.name}-${index}`}>
                        <Sprite icon={item.icon} iconState={item.icon_state} size={18} />
                        <span>{item.name}</span>
                        <small>{index === 0 ? 'Target' : 'On table'}</small>
                      </div>
                    ))}
                  </div>

                  {smeltMode ? (
                    <div className="TechnicianWorkshop__smelt-summary">
                      <b>{smelting?.supported ? `Smelt into ${smelting.output_name}` : 'Smelting unavailable'}</b>
                      <span>{smelting?.supported ? 'The technician will return the resulting ingot to the workbench.' : smelting?.reason || 'This ore cannot be smelted by the workstation.'}</span>
                    </div>
                  ) : serviceTab === 'upgrades' ? (
                    <>
                      {upgradeCategories.length > 1 && (
                        <div className="TechnicianWorkshop__upgrade-category-row">
                          {upgradeCategories.map((category) => (
                            <button
                              type="button"
                              key={category}
                              className={`TechnicianWorkshop__upgrade-category ${activeUpgradeCategory === category ? 'is-active' : ''}`}
                              onClick={() => {
                                setStoredUpgradeCategory(category);
                                setSelectedUpgradeRef('');
                              }}>
                              {category}
                            </button>
                          ))}
                        </div>
                      )}
                      <div className="TechnicianWorkshop__recipe-list">
                        {visibleUpgradeRecipes.length ? visibleUpgradeRecipes.map((recipe) => (
                          <UpgradeEntry
                            key={recipe.ref}
                            recipe={recipe}
                            selected={selectedUpgrade?.ref === recipe.ref}
                            onSelect={() => setSelectedUpgradeRef(recipe.ref)}
                          />
                        )) : (
                          <div className="TechnicianWorkshop__empty-list">No upgrades are registered for this item.</div>
                        )}
                      </div>
                    </>
                  ) : serviceTab === 'fix' ? (
                    <div className="TechnicianWorkshop__fix-summary">
                      <div className="TechnicianWorkshop__fix-summary-title">Automatic repair classification</div>
                      <b>{fixing?.repair_method || 'Unsupported repair method'}</b>
                      <div>Condition: {fixing ? `${fixing.integrity_percent}%` : '—'}</div>
                      <div>Missing integrity: {fixing ? `${fixing.missing_percent}%` : '—'}</div>
                      <small>Price is calculated from missing integrity and capped by the workstation's repair-fee limit.</small>
                    </div>
                  ) : (
                    <div className="TechnicianWorkshop__empty-list">No upgrades or supported fixing methods are available for this item.</div>
                  )}
                </section>

                <section className="TechnicianWorkshop__detail-pane">
                  <TechnicianPortrait
                    icon={data.technician_icon}
                    state={data.technician_state}
                    busy={false}
                    remaining={0}
                    total={1}
                    snapshot={data.craft_time_snapshot || 0}
                  />

                  {smeltMode ? (
                    <>
                      <div className="TechnicianWorkshop__selected-recipe">
                        <div className="TechnicianWorkshop__selected-title">Smelting result</div>
                        <div className="TechnicianWorkshop__output-row">
                          <Sprite icon={smelting?.output_icon} iconState={smelting?.output_state} size={40} />
                          <div className="TechnicianWorkshop__output-copy">
                            <div className="TechnicianWorkshop__output-name">{smelting?.output_name || 'Unknown ingot'}</div>
                            <div className="TechnicianWorkshop__output-description">
                              {smelting?.supported ? `The workstation produces a basic-quality ingot. Work time: ${Math.round((smelting.work_time || 0) / 10)} seconds.` : smelting?.reason || 'This ore cannot be processed.'}
                            </div>
                          </div>
                        </div>
                      </div>
                      <div className="TechnicianWorkshop__cost-row">
                        <div className="TechnicianWorkshop__material-cost">
                          <div className="TechnicianWorkshop__cost-heading">Input</div>
                          <div className="TechnicianWorkshop__empty-cost">{data.target_item?.name || 'Ore'} × 1</div>
                          <div className="TechnicianWorkshop__empty-cost">One ore produces its configured ingot result.</div>
                        </div>
                        <div className="TechnicianWorkshop__fee-cost">
                          <div className="TechnicianWorkshop__cost-heading">Service fee</div>
                          <div className={`TechnicianWorkshop__fee-value ${smelting && data.budget < (smelting.service_fee ?? 0) ? 'is-missing' : ''}`}>
                            {smelting?.supported ? `${smelting.service_fee} a` : '—'}
                          </div>
                          <div className="TechnicianWorkshop__depot-value">Stored: {data.budget || 0} a</div>
                          {smelting?.supported && data.budget < (smelting.service_fee ?? 0) && <div className="TechnicianWorkshop__fee-warning">Insufficient amnas</div>}
                        </div>
                      </div>
                    </>
                  ) : serviceTab === 'upgrades' ? (
                    <>
                      <div className="TechnicianWorkshop__selected-recipe">
                        {selectedUpgrade ? (
                          <>
                            <div className="TechnicianWorkshop__selected-title">Selected upgrade</div>
                            <div className="TechnicianWorkshop__output-row">
                              <Sprite icon={selectedUpgrade.output_icon} iconState={selectedUpgrade.output_state} size={40} />
                              <div className="TechnicianWorkshop__output-copy">
                                <div className="TechnicianWorkshop__output-name">{selectedUpgrade.output_name || selectedUpgrade.name}</div>
                                <div className="TechnicianWorkshop__output-description">{selectedUpgrade.desc || 'No description available.'}</div>
                              </div>
                            </div>
                          </>
                        ) : (
                          <div className="TechnicianWorkshop__no-selection">No compatible upgrade selected.</div>
                        )}
                      </div>
                      <div className="TechnicianWorkshop__cost-row">
                        <div className="TechnicianWorkshop__material-cost">
                          <div className="TechnicianWorkshop__cost-heading">Physical items on table</div>
                          <RequirementRows requirements={selectedUpgrade?.item_requirements || []} emptyText="No additional items required." />
                          <div className="TechnicianWorkshop__cost-heading">Deposited resources</div>
                          <RequirementRows requirements={selectedUpgrade?.resource_requirements || []} emptyText="No depot resources required." />
                        </div>
                        <div className="TechnicianWorkshop__fee-cost">
                          <div className="TechnicianWorkshop__cost-heading">Service fee</div>
                          <div className={`TechnicianWorkshop__fee-value ${selectedUpgrade && !enoughUpgradeMoney ? 'is-missing' : ''}`}>
                            {selectedUpgrade ? `${selectedUpgrade.service_fee} a` : '—'}
                          </div>
                          <div className="TechnicianWorkshop__depot-value">Stored: {data.budget || 0} a</div>
                          {selectedUpgrade && !enoughUpgradeMoney && <div className="TechnicianWorkshop__fee-warning">Insufficient amnas</div>}
                          {selectedUpgrade && !enoughUpgradeInputs && <div className="TechnicianWorkshop__fee-warning">Missing required inputs</div>}
                        </div>
                      </div>
                    </>
                  ) : serviceTab === 'fix' ? (
                    <>
                      <div className="TechnicianWorkshop__selected-recipe">
                        <div className="TechnicianWorkshop__selected-title">Selected fixing operation</div>
                        <div className="TechnicianWorkshop__output-row">
                          <Sprite icon={data.target_item?.icon} iconState={data.target_item?.icon_state} size={40} />
                          <div className="TechnicianWorkshop__output-copy">
                            <div className="TechnicianWorkshop__output-name">{fixing?.repair_method || 'Repair unavailable'}</div>
                            <div className="TechnicianWorkshop__output-description">
                              {fixing?.supported
                                ? `Restore ${data.target_item?.name || 'the workpiece'} to maximum integrity. Current condition: ${fixing.integrity_percent}%.`
                                : fixing?.fix_reason || 'This item has no supported fixing method.'}
                            </div>
                          </div>
                        </div>
                      </div>
                      <div className="TechnicianWorkshop__cost-row">
                        <div className="TechnicianWorkshop__material-cost">
                          <div className="TechnicianWorkshop__cost-heading">Physical material required</div>
                          <RequirementRows
                            requirements={fixing?.item_requirements || []}
                            emptyText="No rare ingot required on the workbench."
                          />
                          <div className="TechnicianWorkshop__cost-heading">Deposited resources</div>
                          <RequirementRows
                            requirements={fixing?.resource_requirements || []}
                            emptyText={fixing?.integrity_percent === 0 ? 'No depot repair material is configured.' : 'No additional depot material required.'}
                          />
                          {fixing?.fix_reason && <div className="TechnicianWorkshop__fix-reason">{fixing.fix_reason}</div>}
                        </div>
                        <div className="TechnicianWorkshop__fee-cost">
                          <div className="TechnicianWorkshop__cost-heading">Service fee</div>
                          <div className={`TechnicianWorkshop__fee-value ${fixing && !enoughFixMoney ? 'is-missing' : ''}`}>
                            {fixing?.supported ? `${fixing.service_fee} a` : '—'}
                          </div>
                          <div className="TechnicianWorkshop__depot-value">Stored: {data.budget || 0} a</div>
                          {fixing?.supported && !enoughFixMoney && <div className="TechnicianWorkshop__fee-warning">Insufficient amnas</div>}
                          {fixing?.supported && !fixing.items_sufficient && <div className="TechnicianWorkshop__fee-warning">Place the required ingot on the workbench</div>}
                          {fixing?.supported && !fixing.resources_sufficient && <div className="TechnicianWorkshop__fee-warning">Missing depot repair material</div>}
                          {fixing?.supported && !fixing.has_damage && <div className="TechnicianWorkshop__fee-warning">No repair needed</div>}
                        </div>
                      </div>
                    </>
                  ) : (
                    <div className="TechnicianWorkshop__no-selection">No compatible operation is registered for this item.</div>
                  )}
                </section>
              </div>
            </>
          ) : (
            <div className="TechnicianWorkshop__main">
              <section className="TechnicianWorkshop__recipe-pane">
                <div className="TechnicianWorkshop__pane-heading">
                  Recipe catalogue
                  <span>{visibleRecipes.length} recipes</span>
                </div>
                <div className="TechnicianWorkshop__recipe-list">
                  {visibleRecipes.length ? visibleRecipes.map((recipe) => (
                    <RecipeEntry
                      key={recipe.ref}
                      recipe={recipe}
                      selected={selectedRecipe?.ref === recipe.ref}
                      onSelect={() => setSelectedRecipeRef(recipe.ref)}
                    />
                  )) : (
                    <div className="TechnicianWorkshop__empty-list">No recipes in this category.</div>
                  )}
                </div>
              </section>

              <section className="TechnicianWorkshop__detail-pane">
                <TechnicianPortrait
                  icon={data.technician_icon}
                  state={data.technician_state}
                  busy={false}
                  remaining={0}
                  total={1}
                  snapshot={data.craft_time_snapshot || 0}
                />
                <div className="TechnicianWorkshop__selected-recipe">
                  {selectedRecipe ? (
                    <>
                      <div className="TechnicianWorkshop__selected-title">Selected recipe</div>
                      <div className="TechnicianWorkshop__output-row">
                        <Sprite icon={selectedRecipe.output_icon} iconState={selectedRecipe.output_state} size={40} />
                        <div className="TechnicianWorkshop__output-copy">
                          <div className="TechnicianWorkshop__output-name">
                            {selectedRecipe.output_name || selectedRecipe.name}
                            {selectedRecipe.output_amount > 1 && ` ×${selectedRecipe.output_amount}`}
                          </div>
                          <div className="TechnicianWorkshop__output-description">{selectedRecipe.desc || 'No description available.'}</div>
                        </div>
                      </div>
                    </>
                  ) : (
                    <div className="TechnicianWorkshop__no-selection">Select a recipe.</div>
                  )}
                </div>
                <div className="TechnicianWorkshop__cost-row">
                  <div className="TechnicianWorkshop__material-cost">
                    <div className="TechnicianWorkshop__cost-heading">Material requirements</div>
                    {selectedRecipe ? <RequirementRows requirements={selectedRecipe.requirements || []} /> : <div className="TechnicianWorkshop__empty-cost">No recipe selected.</div>}
                  </div>
                  <div className="TechnicianWorkshop__fee-cost">
                    <div className="TechnicianWorkshop__cost-heading">Service fee</div>
                    <div className={`TechnicianWorkshop__fee-value ${selectedRecipe && !enoughCraftMoney ? 'is-missing' : ''}`}>
                      {selectedRecipe ? `${selectedRecipe.service_fee} a` : '—'}
                    </div>
                    <div className="TechnicianWorkshop__depot-value">You have: {data.budget || 0} a</div>
                    {selectedRecipe && !enoughCraftMoney && <div className="TechnicianWorkshop__fee-warning">Insufficient amnas</div>}
                  </div>
                </div>
              </section>
            </div>
          )}

          <div className="TechnicianWorkshop__footer">
            {!busy && smeltMode ? (
              <>
                <div className="TechnicianWorkshop__service-footer-copy">
                  {smelting?.supported
                    ? `Smelt ${data.target_item?.name || 'ore'} into ${smelting.output_name} · ${smelting.service_fee} amnas`
                    : smelting?.reason || 'This ore cannot be smelted here.'}
                </div>
                {smelting?.supported && (
                  <button
                    type="button"
                    className="TechnicianWorkshop__craft-button"
                    disabled={!canSmelt}
                    onClick={() => act('start_smelt')}>
                    Smelt
                  </button>
                )}
              </>
            ) : !busy && targetMode ? (
              <>
                <div className="TechnicianWorkshop__categories">
                  {showUpgradeTab && (
                    <button
                      type="button"
                      className={`TechnicianWorkshop__category ${serviceTab === 'upgrades' ? 'is-active' : ''}`}
                      onClick={() => setStoredServiceTab('upgrades')}>
                      Upgrades
                    </button>
                  )}
                  {showFixTab && (
                    <button
                      type="button"
                      className={`TechnicianWorkshop__category ${serviceTab === 'fix' ? 'is-active' : ''}`}
                      onClick={() => setStoredServiceTab('fix')}>
                      Fixing
                    </button>
                  )}
                  {!showUpgradeTab && !showFixTab && (
                    <div className="TechnicianWorkshop__service-footer-copy">No available upgrade or fixing operation for this item.</div>
                  )}
                </div>
                {serviceTab === 'upgrades' && showUpgradeTab && (
                  <button
                    type="button"
                    className="TechnicianWorkshop__craft-button"
                    disabled={!canUpgrade}
                    onClick={() => selectedUpgrade && act('start_upgrade', { recipe: selectedUpgrade.ref })}>
                    Upgrade
                  </button>
                )}
                {serviceTab === 'fix' && showFixTab && (
                  <button
                    type="button"
                    className="TechnicianWorkshop__craft-button"
                    disabled={!canFix}
                    onClick={() => act('start_fix')}>
                    {fixing?.has_damage ? 'Fix' : 'No repair needed'}
                  </button>
                )}
              </>
            ) : !busy ? (
              <>
                <div className="TechnicianWorkshop__categories">
                  {categories.map((category) => (
                    <button
                      type="button"
                      key={category}
                      className={`TechnicianWorkshop__category ${activeCategory === category ? 'is-active' : ''}`}
                      onClick={() => {
                        setStoredCategory(category);
                        setSelectedRecipeRef('');
                      }}>
                      {category}
                    </button>
                  ))}
                </div>
                <button
                  type="button"
                  className="TechnicianWorkshop__craft-button"
                  disabled={!canCraft}
                  onClick={() => selectedRecipe && act('start_craft', { recipe: selectedRecipe.ref })}>
                  Craft
                </button>
              </>
            ) : (
              <div className="TechnicianWorkshop__busy-footer">
                The technician remains at the workbench. The operation continues if the interface closes or the initiating player disconnects.
              </div>
            )}
          </div>
          <div
            className={`TechnicianWorkshop__footer-warning ${!busy && !targetMode && selectedRecipe && (!enoughCraftMaterials || !enoughCraftMoney) ? '' : 'is-hidden'}`}
            aria-hidden={busy || targetMode || !selectedRecipe || (enoughCraftMaterials && enoughCraftMoney)}>
            {!enoughCraftMaterials && 'Missing resources are shown in red.'}
            {!enoughCraftMaterials && !enoughCraftMoney && ' · '}
            {!enoughCraftMoney && 'The workstation needs more amnas.'}
          </div>
            </>
          )}
        </div>
      </Window.Content>
    </Window>
  );
};
