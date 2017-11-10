-- Committed

SET SEARCH_PATH TO parlgov;
drop table if exists q5 cascade;

-- You must not change this table definition.

CREATE TABLE q5(
        countryName VARCHAR(50),
        partyName VARCHAR(100),
        partyFamily VARCHAR(50),
        stateMarket REAL
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
-- Define views for your intermediate steps here.
DROP VIEW IF EXISTS PARTY_CABINET_TIME CASCADE;
CREATE VIEW PARTY_CABINET_TIME AS
  (SELECT party_id, cabinet_id, country_id, cast(to_char(start_date, 'YYYY') AS integer) AS year
    FROM cabinet JOIN cabinet_party ON cabinet.id = cabinet_party.cabinet_id
    WHERE start_date >= DATE '1996-01-01');
    
DROP VIEW IF EXISTS COMMITTED_PARTY CASCADE;
CREATE VIEW COMMITTED_PARTY AS
  (SELECT party_id 
    FROM PARTY_CABINET_TIME)
  EXCEPT
  (SELECT P1.party_id
    FROM PARTY_CABINET_TIME P1
    WHERE EXISTS 
      (SELECT P2.party_id
        FROM PARTY_CABINET_TIME P2
        WHERE P1.country_id = P2.country_id
              AND P1.party_id not in 
                (SELECT party_id 
                  FROM PARTY_CABINET_TIME P3
                  WHERE P2.cabinet_id = P3.cabinet_id)));             

DROP VIEW IF EXISTS ANSWER CASCADE;
CREATE VIEW ANSWER AS
  (SELECT C.name AS countryName, P.name AS partyName, PF.family AS partyFamily, PP.state_market AS stateMarket
    FROM COMMITTED_PARTY CP 
      JOIN party P ON CP.party_id = P.id
      JOIN country C ON P.country_id = C.id
      JOIN party_family PF ON CP.party_id = PF.party_id
      JOIN party_position PP ON CP.party_id = PP.party_id);

-- the answer to the query 
insert into q5
SELECT * FROM ANSWER;
