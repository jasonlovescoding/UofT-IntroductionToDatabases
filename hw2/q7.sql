-- Alliances

SET SEARCH_PATH TO parlgov;
drop table if exists q7 cascade;

-- You must not change this table definition.

DROP TABLE IF EXISTS q7 CASCADE;
CREATE TABLE q7(
        countryId INT, 
        alliedPartyId1 INT, 
        alliedPartyId2 INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
-- Define views for your intermediate steps here.

-- allliance can be 1: parties who share the same leader in the same election 2: party with its leader
DROP VIEW IF EXISTS ALLIANCE CASCADE;
CREATE VIEW ALLIANCE AS
  (SELECT ER1.party_id AS alliedPartyId1, ER2.party_id AS alliedPartyId2, country_id, election.id AS election_id
    FROM election_result ER1 JOIN election_result ER2
      ON ER1.election_id = ER2.election_id JOIN election
      ON ER1.election_id = election.id
    WHERE (ER1.alliance_id = ER2.alliance_id AND ER1.party_id < ER2.party_id) 
      OR (ER1.alliance_id = ER2.id)); 

-- re-order party alliance pairs with smaller id first
DROP VIEW IF EXISTS ALLIANCE_PAIR CASCADE;
CREATE VIEW ALLIANCE_PAIR AS
  (SELECT election_id, country_id, alliedPartyId1, alliedPartyId2
    FROM ALLIANCE
    WHERE alliedPartyId1 < alliedPartyId2)
  UNION 
  (SELECT election_id, country_id, alliedPartyId2 as alliedPartyId1, alliedPartyId1 AS alliedPartyId2
    FROM ALLIANCE
    WHERE alliedPartyId1 > alliedPartyId2);

-- count the frequency of alliance pairs
DROP VIEW IF EXISTS ALLIANCE_COUNT CASCADE;
CREATE VIEW ALLIANCE_COUNT AS
  (SELECT alliedPartyId1, alliedPartyId2, country_id, count(distinct election_id) AS alliance_count
    FROM ALLIANCE_PAIR
    GROUP BY alliedPartyId1, alliedPartyId2, country_id);

-- conut the frequency of elections in a country
DROP VIEW IF EXISTS COUNTRY_ELECTION_COUNT CASCADE;
CREATE VIEW COUNTRY_ELECTION_COUNT AS
  (SELECT country_id, count(distinct id) as election_count
    FROM election
    GROUP BY country_id);

-- select only those pairs who are in more than 30% of the elections
DROP VIEW IF EXISTS ANSWER CASCADE;
CREATE VIEW ANSWER AS
  (SELECT A.country_id as countryId, alliedPartyId1, alliedPartyId2
    FROM ALLIANCE_COUNT A JOIN COUNTRY_ELECTION_COUNT C 
      ON A.country_id = C.country_id
    WHERE (100.0 * alliance_count) / election_count >= 30);

-- the answer to the query 
insert into q7 
SELECT * FROM ANSWER;
