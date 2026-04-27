-- Stored option presets for the Settings page.
-- Anyone can create a preset and anyone with its ID can load it.
-- No auth required: presets contain only non-sensitive config choices.
CREATE TABLE public.config_presets (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  script_id   TEXT NOT NULL,
  label       TEXT NOT NULL DEFAULT 'Untitled preset',
  options     JSONB NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT config_presets_label_len   CHECK (char_length(label) BETWEEN 1 AND 120),
  CONSTRAINT config_presets_script_len  CHECK (char_length(script_id) BETWEEN 1 AND 32),
  -- Cap payload size so anonymous writes can't bloat the table.
  CONSTRAINT config_presets_options_size CHECK (octet_length(options::text) <= 16384)
);

CREATE INDEX config_presets_script_id_created_idx
  ON public.config_presets (script_id, created_at DESC);

-- Auto-bump updated_at on row change
CREATE OR REPLACE FUNCTION public.touch_config_presets_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER config_presets_set_updated_at
  BEFORE UPDATE ON public.config_presets
  FOR EACH ROW EXECUTE FUNCTION public.touch_config_presets_updated_at();

-- RLS: open read + open insert/update/delete by ID. No user_id column,
-- so possession of the UUID is the only access control.
ALTER TABLE public.config_presets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read presets"
  ON public.config_presets FOR SELECT
  USING (true);

CREATE POLICY "Anyone can create presets"
  ON public.config_presets FOR INSERT
  WITH CHECK (true);

CREATE POLICY "Anyone can update presets"
  ON public.config_presets FOR UPDATE
  USING (true) WITH CHECK (true);

CREATE POLICY "Anyone can delete presets"
  ON public.config_presets FOR DELETE
  USING (true);