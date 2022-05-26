//NOTE: This script loads subset of data set
//Total loaded data size:
//47999 nodes
//86456 relationships

//Create constraints
CREATE CONSTRAINT FOR (b:Book) REQUIRE b.book_id IS UNIQUE;
CREATE CONSTRAINT FOR (a:Author) REQUIRE a.author_id IS UNIQUE;
CREATE CONSTRAINT FOR (r:Review) REQUIRE r.review_id IS UNIQUE;

//Load 8.5k books
CALL apoc.load.json("https://raw.githubusercontent.com/JMHReif/microservices-level6/main/data-neo4j/goodreads_books_5500.json") YIELD value as book
MERGE (b:Book {book_id: book.book_id})
SET b += apoc.map.clean(book, ['authors'],[""]);
//5500 Book nodes

//Import initial authors for 8.5k books
CALL apoc.load.json("https://raw.githubusercontent.com/JMHReif/microservices-level6/main/data-neo4j/goodreads_books_5500.json") YIELD value as book
WITH book
UNWIND book.authors as author
MERGE (a:Author {author_id: author.author_id});
//7157 Author nodes

//Hydrate Author nodes
CALL apoc.periodic.iterate(
'CALL apoc.load.json("https://data.neo4j.com/goodreads/goodreads_book_authors.json.gz") YIELD value as author',
'WITH author MATCH (a:Author {author_id: author.author_id}) SET a += apoc.map.clean(author, [],[""])',
{batchsize: 8000}
);

//Load Author relationships
CALL apoc.load.json("https://raw.githubusercontent.com/JMHReif/microservices-level6/main/data-neo4j/goodreads_books_5500.json") YIELD value as book
WITH book
MATCH (b:Book {book_id: book.book_id})
WITH book, b
UNWIND book.authors as author
MATCH (a:Author {author_id: author.author_id})
MERGE (a)-[w:AUTHORED]->(b);
//15772 AUTHORED relationships

//LEFT OFF HERE!

//Load Reviews
CALL apoc.periodic.iterate(
'CALL apoc.load.json("https://data.neo4j.com/goodreads/goodreads_bookReviews_demo.json.gz") YIELD value as review',
'WITH review MERGE (r:Review {review_id: review.review_id}) SET r += apoc.map.clean(review, [],[""])',
{batchsize: 10000}
);
//35342 Review nodes

//Load Review relationships
CALL apoc.periodic.iterate(
'CALL apoc.load.json("https://data.neo4j.com/goodreads/goodreads_reviewRels_demo.json.gz") YIELD value as rel',
'WITH rel MATCH (r:Review {review_id: rel.review_id}) MATCH (b:Book {book_id: rel.book_id}) MERGE (r)-[wf:WRITTEN_FOR]->(b)',
{batchsize: 10000}
);
//70684 WRITTEN_FOR relationships
