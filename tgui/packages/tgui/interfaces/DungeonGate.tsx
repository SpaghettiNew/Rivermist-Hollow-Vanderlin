import { useBackend } from '../backend';
import {
  Button,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
} from 'tgui-core/components';
import { Window } from '../layouts';

type Data = {
  role: 'forward' | 'back' | 'descent';
  sealed: 0 | 1;
  forsaken: 0 | 1;
  locked: 0 | 1;
  reward_text: string | null;
  danger_text: string | null;
  special_text: string | null;
  destination_text: string | null;
  boss_ahead: 0 | 1;
  hint: string | null;
  back_available: 0 | 1;
  muster_missing: string[];
  is_leader: 0 | 1;
};

const ROLE_TITLES = {
  forward: 'Passage Onward',
  back: 'The Way Back',
  descent: 'Stairway Below',
};

export function DungeonGate(props) {
  const { act, data } = useBackend<Data>();
  const {
    role,
    sealed,
    forsaken,
    locked,
    reward_text,
    danger_text,
    special_text,
    destination_text,
    boss_ahead,
    hint,
    back_available,
    muster_missing = [],
    is_leader,
  } = data;

  const isBack = role === 'back';
  const needsMuster = !isBack && muster_missing.length > 0;
  const blocked =
    !!sealed || !!forsaken || !!locked || (isBack && !back_available);

  return (
    <Window title={ROLE_TITLES[role] || 'Shifting Passage'} width={380} height={340}>
      <Window.Content>
        <Stack fill vertical>
          {!!forsaken && (
            <Stack.Item>
              <NoticeBox danger>
                Dead stone. The party chose another path — this passage is gone
                forever.
              </NoticeBox>
            </Stack.Item>
          )}
          {!!sealed && !forsaken && (
            <Stack.Item>
              <NoticeBox danger>
                Sealed shut — the hostile presence in this room holds it
                closed.
              </NoticeBox>
            </Stack.Item>
          )}
          {!!locked && !sealed && !forsaken && (
            <Stack.Item>
              <NoticeBox danger>
                Locked. A key lies somewhere in this room — take it from
                whatever carries it.
              </NoticeBox>
            </Stack.Item>
          )}
          {isBack && !back_available && (
            <Stack.Item>
              <NoticeBox danger>
                The way back has crumbled — the passages behind are gone.
              </NoticeBox>
            </Stack.Item>
          )}
          <Stack.Item grow>
            <Section fill title="What Lies Beyond">
              {hint ? (
                <i>{hint}</i>
              ) : (
                isBack && <i>It leads back the way you came.</i>
              )}
              {!isBack && !!boss_ahead && (
                <NoticeBox danger>
                  War-drums and a vast presence — the floor&apos;s master waits
                  beyond this passage.
                </NoticeBox>
              )}
              {!isBack && (
                <LabeledList>
                  {special_text && (
                    <LabeledList.Item label="Beyond" color="purple">
                      {special_text}
                    </LabeledList.Item>
                  )}
                  {destination_text && (
                    <LabeledList.Item label="Destination" color="blue">
                      {destination_text}
                    </LabeledList.Item>
                  )}
                  {reward_text && (
                    <LabeledList.Item label="Promise" color="good">
                      {reward_text}
                    </LabeledList.Item>
                  )}
                  {danger_text && (
                    <LabeledList.Item
                      label="Danger"
                      color={danger_text.includes('high') ? 'bad' : 'average'}
                    >
                      {danger_text}
                    </LabeledList.Item>
                  )}
                  {role === 'descent' && (
                    <LabeledList.Item label="Depth" color="bad">
                      The next floor — colder, hungrier, richer.
                    </LabeledList.Item>
                  )}
                </LabeledList>
              )}
            </Section>
          </Stack.Item>
          {!isBack && (
            <Stack.Item>
              <Section title="The Party">
                {needsMuster ? (
                  <NoticeBox danger>
                    Still scattered: {muster_missing.join(', ')}. The passage
                    opens only for a gathered party.
                  </NoticeBox>
                ) : (
                  'The party stands ready.'
                )}
              </Section>
            </Stack.Item>
          )}
          <Stack.Item>
            <Stack>
              <Stack.Item grow>
                <Button
                  fluid
                  icon="dungeon"
                  disabled={blocked || needsMuster}
                  tooltip={
                    needsMuster
                      ? 'Gather the party first — or the leader may force the march.'
                      : undefined
                  }
                  onClick={() => act('traverse')}
                >
                  Traverse
                </Button>
              </Stack.Item>
              {needsMuster && !!is_leader && !blocked && (
                <Stack.Item grow>
                  <Button.Confirm
                    fluid
                    color="bad"
                    icon="person-military-pointing"
                    onClick={() => act('force')}
                  >
                    Force the March
                  </Button.Confirm>
                </Stack.Item>
              )}
            </Stack>
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
}
