import { useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { RadioGroup, RadioGroupItem } from "@/components/ui/radio-group";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { toast } from "@/hooks/use-toast";
import baseConfig from "../../scripts/52-vscode-folder-repair/config.json";

type Edition = "stable" | "insiders";

const Settings = () => {
  const [edition, setEdition] = useState<Edition>("stable");
  const [adminOnly, setAdminOnly] = useState(true);
  const [nonInteractive, setNonInteractive] = useState(false);
  const [requireSignature, setRequireSignature] = useState(false);

  const merged = useMemo(
    () => ({
      ...(baseConfig as Record<string, unknown>),
      enabledEditions: [edition],
      requireAdmin: adminOnly,
      nonInteractive,
      requireSignature,
    }),
    [edition, adminOnly, nonInteractive, requireSignature],
  );

  const handleDownload = () => {
    try {
      const blob = new Blob([JSON.stringify(merged, null, 2)], { type: "application/json" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "config.json";
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
      toast({
        title: "config.json generated",
        description: "Drop it into scripts/52-vscode-folder-repair/ to apply.",
      });
    } catch (err) {
      const reason = err instanceof Error ? err.message : String(err);
      // CODE RED: include exact path + reason
      toast({
        title: "Download failed",
        description: `path: scripts/52-vscode-folder-repair/config.json — reason: ${reason}`,
        variant: "destructive",
      });
    }
  };

  return (
    <main className="min-h-screen bg-background px-6 py-12">
      <div className="mx-auto max-w-2xl space-y-6">
        <header className="space-y-2">
          <Link to="/" className="text-sm text-muted-foreground hover:text-foreground">
            ← Back
          </Link>
          <h1 className="text-3xl font-bold tracking-tight">Script 52 settings</h1>
          <p className="text-sm text-muted-foreground">
            Configure VS Code folder context-menu repair, then download a merged{" "}
            <code className="rounded bg-muted px-1 py-0.5 text-xs">config.json</code>.
          </p>
        </header>

        <Card>
          <CardHeader>
            <CardTitle>Edition</CardTitle>
            <CardDescription>Which VS Code build to target.</CardDescription>
          </CardHeader>
          <CardContent>
            <RadioGroup
              value={edition}
              onValueChange={(v) => setEdition(v as Edition)}
              className="grid grid-cols-2 gap-3"
            >
              <Label
                htmlFor="ed-stable"
                className="flex cursor-pointer items-center gap-3 rounded-md border border-border p-4 hover:bg-accent"
              >
                <RadioGroupItem id="ed-stable" value="stable" />
                <div>
                  <div className="font-medium">Stable</div>
                  <div className="text-xs text-muted-foreground">Open with Code</div>
                </div>
              </Label>
              <Label
                htmlFor="ed-insiders"
                className="flex cursor-pointer items-center gap-3 rounded-md border border-border p-4 hover:bg-accent"
              >
                <RadioGroupItem id="ed-insiders" value="insiders" />
                <div>
                  <div className="font-medium">Insiders</div>
                  <div className="text-xs text-muted-foreground">Open with Code - Insiders</div>
                </div>
              </Label>
            </RadioGroup>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Behavior</CardTitle>
            <CardDescription>Switches passed to script 52 at run time.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <ToggleRow
              id="admin"
              label="Admin-only"
              hint="Refuse to run unless launched from an elevated PowerShell."
              checked={adminOnly}
              onChange={setAdminOnly}
            />
            <Separator />
            <ToggleRow
              id="ci"
              label="Non-interactive (CI mode)"
              hint="Suppress all prompts. Safe defaults are used."
              checked={nonInteractive}
              onChange={setNonInteractive}
            />
            <Separator />
            <ToggleRow
              id="sig"
              label="Require Authenticode signature"
              hint="Verify the VS Code executable is signed before writing registry."
              checked={requireSignature}
              onChange={setRequireSignature}
            />
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Preview</CardTitle>
            <CardDescription>Generated config.json (existing keys preserved).</CardDescription>
          </CardHeader>
          <CardContent>
            <pre className="max-h-72 overflow-auto rounded-md bg-muted p-4 text-xs">
              {JSON.stringify(merged, null, 2)}
            </pre>
          </CardContent>
        </Card>

        <div className="flex justify-end gap-3">
          <Button variant="outline" asChild>
            <Link to="/">Cancel</Link>
          </Button>
          <Button onClick={handleDownload}>Download config.json</Button>
        </div>
      </div>
    </main>
  );
};

const ToggleRow = ({
  id,
  label,
  hint,
  checked,
  onChange,
}: {
  id: string;
  label: string;
  hint: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) => (
  <div className="flex items-start justify-between gap-4">
    <div className="space-y-0.5">
      <Label htmlFor={id} className="text-sm font-medium">
        {label}
      </Label>
      <p className="text-xs text-muted-foreground">{hint}</p>
    </div>
    <Switch id={id} checked={checked} onCheckedChange={onChange} />
  </div>
);

export default Settings;
