#!/usr/bin/env python3
"""Regenerate the two figures from data/*.csv (written by collect_isan.sh).
Usage: python3 plot_isan.py   ->  figures/annual_counts_1945-1999, monthly_counts_1969-1973 (.png/.svg/.pdf)
Requires matplotlib."""
import csv, os
import matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt

HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(HERE); os.makedirs('figures', exist_ok=True)

IG = r'$\mathit{isan\ gajok}$'  # italic term; DejaVu Sans (bundled) has a true italic
plt.rcParams.update({'font.family': 'DejaVu Sans', 'font.size': 11, 'axes.edgecolor': '#444',
                     'axes.linewidth': 0.8, 'figure.dpi': 150, 'savefig.dpi': 200,
                     'svg.fonttype': 'none', 'pdf.fonttype': 42})  # keep text editable in vector output

def save(fig, name, formats=('png', 'svg', 'pdf')):
    for ext in formats:
        fig.savefig(f'figures/{name}.{ext}', bbox_inches='tight')

rows = lambda p: list(csv.DictReader(open(p, encoding='utf-8')))
compY = {int(r['year']): int(r['q_compound']) for r in rows('data/isan_yearly_counts.csv')}
comp = {(int(r['year']), int(r['month'])): int(r['count'])
        for r in rows('data/isan_compound_monthly_1969_1973.csv')}
INK = '#1a1a1a'; ACC = '#7a1f1f'

# --- annual counts, 1945-1999 ---
fig, ax = plt.subplots(figsize=(9.2, 4.4))
yrs = list(range(1945, 2000)); vals = [compY.get(y, 0) for y in yrs]
ax.bar(yrs, vals, width=0.78, color=INK, zorder=3); ax.set_xlim(1944.3, 1999.7)
ax.set_ylim(0, max(vals) * 1.12)  # headroom so the 1983 label clears the title
ax.set_ylabel(f'Articles per year containing {IG}\n(contiguous compound, exact-phrase)', fontsize=10)
ax.set_xlabel('Year')
for sp in ['top', 'right']: ax.spines[sp].set_visible(False)
def ann(x, txt, dy=0, dx=0):
    y = compY.get(x, 0)
    ax.annotate(txt, xy=(x, y), xytext=(x + dx, y + 55 + dy), ha='center', fontsize=8.6,
                arrowprops=dict(arrowstyle='-', color=ACC, lw=0.9), color=ACC)
ann(1971, '1971.08\nKNRC proposes\nNorth–South\nfamily search', dy=120, dx=-4.5)  # dx keeps it off the 1972 bar
ann(1972, '1972\nNorth–South\nRed Cross\ntalks', dy=-10)
ann(1983, '1983\nKBS telethon\n“Finding Dispersed\nFamilies”', dy=-10)
ax.axvspan(1944.3, 1970.5, color='#ececec', zorder=0)
ax.text(1957, max(vals) * 0.74, 'pre-1971:\n30 articles total\n(mostly Japan-repatriation\nreferent)',
        ha='center', fontsize=8.3, color='#555', style='italic')
ax.set_title(f'The lexicalization of {IG} (“dispersed family”): annual press frequency, 1945–1999',
             fontsize=12, loc='left', pad=10)
ax.text(0.0, -0.20, f'Source: NAVER News Library — Chosŏn, Tonga, Kyunghyang, Maeil Kyŏngje, Hankyoreh. Exact-phrase query for {IG}.',
        transform=ax.transAxes, fontsize=7.3, color='#666')
tot = sum(vals); pre = sum(v for y, v in zip(yrs, vals) if y < 1971); post = tot - pre
ax.text(0.015, 0.975, f'n = {tot:,} articles total, 1945–1999\n({pre} before 1971  ·  {post:,} from 1971 on)',
        transform=ax.transAxes, ha='left', va='top', fontsize=8.6, color=INK,
        bbox=dict(boxstyle='round,pad=0.4', fc='white', ec='#cccccc', lw=0.6))
fig.tight_layout(); save(fig, 'annual_counts_1945-1999'); plt.close(fig)

# --- monthly counts, 1969-1973 ---
fig, ax = plt.subplots(figsize=(9.2, 3.6))
months = [(y, m) for y in range(1969, 1974) for m in range(1, 13)]
mv = [comp.get(k, 0) for k in months]; x = list(range(len(months)))
cols = [ACC if k == (1971, 8) else INK for k in months]
ax.bar(x, mv, width=0.82, color=cols, zorder=3)
ax.set_xticks([12 * i for i in range(5)]); ax.set_xticklabels(range(1969, 1974))
for i in range(0, len(months), 12): ax.axvline(i - 0.5, color='#ddd', lw=0.7, zorder=0)
a = months.index((1971, 8))
ax.annotate('Aug 1971\n83 articles in one month\n(0 in the preceding 7 months)', xy=(a, 83),
            xytext=(a - 10, 150), fontsize=8.6, color=ACC, arrowprops=dict(arrowstyle='->', color=ACC, lw=1))
for sp in ['top', 'right']: ax.spines[sp].set_visible(False)
ax.set_ylim(0, 215)
for yi, yr in enumerate(range(1969, 1974)):
    yt = sum(comp.get((yr, mo), 0) for mo in range(1, 13))
    ax.text(12 * yi + 5.5, 210, f'{yr} total\nn = {yt}', ha='center', va='top', fontsize=8.0, color='#555')
ax.set_ylabel('Articles per month'); ax.set_xlabel('Year')
ax.set_title(f'Inflection point: monthly frequency of {IG}, 1969–1973', fontsize=12, loc='left', pad=8)
fig.tight_layout(); save(fig, 'monthly_counts_1969-1973'); plt.close(fig)

print('wrote figures/annual_counts_1945-1999, monthly_counts_1969-1973  (png + svg + pdf)')
