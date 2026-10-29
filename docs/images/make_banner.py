"""Draws docs/images/banner.png: concept of the generalized Point Method at an interlocking corner.
Left: one dovetail tooth with the L/2 loci of both materials. Right: schematic stress decay near a
sharp corner and a smooth interface, evaluated at the critical distance. Illustrative curves only.
Requirements: numpy, matplotlib, shapely.  Usage: python make_banner.py"""
import numpy as np, matplotlib; matplotlib.use('Agg')
import matplotlib.pyplot as plt
from shapely.geometry import LineString, Polygon
C = {'a': '#2A9D8F', 'b': '#E9C46A', 'ink': '#1F2933', 'acc': '#E76F51', 'grid': '#D9DEE3'}
fig = plt.figure(figsize=(15, 4.6), dpi=150)
# ---------- left: one dovetail tooth with L/2 loci and critical points
ax = fig.add_axes([0.01, 0.03, 0.44, 0.94])
lam, A = 4.0, 0.6; d = 2*A*np.tan(np.radians(15)); wt, wb = lam/2 + d, lam/2 - d
P = np.array([p for k in range(-1, 3) for c in [k*lam + lam/2]
              for p in [(c - wb/2, -A), (c - wt/2, A), (c + wt/2, A), (c + wb/2, -A)]])
line = LineString(P); H = 3.0
top = Polygon(list(P) + [(P[-1, 0], H), (P[0, 0], H)]); bot = Polygon(list(P) + [(P[-1, 0], -H), (P[0, 0], -H)])
ax.fill(*top.exterior.xy, color=C['a'], alpha=0.9, lw=0); ax.fill(*bot.exterior.xy, color=C['b'], alpha=0.95, lw=0)
for dist, poly in [(1.0, top), (0.5, bot)]:
    ring = line.buffer(dist, quad_segs=48).exterior.intersection(poly.buffer(-1e-6))
    for g in getattr(ring, 'geoms', [ring]):
        if g.length > 0.05: ax.plot(*g.xy, color='white', lw=1.6, ls=(0, (5, 3)))
ax.plot(P[:, 0], P[:, 1], color=C['ink'], lw=2.6)
c = lam/2
for dist, poly, corner in [(1.0, top, (c - wt/2, A)), (0.5, bot, (c + wb/2, -A))]:
    ring = line.buffer(dist, quad_segs=48).exterior.intersection(poly.buffer(-1e-6))
    pts = np.vstack([np.array(g.coords) for g in getattr(ring, 'geoms', [ring]) if g.length > 0.05])
    k = np.argmin(np.hypot(pts[:, 0] - corner[0], pts[:, 1] - corner[1]))
    ax.plot(*pts[k], marker='*', ms=17, color=C['acc'], mec='white', mew=1.2, zorder=5)
ax.text(c, 2.2, 'material A', ha='center', va='center', fontsize=13, color='white', fontweight='bold')
ax.text(c, -2.2, 'material B', ha='center', va='center', fontsize=13, color=C['ink'], fontweight='bold')
ax.set_xlim(c - 3.6, c + 3.6); ax.set_ylim(-2.5, 2.5); ax.set_aspect('equal'); ax.axis('off')
# ---------- right: schematic stress decay and critical distance
bx = fig.add_axes([0.50, 0.18, 0.46, 0.70])
r = np.linspace(0.02, 3.0, 400); Lh = 1.0
sharp = 0.68 + 0.32*r**-0.39; smooth = 0.80 + 0.30*np.exp(-r/1.2) + 0.03
bx.plot(r, sharp, color=C['acc'], lw=2.8, label='sharp re-entrant corner')
bx.plot(r, smooth, color=C['a'], lw=2.8, label='smooth interface')
bx.axhline(1.0, color=C['ink'], lw=1.4, ls=(0, (6, 3)))
bx.axvline(Lh, color=C['ink'], lw=1.2, ls=(0, (2, 3)))
bx.plot(Lh, 0.68 + 0.32*Lh**-0.39, marker='*', ms=17, color=C['acc'], mec='white', mew=1.2, zorder=5)
bx.text(2.95, 0.975, 'inherent strength', ha='right', va='top', fontsize=11, color=C['ink'])
bx.text(Lh + 0.05, 1.62, 'L/2', ha='left', va='top', fontsize=13, color=C['ink'], fontweight='bold')
bx.set_xlim(0, 3.0); bx.set_ylim(0.7, 1.65); bx.set_xticks([]); bx.set_yticks([])
for s in ['top', 'right']: bx.spines[s].set_visible(False)
for s in ['left', 'bottom']: bx.spines[s].set_color(C['ink']); bx.spines[s].set_linewidth(1.4)
bx.set_xlabel('distance from the interface', fontsize=12, color=C['ink']); bx.set_ylabel('effective stress', fontsize=12, color=C['ink'])
bx.legend(frameon=False, fontsize=11, loc='upper right', bbox_to_anchor=(1.0, 0.92))
fig.savefig('banner.png', dpi=150, facecolor='white')
