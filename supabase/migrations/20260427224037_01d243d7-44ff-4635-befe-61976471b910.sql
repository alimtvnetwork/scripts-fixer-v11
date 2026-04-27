-- 1. Lock down the trigger function's search_path
CREATE OR REPLACE FUNCTION public.touch_config_presets_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- 2. Replace the broad write policies with ID-scoped ones.
--    Writers must reference an existing row by its UUID (which is what
--    "load/share by ID" already requires), so bulk-mutation surface is reduced.
DROP POLICY IF EXISTS "Anyone can update presets" ON public.config_presets;
DROP POLICY IF EXISTS "Anyone can delete presets" ON public.config_presets;
DROP POLICY IF EXISTS "Anyone can create presets" ON public.config_presets;

-- INSERT: must supply a non-null id (client uses gen_random_uuid via default
-- or its own UUID), and label/script_id must be present (also enforced by
-- NOT NULL + CHECK constraints).
CREATE POLICY "Create preset with explicit fields"
  ON public.config_presets
  FOR INSERT
  WITH CHECK (
    script_id IS NOT NULL
    AND options IS NOT NULL
    AND label IS NOT NULL
  );

-- UPDATE: caller must target an existing row by its id and keep id/script_id stable.
CREATE POLICY "Update preset by id"
  ON public.config_presets
  FOR UPDATE
  USING (id IS NOT NULL)
  WITH CHECK (id IS NOT NULL AND script_id IS NOT NULL);

-- DELETE: caller must target an existing row by its id.
CREATE POLICY "Delete preset by id"
  ON public.config_presets
  FOR DELETE
  USING (id IS NOT NULL);