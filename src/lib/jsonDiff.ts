// Minimal JSON diff: compares two plain JSON values and returns a flat list
// of changes keyed by dot/bracket path. Good enough for showing a config
// preview before the user confirms a save.

export type DiffKind = "added" | "removed" | "changed" | "unchanged";

export interface DiffEntry {
  path: string;          // e.g. "behavior.requireAdmin" or "enabledEditions[0]"
  kind: DiffKind;
  before?: unknown;
  after?: unknown;
}

type Json = unknown;

const isObject = (v: Json): v is Record<string, Json> =>
  typeof v === "object" && v !== null && !Array.isArray(v);

const fmtKey = (parent: string, key: string) =>
  parent ? `${parent}.${key}` : key;

const fmtIdx = (parent: string, idx: number) => `${parent}[${idx}]`;

export function diffJson(before: Json, after: Json, path = ""): DiffEntry[] {
  // Strict-equal scalars / same reference
  if (Object.is(before, after)) {
    return path ? [{ path, kind: "unchanged", before, after }] : [];
  }

  // One side missing
  if (before === undefined) return [{ path, kind: "added", after }];
  if (after === undefined) return [{ path, kind: "removed", before }];

  // Both are objects -> recurse by key union
  if (isObject(before) && isObject(after)) {
    const keys = Array.from(new Set([...Object.keys(before), ...Object.keys(after)])).sort();
    return keys.flatMap((k) => diffJson(before[k], after[k], fmtKey(path, k)));
  }

  // Both are arrays -> recurse by index union
  if (Array.isArray(before) && Array.isArray(after)) {
    const max = Math.max(before.length, after.length);
    const out: DiffEntry[] = [];
    for (let i = 0; i < max; i++) {
      out.push(...diffJson(before[i], after[i], fmtIdx(path, i)));
    }
    return out;
  }

  // Type mismatch or differing scalars
  return [{ path, kind: "changed", before, after }];
}

export const summarizeDiff = (entries: DiffEntry[]) => {
  let added = 0, removed = 0, changed = 0;
  for (const e of entries) {
    if (e.kind === "added") added++;
    else if (e.kind === "removed") removed++;
    else if (e.kind === "changed") changed++;
  }
  return { added, removed, changed, total: added + removed + changed };
};
