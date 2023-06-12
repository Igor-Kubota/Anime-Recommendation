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

1 - Exemplo de Seiyuus do Anime Shadow House:
```sql
MATCH (a)-[c:cast]->(s)
WHERE a.name =~ '(?i).*Shadow House.*'
RETURN *
-- return s.VoiceActor -- para pegar a tabela com os nomes
```
resultado - grafo:

![shadows house](https://github.com/Igor-Kubota/Anime-Recommendation/blob/main/imgs/1%20-%20shadow_house.png)

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