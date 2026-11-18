#!/usr/bin/env python3
"""Genera assets/dati/mappa.json, assets/mappa/aree.png (indice delle aree) e assets/mappa/mappa.jpg."""
import sys, json
import numpy as np, cv2
sys.path.insert(0, '/home/claude/work/tools')
from defs import *

W = '/home/claude/work/'
REPO = sys.argv[1]
names = json.load(open(W + 'areanames.json'))
M = np.load(W + 'areamasks_h.npy')
adj = json.load(open(W + 'adj2.json'))
auto = json.load(open(W + 'auto.json'))
H2, W2 = M.shape[1], M.shape[2]

ids = sorted(AREE[n][0] for n in names)
idx = {a: i + 1 for i, a in enumerate(ids)}
per_nome = {n: AREE[n][0] for n in names}

# indice delle aree, con i buchi (scritte, simboli, confini) riempiti dall'area più vicina
L = np.zeros((H2, W2), np.uint8)
for i, n in enumerate(names):
    L[M[i] > 0] = idx[per_nome[n]]
seab = cv2.resize(np.load(W + 'seab.npy').astype(np.uint8), (W2, H2), interpolation=cv2.INTER_NEAREST)
vuoto = (L == 0).astype(np.uint8)
dist, lab = cv2.distanceTransformWithLabels(vuoto, cv2.DIST_L2, 5, labelType=cv2.DIST_LABEL_PIXEL)
# mappa etichetta -> valore
ys, xs = np.nonzero(L)
val_per_lab = np.zeros(lab.max() + 1, np.uint8)
val_per_lab[lab[ys, xs]] = L[ys, xs]
riemp = val_per_lab[lab]
mask = (L == 0) & (dist < 14) & (seab == 0)
L[mask] = riemp[mask]
cv2.imwrite(REPO + '/assets/mappa/aree.png', np.dstack([np.zeros_like(L), np.zeros_like(L), L]))

img = cv2.imread(W + 'map_full.png')
cv2.imwrite(REPO + '/assets/mappa/mappa.jpg', cv2.resize(img, (4096, int(4096 * 3508 / 4967)), interpolation=cv2.INTER_AREA),
            [cv2.IMWRITE_JPEG_QUALITY, 86])

def coppie(lista):
    s = set()
    for a, b in lista:
        s.add((a, b)); s.add((b, a))
    return s

vic = {n: set() for n in names}
for a, b, c in adj:
    vic[a].add(b); vic[b].add(a)
for a, b in AGGIUNTE:
    vic[a].add(b); vic[b].add(a)
stretti = coppie(STRETTI)
alte = coppie(ALTA_MONTAGNA)
linee = coppie(LINEE_FORTIFICATE)
fiumi = coppie(FIUMI) | set(RENO)

aree = {}
for i, n in enumerate(names):
    aid, it, naz = AREE[n]
    m = np.pad(M[i], 1)
    d = cv2.distanceTransform(m, cv2.DIST_L2, 5)
    y, x = np.unravel_index(d.argmax(), d.shape)
    x, y = (x - 1) * 2, (y - 1) * 2
    if n in CENTRI:
        x, y = CENTRI[n]
    terr = []
    if n in FORESTA: terr.append('foresta')
    if n in PALUDE: terr.append('palude')
    if n in MONTAGNA: terr.append('montagna')
    if n in PASSO: terr.append('passo')
    mari = [s for s in auto['coast'].get(n, []) if s not in COSTE_TOLTE.get(n, [])] + COSTE_EXTRA.get(n, [])
    conf = {}
    for v in sorted(vic[n]):
        c = {}
        if (n, v) in fiumi: c['f'] = 1
        if (n, v) in stretti: c['s'] = 1
        if (n, v) in linee: c['l'] = 1
        if (n, v) in alte: c['a'] = 1
        if c: conf[per_nome[v]] = c
    a = {'n': it, 'naz': naz, 'x': round(x / 4967, 5), 'y': round(y / 3508, 5), 'idx': idx[aid],
         'vicini': sorted(per_nome[v] for v in vic[n]), 'mari': sorted(set(mari))}
    if terr: a['terr'] = terr
    if n in FORTEZZE: a['fort'] = 1
    if n in RIFORNIMENTO: a['rif'] = RIFORNIMENTO[n]
    if n in CHIAVE: a['chiave'] = CHIAVE[n]
    if n in CAPITALI: a['cap'] = CAPITALI[n]
    if n in EST: a['est'] = 1
    if conf: a['conf'] = conf
    aree[aid] = a

out = {
    'img': [4967, 3508],
    'aree': aree,
    'mari': MARI,
    'mari_adiacenti': MARI_ADIACENTI,
    'linee_sbarco': [[per_nome[a], per_nome[b]] for a, b in LINEE_SBARCO],
    'linee_med': [[per_nome[a], per_nome[b]] for a, b in MEDITERRANEO_LL],
    'sbarchi_d': {per_nome[k]: [per_nome.get(x, x) for x in v] for k, v in SBARCHI_D.items()},
    'sedi': SEDI,
}
json.dump(out, open(REPO + '/assets/dati/mappa.json', 'w'), ensure_ascii=False, indent=1)
print(len(aree), 'aree')
