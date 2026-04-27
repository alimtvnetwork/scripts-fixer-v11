import { supabase } from "@/integrations/supabase/client";
import { script52OptionsSchema, type Script52Options } from "@/lib/configSchema";
import { z } from "zod";

export const presetLabelSchema = z
  .string()
  .trim()
  .min(1, { message: "Label cannot be empty" })
  .max(120, { message: "Label must be ≤ 120 characters" });

export interface ConfigPreset {
  id: string;
  scriptId: string;
  label: string;
  options: Script52Options;
  createdAt: string;
  updatedAt: string;
}

const TABLE = "config_presets";

const rowToPreset = (row: {
  id: string;
  script_id: string;
  label: string;
  options: unknown;
  created_at: string;
  updated_at: string;
}): ConfigPreset => {
  // Defensive: validate stored options against current schema. If the row was
  // created by an older schema, surface an error rather than crashing the UI.
  const parsed = script52OptionsSchema.safeParse(row.options);
  if (!parsed.success) {
    throw new Error(
      `path: preset ${row.id} — reason: stored options invalid (${parsed.error.issues[0].message})`,
    );
  }
  return {
    id: row.id,
    scriptId: row.script_id,
    label: row.label,
    options: parsed.data,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
};

export async function listPresets(scriptId: string): Promise<ConfigPreset[]> {
  const { data, error } = await supabase
    .from(TABLE)
    .select("id, script_id, label, options, created_at, updated_at")
    .eq("script_id", scriptId)
    .order("created_at", { ascending: false })
    .limit(50);
  if (error) throw new Error(`path: ${TABLE} — reason: ${error.message}`);
  return (data ?? []).map(rowToPreset);
}

export async function getPreset(id: string): Promise<ConfigPreset | null> {
  const { data, error } = await supabase
    .from(TABLE)
    .select("id, script_id, label, options, created_at, updated_at")
    .eq("id", id)
    .maybeSingle();
  if (error) throw new Error(`path: ${TABLE}/${id} — reason: ${error.message}`);
  if (!data) return null;
  return rowToPreset(data);
}

export async function createPreset(input: {
  scriptId: string;
  label: string;
  options: Script52Options;
}): Promise<ConfigPreset> {
  // Validate before sending — mirrors server CHECK constraints + RLS.
  const label = presetLabelSchema.parse(input.label);
  const options = script52OptionsSchema.parse(input.options);
  const { data, error } = await supabase
    .from(TABLE)
    .insert({ script_id: input.scriptId, label, options })
    .select("id, script_id, label, options, created_at, updated_at")
    .single();
  if (error) throw new Error(`path: ${TABLE} — reason: ${error.message}`);
  return rowToPreset(data);
}

export async function updatePreset(input: {
  id: string;
  label?: string;
  options?: Script52Options;
}): Promise<ConfigPreset> {
  const patch: Record<string, unknown> = {};
  if (input.label !== undefined) patch.label = presetLabelSchema.parse(input.label);
  if (input.options !== undefined) patch.options = script52OptionsSchema.parse(input.options);
  const { data, error } = await supabase
    .from(TABLE)
    .update(patch)
    .eq("id", input.id)
    .select("id, script_id, label, options, created_at, updated_at")
    .single();
  if (error) throw new Error(`path: ${TABLE}/${input.id} — reason: ${error.message}`);
  return rowToPreset(data);
}

export async function deletePreset(id: string): Promise<void> {
  const { error } = await supabase.from(TABLE).delete().eq("id", id);
  if (error) throw new Error(`path: ${TABLE}/${id} — reason: ${error.message}`);
}
