import { Fragment, useState } from 'react';
import { Box, Button, Input, Section, Table, Tabs } from 'tgui-core/components';
import { useBackend } from '../backend';

type JobChoice = {
  value: string;
};

type JobEntry = {
  title: string;
  tutorial: string;
  slots: number;
  has_info?: boolean | number;
  title_choices: JobChoice[];
  honorary_choices: JobChoice[];
};

type JobCategory = {
  name: string;
  color: string;
  jobs: JobEntry[];
};

type JobState = {
  display_name: string;
  pref_level: number | null;
  status: 'available' | 'locked' | 'banned';
  lock_label?: string;
  lock_detail?: string[];
  current_title: string;
  current_honorary: string;
};

type JobsData = {
  job_categories?: JobCategory[];
  job_states?: Record<string, JobState>;
  jobless_role?: string;
  last_class?: string;
  job_changes_locked?: boolean | number;
  race_banned?: boolean | number;
  race_banned_name?: string;
};

const priorityLevels = [
  { value: 3, label: 'High' },
  { value: 2, label: 'Medium' },
  { value: 1, label: 'Low' },
  { value: null, label: 'Never' },
] as const;

export const PreferencesJobs = () => {
  const { act, data } = useBackend<JobsData>();
  const categories = data.job_categories ?? [];
  const jobStates = data.job_states ?? {};
  const [activeCategory, setActiveCategory] = useState(categories[0]?.name);
  const [expandedJob, setExpandedJob] = useState<string | null>(null);
  const [extraTab, setExtraTab] = useState<'titles' | 'honorary'>('titles');
  const [searchText, setSearchText] = useState('');

  const currentCategory =
    categories.find((category) => category.name === activeCategory) ??
    categories[0];
  const normalizedSearch = searchText.trim().toLowerCase();
  const isSearching = normalizedSearch.length > 0;

  const getJobState = (job: JobEntry): JobState =>
    jobStates[job.title] ?? {
      display_name: job.title,
      pref_level: null,
      status: 'locked',
      current_title: job.title,
      current_honorary: '',
    };

  const jobMatchesSearch = (job: JobEntry) => {
    const state = getJobState(job);
    return [
      job.title,
      state.display_name,
      state.current_title,
      state.current_honorary,
      ...job.title_choices.map((choice) => choice.value),
      ...job.honorary_choices.map((choice) => choice.value),
    ]
      .filter(Boolean)
      .join(' ')
      .toLowerCase()
      .includes(normalizedSearch);
  };

  const visibleJobs = isSearching
    ? categories.flatMap((category) =>
        category.jobs.filter(jobMatchesSearch),
      )
    : (currentCategory?.jobs ?? []);

  const categoryColorFor = (job: JobEntry) =>
    categories.find((category) =>
      category.jobs.some((candidate) => candidate.title === job.title),
    )?.color;

  if (data.race_banned) {
    return (
      <Section title="Class Selection">
        <Box color="bad" bold>
          You are banned from playing the species: {data.race_banned_name}
        </Box>
      </Section>
    );
  }

  return (
    <>
      <Section title="Class Preferences">
        <Button
          icon="random"
          disabled={!!data.job_changes_locked}
          onClick={() => act('job_toggle_unavailable')}
        >
          If unavailable: {data.jobless_role || 'Return to Lobby'}
        </Button>
        <Button
          icon="undo"
          ml={1}
          disabled={!!data.job_changes_locked}
          onClick={() => act('job_reset_priorities')}
        >
          Reset Priorities
        </Button>
        <Button
          icon="list"
          ml={1}
          onClick={() => act('pref', { preference: 'role_settings' })}
        >
          Role Settings
        </Button>
        {data.last_class ? (
          <Button
            icon="history"
            ml={1}
            disabled={!!data.job_changes_locked}
            onClick={() => act('job_play_last_class')}
          >
            Play as {data.last_class} again
          </Button>
        ) : null}
      </Section>

      <Section>
        <Input
          fluid
          placeholder="Search classes, titles, or honoraries..."
          value={searchText}
          onChange={(value) => setSearchText(String(value ?? ''))}
        />
      </Section>

      <Tabs>
        {categories.map((category) => {
          const selected = currentCategory?.name === category.name;
          return (
            <Tabs.Tab
              key={category.name}
              selected={selected && !isSearching}
              onClick={() => {
                setActiveCategory(category.name);
                setExpandedJob(null);
                setSearchText('');
              }}
              style={{
                borderBottom: `2px solid ${selected ? category.color : 'transparent'}`,
              }}
            >
              <Box style={{ color: category.color }} bold={selected}>
                {category.name}
              </Box>
            </Tabs.Tab>
          );
        })}
      </Tabs>

      <Section
        title={
          isSearching
            ? `Search Results (${visibleJobs.length})`
            : currentCategory?.name || 'Classes'
        }
      >
        <Table>
          <Table.Row header>
            <Table.Cell width="38%">Class</Table.Cell>
            <Table.Cell width="20%">Options</Table.Cell>
            <Table.Cell width="42%">Priority</Table.Cell>
          </Table.Row>

          {visibleJobs.length === 0 ? (
            <Table.Row>
              <Table.Cell colSpan={3}>
                <Box color="label" italic>
                  No classes match this search.
                </Box>
              </Table.Cell>
            </Table.Row>
          ) : null}

          {visibleJobs.map((job) => {
            const state = getJobState(job);
            const isExpanded = expandedJob === job.title;
            const hasTitles = job.title_choices.length > 1;
            const hasHonoraries = job.honorary_choices.length > 1;
            const canCustomize =
              state.status === 'available' && (hasTitles || hasHonoraries);

            return (
              <Fragment key={job.title}>
                <Table.Row>
                  <Table.Cell
                    py={0.5}
                    style={{
                      borderLeft: `3px solid ${categoryColorFor(job) || 'transparent'}`,
                      paddingLeft: '7px',
                    }}
                  >
                    <span title={job.has_info ? 'Click for class details' : undefined}>
                      <Box
                        bold={state.status === 'available'}
                        style={
                          job.has_info
                            ? { textDecoration: 'underline', cursor: 'pointer' }
                            : undefined
                        }
                        onClick={
                          job.has_info
                            ? () => act('job_explain', { job: job.title })
                            : undefined
                        }
                      >
                        {state.status === 'available'
                          ? state.current_title
                          : state.display_name}
                      </Box>
                    </span>
                    {state.current_honorary ? (
                      <Box color="label" fontSize="11px">
                        Honorary: {state.current_honorary}
                      </Box>
                    ) : null}
                    <span title={job.tutorial}>
                      <Box color="label" fontSize="11px">
                        {job.slots} slot{job.slots === 1 ? '' : 's'}
                      </Box>
                    </span>
                    {state.status === 'banned' ? (
                      <Box color="bad" fontSize="11px" bold>
                        BANNED
                      </Box>
                    ) : null}
                    {state.status === 'locked' ? (
                      <Box color="average" fontSize="11px">
                        <Box bold>{state.lock_label}</Box>
                        {state.lock_detail?.map((line) => (
                          <Box key={line}>{line}</Box>
                        ))}
                      </Box>
                    ) : null}
                  </Table.Cell>

                  <Table.Cell py={0.5}>
                    {canCustomize ? (
                      <Button
                        icon="id-badge"
                        selected={isExpanded}
                        onClick={() => {
                          setExpandedJob(isExpanded ? null : job.title);
                          setExtraTab(hasTitles ? 'titles' : 'honorary');
                        }}
                      >
                        {isExpanded ? 'Close' : 'Customize'}
                      </Button>
                    ) : null}
                  </Table.Cell>

                  <Table.Cell py={0.5}>
                    {state.status === 'available'
                      ? priorityLevels.map((level) => {
                          const selected =
                            (state.pref_level ?? null) === level.value;
                          return (
                            <Button
                              key={level.value ?? 'never'}
                              selected={selected}
                              color={selected ? 'good' : 'transparent'}
                              disabled={!!data.job_changes_locked}
                              onClick={() =>
                                act('job_set_pref_level', {
                                  job: job.title,
                                  level: level.value,
                                })
                              }
                            >
                              {level.label}
                            </Button>
                          );
                        })
                      : null}
                  </Table.Cell>
                </Table.Row>

                {isExpanded ? (
                  <Table.Row>
                    <Table.Cell
                      colSpan={3}
                      style={{
                        backgroundColor: 'rgba(0, 0, 0, 0.18)',
                        padding: '8px',
                      }}
                    >
                      <Box mb={1}>
                        {hasTitles ? (
                          <Button
                            compact
                            selected={extraTab === 'titles'}
                            onClick={() => setExtraTab('titles')}
                          >
                            Alternate Title
                          </Button>
                        ) : null}
                        {hasHonoraries ? (
                          <Button
                            compact
                            ml={hasTitles ? 0.5 : 0}
                            selected={extraTab === 'honorary'}
                            onClick={() => setExtraTab('honorary')}
                          >
                            Honorary Prefix
                          </Button>
                        ) : null}
                      </Box>

                      {extraTab === 'titles' && hasTitles
                        ? job.title_choices.map((choice) => {
                            const selected =
                              state.current_title === choice.value;
                            return (
                              <Button
                                key={choice.value}
                                selected={selected}
                                color={selected ? 'good' : 'transparent'}
                                disabled={!!data.job_changes_locked}
                                onClick={() =>
                                  act('job_set_alt', {
                                    job: job.title,
                                    category: 'title',
                                    value: choice.value,
                                  })
                                }
                              >
                                {choice.value}
                              </Button>
                            );
                          })
                        : null}

                      {extraTab === 'honorary' && hasHonoraries
                        ? job.honorary_choices.map((choice) => {
                            const selected =
                              state.current_honorary === choice.value;
                            return (
                              <Button
                                key={choice.value || 'none'}
                                selected={selected}
                                color={selected ? 'good' : 'transparent'}
                                disabled={!!data.job_changes_locked}
                                onClick={() =>
                                  act('job_set_alt', {
                                    job: job.title,
                                    category: 'honorary',
                                    value: choice.value,
                                  })
                                }
                              >
                                {choice.value || 'None'}
                              </Button>
                            );
                          })
                        : null}
                    </Table.Cell>
                  </Table.Row>
                ) : null}
              </Fragment>
            );
          })}
        </Table>
      </Section>
    </>
  );
};
