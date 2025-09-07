#!/usr/bin/env bash
# find_homologs.sh (starter)
# usage: ./find_homologs.sh query.fna subject.fna out.tsv
set -euo pipefail
#!/usr/bin/env bash
if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <protein_query.faa> <nucleotide_subject.fna> <output.tsv>" >&2
  exit 1
fi

query="$1"
subject="$2"
out="$3"

tblastn \
  -query "$query" \
  -subject "$subject" \
  -outfmt '6 std qlen' \
| awk '($3 > 30) && ($4 >= 0.9*$NF)' > "$out"

wc -l < "$out"
