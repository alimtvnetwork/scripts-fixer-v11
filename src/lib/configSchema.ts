import { z } from "zod";

// Schema for the options the Settings page can change in script-52 config.json.
// Mirrors the bridge's validation surface; keeps client + server in sync.
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

export const bridgeUrlSchema = z
  .string()
  .trim()
  .url({ message: "Bridge URL must be a valid URL" })
  .max(255)
  .refine(
    (u) => {
      try {
        const { hostname, protocol } = new URL(u);
        if (protocol !== "http:" && protocol !== "https:") return false;
        // Localhost only — never POST settings to a remote host
        return (
          hostname === "127.0.0.1" ||
          hostname === "localhost" ||
          hostname === "::1"
        );
      } catch {
        return false;
      }
    },
    { message: "Bridge URL must point to localhost (127.0.0.1)" },
  );

export const bridgeTokenSchema = z
  .string()
  .max(256, { message: "Token must be ≤ 256 chars" })
  // Disallow control chars and header-breaking newlines
  .regex(/^[\x20-\x7E]*$/, { message: "Token has invalid characters" });
