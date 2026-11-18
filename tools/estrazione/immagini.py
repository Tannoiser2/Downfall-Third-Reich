#!/usr/bin/env python3
"""Ricava dal modulo TTS le immagini del gioco: pedine con i nomi in italiano, tessere sviluppo tradotte,
segnalini, plance. Uso: python3 immagini.py <cartella Mods/Images> <cartella del repository>"""
import sys, os, json, glob
import numpy as np, cv2
from PIL import Image, ImageDraw, ImageFont

SRC, REPO = sys.argv[1], sys.argv[2]
FONT = '/home/claude/fonts/'
files = sorted(glob.glob(SRC + '/*'))
files = [f for f in files if os.path.getsize(f) < 300000]

def im(i):
    return Image.open(files[i]).convert('RGBA')

# indice nel foglio -> (nome file, nazione per l'etichetta)
PEDINE = {
    7: ('BEL_f_3', 'Belgio'), 8: ('BEL_r_2', 'Belgio'),
    11: ('GB_c_6', 'Gran Bretagna'), 12: ('GB_cr_4', 'Gran Bretagna'), 13: ('GB_a_5', 'Gran Bretagna'), 14: ('GB_ar_3', 'Gran Bretagna'),
    15: ('GB_f_4', 'Gran Bretagna'), 16: ('GB_fr_2', 'Gran Bretagna'),
    17: ('BUL_f_3', 'Bulgaria'), 18: ('BUL_fr_2', 'Bulgaria'),
    47: ('FIN_f_4', 'Finlandia'), 48: ('FIN_fr_2', 'Finlandia'),
    49: ('FRA_a_5', 'Francia'), 50: ('FRA_ar_3', 'Francia'), 51: ('FRA_f_3', 'Francia'), 52: ('FRA_fr_2', 'Francia'),
    55: ('GER_c_8', 'Germania'), 56: ('GER_cr_5', 'Germania'), 59: ('GER_a_6', 'Germania'), 60: ('GER_ar_4', 'Germania'),
    61: ('DAK_a_7', None), 62: ('DAK_ar_4', None), 63: ('GER_f_5', 'Germania'), 64: ('GER_fr_3', 'Germania'),
    70: ('GRE_f_3', 'Grecia'), 71: ('GRE_fr_2', 'Grecia'), 72: ('UNG_f_4', 'Ungheria'), 73: ('UNG_fr_2', 'Ungheria'),
    74: ('ITA_f_3', 'Italia'), 75: ('ITA_fr_2', 'Italia'), 88: ('ROM_f_4', 'Romania'), 89: ('ROM_fr_2', 'Romania'),
    90: ('URSS_c_7', 'URSS'), 91: ('URSS_cr_4', 'URSS'), 92: ('URSS_a_5', 'URSS'), 93: ('URSS_ar_3', 'URSS'),
    94: ('URSS_g_5', 'URSS'), 95: ('URSS_gr_3', 'URSS'), 96: ('URSS_f_3', 'URSS'), 97: ('URSS_fr_2', 'URSS'),
    99: ('USA_c_6', None), 100: ('USA_cr_4', None), 101: ('USA_f_4', None), 102: ('USA_fr_2', None),
    105: ('JUG_fr_2', 'Jugoslavia'), 106: ('JUG_f_3', 'Jugoslavia'),
}
SEGNALINI = {2: 'ctl_alleati', 65: 'ctl_asse', 87: 'ctl_urss', 9: 'aereo_gb', 10: 'aereo_gb_av', 53: 'aereo_ger', 54: 'aereo_ger_av',
             57: 'sub_ger', 58: 'sub_ger_av', 82: 'aereo_urss', 83: 'aereo_usa', 84: 'aereo_usa_av', 98: 'turno',
             20: 'carta_alleati', 30: 'carta_asse', 39: 'carta_urss'}
SVILUPPI = {
    19: ('alleati', 'aviazione_av'), 21: ('alleati', 'carri_av'), 22: ('alleati', 'navi_av'), 23: ('alleati', 'ind_aerea'),
    24: ('alleati', 'sbarchi'), 25: ('alleati', 'aviazione'), 26: ('alleati', 'blitzkrieg'), 27: ('alleati', 'logistica'), 28: ('alleati', 'ind_carri'),
    29: ('asse', 'aviazione_av'), 31: ('asse', 'carri_av'), 32: ('asse', 'navi_av'), 33: ('asse', 'ind_aerea'), 34: ('asse', 'aviazione'),
    35: ('asse', 'blitzkrieg'), 36: ('asse', 'logistica'), 37: ('asse', 'ind_carri'),
    38: ('urss', 'carri_av'), 40: ('urss', 'ind_aerea'), 41: ('urss', 'aviazione'), 42: ('urss', 'blitzkrieg'), 43: ('urss', 'guardie'),
    44: ('urss', 'logistica'), 45: ('urss', 'ind_carri'), 46: ('urss', 'urali'),
}
TITOLI = {'aviazione_av': 'AVIAZIONE\nAVANZATA', 'carri_av': 'CARRI\nAVANZATI', 'navi_av': 'NAVI\nAVANZATE', 'ind_aerea': 'INDUSTRIA\nAEREA',
          'sbarchi': 'SBARCHI\nANFIBI', 'aviazione': 'AVIAZIONE', 'blitzkrieg': 'BLITZKRIEG', 'logistica': 'LOGISTICA',
          'ind_carri': 'INDUSTRIA\nCARRI', 'guardie': 'GUARDIE', 'urali': 'INDUSTRIA\nDEGLI URALI'}
URALI = ' RICHIEDE INDUSTRIA DEGLI URALI.'
TESTI = {
    ('alleati', 'aviazione_av'): 'Missioni aeree avanzate. SOLO DAL 1943.',
    ('asse', 'aviazione_av'): 'Missioni aeree avanzate. SOLO DAL 1943.',
    ('alleati', 'carri_av'): 'Carri con fattore di combattimento 6.',
    ('asse', 'carri_av'): 'Carri con fattore di combattimento 8. SOLO DAL 1942.',
    ('urss', 'carri_av'): 'Carri con fattore di combattimento 7.',
    ('alleati', 'navi_av'): 'I sottomarini tedeschi non avanzati non hanno effetto. SOLO DAL 1943.',
    ('asse', 'navi_av'): 'Basta 1 missione nella Battaglia dell\'Atlantico se gli Alleati non hanno Navi avanzate. SOLO DAL 1943.',
    ('alleati', 'ind_aerea'): 'Ogni azione Missioni aeree fornisce 4 missioni.',
    ('asse', 'ind_aerea'): 'Ogni azione Missioni aeree fornisce 4 missioni.',
    ('urss', 'ind_aerea'): 'Ogni azione Missioni aeree fornisce 4 missioni.' + URALI,
    ('alleati', 'sbarchi'): 'Fino a 3 armate sbarcano per turno (4 nel 1944). SOLO DAL 1942.',
    ('alleati', 'aviazione'): 'Missioni aeree disponibili: ogni azione ne fornisce 2.',
    ('asse', 'aviazione'): 'Missioni aeree disponibili: ogni azione ne fornisce 2.',
    ('urss', 'aviazione'): 'Missioni aeree disponibili: ogni azione ne fornisce 2.',
    ('alleati', 'blitzkrieg'): 'Sfruttamento dei corazzati e linee di rifornimento attraverso le proprie armate.',
    ('asse', 'blitzkrieg'): 'Sfruttamento dei corazzati e linee di rifornimento attraverso le proprie armate.',
    ('urss', 'blitzkrieg'): 'Sfruttamento dei corazzati e linee di rifornimento. SOLO DAL 1942.',
    ('urss', 'guardie'): 'Fanteria della Guardia con fattore 5.' + URALI,
    ('alleati', 'logistica'): 'Ogni azione Rifornimento fornisce 7 unità di rifornimento.',
    ('asse', 'logistica'): 'Ogni azione Rifornimento fornisce 7 unità di rifornimento.',
    ('urss', 'logistica'): 'Ogni azione Rifornimento fornisce 7 unità.' + URALI,
    ('alleati', 'ind_carri'): 'Ogni azione Produzione corazzati fornisce 5 passi corazzati.',
    ('asse', 'ind_carri'): 'Ogni azione Produzione corazzati fornisce 5 passi corazzati.',
    ('urss', 'ind_carri'): 'Ogni azione Produzione corazzati fornisce 5 passi.' + URALI,
    ('urss', 'urali'): 'Permette Industria aerea, Industria carri, Logistica e Guardie. SOLO DAL 1941.',
}

def font(n, s):
    return ImageFont.truetype(FONT + n, s)

def cancella_testo(img, box, chiaro=True, soglia=175):
    """toglie le scritte chiare (o scure) dentro il riquadro con l'inpainting"""
    a = np.array(img.convert('RGB'))
    x0, y0, x1, y1 = box
    sub = cv2.cvtColor(a[y0:y1, x0:x1], cv2.COLOR_RGB2HSV)
    if chiaro:
        m = (sub[:, :, 2] > soglia) & (sub[:, :, 1] < 70)
    else:
        m = sub[:, :, 2] < soglia
    mask = np.zeros(a.shape[:2], np.uint8)
    mask[y0:y1, x0:x1][m] = 255
    mask = cv2.dilate(mask, np.ones((9, 9), np.uint8))
    # anche il contorno scuro delle lettere
    out = cv2.inpaint(a, mask, 6, cv2.INPAINT_TELEA)
    r = Image.fromarray(out).convert('RGBA')
    r.putalpha(img.getchannel('A'))
    return r

def testo_centrato(d, box, t, f, fill, stroke=0, stroke_fill=None):
    x0, y0, x1, y1 = box
    w = d.textlength(t, font=f)
    asc, desc = f.getmetrics()
    d.text(((x0 + x1 - w) / 2, (y0 + y1 - asc - desc) / 2 + 2), t, font=f, fill=fill, stroke_width=stroke, stroke_fill=stroke_fill)

def pedine():
    out = REPO + '/assets/pedine'
    os.makedirs(out, exist_ok=True)
    for i, (nome, naz) in PEDINE.items():
        g = im(i).resize((285, 285), Image.LANCZOS)
        if naz:
            box = (10, 198, 275, 264)
            g = cancella_testo(g, box)
            d = ImageDraw.Draw(g)
            dim = 46
            f = font('BarlowCondensed-Bold.ttf', dim)
            while d.textlength(naz, font=f) > 240:
                dim -= 2
                f = font('BarlowCondensed-Bold.ttf', dim)
            testo_centrato(d, box, naz, f, (250, 248, 240), 3, (40, 36, 30))
        g = g.resize((192, 192), Image.LANCZOS)
        g.save(out + '/%s.webp' % nome, quality=90)
    for i, nome in SEGNALINI.items():
        g = im(i)
        if nome.startswith('carta'):
            g = g.resize((568, 380), Image.LANCZOS)
            box = (0, 300, 568, 380)
            g = cancella_testo(g, box)
            d = ImageDraw.Draw(g)
            t = {'carta_alleati': 'ALLEATI', 'carta_asse': 'ASSE', 'carta_urss': 'URSS'}[nome]
            testo_centrato(d, (0, 300, 568, 372), t, font('BebasNeue-Regular.ttf', 70), (250, 248, 240), 3, (30, 26, 22))
        else:
            g = g.resize((192, 192), Image.LANCZOS)
            if nome == 'aereo_urss':
                g = cancella_testo(g, (0, 105, 120, 192))
        g.save(out + '/%s.webp' % nome, quality=90)

def a_capo(d, t, f, larg):
    righe, cur = [], ''
    for p in t.split(' '):
        prova = (cur + ' ' + p).strip()
        if d.textlength(prova, font=f) <= larg:
            cur = prova
        else:
            righe.append(cur)
            cur = p
    righe.append(cur)
    return righe

def sviluppi():
    out = REPO + '/assets/sviluppi'
    os.makedirs(out, exist_ok=True)
    for i, (lato, sv) in SVILUPPI.items():
        g = im(i).resize((568, 380), Image.LANCZOS)
        # banda verticale a sinistra: si ridipinge con il suo colore
        a = np.array(g)
        col = np.median(a[40:340, 6:20, :3].reshape(-1, 3), axis=0)
        banda = Image.new('RGBA', (122, 380), tuple(int(c) for c in col) + (255,))
        # leggera grana
        rumore = (np.random.RandomState(i).rand(380, 122) * 18 - 9).astype(np.int16)
        ba = np.array(banda).astype(np.int16)
        for c in range(3):
            ba[:, :, c] = np.clip(ba[:, :, c] + rumore, 0, 255)
        banda = Image.fromarray(ba.astype(np.uint8))
        g.alpha_composite(banda, (0, 0))
        g.putalpha(Image.open(files[i]).convert('RGBA').resize((568, 380)).getchannel('A'))
        # titolo verticale
        tit = TITOLI[sv]
        righe = tit.split('\n')
        timg = Image.new('RGBA', (380, 122), (0, 0, 0, 0))
        td = ImageDraw.Draw(timg)
        dim = 58 if len(righe) == 1 else 50
        f = font('BebasNeue-Regular.ttf', dim)
        while max(td.textlength(r, font=f) for r in righe) > 350:
            dim -= 2
            f = font('BebasNeue-Regular.ttf', dim)
        hriga = dim * 0.95
        y = (122 - hriga * len(righe)) / 2
        for r in righe:
            w = td.textlength(r, font=f)
            td.text(((380 - w) / 2, y), r, font=f, fill=(238, 232, 214, 235))
            y += hriga
        timg = timg.rotate(90, expand=True)
        g.alpha_composite(timg, (0, 0))
        # testo in basso
        box = (128, 226 if sv == 'navi_av' and lato == 'asse' else 262, 566, 372)
        g = cancella_testo(g, box)
        d = ImageDraw.Draw(g)
        t = TESTI[(lato, sv)]
        dim = 30
        while True:
            f = font('BarlowCondensed-SemiBold.ttf', dim)
            righe = a_capo(d, t, f, 420)
            if len(righe) * dim * 1.05 <= 104 or dim <= 18:
                break
            dim -= 1
        y = 318 - len(righe) * dim * 1.05 / 2
        for r in righe:
            w = d.textlength(r, font=f)
            d.text((128 + (438 - w) / 2, y), r, font=f, fill=(252, 250, 244), stroke_width=2, stroke_fill=(45, 40, 34))
            y += dim * 1.05
        g.resize((426, 285), Image.LANCZOS).save(out + '/%s_%s.webp' % (lato, sv), quality=90)

if __name__ == '__main__':
    pedine()
    sviluppi()
    print('ok')
