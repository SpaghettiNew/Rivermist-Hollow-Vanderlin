/**
 * @file
 * @copyright 2020 Aleksej Komarov
 * @license MIT
 */

import { useAtomValue } from 'jotai';
import { backendStateAtom } from '../events/store';
import { selectDebug } from './selectors';

export function useDebug() {
  return selectDebug(useAtomValue(backendStateAtom));
}
