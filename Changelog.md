# Changelog

## 2.0.0
Replace the vendor-shipped AMBER 4.3-beta.4 JAR with a locally patched rebuild of the
same version, fixing a non-deterministic PCF segmentation bug discovered during v1.0.0
T3 output-determinism testing.

**Root cause:** `PerArmSegmenter` concatenates chromosome-arm BAF values in
`HashMap.keySet()` order to compute a shared segmentation penalty (active when total
het-sites < 100,000, as is the case for targeted-capture sequencing). The `ChrArm` key's
`hashCode()` delegates to the JVM identity hash, which is not stable across separate JVM
process launches, so the concatenation order — and therefore the windowed-rolling-median
penalty calculation over it — can differ between otherwise identical runs.

**Fix:** one-line change in `hmf-common/PerArmSegmenter.java`: sort `mDataByArm.keySet()`
before concatenation. `ChrArm` already implements `Comparable<ChrArm>`, so the sort is
stable and well-defined. Reported upstream as hartwigmedical/hmftools#844.

No changes to `src/code.sh` or `dxapp.json` app logic — only the recommended `amber_jar`
input changes (use the patched build). Version bumped 1.0.0 → 2.0.0 to reflect the change
in the validated JAR artifact.

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
