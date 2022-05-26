//NOTE: This script loads subset of data set
//Total loaded data size:
// nodes
// relationships

//Create constraints
CREATE CONSTRAINT FOR (b:Book) REQUIRE b.book_id IS UNIQUE;
CREATE CONSTRAINT FOR (a:Author) REQUIRE a.author_id IS UNIQUE;
CREATE CONSTRAINT FOR (r:Review) REQUIRE r.review_id IS UNIQUE;

//Load 8.5k books
CALL apoc.load.json("https://raw.githubusercontent.com/JMHReif/microservices-level6/main/data-neo4j/goodreads_books_6k.json") YIELD value as book
MERGE (b:Book {book_id: book.book_id})
SET b += apoc.map.clean(book, ['authors'],[""]);
//8500 Book nodes

//Import initial authors for 8.5k books
CALL apoc.load.json("https://raw.githubusercontent.com/JMHReif/microservices-level6/main/data-neo4j/goodreads_books_6k.json") YIELD value as book
WITH book
UNWIND book.authors as author
MERGE (a:Author {author_id: author.author_id});
//10669 Author nodes

//Hydrate Author nodes
CALL apoc.periodic.iterate(
'CALL apoc.load.json("https://data.neo4j.com/goodreads/goodreads_book_authors.json.gz") YIELD value as author',
'WITH author MATCH (a:Author {author_id: author.author_id}) SET a += apoc.map.clean(author, [],[""])',
{batchsize: 10000}
);

//Load Author relationships
CALL apoc.load.json("https://raw.githubusercontent.com/JMHReif/microservices-level6/main/data-neo4j/goodreads_books_6k.json") YIELD value as book
WITH book
MATCH (b:Book {book_id: book.book_id})
WITH book, b
UNWIND book.authors as author
MATCH (a:Author {author_id: author.author_id})
MERGE (a)-[w:AUTHORED]->(b);
//12131 AUTHORED relationships

//LEFT OFF HERE!

//Load Reviews
CALL apoc.periodic.iterate(
'CALL apoc.load.json("https://data.neo4j.com/goodreads/goodreads_bookReviews_demo.json.gz") YIELD value as review',
'WITH review MERGE (r:Review {review_id: review.review_id}) SET r += apoc.map.clean(review, [],[""])',
{batchsize: 10000}
);
//69791 Review nodes

//Load Review relationships
CALL apoc.periodic.iterate(
'CALL apoc.load.json("https://data.neo4j.com/goodreads/goodreads_reviewRels_demo.json.gz") YIELD value as rel',
'WITH rel MATCH (r:Review {review_id: rel.review_id}) MATCH (b:Book {book_id: rel.book_id}) MERGE (r)-[wf:WRITTEN_FOR]->(b)',
{batchsize: 10000}
);
//69791 WRITTEN_FOR relationships
