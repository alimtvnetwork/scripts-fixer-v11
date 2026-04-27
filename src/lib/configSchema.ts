import { z } from "zod";

// Schema for the user-selectable options in the Settings page.
// Mirrors what the bridge accepts and what we store in config_presets.options.
export const editionSchema = z.enum(["stable", "insiders"]);

export const script52OptionsSchema = z.object({
  enabledEditions: z
    .array(editionSchema)
    .min(1, { message: "Pick at least one edition" })
    .max(2, { message: "At most two editions" }),
  requireAdmin: z.boolean(),
  nonInteractive: z.boolean(),
  requireSignature: z.boolean(),
});

export type Script52Options = z.infer<typeof script52OptionsSchema>;
