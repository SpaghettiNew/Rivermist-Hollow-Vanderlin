import { useState } from 'react';
import { useBackend } from '../backend';
import {
  Box,
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Tabs,
} from 'tgui-core/components';
import { Window } from '../layouts';

type RosterRow = {
  name: string;
  rank: string | null;
  ready: 0 | 1;
  leader: 0 | 1;
};

type HeatDial = {
  id: string;
  name: string;
  desc: string;
  rank: number;
  max_rank: number;
};

type UnlockRow = {
  id: string;
  name: string;
  desc: string;
  cost: number;
  owned: 0 | 1;
};

type TitleRow = UnlockRow & {
  title_text: string | null;
};

type Data = {
  has_party: 0 | 1;
  party_name: string | null;
  leader_name: string | null;
  is_leader: 0 | 1;
  run_active: 0 | 1;
  dormant: 0 | 1;
  reopens_in: number;
  roster: RosterRow[];
  echoes: number;
  covenant_owned: 0 | 1;
  heat_locked: 0 | 1;
  dials: HeatDial[];
  total_heat: number;
  echo_bonus_percent: number;
  unlocks: UnlockRow[];
  titles: TitleRow[];
  selected_title: string | null;
};

export function DungeonAssembly(props) {
  const { data } = useBackend<Data>();
  const [tab, setTab] = useState('expedition');

  return (
    <Window title="The Abyssal Delve" width={440} height={520}>
      <Window.Content scrollable>
        <Stack fill vertical>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                icon="dungeon"
                selected={tab === 'expedition'}
                onClick={() => setTab('expedition')}
              >
                Expedition
              </Tabs.Tab>
              <Tabs.Tab
                icon="book"
                selected={tab === 'ledger'}
                onClick={() => setTab('ledger')}
              >
                Delver&apos;s Ledger ({data.echoes})
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          {tab === 'expedition' ? <ExpeditionTab /> : <LedgerTab />}
        </Stack>
      </Window.Content>
    </Window>
  );
}

function ExpeditionTab(props) {
  const { act, data } = useBackend<Data>();
  const {
    has_party,
    party_name,
    leader_name,
    is_leader,
    run_active,
    dormant,
    reopens_in,
    roster = [],
    covenant_owned,
    heat_locked,
    dials = [],
    total_heat,
    echo_bonus_percent,
  } = data;

  return (
    <>
      {!!dormant && (
        <Stack.Item>
          <NoticeBox danger>
            The way down is buried under fresh rubble.
            {reopens_in > 0
              ? ` The depths will reopen in ~${Math.ceil(reopens_in / 60)} minute${Math.ceil(reopens_in / 60) === 1 ? '' : 's'}.`
              : ' It has not reopened yet.'}
          </NoticeBox>
        </Stack.Item>
      )}
      {!!run_active && (
        <Stack.Item>
          <NoticeBox info>
            An expedition is already underway below. Members may descend to
            rejoin it.
          </NoticeBox>
        </Stack.Item>
      )}
      {!dormant && !run_active && (
        <Stack.Item>
          <NoticeBox danger>
            The dark does not let go: there is no way back to the surface until
            the floor&apos;s master falls and its place of respite is won.
          </NoticeBox>
        </Stack.Item>
      )}
      {!!covenant_owned && (
        <Stack.Item>
          <Section
            title="The Grim Covenant"
            buttons={
              <Box inline color="purple" bold>
                Heat {total_heat} · +{echo_bonus_percent}% echoes
              </Box>
            }
          >
            {heat_locked ? (
              <NoticeBox info>The pact is sealed for the run underway.</NoticeBox>
            ) : (
              dials.map((dial) => (
                <Box key={dial.id} mb={0.5}>
                  <Box inline width="55%">
                    <Box bold>{dial.name}</Box>
                    <Box color="label" fontSize="0.85em">
                      {dial.desc}
                    </Box>
                  </Box>
                  <Box inline width="45%" textAlign="right" verticalAlign="top">
                    {[...Array(dial.max_rank + 1).keys()].map((r) => (
                      <Button
                        key={r}
                        selected={dial.rank === r}
                        onClick={() => act('set_dial', { id: dial.id, rank: r })}
                      >
                        {r}
                      </Button>
                    ))}
                  </Box>
                </Box>
              ))
            )}
          </Section>
        </Stack.Item>
      )}
      <Stack.Item grow>
        {has_party ? (
          <Section
            fill
            title={party_name || 'The Party'}
            buttons={
              <Button icon="user-plus" onClick={() => act('invite')}>
                Invite
              </Button>
            }
          >
            <LabeledList>
              <LabeledList.Item label="Leader">
                {leader_name || '—'}
              </LabeledList.Item>
            </LabeledList>
            <Box mt={1}>
              {roster.map((row) => (
                <Box key={row.name}>
                  <Box inline color={row.ready ? 'good' : 'bad'}>
                    {row.ready ? '●' : '○'}
                  </Box>{' '}
                  <Box inline bold={!!row.leader}>
                    {row.name}
                  </Box>{' '}
                  {row.rank && (
                    <Box inline color="label">
                      — {row.rank}
                    </Box>
                  )}
                  <Box inline color="label" ml={0.5}>
                    ({row.ready ? 'at the mouth' : 'away'})
                  </Box>
                </Box>
              ))}
            </Box>
          </Section>
        ) : (
          <Section fill title="No Party">
            <Box color="label" mb={1}>
              A party shares its motes, blessings, and fate. Or descend alone —
              the dark does not insist on company.
            </Box>
            <Button fluid icon="users" onClick={() => act('create_party')}>
              Form an Expedition
            </Button>
            <Button
              fluid
              mt={0.5}
              icon="person-walking-arrow-right"
              color="average"
              disabled={!!dormant}
              onClick={() => act('descend_solo')}
            >
              Descend Alone
            </Button>
          </Section>
        )}
      </Stack.Item>
      {!!has_party && (
        <Stack.Item>
          <Button
            fluid
            icon="dungeon"
            color="good"
            disabled={!is_leader || !!dormant}
            tooltip={
              !is_leader ? 'Only the leader gives the order to descend.' : undefined
            }
            onClick={() => act('descend')}
          >
            Descend
          </Button>
        </Stack.Item>
      )}
    </>
  );
}

function LedgerTab(props) {
  const { act, data } = useBackend<Data>();
  const { echoes, unlocks = [], titles = [], selected_title } = data;

  return (
    <>
      <Stack.Item>
        <Section title="The Ledger">
          <LabeledList>
            <LabeledList.Item label="Banked Echoes" color="teal">
              {echoes}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item>
        <Section title="Unlocks">
          {unlocks.map((row) => (
            <Box key={row.id} mb={0.5}>
              <Box inline width="70%">
                <Box bold>{row.name}</Box>
                <Box color="label" fontSize="0.85em">
                  {row.desc}
                </Box>
              </Box>
              <Box inline width="30%" textAlign="right" verticalAlign="top">
                {row.owned ? (
                  <Box color="good" bold>
                    OWNED
                  </Box>
                ) : (
                  <Button
                    icon="coins"
                    disabled={echoes < row.cost}
                    onClick={() => act('buy_unlock', { id: row.id })}
                  >
                    {row.cost}
                  </Button>
                )}
              </Box>
            </Box>
          ))}
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Section
          fill
          title="Titles"
          buttons={
            <Button
              selected={!selected_title}
              onClick={() => act('set_title', { id: 'none' })}
            >
              None
            </Button>
          }
        >
          <Box color="label" mb={1}>
            Wearing a title appends it to your visible name. Choose None to
            hide it again.
          </Box>
          {titles.map((row) => (
            <Box key={row.id} mb={0.5}>
              <Box inline width="70%">
                <Box bold>{row.title_text || row.name}</Box>
                <Box color="label" fontSize="0.85em">
                  {row.desc}
                </Box>
              </Box>
              <Box inline width="30%" textAlign="right" verticalAlign="top">
                {row.owned ? (
                  <Button
                    icon="signature"
                    selected={selected_title === row.id}
                    onClick={() => act('set_title', { id: row.id })}
                  >
                    Wear
                  </Button>
                ) : (
                  <Button
                    icon="coins"
                    disabled={echoes < row.cost}
                    onClick={() => act('buy_title', { id: row.id })}
                  >
                    {row.cost}
                  </Button>
                )}
              </Box>
            </Box>
          ))}
        </Section>
      </Stack.Item>
    </>
  );
}
