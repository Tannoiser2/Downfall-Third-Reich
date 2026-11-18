# Downfall of the Third Reich — versione digitale (uso personale)

Il gioco strategico di Víctor Catalá (DoItGames, 2022) sulla seconda guerra mondiale in Europa, dal 1940 al 1945,
per uno, due o tre giocatori, in Godot 4.7.

Si gioca nel browser: https://tannoiser2.github.io/Downfall-Third-Reich/

## Modalità

- **Solitario** con l'Asse, gli Alleati o l'Unione Sovietica: gli altri due lati li gioca l'IA (livello normale o esperto).
- **In due**: uno guida l'Asse (IA o umano) e l'altro Alleati e URSS insieme, sullo stesso schermo.
- **Tre giocatori sullo stesso schermo** e **IA contro IA** per guardare.
- **Online** fino a tre giocatori: chi crea la stanza sceglie il suo schieramento, gli altri entrano con il codice
  di 4 lettere e ricevono gli schieramenti rimasti; i lati liberi li gioca l'IA del dispositivo che ha creato la stanza.
- **Salvataggio** automatico su Firebase (e sul dispositivo) a ogni fine turno; «Continua la partita salvata» riprende.

## Comandi

- Tocca o fai clic su un'area: a destra compaiono le armate. Scegli «Muovi o attacca»: in verde i movimenti tattici,
  in azzurro i movimenti strategici e navali, in viola gli sbarchi, in rosso le aree dove attaccare.
- Le azioni (Rifornimento, Rinforzi, Produzione corazzati, Missioni aeree, Sottomarini, Sviluppo, Affitti e prestiti)
  sono nel pannello a sinistra; poi «Risolvi i combattimenti» e «Fine turno».
- Mouse: trascina con il tasto sinistro per spostare, tasto destro per ruotare e inclinare, rotella per lo zoom.
- iPad e telefono: un dito sposta la mappa, due dita pizzicano per lo zoom e ruotano, due dita in verticale inclinano.
- Trackpad del Mac: pizzico per lo zoom, due dita per spostare, Maiusc + due dita per ruotare.
- Pulsanti a lato della mappa: zoom, vista dall'alto o inclinata, modellini 3D o pedine originali, nascondi pannelli.

## Regole implementate

Tutto il regolamento del gioco base: 22 turni stagionali, azioni per turno (guerra limitata e totale, con le penalità
per aree di rifornimento perdute, Trondheim, Londra, Mosca, sottomarini e bombardamento strategico), rifornimenti
(massimo 12, petrolio di Bucarest, Groznyj e Baku, Suez), rinforzi delle potenze maggiori nelle aree di rifornimento e
delle nazioni minori a ogni turno o in inverno ed estate, produzione corazzati e conversione della fanteria, missioni
aeree (attacco, contrasto, bombardamento strategico, missioni avanzate), Battaglia dell'Atlantico, sviluppi (avvio e
completamento, limiti di anno, Industria degli Urali), affitti e prestiti; operazioni delle armate (movimento tattico,
attacco e sostegno, strategico, navale, sbarchi lungo le linee di sbarco e nelle aree D con lo sviluppo), limite di
3 armate, controllo delle aree, linee di rifornimento anche via mare, Blitzkrieg (sfruttamento e rifornimento),
combattimento armata contro armata con terreni, fortezze, fiumi, stretti, coste, linee fortificate e alta montagna,
regole speciali (corazzati tedeschi in URSS, Afrika Korps e corazzati britannici in Africa, inverno 1942, italiani con i
tedeschi), restrizioni politiche, entrate in guerra, Barbarossa, rese (Francia con l'Africa del Nord neutrale, Belgio,
Italia, nazioni minori, Norvegia e Danimarca, URSS e Germania), partigiani jugoslavi e vittoria.

Semplificazioni: il contrasto alle missioni aeree si decide una volta sola, al momento dei combattimenti (non a
rilanci successivi); gli sviluppi non sono segreti; le invasioni dell'Africa del Nord francese neutrale non richiedono
tre armate piene.

## L'IA

Gioca a passi come un giocatore e segue i consigli dell'autore del gioco: la Germania sfrutta subito il vantaggio di
azioni (Francia nel 1940), accumula rifornimenti prima di Barbarossa e usa i sottomarini finché gli Alleati sono in
guerra limitata, poi difende le sue quattro aree di rifornimento; gli Alleati puntano sui Carri avanzati (senza i quali
gli Stati Uniti non hanno corazzati), affitti e prestiti, Trondheim e gli sbarchi; l'URSS costruisce vicino al fronte e
contrattacca quando i rapporti di forza lo permettono. Ogni attacco è valutato con la probabilità esatta dei due dadi.

## Struttura

- `scripts/dati.gd` — aree, nazioni, armate, sviluppi, schieramento iniziale.
- `scripts/motore.gd` — regole e stato della partita (deterministico: online si scambiano solo le decisioni).
- `scripts/ia.gd` — intelligenza artificiale per i tre schieramenti.
- `scripts/vista3d.gd` e `scripts/mappa.gdshader` — tavolo 3D, modellini e pedine, evidenziazioni, comandi touch.
- `scripts/main.gd` — interfaccia, menu, salvataggi, gioco online. `scripts/rete.gd` — Firebase.
- `assets/mappa/` — la mappa del modulo di Tabletop Simulator e `aree.png`, l'indice delle aree ricavato dalla mappa.
- `assets/dati/mappa.json` — le 132 aree con vicini, terreni, fortezze, fiumi, stretti, linee fortificate, mari.
- `assets/pedine/` e `assets/sviluppi/` — pedine e tessere sviluppo del modulo, con i testi in italiano.
- `tests/` — partita IA contro IA (`sim.gd`), schermate (`foto.gd`), prova online con un finto Firebase.

## Firebase

Radice `downfall` nel progetto condiviso `flammerouge-f8669`: stanze con registro delle decisioni
(`downfall/rooms/<codice>`: `host`, `status`, `cfg`, `game`, `seats`, `members`, `log`) e salvataggi personali
(`downfall/salvataggi/<uid>`). Sono strutture coperte dalla regola comune della ludoteca: non serve una sezione nuova.

## Pubblicazione

Solo a richiesta: Actions → Pubblica → Run workflow, oppure un commit con `[pubblica]` nel messaggio.
