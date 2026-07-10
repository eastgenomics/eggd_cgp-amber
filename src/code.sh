#!/bin/bash
# eggd_cgp-amber v1.0.0 — AMBER 4.3-beta.4 tumour-only BAF
# Converted from cgp-amber applet: metadata + timeoutPolicy + execDepends.
# Tool flags and output names are FROZEN (downstream links depend on them).
set -euo pipefail

main() {
    # Reject unsafe sample_id (used as dir/file/tar names and the AMBER tumour name)
    case "${sample_id}" in
        *[!A-Za-z0-9._-]* | "" | .* | -* )
            echo "ERROR: unsafe sample_id '${sample_id}' (allowed: A-Za-z0-9._-, no leading '-'/'.')" >&2; exit 1 ;;
    esac
    echo "====================================================="
    echo " eggd_cgp-amber: AMBER tumour-only BAF"
    echo " Sample  : ${sample_id}"
    echo "====================================================="

    # ── 1. Download inputs ──────────────────────────────────────────────────
    # (system deps come from execDepends — no run-time apt-get)
    java     -version  2>&1 | sed -n '1p'
    samtools --version 2>&1 | sed -n '1p'

    echo "[1/4] Downloading inputs..."
    dx download "${tumour_bam}"     -o tumour.bam                  & pid_bam=$!
    dx download "${tumour_bai}"     -o tumour.bam.bai              & pid_bai=$!
    dx download "${amber_jar}"      -o amber.jar                   & pid_jar=$!
    dx download "${germline_sites}" -o germline_sites.tsv.gz       & pid_sites=$!
    wait "${pid_bam}"   || { echo "ERROR: failed to download tumour_bam"     >&2; exit 1; }
    wait "${pid_bai}"   || { echo "ERROR: failed to download tumour_bai"     >&2; exit 1; }
    wait "${pid_jar}"   || { echo "ERROR: failed to download amber_jar"      >&2; exit 1; }
    wait "${pid_sites}" || { echo "ERROR: failed to download germline_sites" >&2; exit 1; }

    # Verify all chr-expected inputs have chr-prefixed contigs (GRCh38)
    # (use > /dev/null not grep -q to avoid SIGPIPE under set -o pipefail)
    if ! samtools view -H tumour.bam | grep '^@SQ.*SN:chr' > /dev/null; then
        echo "ERROR: tumour_bam does not have chr-prefixed contigs — expected GRCh38 with 'chr' prefix" >&2
        exit 1
    fi
    if ! zcat germline_sites.tsv.gz | grep '^chr[0-9XY]' > /dev/null; then
        echo "ERROR: germline_sites does not have chr-prefixed contigs — expected GRCh38 with 'chr' prefix" >&2
        exit 1
    fi

    # ── 2. Run AMBER ────────────────────────────────────────────────────────
    echo "[2/4] Running AMBER..."
    mkdir -p "${sample_id}"

    # Derive JVM heap from available RAM, leaving ~2 GiB headroom
    HEAP_MB=$(( $(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 - 2048 ))

    java -Xmx${HEAP_MB}m -jar amber.jar \
        -tumor             "${sample_id}" \
        -tumor_bam         tumour.bam \
        -loci              germline_sites.tsv.gz \
        -tumor_min_depth   10 \
        -bam_validation    LENIENT \
        -ref_genome_version 38 \
        -threads           "$(nproc)" \
        -output_dir        "${sample_id}/"

    # ── 3. Verify outputs ──────────────────────────────────────────────────
    echo "[3/4] Verifying outputs..."
    BAF_FILE="${sample_id}/${sample_id}.amber.baf.tsv.gz"
    PCF_FILE="${sample_id}/${sample_id}.amber.baf.pcf"
    [[ -s "${BAF_FILE}" ]] || { echo "ERROR: AMBER BAF TSV missing"; exit 1; }
    [[ -s "${PCF_FILE}" ]] || { echo "ERROR: AMBER BAF PCF missing (Java PCF failed?)"; exit 1; }

    SITES=$(zcat "${BAF_FILE}" | tail -n +2 | wc -l)
    echo "BAF sites: ${SITES}"
    [[ "${SITES}" -gt 0 ]] || { echo "ERROR: AMBER produced zero BAF sites — check loci file and BAM compatibility"; exit 1; }
    ls -lh "${sample_id}/"

    # ── 4. Tar and upload ──────────────────────────────────────────────────
    echo "[4/4] Uploading..."
    tar --no-same-owner -czf "${sample_id}.amber.tar.gz" "${sample_id}/"

    amber_tar=$(dx upload "${sample_id}.amber.tar.gz" --brief)
    dx-jobutil-add-output amber_tar "${amber_tar}" --class=file

    echo "====================================================="
    echo " eggd_cgp-amber DONE: ${sample_id}  sites=${SITES}"
    echo "====================================================="
}
