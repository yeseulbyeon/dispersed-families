#!/bin/bash
# Reproducible collector for the isan gajok (이산가족) lexicalization analysis.
# Pulls per-period article counts and sample headlines from NAVER News Library
# (newslibrary.naver.com), the OCR'd South Korean press archive 1920-1999.
#
# Uses the two JSON endpoints behind the public search page:
#   GET  /api/search/countByPeriod/json?keyword=<kw>     -> {year,month,articleCount}
#   POST /api/search/article/json  (keyword,page,pageSize,startDate,endDate,order,detailCode)
#
# KEY METHOD NOTE: quote the keyword ("이산가족") to force ADJACENCY. Unquoted, NAVER
# matches 이산 and 가족 as separate tokens and overcounts (12,379 vs 10,898).
#
# Usage:  ./collect_isan.sh        (writes raw_json/, data/, prints summary)
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p raw_json data
UA="dispersed-families research script (academic, low-volume)"
REF="https://newslibrary.naver.com/search/searchByKeyword.naver"
CNT="https://newslibrary.naver.com/api/search/countByPeriod/json"
ART="https://newslibrary.naver.com/api/search/article/json"
DC="11111000010000011100011011000100111100100101"   # detailCode (all sections/types)

# ---- count series: label  keyword ----
count () {  # $1=label  $2=keyword(quote it yourself for adjacency)
  curl -sf -A "$UA" -H "Referer: $REF" \
    -G "$CNT" --data-urlencode "keyword=$2" --max-time 60 -o "raw_json/$1.json"
  python3 - "$1" "$2" <<'PY'
import json,sys
lbl,kw=sys.argv[1],sys.argv[2]
cu=json.load(open(f"raw_json/{lbl}.json"))['result'].get('countUnits')
tot=sum(int(x['articleCount']) for x in cu['countUnit']) if cu else 0
print(f"  {lbl:18s} {kw:16s} total={tot}")
PY
}

echo "== count series (quoted = exact-phrase adjacency) =="
count q_compound        '"이산가족"'
count u_compound        '이산가족'        # unquoted series: overcount comparison only
count u_spaced          '이산 가족'
count u_doen            '이산된 가족'
count u_doen_ns         '이산된가족'
count q_isan_kajok_han  '"離散家族"'
count q_doen            '"이산된 가족"'
count q_heutojin        '"흩어진 가족"'
count q_heeojin         '"헤어진 가족"'
count q_nambuk_isan     '"남북이산가족"'
count q_risan           '"리산가족"'
count q_pungnam_risan   '"북남리산가족"'
count pinanmin          '피난민'
count silhyangmin       '실향민'
count wolnammin         '월남민'
count ref_jeongbu       '정부'
count ref_sahoe         '사회'

# ---- sample headlines (attestation tables) ----
articles () {  # $1=outfile $2=keyword $3=start $4=end
  curl -sf -A "$UA" -H "Referer: $REF" \
    -H "Content-Type: application/x-www-form-urlencoded; charset=UTF-8" \
    --data-urlencode "keyword=$2" \
    --data "page=1&startDate=$3&endDate=$4&order=00020&detailCode=$DC&pageSize=100&officeId=&includeSectionId=&includeEntityId=&genre=&startPageNo=&searchRange=" \
    "$ART" --max-time 60 -o "raw_json/$1.json"
}
articles L_pre   '"이산가족"' '1963-01-01' '1970-12-31'
articles L_aug71 '"이산가족"' '1971-08-01' '1971-08-31'

# ---- build CSVs + markdown tables ----
python3 - <<'PY'
import json,csv,re,os
def monthly(l):
    cu=json.load(open(f"raw_json/{l}.json"))['result'].get('countUnits'); o={}
    if cu:
        for x in cu['countUnit']: o[(int(x['year']),int(x['month']))]=int(x['articleCount'])
    return o
def yearly(m):
    y={}
    for (a,b),c in m.items(): y[a]=y.get(a,0)+c
    return y
series=['q_compound','q_isan_kajok_han','q_doen','q_heutojin','q_heeojin','q_nambuk_isan',
        'q_risan','q_pungnam_risan','pinanmin','silhyangmin','wolnammin','ref_jeongbu','ref_sahoe']
Y={s:yearly(monthly(s)) for s in series}
with open('data/isan_yearly_counts.csv','w',newline='',encoding='utf-8') as f:
    w=csv.writer(f); w.writerow(['year']+series)
    for yr in range(1945,2000): w.writerow([yr]+[Y[s].get(yr,0) for s in series])
mc=monthly('q_compound')
with open('data/isan_compound_monthly_1969_1973.csv','w',newline='',encoding='utf-8') as f:
    w=csv.writer(f); w.writerow(['year','month','count'])
    for yr in range(1969,1974):
        for mo in range(1,13): w.writerow([yr,mo,mc.get((yr,mo),0)])
def arts(p):
    d=json.load(open(p))['result']; a=d.get('articles')
    if a is None: return []
    if isinstance(a,dict): a=a.get('article',[])
    if isinstance(a,dict): a=[a]
    return a or []
clean=lambda s: re.sub('<[^>]+>','',s or '').strip()
def rows(p): return sorted((a.get('publishDate','?'),a.get('officeName','?'),f"{a.get('pageNo','?')}면",
                            clean(a.get('translatedTitle') or a.get('title'))) for a in arts(p))
lit=lambda t: ('離散家族' in t) or ('이산가족' in t)
with open('data/table_pre1971_attestations.md','w',encoding='utf-8') as f:
    f.write("| Date | Paper | Page | Headline | 離散家族 in title |\n|---|---|---|---|:--:|\n")
    for d,o,p,t in rows('raw_json/L_pre.json'): f.write(f"| {d} | {o} | {p} | {t} | {'✔' if lit(t) else ''} |\n")
with open('data/table_aug1971_headlines.md','w',encoding='utf-8') as f:
    f.write("All articles matching \"이산가족\" in Aug 1971. The match is in the article text; "
            "the headline itself may not contain the term.\n\n")
    f.write("| Date | Paper | Page | Headline | 離散家族 in title |\n|---|---|---|---|:--:|\n")
    for d,o,p,t in rows('raw_json/L_aug71.json'): f.write(f"| {d} | {o} | {p} | {t} | {'✔' if lit(t) else ''} |\n")
print("wrote data/*.csv and data/table_*.md")
PY
echo "Done. Run 'python3 plot_isan.py' to regenerate figures/."
