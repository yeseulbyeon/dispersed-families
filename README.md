# 이산가족 (*isan gajok*) — Lexicalization Analysis

Press-frequency evidence that **"이산가족" ("dispersed family") became a fixed, institutionalized
term in August 1971**, from the NAVER News Library archive of the South Korean daily press. Supplement
to the "Dispersed Family" dissertation chapter.

## Figures
- `figures/monthly_counts_1969-1973.*` — 0 → 83 articles in August 1971.
- `figures/annual_counts_1945-1999.*` — annual counts, 1945–1999.

## Reproducing
```sh
python3 plot_isan.py     # figures from data/*.csv (matplotlib)
./collect_isan.sh        # re-pulls the counts from NAVER into data/ (curl + python3)
```
Queries must be **quoted** (`"이산가족"`) to force exact-phrase matching; unquoted, NAVER matches the
two words separately and overcounts (12,379 vs 10,898).

## Data
NAVER News Library (https://newslibrary.naver.com): Chosŏn, Tonga, Kyunghyang, Maeil Kyŏngje,
Hankyoreh. Retrieved 2026-06-23; NAVER may revise its index, so later pulls can differ.

## License
Code: MIT. Figures and data: CC BY 4.0. Cite via `CITATION.cff`.
