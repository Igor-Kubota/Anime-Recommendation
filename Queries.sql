ir no diretório do usuário e reconfigurar neo4j.conf
server.memory.heap.initial_size=4G
server.memory.heap.max_size=8G
server.memory.pagecache.size=4G

CALL dbms.listConfig()
YIELD name, value
WHERE name STARTS WITH 'server.memory'
RETURN name, value
ORDER BY name

// **********************************************************

MATCH (n)
DELETE n;

// Importando os Animes
LOAD CSV WITH HEADERS FROM "file:///anime_treated.csv" AS animedb
FIELDTERMINATOR ','
CREATE (:anime {rank_anime:animedb.Rank, Name:animedb.Name,
Type: animedb.Type, Episodes: animedb.Episodes, Studio: animedb.Studio, 
Season: animedb.Release_Season , Tags: animedb.tags, Rating : animedb.Rating, 
ReleaseYear : animedb.Release_year, Sinopsis: animedb.Description , RelatedAnime : animedb.Related_anime})


// Importando os Dubladores
LOAD CSV WITH HEADERS FROM "file:///seiyuu_treated_only.csv" AS seiyuu
FIELDTERMINATOR ','
CREATE (:seiyuu {id_seiyuu: seiyuu.id_seiyuu , VoiceActor: seiyuu.seiyuu})

LOAD CSV WITH HEADERS FROM "file:///cast.csv" AS cast
FIELDTERMINATOR ','
CREATE (:cast {id_anime:cast.Rank, id_seiyuu :cast.id_seiyuu, Character :cast.char})


// indices
CREATE INDEX idx_idanime FOR (a:anime)
ON (a.rank_anime)
CREATE INDEX idx_nameanime FOR (a:anime)
ON (a.Name)
CREATE INDEX idx_taganime FOR (a:anime)
ON (a.Tags)

CREATE INDEX idx_idseiyuu FOR (s:seiyuu)
ON (s.id_seiyuu)
CREATE INDEX idx_nomevoiceactor FOR (s:seiyuu)
ON (s.Voice_Actor)

CREATE INDEX idx_char FOR (c:cast)
ON (c.Character)


// relacionando anime e dublador e cast

MATCH (a:anime),(s:seiyuu), (ca:cast)
WHERE a.rank_anime = ca.id_anime
AND  s.id_seiyuu = ca.id_seiyuu
MERGE (a)-[c:cast {dubla: true}]->(s)
WITH COUNT(*) AS AFFECTED
RETURN *

MATCH (f:Filme),(a:Artista),(elc:Elencos)
WHERE f.id_filme = elc.id_filme
AND a.id_ator = elc.id_ator
MERGE (f)-[e:Elenco {tipo_participação: elc.participação }]->(a)
WITH COUNT(*) AS AFFECTED
RETURN *



// Exemplo da relação entre Seiyuu e Anime -> img1


//Participou Akari Kitou
MATCH (a)-[c:cast]->(s)
WHERE s.VoiceActor =~ '(?i).*Akari Kitou.*'
RETURN a.Name

//Exemplo de animes da Akari Kitou -> img2


MATCH (s)<-[:participa]-(a)
RETURN s.VoiceActor, COUNT(*) AS Contagem
ORDER BY Contagem DESC

//Contagem de animes por dublador -> img3



// quem trabalhou com Rikako Aida
MATCH (s1: seiyuu)<-[:participa]-(a)-[:participa]->(s2:seiyuu)
WHERE s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s1 <> s2
RETURN *




MATCH (s1:seiyuu)<-[:participa]-(a1:anime)-[:participa]->       (s2:seiyuu)     <-[:participa]-(a2:anime)-[:participa]->(s3:seiyuu)
WHERE s1 <> s3
AND s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND NOT (s1)<-[:participa]-(:anime)-[:participa]->(s3)
RETURN a1.titulo , s2.VoiceActor AS Proximo_Rikako_Aida, a2.titulo, s3.VoiceActor AS Trabalhou_com_proximos_Rikako_aida
ORDER BY a1.titulo, s2.VoiceActor, a2.titulo, s3.VoiceActor


    

MATCH (s1:seiyuu)-[:participa]->(a1:anime)<-[:participa]-(s2:seiyuu)-[:participa]->(a2:anime)<-[:participa]-(s3:seiyuu)
WHERE s1 <> s3
AND s1.VoiceActor =~ '(?i).*rikako aida.*'
RETURN a1.Name , s2.VoiceActor AS Proximo_rikako_aida, a2.Name, s3.VoiceActor AS Trabalhou_com_proximos_rikako_aida
ORDER BY a1.Name, s2.VoiceActor, a2.Name, s3.VoiceActor





///recomendação

//participações de cada ator   -- 03/junho
MATCH (s)<-[:participa]-(a)
WHERE e.tipo_participação =~ '(?i).*act.*'
RETURN a.nome, COUNT(e) AS Contagem
ORDER BY Contagem DESC

// filmes do Selton Mello 
MATCH (f)-[e:Elenco]->(a)
WHERE a.nome =~ '(?i).*selton mello.*'
RETURN *

MATCH (f)-[e:Elenco]->(a)
WHERE f.titulo_original =~ '(?i).*godfather.*'
RETURN *

MATCH (f)-[e:Elenco]->(a)
WHERE a.nome =~ '(?i).*paulo gustavo.*'
RETURN *

// quem trabalhou com Selton Mello atuando  
MATCH (a1:Artista)<-[e1:Elenco]-(f)-[e2:Elenco]->(a2: Artista)
WHERE e2.tipo_participação =~ '(?i).*act.*'
AND a1.nome =~ '(?i).*selton mello.*'
AND a1 <> a2
RETURN *

RETURN a2.nome
ORDER BY a2.nome

// quem mais trabalhou com o Selton Mello
MATCH (a1:Artista)<-[e1:Elenco]-(f)-[e2:Elenco]->(a2: Artista)
WHERE e2.tipo_participação =~ '(?i).*act.*'
AND a1.nome =~ '(?i).*selton mello.*'
AND a1 <> a2
RETURN a2.nome , COUNT(*) AS Qtas_Parcerias
ORDER BY COUNT(*) DESC

MATCH (a1:Artista)<-[e1:Elenco]-(f)-[e2:Elenco]->(a2: Artista)
WHERE e2.tipo_participação =~ '(?i).*act.*'
AND a1.nome =~ '(?i).*paulo gustavo.*'
AND a1 <> a2
RETURN *


// quantidade
MATCH (a1:Artista)<-[e1:Elenco]-(f)-[e2:Elenco]->(a2: Artista)
WHERE e2.tipo_participação =~ '(?i).*act.*'
AND a1.nome =~ '(?i).*paulo gustavo.*'
RETURN a2.nome, COUNT(*) AS Qtas_parcerias
ORDER BY Qtas_parcerias DESC

//parcerias de paulo gustavo
MATCH (a1:Artista)<-[e1:Elenco]-(f)-[e2:Elenco]->(a2: Artista)
WHERE e2.tipo_participação =~ '(?i).*act.*'
AND a1.nome =~ '(?i).*paulo gustavo.*'
RETURN a2.nome, COUNT(*) AS Qtas_parcerias
ORDER BY Qtas_parcerias DESC

// quem dirigiu Paulo Gustavo 
MATCH (a1:Artista)<-[e1:Elenco]-(f)-[e2:Elenco]->(a2: Artista)
WHERE e2.tipo_participação =~ '(?i).*dir.*'
AND a1.nome =~ '(?i).*paulo gustavo.*'
RETURN a2.nome, f.titulo
ORDER BY a2.nome

// primeiro grau de proximidade, atuou diretamente no mesmo elenco
MATCH (a1:Artista)<-[e1:Elenco]-(f)-[e2:Elenco]->(a2: Artista)
WHERE e2.tipo_participação =~ '(?i).*act.*'
AND a1.nome =~ '(?i).*paulo gustavo.*'
RETURN *

// Agora podemos virar a consulta do co-ator acima em uma consulta de recomendação seguindo esses relacionamentos com outra saída
// para encontrar os "co-co-actores", isto é, os atores de segundo grau na rede de Selton Mello
// Isso nos mostrará todos os atores que Selton ainda não trabalhou, e podemos especificar um critério 
// para ter certeza de que ele não atuou diretamente com essa pessoa.

// segundo grau - Funcionou  paulo gustavo  selton mello
MATCH (s1:seiyuu)<-[:participa]-(a1:anime)-[:participa]->(s2:seiyuu)<-[:participa]-(a2:anime)-[:participa]->(s3:seiyuu)
WHERE s1 <> s3
AND s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND NOT (s1)<-[:participa]-(:anime)-[:participa]->(s3)
RETURN a1.titulo , s2.VoiceActor AS Proximo_Rikako_Aida, a2.titulo, s3.VoiceActor AS Trabalhou_com_proximos_Rikako_aida
ORDER BY a1.titulo, s2.VoiceActor, a2.titulo, s3.VoiceActor

// caminho para chegar ao Fábio Porchat 
MATCH (a1:Artista)<-[e1:Elenco]-(f1:Filme)-[e2:Elenco]->(a2:Artista)<-[e3:Elenco]-(f2:Filme)-[e4:Elenco]->(a3:Artista)
WHERE a1.nome =~ '(?i).*paulo gustavo.*'
AND a3.nome =~ '(?i).*porchat.*'
AND e2.tipo_participação =~ '(?i).*act.*'
AND e3.tipo_participação =~ '(?i).*act.*'
AND e4.tipo_participação =~ '(?i).*act.*'
AND NOT (a1)<-[:Elenco]-(:Filme)-[:Elenco]->(a3)
RETURN *

//***** atores que paulo gustavo não trabalhou ainda, e a força para chegar até ele(a) - número de conexões do intermediário
MATCH (a1:Artista)<-[:Elenco]-(f1)-[e2:Elenco]->(a2),
  (a2)<-[e3:Elenco]-(f2)-[e4:Elenco]->(a3)
WHERE a1.nome =~ '(?i).*paulo gustavo.*'
AND a3.nome =~ '(?i).*dira paes.*'
AND e2.tipo_participação =~ '(?i).*act.*'
AND e3.tipo_participação =~ '(?i).*act.*'
AND e4.tipo_participação =~ '(?i).*act.*'
AND NOT (a1)<-[:Elenco]-()-[:Elenco]->(a3) AND a1 <> a3
RETURN *
RETURN a3.nome AS Recomendado, COUNT(*) AS Força
ORDER BY Força DESC