# Changelog

## 1.0.0
Initial app release. Converted from the `cnv-backbone-purple-atlas` `cgp-amber` **applet**
into a versioned, namespaced DNAnexus **app** (`org-emee_1`, `aws:eu-central-1`) for the
`eggd_atlas_cnv` somatic CNV workflow.

Conversion changes only:
- App metadata (`version`, `developers`, `authorizedUsers`).
- Explicit `timeoutPolicy` (6 h).
- System dependencies moved from an inline `apt-get install` in `code.sh` to
  `runSpec.execDepends` (`openjdk-21-jre-headless`, `samtools`, `tabix`) — no run-time network.

AMBER tool flags, reference inputs and the output name (`amber_tar`) are unchanged from the
applet, so downstream links and legacy validation are preserved.
