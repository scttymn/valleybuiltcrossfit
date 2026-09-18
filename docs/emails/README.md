# PushPress Grow email templates

These are pasted into the workflow's email actions in PushPress Grow (HTML/source
block, not the rich-text editor). They're kept here so we still have them if the
templates are ever lost or need editing.

- `confirmation.html` — sent to the person who submitted the inquiry form.
- `internal-notification.html` — sent to the gym, with the answers and what to do next.

Merge tags come from Grow's contact custom fields: `starting_from`,
`interested_in`, `who_is_joining`, `notes`. The website sends those names in its
webhook payload (see `Lead#webhook_payload`).
