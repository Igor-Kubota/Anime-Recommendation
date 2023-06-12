# Sistema de Recomendação de Animes baseado nos Dubladores
Utilizando o Neo4j, um banco de dados Baseado em Grafo, criou-se um modelo que utiliza os dubladores, ou _seiyuus_, presentes nos animes para "recomendar" outros animes.


## Integrantes
| Nome | RA |
|------|-----------|
| Fernando Laiser F Kon | 19.01336-0 |
| Igor Eiki Ferreira Kubota | 19.02466-5 |

## Base de Dados
O dataset escolhido foi o [_Anime Dataset 2022_](https://www.kaggle.com/datasets/vishalmane10/anime-dataset-2022) disponibilizado no _Kaggle_. O dataSet foi criado através de _Web Scrapping_ no site [_Anime-planet_](https://www.anime-planet.com/). Ele contém 18495 linhas and 17 colunas com informações relacionadas aos animes disponiveis no site.

## Pré-Requisitos
é necessário a biblioteca _**pandas**_ para o tratamento dos dados do dataset original.

## **Tratamento de Dados**

_**Todo o processo de tratamento de dados está salvo no arquivo _tratamento.ipynb_**_

Para a realização do Sistema de Recomendação, foi necessário realizar o tratamento e limpeza do dataset original (_/datasets/base/Anime.csv_). Para sua utilização no Neo4j, escolheu-se separar o dataset em 3 datasets separados. 

 - anime_treated.csv       - Informações relacionado aos animes.
 - Seiyuu_treated_only.csv - Dubladores atribuidos a um ID único.
 - cast.csv                - Correlação entre os dubladores e os personagens dublados em seus respectivos animes.


### **1º Passo - Iniciar o dataframe**
transformar o dataset Anime.csv em um dataframe em _pandas_.

### **2º Passo - Remoção de campos que não são usados**
Criar um novo dataframe com os dados do dataframe original a fim de não mudá-lo e Dropar os campos que não são relevantes do dataset, como: 
- Mangás relacionados, 
- Staff, 
- Nome em Japonês, 
- Content Warning,
- Ano de Encerramento

### **3º Passo - Limpeza dos dados**

Dropar as tuplas que contém valores nulos nos campos:
    
- Tags
- Rating
- Studio
- Voice_actors

e  por ser um sistema de recomendação, também dropar todos os animes com rating inferior a 3.01.

### **4º Passo - criação do dataframe de seiyuu**
Criar um novo dataframe com as informações de seiyuu(Dubladores). Para isso foi feito um split em ',' conforme a função criada nos valores da coluna _Voice_actors_ do dataset de anime com o tratamento inicial para pegar as seguintes informações e descartar alguns valores inúteis para nós na coluna _Voice_actors_ como produtores musicais entre outros que se encontram na coluna. 

- Rank           -> utilizado como id do anime
- Name           -> qual anime que é
- Voice_actors   -> os personagens e seus respectivos dubladores

Após isso foi separadocada personagem e seu dublador dos outros, "explodindo" o campo original e criando uma coluna _pairs_ que foi novamente dividida por um split para separar os personagens dos dubladores em si, Criando assim os campos 
_char_ e _seiyuu_ em um novo dataframe.

Os dubladores foram atribuidos IDs Únicos para serem referenciados.

### **5º Passo- Criação do Cast.csv**
Por fim a criação de um dataset com informações de elenco de cada anime. Esse dataset recebe os valores:
- Rank, usado com id_anime ,do dataset de animes tratados
- char, Nome do personagem no anime, do dataset de seiyuus
- id_seiyuu, ID único atribuido ao dublador, do dataset de seiyuus.

é esse dataset que faz com que seja possível relacionar as informações de dubladores com os animes feitos.

## **Queries**
Após a importação dos dados e o merge nas tabelas para fazer os relacionamentos entre as tabelas, foram realizadas algumas queries no banco neo4j para a obtenção de resultados.

_**Todas a Queries se encontram no arquivo Queries.sql**_

**Resultados em formato de tabelas estão disponíveis na pasta _/exported_csv/_**


_1 - Exemplo de Seiyuus do Anime Shadow House:_
```sql
MATCH (a)-[c:cast]->(s)
WHERE a.name =~ '(?i).*Shadow House.*'
RETURN *
-- return s.VoiceActor -- para pegar a tabela com os nomes
```
resultado - grafo:

![shadows house](https://github.com/Igor-Kubota/Anime-Recommendation/blob/main/imgs/1%20-%20shadow_house.png)


Resultado - Tabela: 
```
╒═════════════════╕
│s.VoiceActor     │
╞═════════════════╡
│"Yuu Sasahara"   │
├─────────────────┤
│"Yumi Kakazu"    │
├─────────────────┤
│"Koudai Sakai"   │
├─────────────────┤
│"Reiji Kawashima"│
├─────────────────┤
│"Akari Kitou"    │
├─────────────────┤
│"Ayane Sakura"   │
└─────────────────┘
```
_2 - Exemplo de animes da Akari Kitou:_
```sql
MATCH (a)-[c:cast]->(s)
WHERE s.VoiceActor =~ '(?i).*Akari Kitou.*'
RETURN *
-- return a.Name -- para pegar a tabela com os nomes
```
resultado - grafo:

![akari](https://github.com/Igor-Kubota/Anime-Recommendation/blob/main/imgs/2%20-%20akari_kitou.png)


Resultado - Tabela com linhas de exemplo: 
```
╒══════════════════════════════════════════════════════════════════════╕
│a.Name                                                                │
╞══════════════════════════════════════════════════════════════════════╡
│"Akebi's Sailor Uniform"                                              │
├──────────────────────────────────────────────────────────────────────┤
│"The Ones Within"                                                     │
├──────────────────────────────────────────────────────────────────────┤
│"In/Spectre Mini Anime"                                               │
├──────────────────────────────────────────────────────────────────────┤
│"TONIKAWA: Over the Moon for You OVA"                                 │
├──────────────────────────────────────────────────────────────────────┤
│"Harukana Receive"                                                    │
├──────────────────────────────────────────────────────────────────────┤
│"Demon Slayer: Kimetsu no Yaiba - Entertainment District Arc"         │
└──────────────────────────────────────────────────────────────────────┘
```

_3 - Contagem de animes por dublador:_

```sql
MATCH (s)<-[:participa]-(a)
RETURN s.VoiceActor, COUNT(*) AS Contagem
ORDER BY Contagem DESC
```

Resultado - Tabela com 5 linhas de exemplo: 
```
╒══════════════════════╤════════╕
│s.VoiceActor          │Contagem│
╞══════════════════════╪════════╡
│"Kana Hanazawa"       │281     │
├──────────────────────┼────────┤
│"Takahiro Sakurai"    │273     │
├──────────────────────┼────────┤
│"Jun Fukuyama"        │258     │
├──────────────────────┼────────┤
│"Miyuki Sawashiro"    │233     │
├──────────────────────┼────────┤
│"Rie Kugimiya"        │229     │
├──────────────────────┼────────┤
│"Akiko Kimura"        │23      │
└──────────────────────┴────────┘
```

_4 - relacionamento primeiro nivel - quem trabalhou com Rikako Aida:_
```sql
MATCH (s1: seiyuu)<-[c1:cast]-(a)-[c2:cast]->(s2:seiyuu)
WHERE s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s1 <> s2
RETURN *
```
resultado - grafo:

![primeiro nivel](https://github.com/Igor-Kubota/Anime-Recommendation/blob/main/imgs/3%20-%20first-level.png)

```sql
MATCH (s1: seiyuu)<-[c1:cast]-(a)-[c2:cast]->(s2:seiyuu)
WHERE s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s1 <> s2
RETURN s1.VoiceActor, a.Name ,s2.VoiceActor
ORDER BY s1.VoiceActor, a.Name ,s2.VoiceActor
```

Resultado - Tabela com linhas de exemplo: 
```
╒═════════════╤═══════════════════════════════════════╤══════════════════╕
│s1.VoiceActor│a.Name                                 │s2.VoiceActor     │
╞═════════════╪═══════════════════════════════════════╪══════════════════╡
│"Rikako Aida"│"Happy Party Train"                    │"Ai Furihata"     │
├─────────────┼───────────────────────────────────────┼──────────────────┤
│"Rikako Aida"│"Happy Party Train"                    │"Aina Suzuki"     │
├─────────────┼───────────────────────────────────────┼──────────────────┤
│"Rikako Aida"│"Happy Party Train"                    │"Anju Inami"      │
├─────────────┼───────────────────────────────────────┼──────────────────┤
│"Rikako Aida"│"The Aquatope on White Sand Mini Anime"│"Miku Itou"       │
├─────────────┼───────────────────────────────────────┼──────────────────┤
│"Rikako Aida"│"The Aquatope on White Sand Mini Anime"│"Shimba Tsuchiya" │
├─────────────┼───────────────────────────────────────┼──────────────────┤
│"Rikako Aida"│"The Aquatope on White Sand Mini Anime"│"Youhei Azakami"  │
└─────────────┴───────────────────────────────────────┴──────────────────┘
```

_5 - Relacionamento segundo nivel - Dubladores que trabalharam em Animes com a dubladora Aina Suzuki que Trabalhou com Rikako Aida - Grafo - Detalhe na dubladora 'Aina Suzuki':_
```sql
MATCH (s1:seiyuu)<-[c1:cast]-(a1:anime)-[c2:cast]->(s2:seiyuu)<-[c3:cast]-(a2:anime)-[c4:cast]->(s3:seiyuu)
WHERE s1 <> s3
AND s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND NOT (s1)<-[:cast]-(:anime)-[:cast]->(s3)
RETURN a1.Name , s2.VoiceActor AS Proximo_Rikako_Aida, a2.Name, s3.VoiceActor AS Trabalhou_com_proximos_Rikako_aida
ORDER BY a1.Name, s2.VoiceActor, a2.Name, s3.VoiceActor
```
Resultado - grafo:
![segundo nivel detalhado](https://github.com/Igor-Kubota/Anime-Recommendation/blob/main/imgs/5%20-%20second-level-detailed.png)

Resultado - Tabela com linhas de exemplo: 
```
╒═══════════════╤═══════════════╤═══════════════╤═══════════════╕
│a1.Name        │Proximo_Rikako_│a2.Name        │Trabalhou_com_p│
│               │Aida           │               │roximos_Rikako_│
│               │               │               │aida           │
╞═══════════════╪═══════════════╪═══════════════╪═══════════════╡
│"Happy Party Tr│"Aina Suzuki"  │"Alice or Alice│"Ayaka Suwa"   │
│ain"           │               │: Siscon Nii-sa│               │
│               │               │n to Futago no │               │
│               │               │Imouto Recap"  │               │
├───────────────┼───────────────┼───────────────┼───────────────┤
│"Happy Party Tr│"Aina Suzuki"  │"Alice or Alice│"Ayane Sakura" │
│ain"           │               │: Siscon Nii-sa│               │
│               │               │n to Futago no │               │
│               │               │Imouto Recap"  │               │
├───────────────┼───────────────┼───────────────┼───────────────┤
│"Happy Party Tr│"Aina Suzuki"  │"Dropkick on My│"Rico Sasaki"  │
│ain"           │               │ Devil!! Dash" │               │
├───────────────┼───────────────┼───────────────┼───────────────┤
│"Happy Party Tr│"Aina Suzuki"  │"Dropkick on My│"Riho Iida"    │
│ain"           │               │ Devil!! Dash" │               │
├───────────────┼───────────────┼───────────────┼───────────────┤
│"Senryu Girl"  │"Hiroyuki Yoshi│"Hakuouki: A Me│"Tomohiro Tsubo│
│               │no"            │mory of Snow Fl│i"             │
│               │               │owers"         │               │
└───────────────┴───────────────┴───────────────┴───────────────┘
```

_6 - Relacionamento segundo nivel - Quem Trabalhou com os atores que trabalharam com Rikako Aida:_
```sql
MATCH (s1:seiyuu)<-[c1:cast]-(a1:anime)-[c2:cast]->(s2:seiyuu)<-[c3:cast]-(a2:anime)-[c4:cast]->(s3:seiyuu)
WHERE s1 <> s3
AND s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s2.VoiceActor =~ '(?i).*Aina Suzuki.*'
AND NOT (s1)<-[:cast]-(:anime)-[:cast]->(s3)
RETURN *
```

Resultado - grafo:
![segundo nivel geral ](https://github.com/Igor-Kubota/Anime-Recommendation/blob/main/imgs/4%20-%20second-level-general.png)

_7 - Recomendação Segundo nivel -  Anime baseado na dubladora Aina Suzuki que trabalhou com Rikako Aida - Detalhe na dubladora 'Aina Suzuki' e no anime 'Dropkick on My Devil!':_
```sql
MATCH (s1:seiyuu)<-[c1:cast]-(a1:anime)-[c2:cast]->(s2:seiyuu)<-[c3:cast]-(a2:anime)-[c4:cast]->(s3:seiyuu)<-[c5:cast]-(a3:anime)
WHERE s1 <> s3
AND s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s2.VoiceActor =~ '(?i).*Aina Suzuki.*'
AND a2.Name ='Dropkick on My Devil!'
AND NOT (s1)<-[:cast]-(:anime)-[:cast]->(s3)
RETURN *
```

Resultado - grafo:
![recomendacao](https://github.com/Igor-Kubota/Anime-Recommendation/blob/main/imgs/6%20-%20Recomendation.png)

Resultado - Tabela com linhas de exemplo
```
╒═════════════╤═════════════╤═════════════╤═════════════╤═════════════╕
│a1.Name      │Proximo_Rikak│a2.Name      │Trabalhou_com│a3.Name      │
│             │o_Aida       │             │_proximos_Rik│             │
│             │             │             │ako_aida     │             │
╞═════════════╪═════════════╪═════════════╪═════════════╪═════════════╡
│"Happy Party │"Aina Suzuki"│"Alice or Ali│"Ayaka Suwa" │"Hello!! KINM│
│Train"       │             │ce: Siscon Ni│             │OZA!"        │
│             │             │i-san to Futa│             │             │
│             │             │go no Imouto │             │             │
│             │             │Recap"       │             │             │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│"Happy Party │"Aina Suzuki"│"Alice or Ali│"Ayaka Suwa" │"Hikari: Kari│
│Train"       │             │ce: Siscon Ni│             │ya wo Tsunagu│
│             │             │i-san to Futa│             │ Monogatari" │
│             │             │go no Imouto │             │             │
│             │             │Recap"       │             │             │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│"Happy Party │"Aina Suzuki"│"Alice or Ali│"Ayane Sakura│"Charlotte"  │
│Train"       │             │ce: Siscon Ni│"            │             │
│             │             │i-san to Futa│             │             │
│             │             │go no Imouto │             │             │
│             │             │Recap"       │             │             │
├─────────────┼─────────────┼─────────────┼─────────────┼─────────────┤
│"Happy Party │"Aina Suzuki"│"Don't Toy Wi│"Daiki Yamash│"Blue Period.│
│Train"       │             │th Me, Miss N│ita"         │"            │
│             │             │agatoro"     │             │             │
└─────────────┴─────────────┴─────────────┴─────────────┴─────────────┘
```

_8 - Caminho para chegar até Riho Iida :_

```sql
MATCH (s1:seiyuu)<-[c1:cast]-(a1:anime)-[c2:cast]->(s2:seiyuu)<-[c3:cast]-(a2:anime)-[c4:cast]->(s3:seiyuu)
WHERE s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s3.VoiceActor =~ '(?i).*Riho Iida.*'
AND NOT (s1)<-[:cast]-(:anime)-[:cast]->(s3)
RETURN *
```

Resultado - grafo:
![caminho](https://github.com/Igor-Kubota/Anime-Recommendation/blob/main/imgs/7%20-%20caminho.png)


_9 - Caminhos e força de cada Caminho para chegar até Riho Iida :_
```sql
MATCH (s1:seiyuu)<-[c1:cast]-(a1)-[c2:cast]->(s2), (s2)<-[c3:cast]-(a2)-[c4:cast]->(s3)
WHERE s1.VoiceActor =~ '(?i).*Rikako Aida.*'
AND s3.VoiceActor =~ '(?i).*Riho Iida.*'
AND NOT (s1)<-[:cast]-()-[:cast]->(s3) AND s1 <> s3
RETURN s2.VoiceActor, s3.VoiceActor AS Recomendado, COUNT(*) AS Força
ORDER BY Força DESC
```

Resultado - Tabela com Linhas de exemplo
```
╒═════════════╤═══════════╤═════╕
│s2.VoiceActor│Recomendado│Força│
╞═════════════╪═══════════╪═════╡
│"Aina Suzuki"│"Riho Iida"│9    │
├─────────────┼───────────┼─────┤
│"Miku Itou"  │"Riho Iida"│2    │
└─────────────┴───────────┴─────┘
```









## Estrutura do Repositorio
```
📦Anime-Recommendation
 ┣ 📂datasets
 ┃ ┣ 📂base
 ┃ ┃ ┗ 📜Anime.csv
 ┃ ┣ 📂testes
 ┃ ┃ ┣ 📜fixedlove.csv
 ┃ ┃ ┣ 📜love.csv
 ┃ ┃ ┣ 📜seiyuu.csv
 ┃ ┃ ┣ 📜seiyuutreated.csv
 ┃ ┃ ┣ 📜seiyuu_treated.csv
 ┃ ┃ ┣ 📜teste_slice_of_life.csv
 ┃ ┃ ┣ 📜teste_sunshine.csv
 ┃ ┃ ┣ 📜teste_sunshine_split.csv
 ┃ ┃ ┣ 📜teste_superstar.csv
 ┃ ┃ ┗ 📜teste_superstar_va.csv
 ┃ ┣📜anime_treated.csv
 ┃ ┣📜cast.csv
 ┃ ┗📜seiyuu_treated_only.csv
 ┣ 📂exported_csv
 ┃ ┣ 📜1 - shadow_house.csv
 ┃ ┣ 📜2 - animes-akari_kitou.csv
 ┃ ┣ 📜3 - contagem.csv
 ┃ ┣ 📜4 - relationship - first level.csv
 ┃ ┣ 📜5 - relationship - second level.csv
 ┃ ┣ 📜6 - recommendation - detailed.csv
 ┃ ┗ 📜7 - relationship force.csv
 ┣ 📂imgs
 ┃ ┣ 📜1 - shadow_house.png
 ┃ ┣ 📜2 - akari_kitou.png
 ┃ ┣ 📜3 - first-level.png
 ┃ ┣ 📜4 - second-level-general.png
 ┃ ┣ 📜5 - second-level-detailed.png
 ┃ ┣ 📜6 - Recomendation.png
 ┃ ┗ 📜7 - caminho.png
 ┣ 📜.gitattributes
 ┣ 📜.gitignore
 ┣ 📜anime_dataset.ipynb
 ┣ 📜Queries.sql
 ┣ 📜README.md
 ┗ 📜tratamento.ipynb
```