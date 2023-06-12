ir no diretório do usuário e reconfigurar neo4j.conf
server.memory.heap.initial_size=4G
server.memory.heap.max_size=8G
server.memory.pagecache.size=4G

CALL dbms.listConfig()
YIELD name, value
WHERE name STARTS WITH 'server.memory'
RETURN name, value
ORDER BY name

--------------- MONTANDO OS DADOS A SEREM TRABALHADOS NO NEO4J ----------------------------


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


// Importando os Cast
LOAD CSV WITH HEADERS FROM "file:///cast.csv" AS cast
FIELDTERMINATOR ','
CREATE (:cast {id_anime:cast.Rank, id_seiyuu :cast.id_seiyuu, Character :cast.char})


// Criando os indices
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

------------------CONSULTAS NO NEO4J------------------------------------------------------------

// relacionando anime , dublador e cast

MATCH (a:anime),(s:seiyuu), (ca:cast)
WHERE a.rank_anime = ca.id_anime
AND  s.id_seiyuu = ca.id_seiyuu
MERGE (a)-[c:cast {dubla: true}]->(s)
WITH COUNT(*) AS AFFECTED
RETURN *


// Exemplo de Seiyuus do Anime Shadow House -> imagem e tabela
MATCH (a)-[c:cast]->(s)
WHERE a.name =~ '(?i).*Shadow House.*'
RETURN s.VoiceActor

//Exemplo de animes da Akari Kitou -> imagem e tabela
MATCH (a)-[c:cast]->(s)
WHERE s.VoiceActor =~ '(?i).*Akari Kitou.*'
RETURN a.Name


//Contagem de animes por dublador -> tabela
MATCH (s)<-[:participa]-(a)
RETURN s.VoiceActor, COUNT(*) AS Contagem
ORDER BY Contagem DESC
------------Primeiro Nivel-----------------------------------------------------

// relacionamento primeiro nivel - quem trabalhou com Rikako Aida - Grafo
MATCH (s1: seiyuu)<-[c1:cast]-(a)-[c2:cast]->(s2:seiyuu)
WHERE s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s1 <> s2
RETURN *

// relacionamento primeiro nivel - quem trabalhou com Rikako Aida - Tabela
MATCH (s1: seiyuu)<-[c1:cast]-(a)-[c2:cast]->(s2:seiyuu)
WHERE s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s1 <> s2
RETURN s1.VoiceActor, a.Name ,s2.VoiceActor
ORDER BY s1.VoiceActor, a.Name ,s2.VoiceActor


------------Segundo Nivel-----------------------------------------------------

// Relacionamento segundo nivel - Quem Trabalhou com os atores que trabalharam com Rikako Aida - Tabela
MATCH (s1:seiyuu)<-[c1:cast]-(a1:anime)-[c2:cast]->(s2:seiyuu)<-[c3:cast]-(a2:anime)-[c4:cast]->(s3:seiyuu)
WHERE s1 <> s3
AND s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND NOT (s1)<-[:cast]-(:anime)-[:cast]->(s3)
RETURN a1.Name , s2.VoiceActor AS Proximo_Rikako_Aida, a2.Name, s3.VoiceActor AS Trabalhou_com_proximos_Rikako_aida
ORDER BY a1.Name, s2.VoiceActor, a2.Name, s3.VoiceActor


//Relacionamento segundo nivel - Dubladores que trabalharam em Animes com a dubladora Aina Suzuki que Trabalhou com Rikako Aida - Grafo 
//Detalhe na dubladora 'Aina Suzuki'
MATCH (s1:seiyuu)<-[c1:cast]-(a1:anime)-[c2:cast]->(s2:seiyuu)<-[c3:cast]-(a2:anime)-[c4:cast]->(s3:seiyuu)
WHERE s1 <> s3
AND s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s2.VoiceActor =~ '(?i).*Aina Suzuki.*'
AND NOT (s1)<-[:cast]-(:anime)-[:cast]->(s3)
RETURN *


------------Recomendação-----------------------------------------------------

// Recomendação Segundo nivel -  Anime baseado na dubladora Aina Suzuki que trabalhou com Rikako Aida - Grafo 
// Detalhe na dubladora 'Aina Suzuki' e no anime 'Dropkick on My Devil!'
// Rikako Aida -> Anime que Trabalhou com Aina Suzuki -> Aina Suzuki -> Animes que ela trabalhou com outros dubladores -> Outros dubladores -> Anime que esses outros dubladores trabalharam
MATCH (s1:seiyuu)<-[c1:cast]-(a1:anime)-[c2:cast]->(s2:seiyuu)<-[c3:cast]-(a2:anime)-[c4:cast]->(s3:seiyuu)<-[c5:cast]-(a3:anime)
WHERE s1 <> s3
AND s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s2.VoiceActor =~ '(?i).*Aina Suzuki.*'
AND a2.Name ='Dropkick on My Devil!'
AND NOT (s1)<-[:cast]-(:anime)-[:cast]->(s3)
RETURN *


// Recomendação Segundo nivel -  Anime baseado na dubladora Aina Suzuki que trabalhou com Rikako Aida - Tabela
// Detalhe na dubladora 'Aina Suzuki' e no anime 'Dropkick on My Devil!'
// Rikako Aida -> Anime que Trabalhou com Aina Suzuki -> Aina Suzuki -> Animes que ela trabalhou com outros dubladores -> Outros dubladores -> Anime que esses outros dubladores trabalharam
MATCH (s1:seiyuu)<-[c1:cast]-(a1:anime)-[c2:cast]->(s2:seiyuu)<-[c3:cast]-(a2:anime)-[c4:cast]->(s3:seiyuu)<-[c5:cast]-(a3:anime)
WHERE s1 <> s3
AND s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s2.VoiceActor =~ '(?i).*Aina Suzuki.*'
AND NOT (s1)<-[:cast]-(:anime)-[:cast]->(s3)
RETURN a1.Name , s2.VoiceActor AS Proximo_Rikako_Aida, a2.Name, s3.VoiceActor AS Trabalhou_com_proximos_Rikako_aida, a3.Name
ORDER BY a1.Name, s2.VoiceActor, a2.Name, s3.VoiceActor, a3.Name


------------Caminhos-----------------------------------------------------

// caminho para chegar até Riho Iida - Grafo
MATCH (s1:seiyuu)<-[c1:cast]-(a1:anime)-[c2:cast]->(s2:seiyuu)<-[c3:cast]-(a2:anime)-[c4:cast]->(s3:seiyuu)
WHERE s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s3.VoiceActor =~ '(?i).*Riho Iida.*'
AND NOT (s1)<-[:cast]-(:anime)-[:cast]->(s3)
RETURN *

//Caminhos e força de cada Caminho para chegar até Riho Iida - Tabela
MATCH (s1:seiyuu)<-[c1:cast]-(a1)-[c2:cast]->(s2), (s2)<-[c3:cast]-(a2)-[c4:cast]->(s3)
WHERE s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s3.VoiceActor =~ '(?i).*Riho Iida.*'
AND NOT (s1)<-[:cast]-()-[:cast]->(s3) AND s1 <> s3
RETURN s2.VoiceActor, s3.VoiceActor AS Recomendado, COUNT(*) AS Força
ORDER BY Força DESC

