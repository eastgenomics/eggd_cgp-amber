# eggd_cgp-amber

[AMBER](https://github.com/hartwigmedical/hmftools/tree/master/amber) (Hartwig Medical Foundation, v4.3-beta.4) tumour-only B-allele-frequency (BAF) caller,
packaged as a DNAnexus app. It is **stage 2** (parallel with COBALT/SAGE) of the
[`eggd_atlas_cnv`](https://github.com/eastgenomics/eggd_atlas_cnv) somatic CNV workflow: it
measures BAF at germline heterozygous sites, which PURPLE later uses to fit purity/ploidy and
copy number.

## What it does

Runs `amber.jar` in tumour-only mode over a supplied germline het-site loci file, then packages
the AMBER output directory as a single tar for the downstream PURPLE stage.

## Inputs

| Name | Class | Description |
|---|---|---|
| `tumour_bam` | file | Tumour BAM (chr-prefixed GRCh38) |
| `tumour_bai` | file | BAM index |
| `sample_id` | string | Output file stem |
| `amber_jar` | file | AMBER 4.3-beta.4 JAR |
| `germline_sites` | file | `AmberGermlineSites.38.tsv.gz` (chr-prefixed) |

## Outputs

| Name | Class | Description |
|---|---|---|
| `amber_tar` | file | `{sample_id}.amber.tar.gz` — the AMBER output directory |

## Run example

```bash
dx run eggd_cgp-amber \
  -itumour_bam=... -itumour_bai=... -isample_id=25330S0047 \
  -iamber_jar=... -igermline_sites=...
```

## Notes

- **GRCh38 only**: `tumour_bam` and `germline_sites` must use GRCh38 (`chr`-prefixed contigs); the app passes `-ref_genome_version 38` to AMBER and will fail the pre-flight chr check if the BAM lacks `chr`-prefixed contigs.
- Tumour-only (`-ref_sample_count` not applicable); `-tumor_min_depth 10`,
  `-bam_validation LENIENT`, `-ref_genome_version 38`.
- System deps come from `execDepends` (no run-time `apt-get`).

See the versioned build/validation documentation in the CUH Bioinformatics Documentation Vault.
