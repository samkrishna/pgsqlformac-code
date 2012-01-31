//
//  AppDelegate.m
//  PGSQLDispatchTesting
//
//  Created by Neil Tiffin on 1/29/12.
//  Copyright (c) 2012 Performance Champions, Inc. All rights reserved.
//

#import "AppDelegate.h"

#import "PGSQLConnection.h"
#import "PGSQLRecord.h"
#import "PGSQLDispatch.h"

static NSString *sqlCreateFilmsTable = @"CREATE TABLE films ("
"title          varchar PRIMARY KEY,"
"director       varchar,"
"release_date   varchar,"
"genre          varchar"
");";

static NSString *sqlInsertFilmsTable = @"INSERT INTO films (title, director, release_date, genre) VALUES "
"('Citizen Kane', 'Welles, Orson', '1941', 'Drama'),"
"('Vertigo', 'Hitchcock, Alfred', '1958', 'Thriller-Drama-Mystery'),"
"('Rules of the Game, The', 'Renoir, Jean', '1939', 'Drama-Comedy'),"
"('2001: A Space Odyssey', 'Kubrick, Stanley', '1968', 'Science Fiction'),"
"('Godfather, The', 'Coppola, Francis', '1972', 'Drama-Crime'),"
"('8½', 'Fellini, Federico', '1963', 'Drama'),"
"('Seven Samurai, The', 'Kurosawa, Akira', '1954', 'Drama-Action-Historical'),"
"('Searchers, The', 'Ford, John', '1956', 'Western');";

static NSString *sqlInsertFilmsTableLarge = @"INSERT INTO films (title, director, release_date, genre) VALUES "
"('Singin'' in the Rain', 'Donen, Stanley/Gene Kelly', '1952', 'Musical-Dance-Comedy'),"
"('Battleship Potemkin', 'Eisenstein, Sergei', '1925', 'War-Historical'),"
"('Tokyo Story', 'Ozu, Yasujiro', '1953', 'Drama'),"
"('Sunrise', 'Murnau, F.W.', '1927', 'Romance-Drama-Crime'),"
"('Lawrence of Arabia', 'Lean, David', '1962', 'War-Biography-Adventure'),"
"('Bicycle Thieves', 'De Sica, Vittorio', '1948', 'Drama'),"
"('Godfather Part II, The', 'Coppola, Francis', '1974', 'Drama-Crime'),"
"('Casablanca', 'Curtiz, Michael', '1942', 'War-Romance-Drama'),"
"('Atalante, L''', 'Vigo, Jean', '1934', 'Romance-Drama'),"
"('Raging Bull', 'Scorsese, Martin', '1980', 'Sports-Drama-Biography'),"
"('Rashomon', 'Kurosawa, Akira', '1950', 'Drama-Crime'),"
"('Passion of Joan of Arc, The', 'Dreyer, Carl', '1928', 'Historical-Drama'),"
"('Touch of Evil', 'Welles, Orson', '1958', 'Thriller-Crime'),"
"('Taxi Driver', 'Scorsese, Martin', '1976', 'Drama'),"
"('Some Like it Hot', 'Wilder, Billy', '1959', 'Romance-Crime-Comedy'),"
"('Dolce vita, La', 'Fellini, Federico', '1960', 'Drama'),"
"('Grande illusion, La', 'Renoir, Jean', '1937', 'Prison-Drama-War'),"
"('City Lights', 'Chaplin, Charles', '1931', 'Romance-Comedy'),"
"('Third Man, The', 'Reed, Carol', '1949', 'Thriller-Mystery'),"
"('Apocalypse Now', 'Coppola, Francis', '1979', 'War-Drama-Adventure'),"
"('Dr. Strangelove or: How I Learned to Stop Worrying and Love the Bomb', 'Kubrick, Stanley', '1964', 'War-Comedy'),"
"('Psycho [1960]', 'Hitchcock, Alfred', '1960', 'Thriller-Horror'),"
"('General, The [1926]', 'Keaton, Buster/Clyde Bruckman', '1926', 'Comedy-Adventure'),"
"('Breathless [1959]', 'Godard, Jean-Luc', '1959', 'Romance-Drama-Crime'),"
"('Gold Rush, The', 'Chaplin, Charles', '1925', 'Comedy-Adventure-Family'),"
"('Sunset Blvd.', 'Wilder, Billy', '1950', 'Drama'),"
"('400 Blows, The', 'Truffaut, François', '1959', 'Drama'),"
"('Enfants du paradis, Les', 'Carné, Marcel', '1945', 'Romance-Drama'),"
"('Chinatown', 'Polanski, Roman', '1974', 'Mystery-Crime'),"
"('Blade Runner', 'Scott, Ridley', '1982', 'Science Fiction'),"
"('Ordet', 'Dreyer, Carl', '1955', 'Religious-Drama'),"
"('Night of the Hunter, The', 'Laughton, Charles', '1955', 'Thriller'),"
"('Avventura, L''', 'Antonioni, Michelangelo', '1960', 'Drama-Mystery-Romance'),"
"('Andrei Rublev', 'Tarkovsky, Andrei', '1966', 'Historical-Biography'),"
"('It''s a Wonderful Life', 'Capra, Frank', '1946', 'Fantasy-Drama-Family'),"
"('M [1931]', 'Lang, Fritz', '1931', 'Thriller-Drama-Crime'),"
"('Persona', 'Bergman, Ingmar', '1966', 'Drama'),"
"('Rear Window', 'Hitchcock, Alfred', '1954', 'Thriller-Mystery'),"
"('Jules et Jim', 'Truffaut, François', '1961', 'Romance-Drama'),"
"('Wild Bunch, The', 'Peckinpah, Sam', '1969', 'Western'),"
"('Ugetsu monogatari', 'Mizoguchi, Kenji', '1953', 'Drama'),"
"('Contempt', 'Godard, Jean-Luc', '1963', 'Drama'),"
"('Magnificent Ambersons, The', 'Welles, Orson', '1942', 'Drama'),"
"('Strada, La', 'Fellini, Federico', '1954', 'Drama'),"
"('Seventh Seal, The', 'Bergman, Ingmar', '1957', 'Fantasy-Drama'),"
"('Modern Times', 'Chaplin, Charles', '1936', 'Comedy-Romance'),"
"('Intolerance', 'Griffith, D.W.', '1916', 'Historical-Drama'),"
"('Wild Strawberries', 'Bergman, Ingmar', '1957', 'Drama'),"
"('North by Northwest', 'Hitchcock, Alfred', '1959', 'Thriller-Spy-Romance'),"
"('Rio Bravo', 'Hawks, Howard', '1959', 'Western'),"
"('Apartment, The', 'Wilder, Billy', '1960', 'Drama-Comedy'),"
"('Au hasard Balthazar', 'Bresson, Robert', '1966', 'Drama'),"
"('Wizard of Oz, The', 'Fleming, Victor', '1939', 'Musical-Fantasy-Family'),"
"('Pather Panchali', 'Ray, Satyajit', '1955', 'Drama'),"
"('Once Upon a Time in the West', 'Leone, Sergio', '1968', 'Western'),"
"('Gone with the Wind', 'Fleming, Victor', '1939', 'Historical-Romance-Drama'),"
"('Leopard, The', 'Visconti, Luchino', '1963', 'Historical-Drama-War'),"
"('Conformist, The', 'Bertolucci, Bernardo', '1969', 'Political-Drama'),"
"('Mirror, The', 'Tarkovsky, Andrei', '1976', 'Drama'),"
"('Greed', 'von Stroheim, Erich', '1924', 'Drama'),"
"('All About Eve', 'Mankiewicz, Joseph L.', '1950', 'Drama'),"
"('Viridiana', 'Buñuel, Luis', '1961', 'Drama'),"
"('Metropolis', 'Lang, Fritz', '1926', 'Fantasy-Science Fiction-Drama'),"
"('Man Who Shot Liberty Valance, The', 'Ford, John', '1962', 'Western'),"
"('Jaws', 'Spielberg, Steven', '1975', 'Horror-Thriller-Adventure'),"
"('Battle of Algiers, The', 'Pontecorvo, Gillo', '1965', 'War-Political-Drama'),"
"('Fanny and Alexander', 'Bergman, Ingmar', '1982', 'Drama'),"
"('Nashville', 'Altman, Robert', '1975', 'Drama'),"
"('Amarcord', 'Fellini, Federico', '1973', 'Drama-Comedy'),"
"('To Be or Not to Be [1942]', 'Lubitsch, Ernst', '1942', 'War-Comedy'),"
"('Barry Lyndon', 'Kubrick, Stanley', '1975', 'Drama'),"
"('Clockwork Orange, A', 'Kubrick, Stanley', '1971', 'Science Fiction-Crime-Drama'),"
"('Notorious', 'Hitchcock, Alfred', '1946', 'Romance-Thriller-Mystery'),"
"('Stagecoach', 'Ford, John', '1939', 'Western-Action-Drama'),"
"('Ikiru', 'Kurosawa, Akira', '1952', 'Drama'),"
"('Sansho the Bailiff', 'Mizoguchi, Kenji', '1954', 'Drama'),"
"('Aguirre: The Wrath of God', 'Herzog, Werner', '1972', 'Historical-Drama-Adventure'),"
"('Pierrot le fou', 'Godard, Jean-Luc', '1965', 'Romance-Drama-Crime'),"
"('Annie Hall', 'Allen, Woody', '1977', 'Romance-Comedy'),"
"('Madame de...', 'Ophüls, Max', '1953', 'Romance-Drama'),"
"('Double Indemnity', 'Wilder, Billy', '1944', 'Mystery-Crime'),"
"('Playtime', 'Tati, Jacques', '1967', 'Comedy'),"
"('On the Waterfront', 'Kazan, Elia', '1954', 'Drama'),"
"('Voyage in Italy', 'Rossellini, Roberto', '1953', 'Romance-Drama'),"
"('Pickpocket', 'Bresson, Robert', '1959', 'Drama-Crime'),"
"('Letter from an Unknown Woman', 'Ophüls, Max', '1948', 'Romance-Drama'),"
"('Bringing Up Baby', 'Hawks, Howard', '1938', 'Romance-Comedy'),"
"('My Darling Clementine', 'Ford, John', '1946', 'Western'),"
"('Man with a Movie Camera, The', 'Vertov, Dziga', '1929', 'Documentary-Avant-Garde'),"
"('Rome, Open City', 'Rossellini, Roberto', '1945', 'War-Drama'),"
"('GoodFellas', 'Scorsese, Martin', '1990', 'Drama-Crime'),"
"('Star Wars', 'Lucas, George', '1977', 'Science Fiction-Fantasy-Adventure'),"
"('Last Year at Marienbad', 'Resnais, Alain', '1961', 'Drama-Mystery-Avant-Garde'),"
"('Blue Velvet', 'Lynch, David', '1986', 'Mystery-Crime-Drama'),"
"('Nosferatu', 'Murnau, F.W.', '1922', 'Horror'),"
"('Duck Soup', 'McCarey, Leo', '1933', 'Comedy'),"
"('His Girl Friday', 'Hawks, Howard', '1940', 'Romance-Comedy'),"
"('King Kong [1933]', 'Cooper, Merian C./Ernest B. Schoedsack', '1933', 'Fantasy-Adventure-Horror'),"
"('Âge d''or, L''', 'Buñuel, Luis', '1930', 'Drama-Avant-Garde-Experimental'),"
"('Napoléon [1927]', 'Gance, Abel', '1927', 'War-Historical-Biography'),"
"('Hiroshima mon amour', 'Resnais, Alain', '1959', 'Drama'),"
"('Lady Eve, The', 'Sturges, Preston', '1941', 'Romance-Comedy'),"
"('Manhattan', 'Allen, Woody', '1979', 'Romance-Comedy'),"
"('Gertrud', 'Dreyer, Carl', '1964', 'Drama'),"
"('Shining, The', 'Kubrick, Stanley', '1980', 'Horror'),"
"('Mean Streets', 'Scorsese, Martin', '1973', 'Drama-Crime'),"
"('Olvidados, Los', 'Buñuel, Luis', '1950', 'Drama-Crime'),"
"('Pulp Fiction', 'Tarantino, Quentin', '1994', 'Drama-Crime-Comedy'),"
"('Stalker', 'Tarkovsky, Andrei', '1979', 'Science Fiction-Mystery'),"
"('Out of the Past', 'Tourneur, Jacques', '1947', 'Thriller-Mystery-Crime'),"
"('E.T. The Extra-Terrestrial', 'Spielberg, Steven', '1982', 'Science Fiction-Family'),"
"('Ran', 'Kurosawa, Akira', '1985', 'War-Historical-Drama'),"
"('McCabe & Mrs. Miller', 'Altman, Robert', '1971', 'Western-Drama'),"
"('One Flew Over the Cuckoo''s Nest', 'Forman, Milos', '1975', 'Drama'),"
"('Paisan', 'Rossellini, Roberto', '1946', 'War-Drama'),"
"('Grapes of Wrath, The', 'Ford, John', '1940', 'Drama'),"
"('Matter of Life and Death, A', 'Powell, Michael/Emeric Pressburger', '1946', 'Romance-Fantasy-Comedy'),"
"('Broken Blossoms', 'Griffith, D.W.', '1919', 'Romance-Drama'),"
"('Don''t Look Now', 'Roeg, Nicolas', '1973', 'Mystery-Thriller'),"
"('Birth of a Nation, The', 'Griffith, D.W.', '1915', 'War-Historical-Drama'),"
"('Exterminating Angel, The', 'Buñuel, Luis', '1962', 'Drama-Fantasy-Mystery'),"
"('Ashes and Diamonds', 'Wajda, Andrzej', '1958', 'War-Drama-Political'),"
"('Best Years of Our Lives, The', 'Wyler, William', '1946', 'War-Drama'),"
"('Sherlock Jr.', 'Keaton, Buster', '1924', 'Fantasy-Comedy'),"
"('Treasure of the Sierra Madre, The', 'Huston, John', '1948', 'Adventure-Drama-Western'),"
"('Close Encounters of the Third Kind', 'Spielberg, Steven', '1977', 'Science Fiction-Adventure'),"
"('Red Shoes, The', 'Powell, Michael/Emeric Pressburger', '1948', 'Dance-Musical-Drama'),"
"('Vivre sa vie', 'Godard, Jean-Luc', '1963', 'Drama'),"
"('Umberto D.', 'De Sica, Vittorio', '1952', 'Drama'),"
"('Life and Death of Colonel Blimp, The', 'Powell, Michael/Emeric Pressburger', '1943', 'War-Drama'),"
"('Brazil', 'Gilliam, Terry', '1985', 'Science Fiction-Fantasy'),"
"('Sullivan''s Travels', 'Sturges, Preston', '1941', 'Romance-Comedy'),"
"('Days of Heaven', 'Malick, Terrence', '1978', 'Romance-Drama'),"
"('Brief Encounter', 'Lean, David', '1945', 'Romance-Drama'),"
"('Earth [1930]', 'Dovzhenko, Alexander', '1930', 'Drama'),"
"('Bonnie and Clyde', 'Penn, Arthur', '1967', 'Drama-Crime-Biography'),"
"('Black Narcissus', 'Powell, Michael/Emeric Pressburger', '1946', 'Drama-Religious'),"
"('Dekalog', 'Kieslowski, Krszystof', '1988', 'Drama'),"
"('Once Upon a Time in America', 'Leone, Sergio', '1984', 'Drama-Crime'),"
"('Cabinet of Dr. Caligari, The', 'Wiene, Robert', '1919', 'Horror-Fantasy'),"
"('Badlands', 'Malick, Terrence', '1973', 'Drama-Crime'),"
"('Band Wagon, The', 'Minnelli, Vincente', '1953', 'Musical-Dance-Comedy'),"
"('Chimes at Midnight', 'Welles, Orson', '1966', 'War-Drama-Comedy'),"
"('Maltese Falcon, The [1941]', 'Huston, John', '1941', 'Mystery'),"
"('Exorcist, The', 'Friedkin, William', '1973', 'Horror'),"
"('Woman Under the Influence, A', 'Cassavetes, John', '1974', 'Drama'),"
"('Jetée, La', 'Marker, Chris', '1962', 'Science Fiction-Drama-Short'),"
"('Quiet Man, The', 'Ford, John', '1952', 'Romance-Drama-Comedy'),"
"('Man Escaped, A', 'Bresson, Robert', '1956', 'Prison-Drama'),"
"('Nights of Cabiria', 'Fellini, Federico', '1957', 'Drama'),"
"('Rocco and His Brothers', 'Visconti, Luchino', '1960', 'Drama'),"
"('Red River', 'Hawks, Howard', '1948', 'Western'),"
"('Jeanne Dielman, 23 Quai du Commerce, 1080 Bruxelles', 'Akerman, Chantal', '1975', 'Drama-Avant-Garde'),"
"('Philadelphia Story, The', 'Cukor, George', '1940', 'Romance-Comedy'),"
"('Freaks', 'Browning, Tod', '1932', 'Horror-Drama'),"
"('Conversation, The', 'Coppola, Francis', '1974', 'Thriller-Drama-Crime'),"
"('Chien andalou, Un', 'Buñuel, Luis', '1928', 'Horror-Fantasy-Avant-Garde'),"
"('Belle de jour', 'Buñuel, Luis', '1967', 'Drama'),"
"('Good, the Bad and the Ugly, The', 'Leone, Sergio', '1966', 'Western-Action'),"
"('Do the Right Thing', 'Lee, Spike', '1989', 'Drama-Comedy'),"
"('Shoah', 'Lanzmann, Claude', '1985', 'Documentary'),"
"('Trouble in Paradise', 'Lubitsch, Ernst', '1932', 'Romance-Comedy'),"
"('Partie de campagne', 'Renoir, Jean', '1936', 'Romance-Drama-Short'),"
"('Ivan the Terrible, Part Two', 'Eisenstein, Sergei', '1946', 'Historical-Drama-Biography'),"
"('Cries and Whispers', 'Bergman, Ingmar', '1972', 'Drama'),"
"('Raiders of the Lost Ark', 'Spielberg, Steven', '1981', 'Adventure-Action'),"
"('Sweet Smell of Success', 'Mackendrick, Alexander', '1957', 'Drama'),"
"('Night of the Living Dead', 'Romero, George A.', '1968', 'Horror'),"
"('Alien', 'Scott, Ridley', '1979', 'Science Fiction-Horror'),"
"('Graduate, The', 'Nichols, Mike', '1967', 'Romance-Drama-Comedy'),"
"('Deer Hunter, The', 'Cimino, Michael', '1978', 'War-Drama'),"
"('Wages of Fear, The', 'Clouzot, Henri-Georges', '1952', 'Thriller-Adventure-Action'),"
"('Travelling Players, The', 'Angelopoulos, Theo', '1975', 'Political-Drama'),"
"('Gospel According to St. Matthew, The', 'Pasolini, Pier Paolo', '1964', 'Religious-Drama'),"
"('Blow-Up', 'Antonioni, Michelangelo', '1966', 'Mystery-Drama'),"
"('Ivan the Terrible, Part One', 'Eisenstein, Sergei', '1944', 'Historical-Drama-Biography'),"
"('Belle et la bête, La', 'Cocteau, Jean', '1946', 'Fantasy'),"
"('Great Dictator, The', 'Chaplin, Charles', '1940', 'War-Comedy-Political'),"
"('Last Laugh, The', 'Murnau, F.W.', '1924', 'Drama'),"
"('Palm Beach Story, The', 'Sturges, Preston', '1942', 'Romance-Comedy'),"
"('Performance', 'Roeg, Nicolas/Donald Cammell', '1970', 'Drama'),"
"('Vampyr', 'Dreyer, Carl', '1932', 'Horror'),"
"('Mother and the Whore, The', 'Eustache, Jean', '1973', 'Drama'),"
"('Discreet Charm of the Bourgeoisie, The', 'Buñuel, Luis', '1972', 'Fantasy-Drama-Comedy'),"
"('Kind Hearts and Coronets', 'Hamer, Robert', '1949', 'Comedy'),"
"('Paths of Glory', 'Kubrick, Stanley', '1957', 'War-Drama'),"
"('Bridge on the River Kwai, The', 'Lean, David', '1957', 'War-Drama-Action'),"
"('It Happened One Night', 'Capra, Frank', '1934', 'Romance-Comedy'),"
"('In the Mood for Love', 'Wong Kar-wai', '2000', 'Romance-Drama'),"
"('Bride of Frankenstein', 'Whale, James', '1935', 'Horror-Science Fiction'),"
"('World of Apu, The', 'Ray, Satyajit', '1959', 'Drama'),"
"('Death in Venice', 'Visconti, Luchino', '1971', 'Drama'),"
"('Unforgiven', 'Eastwood, Clint', '1992', 'Western'),"
"('Monsieur Verdoux', 'Chaplin, Charles', '1947', 'Crime-Comedy'),"
"('Peeping Tom', 'Powell, Michael', '1960', 'Thriller-Drama'),"
"('Eclisse, L''', 'Antonioni, Michelangelo', '1962', 'Drama'),"
"('Schindler''s List', 'Spielberg, Steven', '1993', 'War-Historical-Drama'),"
"('Shop Around the Corner, The', 'Lubitsch, Ernst', '1940', 'Romance-Comedy'),"
"('Late Spring', 'Ozu, Yasujiro', '1949', 'Romance-Drama-Family'),"
"('Texas Chainsaw Massacre, The [1974]', 'Hooper, Tobe', '1974', 'Thriller-Horror'),"
"('Rosemary''s Baby', 'Polanski, Roman', '1968', 'Thriller-Horror-Drama'),"
"('Johnny Guitar', 'Ray, Nicholas', '1954', 'Western'),"
"('Sans soleil', 'Marker, Chris', '1983', 'Avant-Garde-Documentary'),"
"('River, The [1951]', 'Renoir, Jean', '1951', 'Romance-Drama'),"
"('Snow White and the Seven Dwarfs', 'Hand, David', '1937', 'Animated-Family-Fantasy'),"
"('Ali: Fear Eats the Soul', 'Fassbinder, Rainer Werner', '1974', 'Romance-Drama'),"
"('Crowd, The', 'Vidor, King', '1928', 'Drama'),"
"('Music Room, The', 'Ray, Satyajit', '1958', 'Drama'),"
"('Umbrellas of Cherbourg, The', 'Demy, Jacques', '1964', 'Romance-Musical-Drama'),"
"('Celine and Julie Go Boating', 'Rivette, Jacques', '1974', 'Fantasy-Drama-Avant-Garde'),"
"('Throne of Blood', 'Kurosawa, Akira', '1957', 'War-Drama'),"
"('Close-Up', 'Kiarostami, Abbas', '1989', 'Documentary-Drama-Crime'),"
"('Pandora''s Box', 'Pabst, G.W.', '1928', 'Drama-Crime-Romance'),"
"('Only Angels Have Wings', 'Hawks, Howard', '1939', 'Drama-Adventure-Romance'),"
"('Crimes and Misdemeanors', 'Allen, Woody', '1989', 'Drama-Comedy'),"
"('Solaris [1972]', 'Tarkovsky, Andrei', '1972', 'Science Fiction-Drama-Mystery'),"
"('Samouraï, Le', 'Melville, Jean-Pierre', '1967', 'Thriller-Crime'),"
"('Spirit of the Beehive, The', 'Erice, Victor', '1973', 'Drama'),"
"('Shoot the Piano Player', 'Truffaut, François', '1960', 'Drama-Crime-Thriller'),"
"('Tabu', 'Murnau, F.W.', '1931', 'Romance-Drama-Adventure'),"
"('Written on the Wind', 'Sirk, Douglas', '1956', 'Drama'),"
"('Argent, L'' [1983]', 'Bresson, Robert', '1983', 'Drama-Crime'),"
"('Mr. Hulot''s Holiday', 'Tati, Jacques', '1953', 'Comedy'),"
"('Nanook of the North', 'Flaherty, Robert', '1922', 'Documentary'),"
"('Cinema Paradiso', 'Tornatore, Giuseppe', '1988', 'Drama-Comedy'),"
"('Notte, La', 'Antonioni, Michelangelo', '1961', 'Drama'),"
"('Last Picture Show, The', 'Bogdanovich, Peter', '1971', 'Drama'),"
"('Alexander Nevsky', 'Eisenstein, Sergei', '1938', 'War-Historical-Biography'),"
"('Empire Strikes Back, The', 'Kershner, Irvin', '1980', 'Science Fiction-Fantasy-Adventure'),"
"('Imitation of Life [1959]', 'Sirk, Douglas', '1959', 'Drama-Romance'),"
"('Meet Me in St. Louis', 'Minnelli, Vincente', '1944', 'Musical-Family-Drama'),"
"('Orpheus', 'Cocteau, Jean', '1950', 'Romance-Fantasy-Drama'),"
"('To Kill a Mockingbird', 'Mulligan, Robert', '1962', 'Drama'),"
"('Birds, The', 'Hitchcock, Alfred', '1963', 'Horror'),"
"('Sátántangó', 'Tarr, Béla', '1994', 'Drama'),"
"('Fantasia', 'Sharpsteen, Ben', '1940', 'Fantasy-Family-Animated'),"
"('Berlin Alexanderplatz', 'Fassbinder, Rainer Werner', '1980', 'Drama-Historical-Political'),"
"('Star is Born, A [1954]', 'Cukor, George', '1954', 'Musical-Drama'),"
"('Diary of a Country Priest', 'Bresson, Robert', '1950', 'Religious-Drama'),"
"('Passenger, The', 'Antonioni, Michelangelo', '1975', 'Drama'),"
"('Week-End', 'Godard, Jean-Luc', '1967', 'Drama'),"
"('Last Tango in Paris', 'Bertolucci, Bernardo', '1973', 'Romance-Drama-Adult'),"
"('Germany, Year Zero', 'Rossellini, Roberto', '1947', 'War-Drama'),"
"('Senso', 'Visconti, Luchino', '1954', 'War-Drama-Romance'),"
"('Zero for Conduct', 'Vigo, Jean', '1933', 'Short-Drama'),"
"('Wings of Desire', 'Wenders, Wim', '1987', 'Fantasy-Drama'),"
"('Night at the Opera, A', 'Wood, Sam', '1935', 'Romance-Musical-Comedy'),"
"('Two or Three Things I Know About Her', 'Godard, Jean-Luc', '1966', 'Drama'),"
"('Midnight Cowboy', 'Schlesinger, John', '1969', 'Drama'),"
"('Salo, or the 120 Days of Sodom', 'Pasolini, Pier Paolo', '1975', 'Horror-Drama-Political'),"
"('Fargo', 'Coen, Joel and Ethan Coen', '1995', 'Thriller-Crime-Comedy'),"
"('Terminator, The', 'Cameron, James', '1984', 'Science Fiction-Action'),"
"('In the Realm of the Senses', 'Oshima, Nagisa', '1976', 'Drama-Adult-Romance'),"
"('Dawn of the Dead [1978]', 'Romero, George A.', '1978', 'Horror-Action'),"
"('Life of Oharu, The', 'Mizoguchi, Kenji', '1952', 'Drama'),"
"('Cabaret', 'Fosse, Bob', '1972', 'Musical-Drama-Dance'),"
"('Story of the Late Chrysanthemums, The', 'Mizoguchi, Kenji', '1939', 'Romance-Drama'),"
"('Shane', 'Stevens, George', '1953', 'Western-Drama'),"
"('Crime of Monsieur Lange, The', 'Renoir, Jean', '1936', 'Drama-Crime-Comedy'),"
"('Blue Angel, The', 'von Sternberg, Josef', '1930', 'Drama'),"
"('To Have and Have Not', 'Hawks, Howard', '1944', 'Romance-Drama'),"
"('Ninotchka', 'Lubitsch, Ernst', '1939', 'Romance-Comedy'),"
"('Day of Wrath', 'Dreyer, Carl', '1943', 'Drama'),"
"('Big Sleep, The', 'Hawks, Howard', '1946', 'Mystery-Crime'),"
"('Yojimbo', 'Kurosawa, Akira', '1961', 'Drama-Action'),"
"('West Side Story', 'Wise, Robert/Jerome Robbins', '1961', 'Romance-Musical-Dance'),"
"('Harold and Maude', 'Ashby, Hal', '1971', 'Comedy'),"
"('Mulholland Dr.', 'Lynch, David', '2001', 'Mystery-Drama'),"
"('Asphalt Jungle, The', 'Huston, John', '1950', 'Thriller-Crime'),"
"('Tree of Wooden Clogs, The', 'Olmi, Ermanno', '1978', 'Drama'),"
"('Day for Night', 'Truffaut, François', '1973', 'Drama-Comedy'),"
"('Easy Rider', 'Hopper, Dennis', '1969', 'Drama'),"
"('Night and Fog', 'Resnais, Alain', '1955', 'War-Documentary-Short'),"
"('Dog Day Afternoon', 'Lumet, Sidney', '1975', 'Drama-Crime'),"
"('1900', 'Bertolucci, Bernardo', '1976', 'Political-Drama'),"
"('Floating Clouds', 'Naruse, Mikio', '1955', 'Romance-Drama'),"
"('Halloween', 'Carpenter, John', '1978', 'Horror-Thriller'),"
"('Lola Montès', 'Ophüls, Max', '1955', 'Drama-Biography'),"
"('Make Way for Tomorrow', 'McCarey, Leo', '1937', 'Drama'),"
"('Kid, The', 'Chaplin, Charles', '1921', 'Drama-Comedy-Family'),"
"('Mouchette', 'Bresson, Robert', '1966', 'Drama'),"
"('Shadows', 'Cassavetes, John', '1959', 'Drama'),"
"('Strangers on a Train', 'Hitchcock, Alfred', '1951', 'Thriller-Drama-Crime'),"
"('Network', 'Lumet, Sidney', '1976', 'Drama'),"
"('Come and See', 'Klimov, Elem', '1985', 'War-Drama'),"
"('Black God, White Devil', 'Rocha, Glauber', '1964', 'Political-Drama-Crime'),"
"('Red Desert', 'Antonioni, Michelangelo', '1964', 'Drama'),"
"('My Night at Maud''s', 'Rohmer, Eric', '1969', 'Romance-Drama'),"
"('King of Comedy, The', 'Scorsese, Martin', '1983', 'Drama-Comedy'),"
"('In a Lonely Place', 'Ray, Nicholas', '1950', 'Drama-Mystery-Romance'),"
"('Scarlet Empress, The', 'von Sternberg, Josef', '1934', 'Historical-Drama-Biography'),"
"('Million, Le', 'Clair, René', '1931', 'Comedy-Musical'),"
"('All That Heaven Allows', 'Sirk, Douglas', '1955', 'Romance-Drama'),"
"('Yi yi', 'Yang, Edward', '2000', 'Drama'),"
"('Paris, Texas', 'Wenders, Wim', '1984', 'Drama'),"
"('Laura', 'Preminger, Otto', '1944', 'Mystery-Romance-Thriller'),"
"('High Noon', 'Zinnemann, Fred', '1952', 'Western'),"
"('Kiss Me Deadly', 'Aldrich, Robert', '1955', 'Crime-Thriller'),"
"('Five Easy Pieces', 'Rafelson, Bob', '1970', 'Drama'),"
"('39 Steps, The', 'Hitchcock, Alfred', '1935', 'Spy-Thriller'),"
"('Thief of Bagdad, The [1940]', 'Powell, Michael/Ludwig Berger/Tim Whelan', '1940', 'Fantasy-Family-Adventure'),"
"('Wind, The', 'Sjöström, Victor', '1928', 'Drama'),"
"('Top Hat', 'Sandrich, Mark', '1935', 'Romance-Musical-Comedy'),"
"('Cameraman, The', 'Keaton, Buster/Edward Sedgwick', '1928', 'Romance-Comedy'),"
"('Aliens', 'Cameron, James', '1986', 'Science Fiction-Horror-Action'),"
"('African Queen, The', 'Huston, John', '1951', 'Romance-Adventure'),"
"('Triumph of the Will', 'Riefenstahl, Leni', '1935', 'Documentary-Historical-Political'),"
"('Doctor Zhivago', 'Lean, David', '1965', 'War-Romance-Drama'),"
"('Kings of the Road', 'Wenders, Wim', '1976', 'Drama'),"
"('Salvatore Giuliano', 'Rosi, Francesco', '1961', 'Historical-Drama-Crime'),"
"('Aparajito', 'Ray, Satyajit', '1956', 'Drama'),"
"('Rebel Without a Cause', 'Ray, Nicholas', '1955', 'Drama'),"
"('Miracle in Milan', 'De Sica, Vittorio', '1951', 'Fantasy-Drama-Comedy'),"
"('Piano, The', 'Campion, Jane', '1993', 'Historical-Drama-Romance'),"
"('Chungking Express', 'Wong Kar-wai', '1994', 'Romance-Drama'),"
"('Strike', 'Eisenstein, Sergei', '1924', 'Historical-Drama-Political'),"
"('All the President''s Men', 'Pakula, Alan J.', '1976', 'Political-Drama'),"
"('White Heat', 'Walsh, Raoul', '1949', 'Crime'),"
"('Meshes of the Afternoon', 'Deren, Maya', '1943', 'Short-Avant-Garde-Fantasy'),"
"('Heat [1995]', 'Mann, Michael', '1995', 'Thriller-Drama-Crime'),"
"('Autumn Afternoon, An', 'Ozu, Yasujiro', '1962', 'Drama'),"
"('Carrie [1976]', 'De Palma, Brian', '1976', 'Horror-Thriller'),"
"('Time to Live and the Time to Die, The', 'Hou Hsiao-hsien', '1985', 'Drama'),"
"('Killer of Sheep', 'Burnett, Charles', '1977', 'Drama'),"
"('Reservoir Dogs', 'Tarantino, Quentin', '1991', 'Drama-Crime-Thriller'),"
"('Hustler, The', 'Rossen, Robert', '1961', 'Drama-Sports'),"
"('Great Expectations [1946]', 'Lean, David', '1946', 'Romance-Drama'),"
"('Wavelength', 'Snow, Michael', '1967', 'Avant-Garde'),"
"('Canterbury Tale, A', 'Powell, Michael/Emeric Pressburger', '1944', 'Drama'),"
"('Big Lebowski, The', 'Coen, Joel and Ethan Coen', '1998', 'Comedy-Crime'),"
"('Point Blank', 'Boorman, John', '1967', 'Thriller-Crime-Action'),"
"('This is Spinal Tap', 'Reiner, Rob', '1984', 'Comedy'),"
"('High and Low', 'Kurosawa, Akira', '1963', 'Thriller-Crime-Drama'),"
"('Eraserhead', 'Lynch, David', '1976', 'Horror'),"
"('F for Fake', 'Welles, Orson', '1973', 'Documentary-Avant-Garde'),"
"('Verdugo, El', 'Berlanga, Luis García', '1963', 'Drama-Comedy'),"
"('Rebecca', 'Hitchcock, Alfred', '1940', 'Mystery-Romance-Drama'),"
"('Man of Aran', 'Flaherty, Robert', '1934', 'Documentary'),"
"('Mad Max 2', 'Miller, George', '1981', 'Science Fiction-Action'),"
"('El', 'Buñuel, Luis', '1952', 'Drama'),"
"('Monty Python''s Life of Brian', 'Jones, Terry', '1979', 'Religious-Comedy'),"
"('How Green Was My Valley', 'Ford, John', '1941', 'Drama'),"
"('Charulata', 'Ray, Satyajit', '1964', 'Romance-Drama'),"
"('City of Sadness, A', 'Hou Hsiao-hsien', '1989', 'Political-Drama'),"
"('Cloud-Capped Star, The', 'Ghatak, Ritwik', '1960', 'Drama-Musical'),"
"('Groundhog Day', 'Ramis, Harold', '1993', 'Romance-Fantasy-Comedy'),"
"('Shadow of a Doubt', 'Hitchcock, Alfred', '1943', 'Thriller'),"
"('All Quiet on the Western Front', 'Milestone, Lewis', '1930', 'War-Drama'),"
"('Silence of the Lambs, The', 'Demme, Jonathan', '1991', 'Thriller-Mystery'),"
"('Eyes Without a Face', 'Franju, Georges', '1959', 'Horror-Drama-Thriller'),"
"('Amadeus', 'Forman, Milos', '1984', 'Musical-Biography-Drama'),"
"('Memories of Underdevelopment', 'Alea, Tomás Gutiérrez', '1968', 'Political-Romance-Drama'),"
"('October', 'Eisenstein, Sergei', '1927', 'Historical-Drama'),"
"('Distant Voices, Still Lives', 'Davies, Terence', '1988', 'Drama'),"
"('Sacrifice, The', 'Tarkovsky, Andrei', '1986', 'Drama'),"
"('Invasion of the Body Snatchers [1956]', 'Siegel, Don', '1956', 'Science Fiction-Horror'),"
"('Awful Truth, The', 'McCarey, Leo', '1937', 'Romance-Comedy'),"
"('Breaking the Waves', 'von Trier, Lars', '1996', 'Romance-Drama'),"
"('Closely Watched Trains', 'Menzel, Jirí', '1966', 'Drama-Comedy'),"
"('Cat People [1942]', 'Tourneur, Jacques', '1942', 'Thriller-Horror-Mystery'),"
"('Ben-Hur [1959]', 'Wyler, William', '1959', 'Religious-Historical'),"
"('Manchurian Candidate, The [1962]', 'Frankenheimer, John', '1962', 'Political-Thriller-Drama'),"
"('Big Heat, The', 'Lang, Fritz', '1953', 'Drama-Crime'),"
"('Back to the Future', 'Zemeckis, Robert', '1985', 'Science Fiction-Comedy'),"
"('Deliverance', 'Boorman, John', '1972', 'Adventure-Thriller-Drama'),"
"('Vitelloni, I', 'Fellini, Federico', '1953', 'Drama'),"
"('Dead, The [1987]', 'Huston, John', '1987', 'Drama'),"
"('Frankenstein', 'Whale, James', '1931', 'Horror-Science Fiction'),"
"('Accattone', 'Pasolini, Pier Paolo', '1961', 'Drama'),"
"('Kes', 'Loach, Ken', '1969', 'Drama'),"
"('Butch Cassidy and the Sundance Kid', 'Hill, George Roy', '1969', 'Western'),"
"('Casque d''or', 'Becker, Jacques', '1952', 'Romance-Drama-Crime'),"
"('Foolish Wives', 'von Stroheim, Erich', '1922', 'Drama'),"
"('Streetcar Named Desire, A', 'Kazan, Elia', '1951', 'Drama'),"
"('Wedding March, The', 'von Stroheim, Erich', '1928', 'Romance-Drama'),"
"('Navigator, The', 'Keaton, Buster/Donald Crisp', '1924', 'Comedy-Adventure'),"
"('Marnie', 'Hitchcock, Alfred', '1964', 'Romance-Thriller-Mystery'),"
"('Evil Dead II', 'Raimi, Sam', '1987', 'Horror'),"
"('Killing of a Chinese Bookie, The', 'Cassavetes, John', '1976', 'Drama-Crime'),"
"('Claire''s Knee', 'Rohmer, Eric', '1971', 'Romance-Drama-Comedy'),"
"('Servant, The', 'Losey, Joseph', '1963', 'Drama'),"
"('Spartacus', 'Kubrick, Stanley', '1960', 'Adventure-Historical-Drama'),"
"('Forbidden Games', 'Clément, René', '1951', 'War-Drama'),"
"('Killing, The', 'Kubrick, Stanley', '1956', 'Crime'),"
"('Don''t Look Back', 'Pennebaker, D.A.', '1967', 'Documentary-Musical'),"
"('Tristana', 'Buñuel, Luis', '1970', 'Drama'),"
"('Mon oncle', 'Tati, Jacques', '1958', 'Comedy'),"
"('Love Streams', 'Cassavetes, John', '1984', 'Drama'),"
"('Lady Vanishes, The', 'Hitchcock, Alfred', '1938', 'Spy-Mystery-Thriller'),"
"('My Neighbour Totoro', 'Miyazaki, Hayao', '1988', 'Fantasy-Family-Animated'),"
"('Stranger Than Paradise', 'Jarmusch, Jim', '1984', 'Comedy'),"
"('Listen to Britain', 'Jennings, Humphrey', '1942', 'Documentary-Short-War'),"
"('Repulsion', 'Polanski, Roman', '1965', 'Horror-Thriller'),"
"('Sound of Music, The', 'Wise, Robert', '1965', 'Musical-Drama-Family'),"
"('In a Year with 13 Moons', 'Fassbinder, Rainer Werner', '1978', 'Drama'),"
"('Mr. Smith Goes to Washington', 'Capra, Frank', '1939', 'Political-Drama'),"
"('Toy Story', 'Lasseter, John', '1995', 'Fantasy-Comedy-Family-Animated'),"
"('Love Me Tonight', 'Mamoulian, Rouben', '1932', 'Musical-Comedy-Romance'),"
"('Pinocchio', 'Sharpsteen, Ben & Hamilton Luske', '1940', 'Fantasy-Family-Animated'),"
"('Providence', 'Resnais, Alain', '1977', 'Drama'),"
"('Saturday Night and Sunday Morning', 'Reisz, Karel', '1960', 'Drama'),"
"('Suspiria', 'Argento, Dario', '1977', 'Horror'),"
"('Lady from Shanghai, The', 'Welles, Orson', '1948', 'Mystery-Crime-Thriller'),"
"('Steamboat Bill, Jr.', 'Keaton, Buster/Charles F. Reisner', '1928', 'Romance-Comedy-Adventure'),"
"('I Know Where I''m Going!', 'Powell, Michael/Emeric Pressburger', '1945', 'Romance-Comedy-Drama'),"
"('Chelsea Girls', 'Warhol, Andy', '1967', 'Drama-Avant-Garde'),"
"('Pyaasa', 'Dutt, Guru', '1957', 'Drama'),"
"('Colour of Pomegranate, The', 'Parajanov, Sergei', '1969', 'Historical-Avant-Garde'),"
"('Plaisir, Le', 'Ophüls, Max', '1951', 'Romance-Drama'),"
"('Fellini Satyricon', 'Fellini, Federico', '1969', 'Historical-Drama'),"
"('Rocky', 'Avildsen, John G.', '1976', 'Sports-Drama'),"
"('Flowers of St. Francis, The', 'Rossellini, Roberto', '1950', 'Religious-Drama'),"
"('Some Came Running', 'Minnelli, Vincente', '1958', 'Drama'),"
"('Henry V [1944]', 'Olivier, Laurence', '1944', 'War-Drama-Historical'),"
"('Alice in the Cities', 'Wenders, Wim', '1974', 'Drama'),"
"('Loves of a Blonde', 'Forman, Milos', '1965', 'Drama-Comedy'),"
"('Our Hospitality', 'Keaton, Buster/John Blystone', '1923', 'Comedy-Family-Romance'),"
"('Bring Me the Head of Alfredo Garcia', 'Peckinpah, Sam', '1974', 'Crime-Thriller-Action'),"
"('Hard Day''s Night, A', 'Lester, Richard', '1964', 'Musical-Comedy'),"
"('Spirited Away', 'Miyazaki, Hayao', '2001', 'Animated-Adventure-Fantasy'),"
"('Vampires, Les', 'Feuillade, Louis', '1915', 'Thriller-Crime-Action'),"
"('if…', 'Anderson, Lindsay', '1968', 'Drama'),"
"('L.A. Confidential', 'Hanson, Curtis', '1997', 'Thriller-Crime'),"
"('Brighter Summer Day, A', 'Yang, Edward', '1991', 'Political-Romance-Drama'),"
"('Innocents, The', 'Clayton, Jack', '1961', 'Horror-Thriller'),"
"('Scorpio Rising', 'Anger, Kenneth', '1964', 'Short-Avant-Garde'),"
"('Thelma & Louise', 'Scott, Ridley', '1991', 'Drama-Comedy-Adventure'),"
"('Man Who Would Be King, The', 'Huston, John', '1975', 'Adventure'),"
"('Faust', 'Murnau, F.W.', '1926', 'Fantasy-Drama-Horror'),"
"('American Graffiti', 'Lucas, George', '1973', 'Drama-Comedy'),"
"('Tootsie', 'Pollack, Sydney', '1982', 'Romance-Comedy'),"
"('Monty Python and the Holy Grail', 'Gilliam, Terry/Terry Jones', '1975', 'Historical-Comedy'),"
"('Muriel', 'Resnais, Alain', '1963', 'Drama'),"
"('Double Life of Veronique, The', 'Kieslowski, Krszystof', '1991', 'Fantasy-Drama-Romance'),"
"('Full Metal Jacket', 'Kubrick, Stanley', '1987', 'War-Drama-Action'),"
"('Army of Shadows', 'Melville, Jean-Pierre', '1969', 'War-Drama'),"
"('Spring in a Small Town', 'Fei Mu', '1948', 'Romance-Drama'),"
"('Bande à part', 'Godard, Jean-Luc', '1964', 'Crime-Drama-Romance'),"
"('Ferris Bueller''s Day Off', 'Hughes, John', '1986', 'Comedy'),"
"('Local Hero', 'Forsyth, Bill', '1983', 'Drama-Comedy'),"
"('Right Stuff, The', 'Kaufman, Philip', '1983', 'Drama-Biography'),"
"('Gun Crazy', 'Lewis, Joseph H.', '1949', 'Drama-Crime'),"
"('JFK', 'Stone, Oliver', '1991', 'Historical-Drama'),"
"('India Song', 'Duras, Marguerite', '1974', 'Drama'),"
"('Adventures of Robin Hood, The', 'Curtiz, Michael/William Keighley', '1938', 'Adventure'),"
"('Dead Man', 'Jarmusch, Jim', '1995', 'Western-Drama'),"
"('Dersu Uzala', 'Kurosawa, Akira', '1975', 'Drama-Adventure'),"
"('Scenes from a Marriage', 'Bergman, Ingmar', '1973', 'Drama'),"
"('Dumbo', 'Sharpsteen, Ben', '1941', 'Musical-Family-Animated'),"
"('Terra em Transe', 'Rocha, Glauber', '1967', 'Drama-Political'),"
"('Winter Light', 'Bergman, Ingmar', '1962', 'Religious-Drama'),"
"('Raising Arizona', 'Coen, Joel and Ethan Coen', '1987', 'Comedy'),"
"('My Life as a Dog', 'Hallström, Lasse', '1985', 'Drama-Comedy'),"
"('Last Detail, The', 'Ashby, Hal', '1973', 'Drama'),"
"('Raise the Red Lantern', 'Zhang Yimou', '1991', 'Drama'),"
"('Young Girls of Rochefort, The', 'Demy, Jacques', '1967', 'Musical-Dance-Comedy'),"
"('Breakfast at Tiffany''s', 'Edwards, Blake', '1961', 'Romance-Drama-Comedy'),"
"('It''s a Gift', 'McLeod, Norman Z.', '1934', 'Comedy'),"
"('Nostalghia', 'Tarkovsky, Andrei', '1983', 'Drama'),"
"('Edward Scissorhands', 'Burton, Tim', '1990', 'Romance-Fantasy'),"
"('Videodrome', 'Cronenberg, David', '1983', 'Horror-Science Fiction'),"
"('Touch of Zen, A', 'Hu, King', '1969', 'Adventure-Action-Drama'),"
"('Three Colours: Red', 'Kieslowski, Krszystof', '1994', 'Drama'),"
"('Enigma of Kaspar Hauser, The', 'Herzog, Werner', '1974', 'Biography-Drama'),"
"('All That Jazz', 'Fosse, Bob', '1979', 'Musical-Fantasy-Drama'),"
"('Shawshank Redemption, The', 'Darabont, Frank', '1994', 'Prison-Drama'),"
"('12 Angry Men', 'Lumet, Sidney', '1957', 'Drama'),"
"('Affair to Remember, An', 'McCarey, Leo', '1957', 'Romance-Drama'),"
"('Producers, The', 'Brooks, Mel', '1968', 'Comedy'),"
"('Seven Chances', 'Keaton, Buster', '1925', 'Romance-Comedy'),"
"('Tiger of Eschnapur, The', 'Lang, Fritz', '1958', 'Romance-Adventure'),"
"('Voyage dans la lune, Le', 'Méliès, Georges', '1902', 'Science Fiction-Short-Adventure'),"
"('Cool Hand Luke', 'Rosenberg, Stuart', '1967', 'Prison-Drama'),"
"('Lola [1961]', 'Demy, Jacques', '1961', 'Romance-Drama'),"
"('Scarface [1932]', 'Hawks, Howard', '1932', 'Crime-Biography-Drama'),"
"('French Cancan', 'Renoir, Jean', '1955', 'Musical-Drama-Comedy'),"
"('Fat City', 'Huston, John', '1972', 'Sports'),"
"('Moment of Innocence, A', 'Makhmalbaf, Mohsen', '1995', 'Drama-Comedy'),"
"('Fitzcarraldo', 'Herzog, Werner', '1982', 'Drama-Adventure'),"
"('Faces', 'Cassavetes, John', '1968', 'Drama'),"
"('Midnight Run', 'Brest, Martin', '1988', 'Crime-Comedy'),"
"('Barton Fink', 'Coen, Joel and Ethan Coen', '1991', 'Drama-Comedy'),"
"('Juliet of the Spirits', 'Fellini, Federico', '1965', 'Fantasy-Drama'),"
"('Thing from Another World, The', 'Nyby, Christian/Howard Hawks', '1951', 'Science Fiction'),"
"('I Am Cuba', 'Kalatozov, Mikhail', '1964', 'Political-Drama'),"
"('Where is the Friend''s Home?', 'Kiarostami, Abbas', '1987', 'Drama'),"
"('Underground', 'Kusturica, Emir', '1995', 'War-Drama-Comedy'),"
"('I Walked with a Zombie', 'Tourneur, Jacques', '1943', 'Horror-Drama-Romance'),"
"('I Was Born, But…', 'Ozu, Yasujiro', '1932', 'Drama-Comedy'),"
"('Husbands', 'Cassavetes, John', '1970', 'Drama'),"
"('Limelight', 'Chaplin, Charles', '1952', 'Drama-Comedy'),"
"('Masculin Feminin', 'Godard, Jean-Luc', '1966', 'Drama'),"
"('Three Colours: Blue', 'Kieslowski, Krszystof', '1993', 'Drama'),"
"('Kagemusha', 'Kurosawa, Akira', '1980', 'War-Drama-Historical'),"
"('Withnail & I', 'Robinson, Bruce', '1987', 'Drama'),"
"('Being There', 'Ashby, Hal', '1979', 'Drama-Comedy'),"
"('42nd Street', 'Bacon, Lloyd', '1933', 'Musical-Dance-Comedy'),"
"('Eternal Sunshine of the Spotless Mind', 'Gondry, Michel', '2004', 'Romance-Drama-Comedy'),"
"('Golden Coach, The', 'Renoir, Jean', '1952', 'Drama-Comedy-Romance'),"
"('Dames du Bois de Boulogne, Les', 'Bresson, Robert', '1945', 'Drama-Romance'),"
"('Silence, The', 'Bergman, Ingmar', '1963', 'Drama'),"
"('Lancelot du Lac', 'Bresson, Robert', '1974', 'Fantasy-Drama'),"
"('Dirty Harry', 'Siegel, Don', '1971', 'Crime-Action'),"
"('Odd Man Out', 'Reed, Carol', '1947', 'Drama-Crime-Thriller'),"
"('Terra trema, La', 'Visconti, Luchino', '1947', 'Drama'),"
"('Man Who Fell to Earth, The', 'Roeg, Nicolas', '1976', 'Science Fiction-Drama'),"
"('Down by Law', 'Jarmusch, Jim', '1986', 'Comedy'),"
"('Thing, The [1982]', 'Carpenter, John', '1982', 'Science Fiction-Action-Horror'),"
"('Dead Ringers', 'Cronenberg, David', '1988', 'Thriller-Horror-Drama'),"
"('Get Carter', 'Hodges, Mike', '1971', 'Crime'),"
"('Terminator 2: Judgment Day', 'Cameron, James', '1991', 'Science Fiction-Action'),"
"('Long Goodbye, The', 'Altman, Robert', '1973', 'Drama-Crime'),"
"('Day the Earth Stood Still, The', 'Wise, Robert', '1951', 'Science Fiction'),"
"('Age of Innocence, The', 'Scorsese, Martin', '1993', 'Romance-Drama'),"
"('She Wore a Yellow Ribbon', 'Ford, John', '1949', 'Western-War'),"
"('Two-Lane Blacktop', 'Hellman, Monte', '1971', 'Drama'),"
"('Lolita [1962]', 'Kubrick, Stanley', '1962', 'Drama'),"
"('Detour', 'Ulmer, Edgar G.', '1945', 'Crime'),"
"('They Were Expendable', 'Ford, John', '1945', 'War-Drama'),"
"('Olympia', 'Riefenstahl, Leni', '1938', 'Documentary-Sports'),"
"('Eyes Wide Shut', 'Kubrick, Stanley', '1999', 'Thriller-Drama'),"
"('Reds', 'Beatty, Warren', '1981', 'Historical-Drama-Biography'),"
"('Jour se lève, Le', 'Carné, Marcel', '1939', 'Thriller-Crime-Drama'),"
"('On the Town', 'Donen, Stanley/Gene Kelly', '1949', 'Musical-Dance'),"
"('À nous la liberté', 'Clair, René', '1931', 'Comedy-Fantasy'),"
"('Trainspotting', 'Boyle, Danny', '1995', 'Drama-Comedy'),"
"('Forrest Gump', 'Zemeckis, Robert', '1994', 'Drama-Comedy'),"
"('That Obscure Object of Desire', 'Buñuel, Luis', '1977', 'Drama'),"
"('Tenant, The', 'Polanski, Roman', '1976', 'Horror-Thriller-Mystery'),"
"('Great Escape, The', 'Sturges, John', '1963', 'War-Prison-Adventure'),"
"('Bitter Tears of Petra von Kant, The', 'Fassbinder, Rainer Werner', '1972', 'Drama'),"
"('Fellini''s Casanova', 'Fellini, Federico', '1976', 'Drama-Biography'),"
"('Place in the Sun, A', 'Stevens, George', '1951', 'Romance-Drama'),"
"('Teorema', 'Pasolini, Pier Paolo', '1968', 'Drama'),"
"('Alphaville', 'Godard, Jean-Luc', '1965', 'Science Fiction'),"
"('Antonio das Mortes', 'Rocha, Glauber', '1969', 'Drama-Western-Political'),"
"('Othello', 'Welles, Orson', '1952', 'Drama'),"
"('Killer, The', 'Woo, John', '1989', 'Thriller-Crime-Action'),"
"('Seven Women', 'Ford, John', '1966', 'Historical-Drama'),"
"('Ride the High Country', 'Peckinpah, Sam', '1962', 'Western'),"
"('Damned, The', 'Visconti, Luchino', '1969', 'War-Drama'),"
"('Salesman', 'Maysles, Albert/David Maysles/Charlotte Zwerin', '1968', 'Documentary'),"
"('Tin Drum, The', 'Schlöndorff, Volker', '1979', 'War-Drama'),"
"('Boogie Nights', 'Anderson, Paul Thomas', '1997', 'Drama'),"
"('Cleo from 5 to 7', 'Varda, Agnès', '1961', 'Drama'),"
"('Devils, The', 'Russell, Ken', '1971', 'Historical-Drama-Horror'),"
"('Picnic at Hanging Rock', 'Weir, Peter', '1975', 'Mystery-Drama'),"
"('Outlaw Josey Wales, The', 'Eastwood, Clint', '1976', 'Western-Drama'),"
"('Blow Out', 'De Palma, Brian', '1981', 'Thriller-Mystery'),"
"('Die Hard', 'McTiernan, John', '1988', 'Thriller-Action'),"
"('Red Balloon, The', 'Lamorisse, Albert', '1956', 'Fantasy-Family-Short'),"
"('Marriage of Maria Braun, The', 'Fassbinder, Rainer Werner', '1978', 'War-Drama'),"
"('Fight Club', 'Fincher, David', '1999', 'Drama-Comedy'),"
"('Time of the Gypsies', 'Kusturica, Emir', '1989', 'Drama'),"
"('Bob le flambeur', 'Melville, Jean-Pierre', '1955', 'Crime'),"
"('Party, The', 'Edwards, Blake', '1968', 'Comedy'),"
"('Pépé le Moko', 'Duvivier, Julien', '1936', 'Romance-Drama-Crime'),"
"('And Life Goes On…', 'Kiarostami, Abbas', '1992', 'Drama-Documentary'),"
"('Fly, The [1986]', 'Cronenberg, David', '1986', 'Horror'),"
"('War and Peace [1967]', 'Bondarchuk, Sergei', '1967', 'War-Historical-Drama'),"
"('Bambi', 'Hand, David', '1942', 'Family-Animated-Drama'),"
"('Pat Garrett and Billy the Kid', 'Peckinpah, Sam', '1973', 'Western'),"
"('Hour of the Furnaces, The', 'Getino, Octavio & Fernando E. Solanas', '1968', 'Political-Drama'),"
"('Shadows of Our Forgotten Ancestors', 'Parajanov, Sergei', '1964', 'Romance-Drama-Historical'),"
"('Young Frankenstein', 'Brooks, Mel', '1974', 'Horror-Comedy-Science Fiction'),"
"('Barren Lives', 'Dos Santos, Nelson Pereira', '1963', 'Drama'),"
"('Devil is a Woman, The', 'von Sternberg, Josef', '1935', 'Romance-Drama'),"
"('Diaboliques, Les', 'Clouzot, Henri-Georges', '1955', 'Thriller-Mystery'),"
"('Beyond the Valley of the Dolls', 'Meyer, Russ', '1970', 'Drama-Comedy'),"
"('French Connection, The', 'Friedkin, William', '1971', 'Crime'),"
"('Blood of a Poet, The', 'Cocteau, Jean', '1930', 'Fantasy-Drama'),"
"('Angel at My Table, An', 'Campion, Jane', '1990', 'Drama-Biography'),"
"('Barefoot Contessa, The', 'Mankiewicz, Joseph L.', '1954', 'Drama'),"
"('Stromboli', 'Rossellini, Roberto', '1949', 'Drama'),"
"('Cranes Are Flying, The', 'Kalatozov, Mikhail', '1957', 'War-Romance-Drama'),"
"('M*A*S*H', 'Altman, Robert', '1970', 'War-Comedy'),"
"('Lives of Others, The', 'von Donnersmarck, Florian Henckel', '2006', 'Drama'),"
"('Xala', 'Sembene, Ousmane', '1974', 'Comedy'),"
"('Passion', 'Godard, Jean-Luc', '1982', 'Drama'),"
"('Excalibur', 'Boorman, John', '1981', 'Fantasy-Adventure-Action'),"
"('Young Mr. Lincoln', 'Ford, John', '1939', 'Political-Biography-Drama'),"
"('Ossessione', 'Visconti, Luchino', '1942', 'Drama'),"
"('City of God', 'Meirelles, Fernando', '2002', 'Drama-Crime-Action'),"
"('Bigger Than Life', 'Ray, Nicholas', '1956', 'Drama'),"
"('Région centrale, La', 'Snow, Michael', '1971', 'Avant-Garde'),"
"('Story of a Cheat, The', 'Guitry, Sacha', '1936', 'Comedy'),"
"('Through the Olive Trees', 'Kiarostami, Abbas', '1994', 'Drama'),"
"('Chant d''amour, Un', 'Genet, Jean', '1950', 'Drama'),"
"('Short Cuts', 'Altman, Robert', '1993', 'Drama'),"
"('Mildred Pierce', 'Curtiz, Michael', '1945', 'Drama'),"
"('There Will Be Blood', 'Anderson, Paul Thomas', '2007', 'Drama'),"
"('East of Eden', 'Kazan, Elia', '1955', 'Drama'),"
"('Liebelei', 'Ophüls, Max', '1932', 'Romance-Drama'),"
"('Ivan''s Childhood', 'Tarkovsky, Andrei', '1962', 'War-Drama'),"
"('Titicut Follies', 'Wiseman, Frederick', '1967', 'Documentary'),"
"('Heaven''s Gate', 'Cimino, Michael', '1980', 'Western-Drama-Historical'),"
"('Funny Face', 'Donen, Stanley', '1957', 'Musical-Dance'),"
"('Scarface [1983]', 'De Palma, Brian', '1983', 'Drama-Crime'),"
"('Now, Voyager', 'Rapper, Irving', '1942', 'Romance-Drama'),"
"('They Live by Night', 'Ray, Nicholas', '1948', 'Drama-Crime'),"
"('Wild Child, The', 'Truffaut, François', '1969', 'Drama'),"
"('Miller''s Crossing', 'Coen, Joel and Ethan Coen', '1990', 'Crime'),"
"('Wagon Master', 'Ford, John', '1950', 'Western'),"
"('Van Gogh', 'Pialat, Maurice', '1991', 'Drama-Biography'),"
"('Gregory''s Girl', 'Forsyth, Bill', '1980', 'Romance-Comedy'),"
"('Hitler: A Film from Germany', 'Syberberg, Hans-Jürgen', '1977', 'Drama-Avant Garde'),"
"('Walkabout', 'Roeg, Nicolas', '1971', 'Drama-Adventure'),"
"('America, America', 'Kazan, Elia', '1963', 'Drama'),"
"('Circus, The', 'Chaplin, Charles', '1928', 'Drama-Comedy-Family'),"
"('Naked', 'Leigh, Mike', '1993', 'Drama'),"
"('Princess Yang Kwei Fei', 'Mizoguchi, Kenji', '1955', 'Romance-Drama-Historical'),"
"('Swing Time', 'Stevens, George', '1936', 'Romance-Musical-Dance'),"
"('Hallelujah!', 'Vidor, King', '1929', 'Musical-Drama'),"
"('Bad and the Beautiful, The', 'Minnelli, Vincente', '1952', 'Drama'),"
"('Blues Brothers, The', 'Landis, John', '1980', 'Action-Comedy-Musical'),"
"('Woman in the Dunes', 'Teshigahara, Hiroshi', '1964', 'Drama'),"
"('Holiday', 'Cukor, George', '1938', 'Comedy'),"
"('Farewell, My Concubine', 'Chen Kaige', '1993', 'Historical-Drama-Romance'),"
"('Matrix, The', 'Wachowski, Andy & Larry Wachowski', '1999', 'Science Fiction-Action'),"
"('Tarnished Angels, The', 'Sirk, Douglas', '1958', 'Drama'),"
"('American in Paris, An', 'Minnelli, Vincente', '1951', 'Musical-Dance'),"
"('Forbidden Planet', 'Wilcox, Fred M.', '1956', 'Science Fiction'),"
"('Que viva Mexico!', 'Eisenstein, Sergei', '1932', 'Historical'),"
"('Thin Red Line, The', 'Malick, Terrence', '1998', 'War-Drama-Action'),"
"('Beau travail', 'Denis, Claire', '1998', 'Drama'),"
"('Grey Gardens', 'Maysles, David/Albert Maysles/Ellen Hovde/Muffie Meyer', '1975', 'Documentary-Comedy'),"
"('Elephant Man, The', 'Lynch, David', '1980', 'Drama-Biography'),"
"('Duel in the Sun', 'Vidor, King', '1946', 'Western'),"
"('Crouching Tiger, Hidden Dragon', 'Lee, Ang', '2000', 'Drama-Adventure-Action'),"
"('Roman Holiday', 'Wyler, William', '1953', 'Romance-Comedy-Drama'),"
"('Fires Were Started', 'Jennings, Humphrey', '1943', 'Documentary-Drama'),"
"('Outskirts [1933]', 'Barnet, Boris', '1933', 'War-Drama'),"
"('Diner', 'Levinson, Barry', '1982', 'Drama-Comedy'),"
"('Rushmore', 'Anderson, Wes', '1998', 'Comedy'),"
"('Land Without Bread', 'Buñuel, Luis', '1932', 'Documentary-Short-Drama'),"
"('Morocco', 'von Sternberg, Josef', '1930', 'War-Romance-Drama'),"
"('Sauve qui peut (la vie)', 'Godard, Jean-Luc', '1980', 'Drama'),"
"('Talk to Her', 'Almodóvar, Pedro', '2002', 'Romance-Drama'),"
"('Sawdust and Tinsel', 'Bergman, Ingmar', '1953', 'Drama'),"
"('Smiles of a Summer Night', 'Bergman, Ingmar', '1955', 'Romance-Comedy'),"
"('Secrets & Lies', 'Leigh, Mike', '1995', 'Drama-Comedy'),"
"('Storm Over Asia', 'Pudovkin, Vsevolod', '1928', 'Historical-Drama-Action'),"
"('Sorrow and the Pity, The', 'Ophüls, Marcel', '1970', 'Documentary-War-Historical'),"
"('Shock Corridor', 'Fuller, Sam', '1963', 'Drama-Mystery'),"
"('Dr. Mabuse, The Gambler', 'Lang, Fritz', '1922', 'Thriller-Mystery-Crime'),"
"('Threepenny Opera, The', 'Pabst, G.W.', '1931', 'Opera-Musical-Comedy'),"
"('Phantom of Liberty, The', 'Buñuel, Luis', '1974', 'Drama-Comedy-Avant Garde'),"
"('Blood Simple', 'Coen, Joel and Ethan Coen', '1984', 'Thriller-Drama-Crime'),"
"('End of Summer, The', 'Ozu, Yasujiro', '1961', 'Drama'),"
"('Hart of London, The', 'Chambers, Jack', '1970', 'Avant-Garde'),"
"('Woman Next Door, The', 'Truffaut, François', '1981', 'Romance-Drama'),"
"('All About My Mother', 'Almodóvar, Pedro', '1999', 'Drama-Comedy'),"
"('Donnie Darko', 'Kelly, Richard', '2001', 'Fantasy-Drama'),"
"('Chienne, La', 'Renoir, Jean', '1931', 'Drama'),"
"('Thin Blue Line, The', 'Morris, Errol', '1988', 'Documentary'),"
"('Mother [1926]', 'Pudovkin, Vsevolod', '1926', 'Drama'),"
"('Gentlemen Prefer Blondes', 'Hawks, Howard', '1953', 'Romance-Musical-Comedy'),"
"('Splendor in the Grass', 'Kazan, Elia', '1961', 'Drama'),"
"('Verdict, The [1982]', 'Lumet, Sidney', '1982', 'Drama'),"
"('Fallen Idol, The', 'Reed, Carol', '1948', 'Thriller-Drama'),"
"('Boudu Saved from Drowning', 'Renoir, Jean', '1932', 'Comedy'),"
"('Pickup on South Street', 'Fuller, Sam', '1953', 'Spy-Crime'),"
"('Man of the West', 'Mann, Anthony', '1958', 'Western'),"
"('Big Deal on Madonna Street', 'Monicelli, Mario', '1958', 'Crime-Comedy'),"
"('Carnival in Flanders', 'Feyder, Jacques', '1935', 'Romance-Historical-Comedy'),"
"('Amants du Pont-Neuf, Les', 'Carax, Lèos', '1991', 'Drama'),"
"('Histoire(s) du  cinéma', 'Godard, Jean-Luc', '1998', 'Documentary'),"
"('Belle noiseuse, La', 'Rivette, Jacques', '1991', 'Drama'),"
"('Godfather Part III, The', 'Coppola, Francis', '1990', 'Drama-Crime'),"
"('Princess Bride, The', 'Reiner, Rob', '1987', 'Comedy-Family-Adventure'),"
"('Magnolia', 'Anderson, Paul Thomas', '1999', 'Drama'),"
"('Ghost and Mrs. Muir, The', 'Mankiewicz, Joseph L.', '1947', 'Romance-Fantasy'),"
"('Shanghai Gesture, The', 'von Sternberg, Josef', '1941', 'Crime-Drama'),"
"('Wind Will Carry Us, The', 'Kiarostami, Abbas', '1999', 'Drama'),"
"('National Lampoon''s Animal House', 'Landis, John', '1978', 'Comedy'),"
"('Heimat [TV]', 'Reitz, Edgar', '1984', 'Drama'),"
"('Unfaithfully Yours [1948]', 'Sturges, Preston', '1948', 'Comedy'),"
"('Royal Tenenbaums, The', 'Anderson, Wes', '2001', 'Drama-Comedy'),"
"('Angel [1937]', 'Lubitsch, Ernst', '1937', 'Drama-Comedy-Romance'),"
"('Gimme Shelter', 'Maysles, Albert/David Maysles/Charlotte Zwerin', '1970', 'Documentary-Musical-Historical'),"
"('Daisies', 'Chytilová, Vera', '1966', 'Drama-Comedy-Avant Garde'),"
"('Gilda', 'Vidor, Charles', '1946', 'Thriller-Drama'),"
"('Red Beard', 'Kurosawa, Akira', '1965', 'Drama'),"
"('Vengeance is Mine', 'Imamura, Shohei', '1979', 'Thriller-Crime-Drama'),"
"('Trial, The', 'Welles, Orson', '1963', 'Drama-Fantasy-Thriller'),"
"('Ludwig', 'Visconti, Luchino', '1973', 'Drama-Biography-Historical'),"
"('Naked Spur, The', 'Mann, Anthony', '1953', 'Western'),"
"('Anatahan', 'von Sternberg, Josef', '1953', 'War-Drama'),"
"('Chronicle of Anna Magdalena Bach, The', 'Straub, Jean-Marie', '1968', 'Drama-Historical-Musical'),"
"('Private Life of Sherlock Holmes, The', 'Wilder, Billy', '1970', 'Mystery-Comedy-Drama'),"
"('Green Ray, The', 'Rohmer, Eric', '1986', 'Romance-Drama'),"
"('Usual Suspects, The', 'Singer, Bryan', '1995', 'Thriller-Mystery-Crime'),"
"('Hôtel Terminus', 'Ophüls, Marcel', '1987', 'Documentary-Historical-War'),"
"('Taste of Cherry, A', 'Kiarostami, Abbas', '1997', 'Drama'),"
"('Miracle of Morgan''s Creek, The', 'Sturges, Preston', '1944', 'Comedy'),"
"('Ronde, La', 'Ophüls, Max', '1950', 'Drama'),"
"('Pakeezah', 'Amrohi, Kamal', '1972', 'Drama'),"
"('Player, The', 'Altman, Robert', '1992', 'Comedy'),"
"('Not Reconciled', 'Straub, Jean-Marie', '1965', 'Drama'),"
"('Yellow Earth', 'Chen Kaige', '1984', 'Drama-Political'),"
"('Last Temptation of Christ, The', 'Scorsese, Martin', '1988', 'Religious'),"
"('Straw Dogs', 'Peckinpah, Sam', '1971', 'Crime-Drama-Thriller'),"
"('Early Summer', 'Ozu, Yasujiro', '1951', 'Drama'),"
"('Pan''s Labyrinth', 'del Toro, Guillermo', '2006', 'Drama-Fantasy-Thriller'),"
"('Rififi', 'Dassin, Jules', '1955', 'Crime'),"
"('Magnificent Seven, The', 'Sturges, John', '1960', 'Western'),"
"('Woman in the Window, The', 'Lang, Fritz', '1944', 'Thriller'),"
"('Design for Living', 'Lubitsch, Ernst', '1933', 'Romance-Comedy'),"
"('There''s Always Tomorrow', 'Sirk, Douglas', '1956', 'Drama'),"
"('Lost in Translation', 'Coppola, Sofia', '2003', 'Romance-Drama-Comedy'),"
"('Kaagaz Ke Phool', 'Dutt, Guru', '1959', 'Romance-Drama'),"
"('Flowers of Shanghai', 'Hou Hsiao-hsien', '1998', 'Drama'),"
"('Audition', 'Miike, Takashi', '1999', 'Thriller-Horror-Drama'),"
"('Platform', 'Jia Zhangke', '2000', 'Drama-Historical'),"
"('My Fair Lady', 'Cukor, George', '1964', 'Musical-Comedy-Romance'),"
"('Faster, Pussycat! Kill! Kill!', 'Meyer, Russ', '1966', 'Drama-Comedy-Action'),"
"('Black Orpheus', 'Camus, Marcel', '1959', 'Drama-Romance'),"
"('Hannah and Her Sisters', 'Allen, Woody', '1986', 'Drama-Comedy-Romance'),"
"('Mon oncle d''Amérique', 'Resnais, Alain', '1980', 'Drama-Comedy'),"
"('Plácido', 'Berlanga, Luis García', '1961', 'Comedy'),"
"('Puppetmaster, The', 'Hou Hsiao-hsien', '1993', 'Drama-Biography'),"
"('Black Sunday', 'Bava, Mario', '1960', 'Horror'),"
"('Short Film About Killing, A', 'Kieslowski, Krszystof', '1987', 'Drama-Crime'),"
"('A.I. Artificial Intelligence', 'Spielberg, Steven', '2001', 'Science Fiction-Drama'),"
"('Memento', 'Nolan, Christopher', '2000', 'Thriller-Mystery-Drama'),"
"('Ace in the Hole', 'Wilder, Billy', '1951', 'Drama'),"
"('Gandhi', 'Attenborough, Richard', '1982', 'Drama-Biography-Historical'),"
"('Casino', 'Scorsese, Martin', '1995', 'Drama-Crime'),"
"('Nazarín', 'Buñuel, Luis', '1958', 'Religious-Drama'),"
"('Orlando', 'Potter, Sally', '1992', 'Historical-Drama-Fantasy'),"
"('Broadway Danny Rose', 'Allen, Woody', '1984', 'Comedy'),"
"('Avanti!', 'Wilder, Billy', '1972', 'Comedy'),"
"('Dead Poets Society', 'Weir, Peter', '1989', 'Drama'),"
"('Oldboy', 'Park Chan-wook', '2003', 'Action-Mystery-Thriller'),"
"('Misfits, The', 'Huston, John', '1961', 'Western-Romance-Drama'),"
"('Hawks and the Sparrows, The', 'Pasolini, Pier Paolo', '1966', 'Comedy-Political'),"
"('Sun Shines Bright, The', 'Ford, John', '1953', 'Drama-Comedy'),"
"('Firemen''s Ball, The', 'Forman, Milos', '1967', 'Comedy'),"
"('Gunga Din', 'Stevens, George', '1939', 'War-Adventure-Action'),"
"('Festen', 'Vinterberg, Thomas', '1998', 'Drama'),"
"('Hour of the Wolf', 'Bergman, Ingmar', '1967', 'Horror-Drama'),"
"('Hana-Bi', 'Kitano, Takeshi', '1997', 'Drama-Crime'),"
"('Limite', 'Peixoto, Mario', '1931', 'Drama'),"
"('Fish Called Wanda, A', 'Crichton, Charles', '1988', 'Romance-Crime-Comedy'),"
"('Harlan County, U.S.A.', 'Kopple, Barbara', '1976', 'Documentary'),"
"('From Here to Eternity', 'Zinnemann, Fred', '1953', 'War-Drama-Romance'),"
"('Marketa Lazarová', 'Vlácil, Frantisek', '1967', 'Romance-Drama'),"
"('Dazed and Confused', 'Linklater, Richard', '1993', 'Drama'),"
"('Pursued', 'Walsh, Raoul', '1947', 'Western-Thriller'),"
"('Actor''s Revenge, An', 'Ichikawa, Kon', '1963', 'Drama'),"
"('Under the Roofs of Paris', 'Clair, René', '1930', 'Comedy-Drama-Musical'),"
"('Dances with Wolves', 'Costner, Kevin', '1990', 'Western'),"
"('Moonfleet', 'Lang, Fritz', '1955', 'Adventure-Drama'),"
"('Night of the Demon', 'Tourneur, Jacques', '1957', 'Horror'),"
"('Se7en', 'Fincher, David', '1995', 'Thriller-Mystery-Drama'),"
"('Robocop', 'Verhoeven, Paul', '1987', 'Science Fiction-Crime'),"
"('Virgin Spring, The', 'Bergman, Ingmar', '1959', 'Drama'),"
"('Punch-Drunk Love', 'Anderson, Paul Thomas', '2002', 'Romance-Drama-Comedy'),"
"('Man in the White Suit, The', 'Mackendrick, Alexander', '1951', 'Comedy'),"
"('Rise to Power of Louis XIV, The', 'Rossellini, Roberto', '1966', 'Drama-Biography-Historical'),"
"('Hatari!', 'Hawks, Howard', '1962', 'Drama'),"
"('Crash [1996]', 'Cronenberg, David', '1996', 'Drama'),"
"('Times of Harvey Milk, The', 'Epstein, Rob', '1984', 'Documentary-Historical-Biography'),"
"('Tom, Tom the Piper''s Son', 'Jacobs, Ken', '1969', 'Avant-Garde'),"
"('Out 1, noli me tangere', 'Rivette, Jacques', '1971', 'Comedy-Drama-Thriller'),"
"('Ceddo', 'Sembene, Ousmane', '1976', 'Drama-Politcal-Avant Garde'),"
"('Grave of the Fireflies', 'Takahata, Isao', '1988', 'Animated-War-Drama'),"
"('Johnny Got His Gun', 'Trumbo, Dalton', '1971', 'War-Drama'),"
"('Witness', 'Weir, Peter', '1985', 'Crime-Drama-Romance'),"
"('Lost Highway', 'Lynch, David', '1996', 'Mystery'),"
"('Requiem for a Dream', 'Aronofsky, Darren', '2000', 'Drama'),"
"('Saving Private Ryan', 'Spielberg, Steven', '1998', 'War-Drama-Action'),"
"('Round-Up, The', 'Jancsó, Miklós', '1965', 'Political-Drama-War'),"
"('Berlin: Symphony of a Great City', 'Ruttmann, Walter', '1927', 'Documentary'),"
"('Lord of the Rings: The Fellowship of the Ring, The', 'Jackson, Peter', '2001', 'Fantasy-Adventure'),"
"('Docks of New York, The', 'von Sternberg, Josef', '1928', 'Romance-Drama-Crime'),"
"('O Lucky Man!', 'Anderson, Lindsay', '1973', 'Fantasy-Drama-Comedy'),"
"('Mother and Son', 'Sokurov, Aleksandr', '1997', 'Drama'),"
"('Branded to Kill', 'Suzuki, Seijun', '1966', 'Crime-Action'),"
"('Starship Troopers', 'Verhoeven, Paul', '1997', 'Science Fiction-Action-Adventure-War'),"
"('Man for All Seasons, A', 'Zinnemann, Fred', '1966', 'Drama'),"
"('Criminal Life of Archibaldo de la Cruz, The', 'Buñuel, Luis', '1955', 'Drama-Crime'),"
"('Phantom Carriage, The', 'Sjöström, Victor', '1920', 'Fantasy-Drama'),"
"('Fountainhead, The', 'Vidor, King', '1949', 'Drama'),"
"('Caché', 'Haneke, Michael', '2005', 'Thriller-Drama'),"
"('Sleeper', 'Allen, Woody', '1973', 'Science Fiction-Comedy'),"
"('Woman of Paris, A', 'Chaplin, Charles', '1923', 'Drama'),"
"('Landscape in the Mist', 'Angelopoulos, Theo', '1988', 'Drama'),"
"('Y tu mamá también', 'Cuarón, Alfonso', '2001', 'Drama-Comedy'),"
"('Man from Laramie, The', 'Mann, Anthony', '1955', 'Western'),"
"('My Own Private Idaho', 'Van Sant, Gus', '1991', 'Drama'),"
"('Reckless Moment, The', 'Ophüls, Max', '1949', 'Drama-Crime'),"
"('Zelig', 'Allen, Woody', '1983', 'Comedy'),"
"('Gleaners & I, The', 'Varda, Agnès', '2000', 'Documentary'),"
"('Hellzapoppin''', 'Potter, H.C.', '1941', 'Comedy'),"
"('W.R.: Mysteries of the Organism', 'Makavejev, Dusan', '1971', 'Drama-Comedy-Fantasy'),"
"('Trou, Le', 'Becker, Jacques', '1959', 'Drama-Crime'),"
"('Burnt by the Sun', 'Mikhalkov, Nikita', '1994', 'Historical-Drama'),"
"('47 Ronin, The', 'Mizoguchi, Kenji', '1941', 'Historical-Action-Drama'),"
"('Subarnarekha', 'Ghatak, Ritwik', '1965', 'Drama'),"
"('You Only Live Once', 'Lang, Fritz', '1937', 'Crime'),"
"('Fellini''s Roma', 'Fellini, Federico', '1972', 'Drama-Comedy'),"
"('Chronicle of a Summer', 'Rouch, Jean & Edgar Morin', '1960', 'Documentary'),"
"('Shoeshine', 'De Sica, Vittorio', '1946', 'Drama'),"
"('While the City Sleeps', 'Lang, Fritz', '1956', 'Drama-Crime'),"
"('Bidone, Il', 'Fellini, Federico', '1955', 'Drama'),"
"('Vagabond', 'Varda, Agnès', '1985', 'Drama'),"
"('Dodsworth', 'Wyler, William', '1936', 'Romance-Drama'),"
"('Yol', 'Gören, Serif', '1982', 'Drama'),"
"('History of Violence, A', 'Cronenberg, David', '2005', 'Crime-Drama-Thriller'),"
"('Lusty Men, The', 'Ray, Nicholas', '1952', 'Western-Sports-Drama'),"
"('Who Framed Roger Rabbit?', 'Zemeckis, Robert', '1988', 'Mystery-Comedy-Animated'),"
"('Arrivée d''un train à la Ciotat, L''', 'Lumière, August & Louis Lumière', '1895', 'Short-Documentary'),"
"('Angel Face', 'Preminger, Otto', '1953', 'Crime'),"
"('Happy Together', 'Wong Kar-wai', '1997', 'Romance-Drama'),"
"('Midnight', 'Leisen, Mitchell', '1939', 'Romance-Comedy'),"
"('Law of Desire', 'Almodóvar, Pedro', '1987', 'Romance-Drama-Comedy'),"
"('War of the Worlds, The', 'Haskin, Byron', '1953', 'Science Fiction-Action'),"
"('Mephisto', 'Szabó, István', '1981', 'War-Drama'),"
"('Mother India', 'Khan, Mehboob', '1957', 'Drama-Musical-Family'),"
"('Loneliness of the Long Distance Runner, The', 'Richardson, Tony', '1962', 'Drama-Sports'),"
"('Beyond a Reasonable Doubt', 'Lang, Fritz', '1956', 'Mystery'),"
"('Haunting, The', 'Wise, Robert', '1963', 'Horror'),"
"('Purple Rose of Cairo, The', 'Allen, Woody', '1985', 'Fantasy-Comedy-Romance'),"
"('Remains of the Day, The', 'Ivory, James', '1993', 'Drama'),"
"('Yeelen', 'Cissé, Souleymane', '1987', 'Drama-Adventure-Action'),"
"('Sugar Cane Alley', 'Palcy, Euzhan', '1983', 'Drama'),"
"('Zabriskie Point', 'Antonioni, Michelangelo', '1970', 'Drama'),"
"('Funny Games [1997]', 'Haneke, Michael', '1997', 'Thriller-Drama'),"
"('Safe', 'Haynes, Todd', '1995', 'Drama'),"
"('Enfance nue, L''', 'Pialat, Maurice', '1968', 'Drama'),"
"('Ordinary People', 'Redford, Robert', '1980', 'Drama'),"
"('Maîtres fous, Les', 'Rouch, Jean', '1955', 'Documentary-Short'),"
"('Red Sorghum', 'Zhang Yimou', '1987', 'Drama'),"
"('Informer, The', 'Ford, John', '1935', 'Drama'),"
"('Duel', 'Spielberg, Steven', '1971', 'Thriller-Action'),"
"('Red Circle, The', 'Melville, Jean-Pierre', '1970', 'Thriller-Crime'),"
"('Days and Nights in the Forest', 'Ray, Satyajit', '1969', 'Romance-Drama-Comedy'),"
"('Bête humaine, La', 'Renoir, Jean', '1938', 'Drama'),"
"('Long Day Closes, The', 'Davies, Terence', '1992', 'Drama'),"
"('Assault on Precinct 13 [1976]', 'Carpenter, John', '1976', 'Action'),"
"('El Dorado [1967]', 'Hawks, Howard', '1967', 'Western'),"
"('Russian Ark', 'Sokurov, Aleksandr', '2002', 'Fantasy-Drama'),"
"('Kameradschaft', 'Pabst, G.W.', '1931', 'Drama-Disaster'),"
"('Caro diario', 'Moretti, Nanni', '1994', 'Comedy'),"
"('Abraham''s Valley', 'de Oliveira, Manoel', '1993', 'Drama'),"
"('Quince Tree of the Sun', 'Erice, Victor', '1991', 'Documentary-Biography-Drama'),"
"('Shanghai Express', 'von Sternberg, Josef', '1932', 'Drama-Adventure'),"
"('Big Red One, The', 'Fuller, Sam', '1980', 'War-Action-Drama'),"
"('My Man Godfrey', 'La Cava, Gregory', '1936', 'Romance-Comedy'),"
"('Samson and Delilah [1949]', 'DeMille, Cecil B.', '1949', 'Religious-Drama-Romance'),"
"('New World, The', 'Malick, Terrence', '2005', 'Drama-Historical-Romance'),"
"('Indian Tomb, The', 'Lang, Fritz', '1958', 'Adventure'),"
"('Pink Flamingos', 'Waters, John', '1972', 'Comedy-Crime'),"
"('Lacombe, Lucien', 'Malle, Louis', '1974', 'War-Drama'),"
"('Wanda', 'Loden, Barbara', '1970', 'Drama-Crime'),"
"('Awaara', 'Kapoor, Raj', '1951', 'Drama-Musical-Romance'),"
"('Lone Star', 'Sayles, John', '1995', 'Mystery-Drama'),"
"('Peter Ibbetson', 'Hathaway, Henry', '1935', 'Romance-Fantasy-Drama'),"
"('Edvard Munch [TV]', 'Watkins, Peter', '1974', 'Drama-Biography'),"
"('In Cold Blood', 'Brooks, Richard', '1967', 'Crime-Biography'),"
"('Big Parade, The', 'Vidor, King', '1925', 'War-Romance-Drama'),"
"('Art of Vision, The', 'Brakhage, Stan', '1964', 'Avant-Garde'),"
"('Anatomy of a Murder', 'Preminger, Otto', '1959', 'Drama'),"
"('Murder by Contract', 'Lerner, Irving', '1958', 'Thriller-Drama-Crime'),"
"('Atlantic City', 'Malle, Louis', '1980', 'Crime'),"
"('Million Dollar Baby', 'Eastwood, Clint', '2004', 'Drama'),"
"('Sweet Hereafter, The', 'Egoyan, Atom', '1997', 'Drama'),"
"('Judex [1963]', 'Franju, Georges', '1963', 'Fantasy-Adventure-Action'),"
"('Tom Jones', 'Richardson, Tony', '1963', 'Romance-Comedy-Adventure'),"
"('Werckmeister Harmonies', 'Tarr, Béla', '2000', 'Drama'),"
"('Wrong Man, The', 'Hitchcock, Alfred', '1956', 'Drama-Crime'),"
"('Saragossa Manuscript, The', 'Has, Wojciech', '1964', 'Drama-Mystery-Fantasy'),"
"('Out 1: Spectre', 'Rivette, Jacques', '1972', 'Drama-Avant Garde'),"
"('Night and the City', 'Dassin, Jules', '1950', 'Crime-Sport'),"
"('Nutty Professor, The [1963]', 'Lewis, Jerry', '1963', 'Comedy'),"
"('Death of Mr. Lazarescu, The', 'Puiu, Cristi', '2005', 'Drama'),"
"('Marquise of O, The', 'Rohmer, Eric', '1976', 'Drama-Historical'),"
"('Ladykillers, The [1955]', 'Mackendrick, Alexander', '1955', 'Crime-Comedy'),"
"('Star Spangled to Death', 'Jacobs, Ken', '2004', 'Avant-Garde'),"
"('4 Months, 3 Weeks and 2 Days', 'Mungiu, Cristian', '2007', 'Drama'),"
"('Red and the White, The', 'Jancsó, Miklós', '1967', 'War-Drama'),"
"('Wild at Heart', 'Lynch, David', '1990', 'Romance-Drama-Crime'),"
"('Year of Living Dangerously, The', 'Weir, Peter', '1983', 'Romance-Adventure'),"
"('Flaming Creatures', 'Smith, Jack', '1963', 'Drama'),"
"('Femme est une femme, Une', 'Godard, Jean-Luc', '1961', 'Drama-Comedy-Musical'),"
"('Diary for Timothy, A', 'Jennings, Humphrey', '1945', 'Documentary-Short'),"
"('Destiny', 'Lang, Fritz', '1921', 'Fantasy'),"
"('Europa ''51', 'Rossellini, Roberto', '1951', 'Drama'),"
"('Killers, The [1946]', 'Siodmak, Robert', '1946', 'Crime'),"
"('Spider''s Stratagem, The', 'Bertolucci, Bernardo', '1970', 'Mystery-Drama'),"
"('Nibelungen, Die', 'Lang, Fritz', '1924', 'Fantasy-Adventure'),"
"('New York, New York', 'Scorsese, Martin', '1977', 'Musical'),"
"('Bellissima', 'Visconti, Luchino', '1951', 'Drama'),"
"('Age of the Earth, The', 'Rocha, Glauber', '1980', 'Political-Drama-Religious'),"
"('To Sleep with Anger', 'Burnett, Charles', '1990', 'Drama'),"
"('Heiress, The', 'Wyler, William', '1949', 'Drama'),"
"('Dracula [1931]', 'Browning, Tod', '1931', 'Horror-Fantasy'),"
"('Opening Night', 'Cassavetes, John', '1977', 'Drama'),"
"('Babe', 'Noonan, Chris', '1995', 'Fantasy-Comedy-Family'),"
"('Three Colours: White', 'Kieslowski, Krszystof', '1993', 'Drama'),"
"('Organiser, The', 'Monicelli, Mario', '1963', 'Drama-Crime-Political'),"
"('Incredibles, The', 'Bird, Brad', '2004', 'Family-Animated-Adventure'),"
"('Childhood of Maxim Gorky, The', 'Donskoi, Mark', '1938', 'Drama-Biography'),"
"('Bridges of Madison County, The', 'Eastwood, Clint', '1995', 'Romance-Drama'),"
"('On Dangerous Ground', 'Ray, Nicholas', '1951', 'Crime-Drama'),"
"('American Friend, The', 'Wenders, Wim', '1977', 'Mystery-Crime'),"
"('Ju Dou', 'Zhang Yimou', '1990', 'Romance-Historical-Drama'),"
"('Port of Shadows', 'Carné, Marcel', '1938', 'Drama'),"
"('Ed Wood', 'Burton, Tim', '1994', 'Drama-Comedy-Biography'),"
"('Queen Kelly', 'von Stroheim, Erich', '1928', 'Drama'),"
"('Medium Cool', 'Wexler, Haskell', '1969', 'Political-Drama'),"
"('Touki Bouki', 'Mambéty, Djibril Diop', '1973', 'Drama'),"
"('3 Women', 'Altman, Robert', '1977', 'Drama'),"
"('Au revoir les enfants', 'Malle, Louis', '1987', 'War-Drama'),"
"('Coeur en hiver, Un', 'Sautet, Claude', '1991', 'Drama'),"
"('Entr''acte', 'Clair, René', '1924', 'Short'),"
"('In the Heat of the Night', 'Jewison, Norman', '1967', 'Crime'),"
"('Commune (Paris, 1871), La', 'Watkins, Peter', '2000', 'Drama-Historical'),"
"('Rio Grande', 'Ford, John', '1950', 'Western-War-Romance'),"
"('Feu follet, Le', 'Malle, Louis', '1963', 'Drama'),"
"('Moana', 'Flaherty, Robert', '1925', 'Documentary'),"
"('Happiness [1934]', 'Medvedkin, Aleksandr', '1934', 'Comedy'),"
"('Lessons of Darkness', 'Herzog, Werner', '1992', 'Documentary'),"
"('Collectionneuse, La', 'Rohmer, Eric', '1966', 'Romance-Drama-Comedy'),"
"('Our Daily Bread [1934]', 'Vidor, King', '1934', 'Drama'),"
"('Chikamatsu monogatari', 'Mizoguchi, Kenji', '1954', 'Drama-Romance'),"
"('Elephant', 'Van Sant, Gus', '2003', 'Drama'),"
"('Plein soleil', 'Clément, René', '1960', 'Thriller-Crime-Drama'),"
"('Cul-de-sac', 'Polanski, Roman', '1966', 'Thriller-Drama'),"
"('Wild River', 'Kazan, Elia', '1960', 'Drama-Romance'),"
"('Mädchen in Uniform', 'Sagan, Leontine', '1931', 'Drama'),"
"('Henry: Portrait of a Serial Killer', 'McNaughton, John', '1986', 'Horror-Crime'),"
"('Douce', 'Autant-Lara, Claude', '1943', 'Romance-Drama'),"
"('Sorpasso, Il', 'Risi, Dino', '1963', 'Drama'),"
"('Ballad of Narayama [1983]', 'Imamura, Shohei', '1983', 'Drama'),"
"('Second Breath', 'Melville, Jean-Pierre', '1966', 'Drama'),"
"('End of St. Petersburg, The', 'Pudovkin, Vsevolod', '1927', 'Political-Drama'),"
"('Stray Dog', 'Kurosawa, Akira', '1949', 'Thriller-Crime-Drama'),"
"('Safety Last', 'Newmeyer, Fred C. & Sam Taylor', '1923', 'Comedy-Family-Romance'),"
"('Gold Diggers of 1933', 'LeRoy, Mervyn', '1933', 'Musical-Dance-Comedy'),"
"('Ride Lonesome', 'Boetticher, Budd', '1959', 'Western'),"
"('Amour fou, L''', 'Rivette, Jacques', '1968', 'Drama'),"
"('Posto, Il', 'Olmi, Ermanno', '1961', 'Drama'),"
"('True Heart Susie', 'Griffith, D.W.', '1919', 'Drama-Comedy'),"
"('Sonatine [1993]', 'Kitano, Takeshi', '1993', 'Drama-Crime-Action'),"
"('Seconds', 'Frankenheimer, John', '1966', 'Thriller-Mystery'),"
"('Passion of Anna, The', 'Bergman, Ingmar', '1969', 'Drama'),"
"('Veronika Voss', 'Fassbinder, Rainer Werner', '1982', 'Drama'),"
"('They Died with Their Boots On', 'Walsh, Raoul', '1941', 'Biography-War-Romance'),"
"('Italian Straw Hat, The', 'Clair, René', '1927', 'Comedy'),"
"('Charade', 'Donen, Stanley', '1963', 'Thriller-Romance-Comedy'),"
"('Corbeau, Le', 'Clouzot, Henri-Georges', '1943', 'Mystery-Drama-Thriller'),"
"('Sur, El', 'Erice, Victor', '1983', 'Romance-Drama'),"
"('Letter to Three Wives, A', 'Mankiewicz, Joseph L.', '1949', 'Drama'),"
"('Spione', 'Lang, Fritz', '1928', 'Thriller-Spy'),"
"('Boucher, Le', 'Chabrol, Claude', '1970', 'Thriller-Drama'),"
"('Roaring Twenties, The', 'Walsh, Raoul', '1939', 'Drama-Crime'),"
"('Night Moves', 'Penn, Arthur', '1975', 'Mystery'),"
"('Dracula [1958]', 'Fisher, Terence', '1958', 'Horror'),"
"('Under the Bridges', 'Kaütner, Helmut', '1944', 'Romance-Drama'),"
"('Seventh Heaven', 'Borzage, Frank', '1927', 'Romance-Drama-War'),"
"('Winchester ''73', 'Mann, Anthony', '1950', 'Western'),"
"('Far Country, The', 'Mann, Anthony', '1955', 'Western'),"
"('Late Autumn', 'Ozu, Yasujiro', '1960', 'Drama'),"
"('Rose Hobart', 'Cornell, Joseph', '1936', 'Short'),"
"('Way Down East', 'Griffith, D.W.', '1920', 'Romance-Drama'),"
"('Z', 'Costa-Gavras, Constantin', '1969', 'Political-Thriller-Historical'),"
"('Heaven Can Wait [1943]', 'Lubitsch, Ernst', '1943', 'Romance-Comedy'),"
"('People on Sunday', 'Siodmak, Robert & Edgar G. Ulmer', '1929', 'Romance-Documentary-Drama'),"
"('Female Trouble', 'Waters, John', '1974', 'Crime-Comedy'),"
"('Bend of the River', 'Mann, Anthony', '1952', 'Western'),"
"('Tropical Malady', 'Weerasethakul, Apichatpong', '2004', 'Drama-Fantasy-Romance'),"
"('Scarlet Street', 'Lang, Fritz', '1945', 'Crime'),"
"('In Praise of Love', 'Godard, Jean-Luc', '2001', 'Drama'),"
"('Leave Her to Heaven', 'Stahl, John M.', '1945', 'Romance-Crime-Drama'),"
"('Louisiana Story', 'Flaherty, Robert', '1948', 'Documentary-Drama'),"
"('Cutter''s Way', 'Passer, Ivan', '1981', 'Mystery-Drama'),"
"('Black Cat, The', 'Ulmer, Edgar G.', '1934', 'Horror'),"
"('Devil in the Flesh', 'Autant-Lara, Claude', '1946', 'Romance-Drama'),"
"('Dog Star Man', 'Brakhage, Stan', '1964', 'Short-Drama'),"
"('Unknown, The', 'Browning, Tod', '1927', 'Romance-Drama-Horror'),"
"('Time to Love and a Time to Die, A', 'Sirk, Douglas', '1958', 'War-Romance-Drama'),"
"('Bitter Tea of General Yen, The', 'Capra, Frank', '1933', 'Romance-Drama'),"
"('Variety', 'Dupont, E.A.', '1925', 'Drama'),"
"('Kanal', 'Wajda, Andrzej', '1956', 'War-Drama'),"
"('Ceremony, The', 'Oshima, Nagisa', '1971', 'Comedy'),"
"('Fury', 'Lang, Fritz', '1936', 'Drama-Crime'),"
"('Arsenal', 'Dovzhenko, Alexander', '1929', 'War-Drama'),"
"('Strangers When We Meet', 'Quine, Richard', '1960', 'Drama-Romance'),"
"('Forty Guns', 'Fuller, Sam', '1957', 'Western'),"
"('Toni', 'Renoir, Jean', '1935', 'Drama');";


@interface AppDelegate ()

- (void)testDispatchSQLSimpleGoodSQL;

@end

@implementation AppDelegate

@synthesize window = _window;

- (void)dealloc
{
    [super dealloc];
}

- (void)setUp
{
    if ([PGSQLConnection defaultConnection] == nil)
    {
        PGSQLConnection *myConn = [[PGSQLConnection alloc] init];
        NSAssert(myConn != nil, @"Failed to connect to database in PGSQLKitUnitTest");
        
        [myConn setDatabaseName:@"PGSQLKit_Testing"];
        [myConn setDefaultEncoding:NSUTF8StringEncoding];
        myConn.logSQL = YES;
        myConn.logInfo = YES;
        
        if (![myConn connect])
        {
            NSLog(@"%@", [myConn errorDescription]);
            NSAssert(0, @"Failed to connect to database in PGSQLKitUnitTest");
        }
        [myConn release];
    }
}

- (void)tearDown
{
    // Tear-down code here.
    
}

#pragma mark -
#pragma mark Log Utility Methods

- (void)logColumnNames:(NSArray *)columnArray
{
    NSMutableString *str = [[[NSMutableString alloc] init] autorelease];
    for (PGSQLColumn *col in columnArray)
    {
        if ([str length] != 0)
        {
            [str appendString:@", "];
        }
        [str appendFormat:@"'%@'", [col name]];
    }
    NSLog(@"%@", str);
}

- (void)logRecordSet:(PGSQLRecordset *)rs
{
    [self logColumnNames:[rs columns]];
    PGSQLRecord *record = [rs moveFirst];
    while (![rs isEOF])
    {
        NSMutableString *string = [[[NSMutableString alloc] init] autorelease];
        for (int myIndex = 0; myIndex < [[rs columns] count]; myIndex++)
        {
            if ([string length] != 0)
            {
                [string appendString:@", "];
            }
            PGSQLField *field = [record fieldByIndex:myIndex];
            [string appendFormat:@"'%@'", [field asString]];
        }
        NSLog(@"%@", string);
        [string setString:@""];
        record = [rs moveNext];
    }
}

#pragma mark -
#pragma mark Data Creation Utility Methods

- (void)createFilms
{
    PGSQLConnection *myConn = [PGSQLConnection defaultConnection];
    if (![myConn execCommand:@"DROP TABLE IF EXISTS films;"])
    {
        NSLog(@"%@", [myConn errorDescription]);
        NSAssert(0, @"Failed to drop table 'films'");
    }
    
    NSLog(@"%@", sqlCreateFilmsTable);
    if (![myConn execCommand:sqlCreateFilmsTable])
    {
        NSLog(@"%@", [myConn errorDescription]);
        NSAssert(0, @"Failed to create table 'films'");
    }    
}

- (void)loadFilmsShort
{
    PGSQLConnection *myConn = [PGSQLConnection defaultConnection];
    NSLog(@"%@", sqlInsertFilmsTable);
    if (![myConn execCommand:sqlInsertFilmsTable])
    {
        NSLog(@"%@", [myConn errorDescription]);
        NSAssert(0, @"Failed to fill table 'films'");
    }
}

- (void)loadFilmsLong
{
    PGSQLConnection *myConn = [PGSQLConnection defaultConnection];
    NSLog(@"%@", sqlInsertFilmsTableLarge);
    if (![myConn execCommand:sqlInsertFilmsTableLarge])
    {
        NSLog(@"%@", [myConn errorDescription]);
        NSAssert(0, @"Failed to fill table 'films'");
    }
}

- (void)truncateFilms
{
    PGSQLConnection *myConn = [PGSQLConnection defaultConnection];
    if (![myConn execCommand:@"TRUNCATE TABLE films;"])
    {
        NSLog(@"%@", [myConn errorDescription]);
        NSAssert(0, @"Failed to drop table 'films'");
    }    
}

#pragma mark -
#pragma mark Utility Methods

-  (NSUInteger)countAsUInteger:(PGSQLRecordset *)rs
{
	NSLog(@"%@ %s", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
    PGSQLRecord *record = [rs moveFirst];
    PGSQLField *field = [record fieldByIndex:0];
    NSString *countStr = [field asString];
    return [countStr integerValue];
}

#pragma mark -
#pragma mark Test Methods

// *************************************************************************************************************************************
//  Test 2 - Queue up a bunch of short failures.
// *************************************************************************************************************************************

static NSMutableArray *testDispatchSQLSimpleBadTableNameSQLResultsArray;
static NSDate *testDispatchSQLSimpleBadTableNameStartTimeStamp;
static double testDispatchSQLSimpleBadTableNameWaitSeconds;     // How long we want to wait for completion.

- (void)testDispatchSQLSimpleBadTableNameCheckCompletion:(NSNumber *)expectedCompletedCount
{
	NSLog(@"%@ %s", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
    NSLog(@"    Found %lu of %@", [testDispatchSQLSimpleBadTableNameSQLResultsArray count], expectedCompletedCount);
    if ([testDispatchSQLSimpleBadTableNameSQLResultsArray count] < [expectedCompletedCount integerValue])
    {
        if (fabs([testDispatchSQLSimpleBadTableNameStartTimeStamp timeIntervalSinceNow]) <= testDispatchSQLSimpleBadTableNameWaitSeconds)
        {
            // Check again in a few seconds
            [self performSelector:@selector(testDispatchSQLSimpleBadTableNameCheckCompletion:) withObject:expectedCompletedCount afterDelay: 1.0];
        }
        else
        {
            // Timed out, should print error.
            NSLog(@"    Timed out.");
        }
    }
    else
    {
        // Do something with the results.
        NSLog(@"    Completed normally in %.6f seconds.", fabs([testDispatchSQLSimpleBadTableNameStartTimeStamp timeIntervalSinceNow]));
    }
}

- (void)testDispatchSQLSimpleBadTableName
{
	NSLog(@"%@ %s", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
    
    // Make sure we have a results array.
    if (testDispatchSQLSimpleBadTableNameSQLResultsArray == nil)
    {
        testDispatchSQLSimpleBadTableNameSQLResultsArray = [[NSMutableArray alloc] init];
    }
    else
    {
        [testDispatchSQLSimpleBadTableNameSQLResultsArray removeAllObjects];
    }
    
    // set the start time.
    [testDispatchSQLSimpleBadTableNameStartTimeStamp release];
    testDispatchSQLSimpleBadTableNameStartTimeStamp = [[NSDate date] retain];

    PGSQLDispatchCallback_t processSQLCallbackBlock = ^(PGSQLRecordset *recordset, NSString *errorString)
    {
        if (recordset)
        {
            NSLog(@"Processed result row count %lu and should not have.", [recordset rowCount]);
        }
        if (errorString)
        {
            [testDispatchSQLSimpleBadTableNameSQLResultsArray addObject:errorString];
            NSLog(@"%@", errorString);
        }
    };
    
    NSUInteger completedCount = 0;                  // Set how many result sets we expect.
    testDispatchSQLSimpleBadTableNameWaitSeconds = 20.0; // Set how long we want to wait for completion.
    NSArray *badSQLArray = [NSArray arrayWithObjects:
                            @"SELECT * from non_existant_table LIMIT 10;",  // Bad table name.
                            @"SELECT * ;",                                  // Malformed SQL
                            @"INSERT INTO no_table;",                       // Malformed SQL Command
                            //@"     ",                                       // Empty SQL
                            @"SELECT birthday from films LIMIT 10;",        // Bad column name
                            @"TRUNCATE table non_existant_table;",          // Bad command.
                            @"SELECT * from non_existant_table LIMIT 10;",  // Bad table name.
                            @"SELECT * from non_existant_table LIMIT 10;",  // Bad table name.
                            @"SELECT * from non_existant_table LIMIT 10;",  // Bad table name.
                            nil];

    for (NSString *sql in badSQLArray)
    {
        // Try something that should fail (bad table name)
        PGSQLDispatchError_t error = [[PGSQLDispatch sharedPGSQLDispatch] processResultsFromSQL:sql 
                                                                                    expectLongRunning:NO 
                                                                             usingCallbackBlock:processSQLCallbackBlock];
        
        NSAssert(error == PGSQLDispatchErrorNone, [[PGSQLDispatch sharedPGSQLDispatch] stringDescriptionForErrorNumber:error]);
        completedCount++;
    }
    
    if ([testDispatchSQLSimpleBadTableNameSQLResultsArray count] < completedCount)
    {
        [self performSelector:@selector(testDispatchSQLSimpleBadTableNameCheckCompletion:) withObject:[NSNumber numberWithInteger:completedCount] afterDelay: 1.0];
    }

}

// *************************************************************************************************************************************
//  Test 1 - Queue up a bunch of short running selects.
// *************************************************************************************************************************************

static NSMutableArray *testDispatchSQLSimpleGoodSQLResultsArray;
static NSDate *testDispatchSQLSimpleGoodSQLStartTimeStamp;
static double testDispatchSQLSimpleGoodSQLWaitSeconds;     // How long we want to wait for completion.

- (void)testDispatchSQLSimpleGoodSQLCheckCompletion:(NSNumber *)expectedCompletedCount
{
	NSLog(@"%@ %s", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
    NSLog(@"    Found %lu of %@", [testDispatchSQLSimpleGoodSQLResultsArray count], expectedCompletedCount);
    if ([testDispatchSQLSimpleGoodSQLResultsArray count] < [expectedCompletedCount integerValue])
    {
        if (fabs([testDispatchSQLSimpleGoodSQLStartTimeStamp timeIntervalSinceNow]) <= testDispatchSQLSimpleGoodSQLWaitSeconds)
        {
            // Check again in a few seconds
            [self performSelector:@selector(testDispatchSQLSimpleGoodSQLCheckCompletion:) withObject:expectedCompletedCount afterDelay: 1.0];
        }
        else
        {
            // Timed out, should print error.
            NSLog(@"    Timed out.");
            [self performSelector:@selector(testDispatchSQLSimpleBadTableName) withObject:nil afterDelay:0.1];
        }
    }
    else
    {
        // Do something with the results.
        NSLog(@"    Completed normally in %.6f seconds.", fabs([testDispatchSQLSimpleGoodSQLStartTimeStamp timeIntervalSinceNow]));
        [self performSelector:@selector(testDispatchSQLSimpleBadTableName) withObject:nil afterDelay:0.1];
    }
}

- (void)testDispatchSQLSimpleGoodSQL
{
	NSLog(@"%@ %s", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
    [self createFilms];
    [self loadFilmsShort];
    [self loadFilmsLong];
    
    // Make sure we have a results array.
    if (testDispatchSQLSimpleGoodSQLResultsArray == nil)
    {
        testDispatchSQLSimpleGoodSQLResultsArray = [[NSMutableArray alloc] init];
    }
    else
    {
        [testDispatchSQLSimpleGoodSQLResultsArray removeAllObjects];
    }
    
    // set the start time.
    [testDispatchSQLSimpleGoodSQLStartTimeStamp release];
    testDispatchSQLSimpleGoodSQLStartTimeStamp = [[NSDate date] retain];
    
    PGSQLDispatchCallback_t processSQLCallbackBlock = ^(PGSQLRecordset *recordset, NSString *errorString)
    {
        NSMutableDictionary *resultsDictionary = [[NSMutableDictionary alloc] init];
        if (recordset)
        {
            [resultsDictionary setObject:recordset forKey:@"Recordset"];
            NSLog(@"Callback processed Result row count %lu", [recordset rowCount]);
        }
        if (errorString)
        {
            [resultsDictionary setObject:errorString forKey:@"ErrorString"];
            NSLog(@"Callback errorString:%@", errorString);
        }
        [testDispatchSQLSimpleGoodSQLResultsArray addObject:resultsDictionary];
        [resultsDictionary release];
    };
    
    NSUInteger completedCount = 0;                  // Set how many result sets we expect.
    testDispatchSQLSimpleGoodSQLWaitSeconds = 20.0; // Set how long we want to wait for completion.
    
    NSArray *goodSQLArray = [NSArray arrayWithObjects:
                             sqlInsertFilmsTable,                           // double the data
                             @"SELECT * from films LIMIT 10 OFFSET 300;",
                             sqlInsertFilmsTableLarge,                      // double the data
                             @"SELECT * from films LIMIT 100 OFFSET 800;",
                             @"SELECT * from films LIMIT 200;",
                             @"SELECT * from films LIMIT 50;",
                             @"SELECT * from films LIMIT 25;",
                             @"SELECT * from films LIMIT 333;",
                             @"SELECT * from films LIMIT 666;",
                             nil];
    
    for (NSString *sql in goodSQLArray)
    {
        // Dispatch something that should not fail.
        PGSQLDispatchError_t error = [[PGSQLDispatch sharedPGSQLDispatch] processResultsFromSQL:sql
                                                                                    expectLongRunning:NO 
                                                                             usingCallbackBlock:processSQLCallbackBlock];
        NSAssert(error == PGSQLDispatchErrorNone, [[PGSQLDispatch sharedPGSQLDispatch] stringDescriptionForErrorNumber:error]);
        completedCount++;
    }

    if ([testDispatchSQLSimpleGoodSQLResultsArray count] < completedCount)
    {
        [self performSelector:@selector(testDispatchSQLSimpleGoodSQLCheckCompletion:) withObject:[NSNumber numberWithInteger:completedCount] afterDelay: 1.0];
    }
}

#pragma mark -
#pragma mark NSApplicationDelegate Methods


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	NSLog(@"%@ %s", [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __func__);
    // Insert code here to initialize your application
    [self setUp];
    [self performSelector:@selector(testDispatchSQLSimpleGoodSQL) withObject:nil afterDelay:0.1];
}

@end
