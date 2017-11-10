-- VoteRange

SET SEARCH_PATH TO parlgov;
drop table if exists q1 cascade;

-- You must not change this table definition.

create table q1(
year INT,
countryName VARCHAR(50),
voteRange VARCHAR(20),
partyName VARCHAR(100)
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
-- Define views for your intermediate steps here.
DROP VIEW IF EXISTS ELECTION_PARTY_RESULTS CASCADE;
CREATE VIEW ELECTION_PARTY_RESULTS AS
  (SELECT election_id, cast(to_char(e_date, 'YYYY') AS integer) AS YEAR, country_id, party_id, votes 
    FROM election_result JOIN election on election_result.election_id = election.id);

DROP VIEW IF EXISTS ELECTION_TOTAL_VOTES CASCADE;
CREATE VIEW ELECTION_TOTAL_VOTES AS
  (SELECT id AS election_id, CASE
                      WHEN election.votes_valid IS NOT NULL THEN election.votes_valid
                      ELSE (SELECT sum(votes) FROM election_result WHERE election_id = election.id GROUP BY election_id)
                      END AS total_votes
    FROM election);

DROP VIEW IF EXISTS ELECTION_PARTY_RANGE CASCADE;
CREATE VIEW ELECTION_PARTY_RANGE AS
  (SELECT year, country_id, party_id, (100.0 * votes) / total_votes as range
    FROM ELECTION_PARTY_RESULTS E1 JOIN ELECTION_TOTAL_VOTES E2 ON E1.election_id = E2.election_id
    WHERE 1996 <= year AND year <= 2016);

DROP VIEW IF EXISTS YEARLY_RANGE CASCADE;
CREATE VIEW YEARLY_RANGE AS
  (SELECT party_id, year, AVG(range) AS avgrange
    FROM ELECTION_PARTY_RANGE
    GROUP BY party_id, year);

DROP VIEW IF EXISTS ELECTION_PARTY_YEARLY_RANGE CASCADE;
CREATE VIEW ELECTION_PARTY_YEARLY_RANGE AS
  (SELECT DISTINCT E.year, E.country_id, CASE 
                                          WHEN avgrange > 0 AND avgrange <= 5 THEN '(0, 5]'
                                          WHEN avgrange > 5  AND avgrange <= 10 THEN '(5, 10]'
                                          WHEN avgrange > 10 AND avgrange <= 20 THEN '(10, 20]'
                                          WHEN avgrange > 20 AND avgrange <= 30 THEN '(20, 30]'
                                          WHEN avgrange > 30 AND avgrange <= 40 THEN '(30, 40]'
                                          ELSE '(40, 100]'
                                          END AS voteRange
                                          , E.party_id
    FROM ELECTION_PARTY_RANGE E JOIN YEARLY_RANGE Y ON E.year = Y.year AND E.party_id = Y.party_id
    WHERE range IS NOT NULL AND avgrange IS NOT NULL);

DROP VIEW IF EXISTS ANSWER CASCADE;
CREATE VIEW ANSWER AS
  (SELECT year, country.name as countryName, voteRange, party.name_short as partyName
    FROM ELECTION_PARTY_YEARLY_RANGE E JOIN country ON E.country_id = country.id JOIN party ON E.party_id = party.id);

-- the answer to the query 
insert into q1
SELECT * FROM ANSWER;
