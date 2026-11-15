import { useState } from 'react';
import { Box, Button, Input, Section, Stack, TextArea } from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';
import { sanitizeHTML } from '../sanitize';

type BoardTask = {
  ref: string;
  title: string;
  description: string;
  description_raw: string;
  payment: string;
  poster_name: string;
  taken: boolean;
  taker_name?: string;
  taken_at_text?: string;
  is_own_posting: boolean;
};

type HistoryEntry = {
  title: string;
  poster_name: string;
  payment: string;
  taker_name: string;
  signed_by_name: string;
  signed_by_leader: boolean;
};

type Data = {
  board_title: string;
  lang: 'en' | 'ru';
  is_role: boolean;
  has_active_task: boolean;
  can_compose: boolean;
  board_full: boolean;
  limits: {
    title: number;
    description: number;
    payment: number;
  };
  own_task_cap: number;
  own_task_count: number;
  location_name: string;
  leader_label: string;
  leader_name: string | null;
  staff_label: string;
  staff_names: string[];
  tasks: BoardTask[];
  history: HistoryEntry[];
};

const SLOT_SIZE = 3;
const FADE_MS = 180;

const STRINGS = {
  en: {
    full: 'Board full (12/12)',
    empty: 'No notices posted.',
    composeTitle: 'New notice',
    editTitle: 'Edit notice',
    fieldTitle: 'Title',
    fieldDescription: 'Description',
    fieldPayment: 'Payment',
    post: 'Post',
    cancel: 'Cancel',
    edit: 'Edit',
    save: 'Save',
    remove: 'Remove',
    take: 'Take',
    cancelJob: 'Cancel job',
    postedBy: 'Posted by',
    takenBy: 'Taken by',
    at: 'at',
    tabNotices: 'Notices',
    tabHistory: 'History',
    historyEmpty: 'Nothing signed off yet.',
    signedBy: 'Signed by',
    ownCap: 'own notices up',
  },
  ru: {
    full: 'Доска заполнена (12/12)',
    empty: 'Объявлений пока нет.',
    composeTitle: 'Новое объявление',
    editTitle: 'Изменить объявление',
    fieldTitle: 'Тема',
    fieldDescription: 'Описание',
    fieldPayment: 'Оплата',
    post: 'Разместить',
    cancel: 'Отмена',
    edit: 'Изменить',
    save: 'Сохранить',
    remove: 'Убрать',
    take: 'Взять',
    cancelJob: 'Отменить задание',
    postedBy: 'Автор',
    takenBy: 'Взял(а)',
    at: 'в',
    tabNotices: 'Задания',
    tabHistory: 'История',
    historyEmpty: 'Пока ничего не подписано.',
    signedBy: 'Подписал',
    ownCap: 'своих объявлений висит',
  },
} as const;

type Locale = (typeof STRINGS)[keyof typeof STRINGS];

type TaskForm = {
  title: string;
  description: string;
  payment: string;
};

const EMPTY_FORM: TaskForm = { title: '', description: '', payment: '' };

const NoticeForm = (props: {
  title: string;
  t: Locale;
  limits: Data['limits'];
  initial: TaskForm;
  submitLabel: string;
  submitColor?: 'good';
  ownCapNote?: string;
  onSubmit: (form: TaskForm) => void;
  onCancel: () => void;
}) => {
  const [form, setForm] = useState<TaskForm>(props.initial);
  return (
    <Section title={props.title}>
      <Stack vertical>
        {!!props.ownCapNote && (
          <Stack.Item className="QuestBoard__CapNote">{props.ownCapNote}</Stack.Item>
        )}
        <Stack.Item>
          <Input
            fluid
            maxLength={props.limits.title}
            placeholder={props.t.fieldTitle}
            value={form.title}
            onChange={(value) => setForm((f) => ({ ...f, title: value }))}
          />
        </Stack.Item>
        <Stack.Item>
          <TextArea
            fluid
            height="7em"
            maxLength={props.limits.description}
            placeholder={props.t.fieldDescription}
            value={form.description}
            onChange={(value) => setForm((f) => ({ ...f, description: value }))}
          />
        </Stack.Item>
        <Stack.Item>
          <Input
            fluid
            maxLength={props.limits.payment}
            placeholder={props.t.fieldPayment}
            value={form.payment}
            onChange={(value) => setForm((f) => ({ ...f, payment: value }))}
          />
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item>
              <Button color={props.submitColor} onClick={() => props.onSubmit(form)}>
                {props.submitLabel}
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button onClick={props.onCancel}>{props.t.cancel}</Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const MIN_CARD_WIDTH = 200;
const MAX_CARD_WIDTH = 230;

const cardWidthFor = (task: BoardTask, limits: Data['limits']) => {
  const combinedMax = limits.title + limits.description || 1;
  const combined = task.title.length + task.description_raw.length;
  const scale = Math.min(1, combined / combinedMax);
  return MIN_CARD_WIDTH + scale * (MAX_CARD_WIDTH - MIN_CARD_WIDTH);
};

const TaskCard = (props: {
  t: Locale;
  task: BoardTask;
  limits: Data['limits'];
  hasActiveTask: boolean;
  onStartEdit: () => void;
  onAct: (action: string) => void;
}) => {
  const { t, task } = props;
  return (
    <div className="QuestBoard__Card" style={{ width: cardWidthFor(task, props.limits) }}>
      <div className="QuestBoard__Pin" />
      <div className="QuestBoard__CardTitle">{task.title}</div>
      <div
        className="QuestBoard__CardObjective"
        dangerouslySetInnerHTML={{ __html: sanitizeHTML(task.description) }}
      />
      <div className="QuestBoard__CardRow">
        <span className="QuestBoard__CardLabel">{t.fieldPayment}:</span>
        <span className="QuestBoard__CardValue">{task.payment}</span>
      </div>
      <div className="QuestBoard__CardRow">
        <span className="QuestBoard__CardLabel">{t.postedBy}:</span>
        <span className="QuestBoard__CardValue">{task.poster_name}</span>
      </div>
      {!!task.taken && (
        <div className="QuestBoard__CardRow">
          <span className="QuestBoard__CardLabel">{t.takenBy}:</span>
          <span className="QuestBoard__CardValue">
            {task.taker_name} ({t.at} {task.taken_at_text})
          </span>
        </div>
      )}
      <Stack className="QuestBoard__CardButtons">
        {!task.taken && !!task.is_own_posting && (
          <>
            <Stack.Item>
              <Button tooltip="Change the title, description, or payment" onClick={props.onStartEdit}>
                {t.edit}
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                color="bad"
                tooltip="Unpin this notice - you'll get a blank parchment back"
                onClick={() => props.onAct('remove_task')}
              >
                {t.remove}
              </Button>
            </Stack.Item>
          </>
        )}
        {!!task.taken && !!task.is_own_posting && (
          <Stack.Item>
            <Button
              color="bad"
              tooltip="Tear up this job and notify whoever took it"
              onClick={() => props.onAct('cancel_taken')}
            >
              {t.cancelJob}
            </Button>
          </Stack.Item>
        )}
        {!task.taken && !task.is_own_posting && (
          <Stack.Item>
            <Button
              disabled={!!props.hasActiveTask}
              tooltip={
                props.hasActiveTask
                  ? 'You already have an active job'
                  : "Take this job - you can only hold one at a time"
              }
              onClick={() => props.onAct('take_task')}
            >
              {t.take}
            </Button>
          </Stack.Item>
        )}
      </Stack>
    </div>
  );
};

const HistoryRow = (props: { t: Locale; entry: HistoryEntry }) => {
  const { t, entry } = props;
  return (
    <div className="QuestBoard__HistoryRow">
      <div className="QuestBoard__HistoryTitle">{entry.title}</div>
      <div className="QuestBoard__CardRow">
        <span className="QuestBoard__CardLabel">{t.postedBy}:</span>
        <span className="QuestBoard__CardValue">{entry.poster_name}</span>
      </div>
      <div className="QuestBoard__CardRow">
        <span className="QuestBoard__CardLabel">{t.fieldPayment}:</span>
        <span className="QuestBoard__CardValue">{entry.payment}</span>
      </div>
      <div className="QuestBoard__CardRow">
        <span className="QuestBoard__CardLabel">{t.takenBy}:</span>
        <span className="QuestBoard__CardValue">{entry.taker_name}</span>
      </div>
      <div className="QuestBoard__CardRow">
        <span className="QuestBoard__CardLabel">{t.signedBy}:</span>
        <span
          className={
            'QuestBoard__CardValue' +
            (entry.signed_by_leader
              ? ' QuestBoard__Signature--leader'
              : ' QuestBoard__Signature--staff')
          }
        >
          {entry.signed_by_name}
        </span>
      </div>
    </div>
  );
};

export const QuestBoard = () => {
  const { act, data } = useBackend<Data>();
  const t = STRINGS[data.lang === 'ru' ? 'ru' : 'en'];
  const tasks = data.tasks || [];
  const history = data.history || [];

  const [tab, setTab] = useState<'notices' | 'history'>('notices');
  const [page, setPage] = useState(0);
  const [fading, setFading] = useState(false);
  const [editingRef, setEditingRef] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<TaskForm>(EMPTY_FORM);

  const pageCount = Math.max(1, Math.ceil(tasks.length / SLOT_SIZE));
  const safePage = Math.min(page, pageCount - 1);
  const visible = tasks.slice(safePage * SLOT_SIZE, safePage * SLOT_SIZE + SLOT_SIZE);
  const showArrows = tasks.length > SLOT_SIZE;

  const changePage = (delta: number) => {
    if (pageCount <= 1) {
      return;
    }
    setFading(true);
    setTimeout(() => {
      setPage((p) => (p + delta + pageCount) % pageCount);
      setFading(false);
    }, FADE_MS);
  };

  const startEdit = (task: BoardTask) => {
    setEditingRef(task.ref);
    setEditForm({ title: task.title, description: task.description_raw, payment: task.payment });
  };

  const editingTask = tasks.find((task) => task.ref === editingRef) || null;

  const ownCapNote =
    data.own_task_cap > 0
      ? `${data.own_task_count}/${data.own_task_cap} ${t.ownCap}`
      : undefined;

  return (
    <Window title={data.board_title} theme="grimoire" width={960} height={640}>
      <Window.Content scrollable>
        <div className="QuestBoard__Root">
          <div className="QuestBoard__LocationName">{data.location_name}</div>

          {!!data.is_role && (
            <Stack className="QuestBoard__Tabs">
              <Stack.Item>
                <Button
                  selected={tab === 'notices'}
                  onClick={() => setTab('notices')}
                >
                  {t.tabNotices}
                </Button>
              </Stack.Item>
              <Stack.Item>
                <Button
                  selected={tab === 'history'}
                  onClick={() => setTab('history')}
                >
                  {t.tabHistory}
                </Button>
              </Stack.Item>
            </Stack>
          )}

          {tab === 'history' ? (
            <div className="QuestBoard__HistoryList">
              {history.length === 0 && (
                <Box className="QuestBoard__Empty">{t.historyEmpty}</Box>
              )}
              {history.map((entry, i) => (
                <HistoryRow key={i} t={t} entry={entry} />
              ))}
            </div>
          ) : (
            <>
              {!!data.board_full && (
                <Box className="QuestBoard__Full" mb={1}>
                  {t.full}
                </Box>
              )}

              {editingTask ? (
                <NoticeForm
                  title={t.editTitle}
                  t={t}
                  limits={data.limits}
                  initial={editForm}
                  submitLabel={t.save}
                  submitColor="good"
                  onSubmit={(form) => {
                    act('update_task', { ref: editingTask.ref, ...form });
                    setEditingRef(null);
                  }}
                  onCancel={() => setEditingRef(null)}
                />
              ) : (
                !!data.can_compose && (
                  <NoticeForm
                    title={t.composeTitle}
                    t={t}
                    limits={data.limits}
                    initial={EMPTY_FORM}
                    submitLabel={t.post}
                    submitColor="good"
                    ownCapNote={ownCapNote}
                    onSubmit={(form) => act('submit_post', form)}
                    onCancel={() => act('cancel_post')}
                  />
                )
              )}

              <div className="QuestBoard__Carousel">
                {showArrows && (
                  <Button
                    className="QuestBoard__Arrow"
                    tooltip="Previous"
                    disabled={pageCount <= 1}
                    onClick={() => changePage(-1)}
                  >
                    ‹
                  </Button>
                )}
                <div
                  className={
                    'QuestBoard__Grid' + (fading ? ' QuestBoard__Grid--fading' : '')
                  }
                >
                  {visible.length === 0 && (
                    <Box className="QuestBoard__Empty">{t.empty}</Box>
                  )}
                  {visible.map((task) => (
                    <TaskCard
                      key={task.ref}
                      t={t}
                      task={task}
                      limits={data.limits}
                      hasActiveTask={data.has_active_task}
                      onStartEdit={() => startEdit(task)}
                      onAct={(action) => act(action, { ref: task.ref })}
                    />
                  ))}
                </div>
                {showArrows && (
                  <Button
                    className="QuestBoard__Arrow"
                    tooltip="Next"
                    disabled={pageCount <= 1}
                    onClick={() => changePage(1)}
                  >
                    ›
                  </Button>
                )}
              </div>
            </>
          )}

          <div className="QuestBoard__Footer">
            <Stack className="QuestBoard__Roster" wrap>
              <Stack.Item className="QuestBoard__RosterItem">
                <span
                  title={
                    data.leader_name
                      ? `${data.leader_label} currently on duty.`
                      : `No one is currently serving as ${data.leader_label.toLowerCase()}.`
                  }
                >
                  <b>{data.leader_label}:</b> {data.leader_name || 'Away'}
                </span>
              </Stack.Item>
              {!!data.staff_label && (
                <Stack.Item className="QuestBoard__RosterItem">
                  <span title={`On-duty ${data.staff_label.toLowerCase()}, if any.`}>
                    <b>{data.staff_label}:</b>{' '}
                    {data.staff_names.length ? data.staff_names.join(', ') : 'None on duty'}
                  </span>
                </Stack.Item>
              )}
            </Stack>
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};
