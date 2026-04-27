---
name: Script 68 strict JSON schema validation
description: add-user-from-json.sh now rejects records with wrong types or missing required fields instead of silently ignoring them
type: feature
---

# Script 68 -- Strict JSON schema validation (v0.170.0)

`scripts-linux/68-user-mgmt/add-user-from-json.sh` previously accepted
malformed `sshKeys` / `sshKeyFiles` (and other typed fields) by silently
dropping bad entries. Now every record passes through `_validate_user_record`
which produces precise error messages and rejects the whole record on any
type/empty/missing violation.

## What is validated

| Field          | Rule |
|----------------|------|
| `name`         | REQUIRED, non-empty string |
| `password`     | OPTIONAL, non-empty string |
| `passwordFile` | OPTIONAL, non-empty string |
| `uid`          | OPTIONAL, non-negative integer (number OR numeric string) |
| `shell`        | OPTIONAL, non-empty string |
| `home`         | OPTIONAL, non-empty string |
| `comment`      | OPTIONAL, string (may be empty) |
| `primaryGroup` | OPTIONAL, non-empty string |
| `groups`       | OPTIONAL, array of non-empty strings |
| `sudo`         | OPTIONAL, boolean |
| `system`       | OPTIONAL, boolean |
| `sshKeys`      | OPTIONAL, array of non-empty strings |
| `sshKeyFiles`  | OPTIONAL, array of non-empty strings |
| top-level      | record MUST be a JSON object (bare strings/numbers rejected) |
| unknown fields | WARN (not error) -- typo guard, lists allowed fields |

## Single-pass jq validator

`_validate_user_record` runs ONE jq invocation per record (not 13). It
emits TSV rows: `ERROR<TAB>field<TAB>reason` or `WARN<TAB>field<TAB>reason`.
For array elements the field carries the index: `sshKeys[2]`. The shell
loop maps each row to the correct templated message and counts errors.

## Message templates added to log-messages.json

- `schemaFieldType`     -- wrong type, expected X got Y
- `schemaFieldEmpty`    -- empty/null where non-empty required
- `schemaArrayItemType` -- bad item inside an array (with index + value)
- `schemaUnknownField`  -- typo guard (warning, not error)
- `schemaRecordRejected`-- final per-record summary line
- `schemaTopLevelType`  -- record is not an object

## Verified end-to-end

Torture-test JSON with 18 records covering every failure mode. Result:
- **5 valid records** flowed through to add-user.sh (alice/henry/mia/noah/olivia)
- **13 invalid records** produced loud per-error messages and were rejected
- **Final exit code: 1** (was 0 before -- silent failure)
- **Per-error precision**:
  - `sshKeys: ["good", 42, "", null, true]` -> 4 separate errors
    naming index, type, and value of each bad element
  - `sshKeys: "string"` -> "expected array, got string -- did you forget
    the [...] brackets?" (helpful hint)
  - `uid: "abc"` -> "string is not numeric"
  - `uid: -5`    -> "not a non-negative integer"
  - `sudo: "yes"`-> "expected boolean, got string"
  - typos `shel`/`primary_group`/`extraField` -> 3 warnings, not errors

## Backwards compatibility

- `sshKeys: []` (empty array) is still a valid no-op
- `comment: ""` is still allowed (only field where empty string is OK)
- All existing valid JSON files in `examples/` continue to work unchanged
- `groups` was previously a soft-typecheck via `if has() and array else ""`
  -- now it's a hard reject if not an array
