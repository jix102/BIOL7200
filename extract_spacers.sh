#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <repeat_query.fna> <assembly_subject.fna> <output_spacers.fna>" >&2
  exit 1
fi

query="$1"      
subject="$2"  
out="$3"      

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

blastn -task blastn-short \
  -query "$query" \
  -subject "$subject" \
  -outfmt '6 sseqid sstart send length qlen pident' \
| awk '($6==100) && ($4==$5)' \
> "$tmpdir/hits.tsv"

awk '{
  s = ($2<$3 ? $2 : $3);  # min(sstart, send)
  e = ($2<$3 ? $3 : $2);  # max(sstart, send)
  start0 = s-1;
  end0   = e;             # because BED end is exclusive
  print $1 "\t" start0 "\t" end0
}' "$tmpdir/hits.tsv" \
| sort -k1,1 -k2,2n \
> "$tmpdir/hits.bed"

tail -n +2 "$tmpdir/hits.bed" > "$tmpdir/hits_next.bed" || true
paste "$tmpdir/hits.bed" "$tmpdir/hits_next.bed" 2>/dev/null \
| awk '($1==$4) && ($5>$3) { print $1 "\t" $3 "\t" $5 }' \
> "$tmpdir/spacers.bed"

if [[ -s "$tmpdir/spacers.bed" ]]; then
  seqtk subseq "$subject" "$tmpdir/spacers.bed" > "$out"
else
  : > "$out"
fi

wc -l < "$tmpdir/spacers.bed"
