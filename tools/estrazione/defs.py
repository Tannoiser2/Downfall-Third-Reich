# Definizione delle aree di Downfall of the Third Reich (dati letti dalla mappa originale)
# chiave: nome inglese sulla mappa -> (id, nome italiano, nazione)
AREE = {
 'Trondheim': ('trondheim', 'Trondheim', 'NOR'), 'Bergen': ('bergen', 'Bergen', 'NOR'), 'Oslo': ('oslo', 'Oslo', 'NOR'),
 'Copenhagen': ('copenaghen', 'Copenaghen', 'DAN'),
 'Ireland': ('irlanda', 'Irlanda', 'GB'), 'Scotland': ('scozia', 'Scozia', 'GB'), 'Manchester': ('manchester', 'Manchester', 'GB'),
 'Plymouth': ('plymouth', 'Plymouth', 'GB'), 'London': ('londra', 'Londra', 'GB'), 'Canada': ('canada', 'Canada', 'GB'),
 'USA': ('usa', 'Stati Uniti', 'USA'),
 'Hamburg': ('amburgo', 'Amburgo', 'GER'), 'Berlin': ('berlino', 'Berlino', 'GER'), 'Danzig': ('danzica', 'Danzica', 'GER'),
 'Königsberg': ('konigsberg', 'Königsberg', 'GER'), 'Breslau': ('breslavia', 'Breslavia', 'GER'), 'Warsaw': ('varsavia', 'Varsavia', 'GER'),
 'Tarnow': ('tarnow', 'Tarnów', 'GER'), 'Leipzig': ('lipsia', 'Lipsia', 'GER'), 'Dresden': ('dresda', 'Dresda', 'GER'),
 'Prague': ('praga', 'Praga', 'GER'), 'Ruhr': ('ruhr', 'Ruhr', 'GER'), 'Frankfurt': ('francoforte', 'Francoforte', 'GER'),
 'Stuttgart': ('stoccarda', 'Stoccarda', 'GER'), 'Munich': ('monaco', 'Monaco di Baviera', 'GER'), 'Vienna': ('vienna', 'Vienna', 'GER'),
 'Brussels': ('bruxelles', 'Bruxelles', 'BEL'),
 'Calais': ('calais', 'Calais', 'FRA'), 'Reims': ('reims', 'Reims', 'FRA'), 'Normandy': ('normandia', 'Normandia', 'FRA'),
 'Brittany': ('bretagna', 'Bretagna', 'FRA'), 'Paris': ('parigi', 'Parigi', 'FRA'), 'Nancy': ('nancy', 'Nancy', 'FRA'),
 'Nantes': ('nantes', 'Nantes', 'FRA'), 'Vichy': ('vichy', 'Vichy', 'FRA'), 'Bordeaux': ('bordeaux', 'Bordeaux', 'FRA'),
 'Montpellier': ('montpellier', 'Montpellier', 'FRA'), 'Marseille': ('marsiglia', 'Marsiglia', 'FRA'),
 'Milan': ('milano', 'Milano', 'ITA'), 'Veneto': ('veneto', 'Veneto', 'ITA'), 'Tuscany': ('toscana', 'Toscana', 'ITA'),
 'Rome': ('roma', 'Roma', 'ITA'), 'Naples': ('napoli', 'Napoli', 'ITA'), 'Calabria': ('calabria', 'Calabria', 'ITA'),
 'Sicily': ('sicilia', 'Sicilia', 'ITA'), 'Albania': ('albania', 'Albania', 'ITA'),
 'Zagreb': ('zagabria', 'Zagabria', 'JUG'), 'Montenegro': ('montenegro', 'Montenegro', 'JUG'), 'Belgrade': ('belgrado', 'Belgrado', 'JUG'),
 'Nis': ('nis', 'Niš', 'JUG'),
 'Sofia': ('sofia', 'Sofia', 'BUL'), 'Varna': ('varna', 'Varna', 'BUL'),
 'Salonica': ('salonicco', 'Salonicco', 'GRE'), 'Ioannina': ('giannina', 'Giannina', 'GRE'), 'Athens': ('atene', 'Atene', 'GRE'),
 'Brasov': ('brasov', 'Brașov', 'ROM'), 'Transylvania': ('transilvania', 'Transilvania', 'ROM'), 'Bucharest': ('bucarest', 'Bucarest', 'ROM'),
 'Constanta': ('costanza', 'Costanza', 'ROM'),
 'Budapest': ('budapest', 'Budapest', 'UNG'), 'Debrecen': ('debrecen', 'Debrecen', 'UNG'),
 'Helsinki': ('helsinki', 'Helsinki', 'FIN'), 'Karelia': ('carelia', 'Carelia', 'FIN'),
 'Leningrad': ('leningrado', 'Leningrado', 'URSS'), 'Volkhov': ('volchov', 'Volchov', 'URSS'), 'Petrozavodsk': ('petrozavodsk', 'Petrozavodsk', 'URSS'),
 'Archangelsk': ('arcangelo', 'Arcangelo', 'URSS'), 'Syktyvkar': ('syktyvkar', 'Syktyvkar', 'URSS'), 'Komi': ('komi', 'Komi', 'URSS'),
 'Sverdlovsk': ('sverdlovsk', 'Sverdlovsk', 'URSS'), 'Vologda': ('vologda', 'Vologda', 'URSS'), 'Vladimir': ('vladimir', 'Vladimir', 'URSS'),
 'Kirov': ('kirov', 'Kirov', 'URSS'), 'Perm': ('perm', 'Perm', 'URSS'), 'Gorky': ('gorkij', 'Gor\'kij', 'URSS'),
 'Moscow': ('mosca', 'Mosca', 'URSS'), 'Kalinin': ('kalinin', 'Kalinin', 'URSS'), 'Tallinn': ('tallinn', 'Tallinn', 'URSS'),
 'Pskov': ('pskov', 'Pskov', 'URSS'), 'Riga': ('riga', 'Riga', 'URSS'), 'Dvinsk': ('dvinsk', 'Dvinsk', 'URSS'),
 'Smolensk': ('smolensk', 'Smolensk', 'URSS'), 'Tula': ('tula', 'Tula', 'URSS'), 'Ryazan': ('rjazan', 'Rjazan\'', 'URSS'),
 'Penza': ('penza', 'Penza', 'URSS'), 'Kuybyshev': ('kujbysev', 'Kujbyšev', 'URSS'), 'Chelyabinsk': ('celjabinsk', 'Čeljabinsk', 'URSS'),
 'Kazakhstan': ('kazakistan', 'Kazakistan', 'URSS'), 'Saratov': ('saratov', 'Saratov', 'URSS'), 'Baskunchak': ('baskuncak', 'Baskunčak', 'URSS'),
 'Guryev': ('gurev', 'Gur\'ev', 'URSS'), 'Vilnius': ('vilnius', 'Vilnius', 'URSS'), 'Minsk': ('minsk', 'Minsk', 'URSS'),
 'Bryansk': ('brjansk', 'Brjansk', 'URSS'), 'Kursk': ('kursk', 'Kursk', 'URSS'), 'Voronezh': ('voronez', 'Voronež', 'URSS'),
 'Stalingrad': ('stalingrado', 'Stalingrado', 'URSS'), 'Kovel': ('kovel', 'Kovel\'', 'URSS'), 'Pripet': ('pripjat', 'Pripjat\'', 'URSS'),
 'Kiev': ('kiev', 'Kiev', 'URSS'), 'Kharkov': ('charkov', 'Char\'kov', 'URSS'), 'Lugansk': ('lugansk', 'Lugansk', 'URSS'),
 'Tarnopol': ('tarnopol', 'Tarnopol', 'URSS'), 'Vinnitsa': ('vinnica', 'Vinnica', 'URSS'), 'Dnipropetrovsk': ('dnepropetrovsk', 'Dnepropetrovsk', 'URSS'),
 'Stalino': ('stalino', 'Stalino', 'URSS'), 'Rostov': ('rostov', 'Rostov', 'URSS'), 'Elista': ('elista', 'Elista', 'URSS'),
 'Astrakhan': ('astrachan', 'Astrachan\'', 'URSS'), 'Maikop': ('majkop', 'Majkop', 'URSS'), 'Grozny': ('groznyj', 'Groznyj', 'URSS'),
 'Tbilisi': ('tbilisi', 'Tbilisi', 'URSS'), 'Baku': ('baku', 'Baku', 'URSS'), 'Sebastopol': ('sebastopoli', 'Sebastopoli', 'URSS'),
 'Odessa': ('odessa', 'Odessa', 'URSS'),
 'Casablanca': ('casablanca', 'Casablanca', 'AFN'), 'Taza': ('taza', 'Taza', 'AFN'), 'Oran': ('orano', 'Orano', 'AFN'),
 'Algiers': ('algeri', 'Algeri', 'AFN'), 'Tebessa': ('tebessa', 'Tébessa', 'AFN'), 'Tunis': ('tunisi', 'Tunisi', 'AFN'),
 'Mareth': ('mareth', 'Mareth', 'AFN'),
 'Tripoli': ('tripoli', 'Tripoli', 'LIB'), 'Sirte': ('sirte', 'Sirte', 'LIB'), 'El Agheila': ('el_agheila', 'El Agheila', 'LIB'),
 'Benghazi': ('bengasi', 'Bengasi', 'LIB'), 'Tobruk': ('tobruch', 'Tobruch', 'LIB'), 'Bir Hacheim': ('bir_hacheim', 'Bir Hacheim', 'LIB'),
 'Matruh': ('marsa_matruh', 'Marsa Matruh', 'EGI'), 'El Alamein': ('el_alamein', 'El Alamein', 'EGI'),
 'Alexandria': ('alessandria', 'Alessandria', 'EGI'), 'Suez': ('suez', 'Suez', 'EGI'),
}
FORESTA = ['Königsberg', 'Stuttgart', 'Kalinin', 'Moscow', 'Gorky', 'Vladimir', 'Vologda', 'Syktyvkar', 'Archangelsk', 'Petrozavodsk', 'Komi', 'Kirov']
PALUDE = ['Karelia', 'Leningrad', 'Volkhov', 'Pripet', 'Helsinki', 'Kuybyshev', 'Baskunchak', 'Guryev', 'Constanta']
MONTAGNA = ['Bergen', 'Trondheim', 'Scotland', 'Debrecen', 'Brasov', 'Zagreb', 'Montenegro', 'Nis', 'Albania', 'Ioannina', 'Athens',
            'Salonica', 'Tuscany', 'Rome', 'Naples', 'Calabria', 'Tebessa', 'Sverdlovsk', 'Chelyabinsk']
PASSO = ['El Alamein', 'Mareth', 'El Agheila']
FORTEZZE = ['Leningrad', 'Moscow', 'Tula', 'Kiev', 'Odessa', 'Sebastopol', 'Grozny', 'Tobruk']
# aree di rifornimento: lato
RIFORNIMENTO = {'Ruhr': 'asse', 'Berlin': 'asse', 'Breslau': 'asse', 'Munich': 'asse',
                'Scotland': 'alleati', 'London': 'alleati', 'Canada': 'alleati', 'Suez': 'alleati', 'USA': 'alleati',
                'Gorky': 'urss', 'Kuybyshev': 'urss', 'Stalingrad': 'urss', 'Sverdlovsk': 'urss', 'Chelyabinsk': 'urss', 'Kazakhstan': 'urss'}
CHIAVE = {'Berlin': 'GER', 'Ruhr': 'GER', 'Frankfurt': 'GER', 'Breslau': 'GER', 'Munich': 'GER',
          'Leningrad': 'URSS', 'Moscow': 'URSS', 'Minsk': 'URSS', 'Kiev': 'URSS', 'Kharkov': 'URSS', 'Rostov': 'URSS', 'Stalingrad': 'URSS', 'Kuybyshev': 'URSS'}
CAPITALI = {'Berlin': 'GER', 'London': 'GB', 'Paris': 'FRA', 'Moscow': 'URSS', 'Rome': 'ITA', 'Brussels': 'BEL', 'Budapest': 'UNG',
            'Bucharest': 'ROM', 'Sofia': 'BUL', 'Belgrade': 'JUG', 'Athens': 'GRE', 'Helsinki': 'FIN', 'Oslo': 'NOR', 'Copenhagen': 'DAN',
            'USA': 'USA'}
EST = ['Komi', 'Perm', 'Sverdlovsk', 'Chelyabinsk', 'Kuybyshev', 'Kazakhstan', 'Baskunchak', 'Guryev', 'Astrakhan', 'Grozny', 'Baku']
AGGIUNTE = [('Nancy', 'Stuttgart'), ('Marseille', 'Milan'), ('Sicily', 'Calabria'), ('Sebastopol', 'Maikop'), ('Komi', 'Syktyvkar')]
STRETTI = [('Sicily', 'Calabria'), ('Sebastopol', 'Maikop'), ('Alexandria', 'Suez')]
ALTA_MONTAGNA = [('Marseille', 'Milan'), ('Munich', 'Veneto'), ('Vienna', 'Veneto'), ('Maikop', 'Tbilisi'), ('Elista', 'Tbilisi'),
                 ('Grozny', 'Tbilisi'), ('Grozny', 'Baku')]
LINEE_FORTIFICATE = [('Nancy', 'Stuttgart'), ('Nancy', 'Frankfurt'), ('Helsinki', 'Karelia')]
# fiume del Reno: (difensore, attaccante) — il fiume sta nell'area del difensore
RENO = [('Ruhr', 'Brussels'), ('Frankfurt', 'Brussels'), ('Frankfurt', 'Reims'), ('Frankfurt', 'Nancy'), ('Stuttgart', 'Nancy')]
FIUMI = [('Budapest', 'Debrecen'), ('Budapest', 'Belgrade'), ('Belgrade', 'Debrecen'), ('Belgrade', 'Transylvania'), ('Bucharest', 'Sofia'),
         ('Bucharest', 'Varna'), ('Constanta', 'Varna'), ('Bucharest', 'Constanta'), ('Constanta', 'Odessa'), ('Brasov', 'Odessa'),
         ('Sofia', 'Transylvania'),
         ('Kirov', 'Penza'), ('Kirov', 'Kuybyshev'), ('Penza', 'Kuybyshev'), ('Saratov', 'Kuybyshev'), ('Saratov', 'Baskunchak'),
         ('Stalingrad', 'Baskunchak'), ('Stalingrad', 'Guryev'), ('Astrakhan', 'Guryev'),
         ('Voronezh', 'Lugansk'), ('Lugansk', 'Stalingrad'), ('Lugansk', 'Rostov')]
COSTE_EXTRA = {'Canada': ['Atlantico'], 'Montenegro': ['Adriatico'], 'Rostov': ['Mar Nero'], 'Stalino': ['Mar Nero'], 'Ioannina': ['Adriatico'],
               'Tunis': ['Mediterraneo or.']}
COSTE_TOLTE = {'Taza': ['Mediterraneo occ.'], 'Ruhr': [], 'Karelia': ['Baltico']}
MARI = ['Atlantico', 'Biscaglia', 'Manica', 'Mare del Nord', 'Baltico', 'Mediterraneo occ.', 'Adriatico', 'Mediterraneo or.', 'Mar Nero', 'Caspio']
MARI_ADIACENTI = [('Atlantico', 'Biscaglia'), ('Atlantico', 'Manica'), ('Atlantico', 'Mare del Nord'), ('Biscaglia', 'Manica'),
                  ('Manica', 'Mare del Nord'), ('Mare del Nord', 'Baltico'), ('Atlantico', 'Mediterraneo occ.'),
                  ('Mediterraneo occ.', 'Mediterraneo or.'), ('Mediterraneo or.', 'Adriatico'), ('Mediterraneo occ.', 'Adriatico')]
# linee di sbarco (frecce azzurre): (da, a)
LINEE_SBARCO = [('Scotland', 'Trondheim'), ('Scotland', 'Ireland'), ('Ireland', 'Scotland'),
                ('Plymouth', 'Brittany'), ('Brittany', 'Plymouth'), ('Plymouth', 'Normandy'), ('Normandy', 'Plymouth'),
                ('London', 'Normandy'), ('Normandy', 'London'), ('London', 'Calais'), ('Calais', 'London'),
                ('Oslo', 'Copenhagen'), ('Copenhagen', 'Oslo'), ('Tunis', 'Sicily'), ('Sicily', 'Naples'),
                ('Kazakhstan', 'Grozny'), ('Kazakhstan', 'Baku')]
MEDITERRANEO_LL = [('Tunis', 'Sicily'), ('Sicily', 'Naples')]
# sbarchi speciali con lo sviluppo Sbarchi anfibi: area -> provenienze
SBARCHI_D = {'Ireland': ['america'], 'Scotland': ['america'], 'Manchester': ['america'], 'Plymouth': ['america'],
             'Nantes': ['america', 'uk'], 'Bordeaux': ['america', 'uk'],
             'Casablanca': ['america'], 'Oran': ['america'], 'Algiers': ['america'], 'Suez': ['america'],
             'Brussels': ['uk'], 'Bergen': ['uk'], 'Marseille': ['Tunis']}
# posizione delle pedine (pixel della mappa originale 4967x3508) dove il centro calcolato non va bene
CENTRI = {'Trondheim': (1780, 140), 'USA': (140, 1640), 'Canada': (200, 1250), 'Chelyabinsk': (4760, 540), 'Kazakhstan': (4800, 960),
          'Sverdlovsk': (4700, 300), 'Karelia': (2870, 120), 'Helsinki': (2560, 200), 'Komi': (4300, 150), 'Archangelsk': (3550, 130),
          'Petrozavodsk': (3150, 160), 'Syktyvkar': (3800, 160), 'Ruhr': (1560, 1180), 'Kirov': (4120, 300), 'Leningrad': (3000, 420)}
SEDI = {'GER': 'asse', 'ITA': 'asse', 'FIN': 'asse', 'ROM': 'asse', 'UNG': 'asse', 'BUL': 'asse', 'LIB': 'asse',
        'GB': 'alleati', 'USA': 'alleati', 'FRA': 'alleati', 'BEL': 'alleati', 'GRE': 'alleati', 'JUG': 'alleati', 'EGI': 'alleati', 'AFN': 'alleati',
        'URSS': 'urss', 'NOR': '', 'DAN': ''}
