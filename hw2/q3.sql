-- Participate

SET SEARCH_PATH TO parlgov;
drop table if exists q3 cascade;

-- You must not change this table definition.

create table q3(
        countryName varchar(50),
        year int,
        participationRatio real
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
-- Define views for your intermediate steps here.

-- convert the votes_cast to participation for each election
DROP VIEW IF EXISTS ELECTION_PARTICIPATION CASCADE;
CREATE VIEW ELECTION_PARTICIPATION AS
  (SELECT id, country_id, cast(to_char(e_date, 'YYYY') AS integer) AS year, (0.0 + votes_cast) / electorate AS participationRatio
    FROM election);

-- convert the average participation with respect to country and year during [2001, 2016]
DROP VIEW IF EXISTS YEARLY_PARTICIPATION CASCADE;
CREATE VIEW YEARLY_PARTICIPATION AS
 (SELECT country_id, year, AVG(participationRatio) AS participationRatio
  FROM ELECTION_PARTICIPATION
  WHERE year >= 2001 AND year <= 2016 
  GROUP BY country_id, year);
  
-- countries where the participation is monotonically non-decreasing
DROP VIEW IF EXISTS COUNTRY_PARTICIPATION_NON_DESC CASCADE;
CREATE VIEW COUNTRY_PARTICIPATION_NON_DESC AS
  (SELECT country_id
    FROM YEARLY_PARTICIPATION)
  EXCEPT
  (SELECT Y1.country_id 
    FROM YEARLY_PARTICIPATION Y1, YEARLY_PARTICIPATION Y2
    WHERE Y1.country_id = Y2.country_id AND Y1.year < Y2.year AND Y1.participationRatio > Y2.participationRatio);

-- concatenate non-desc countries with its participation during [2001, 2016]
DROP VIEW IF EXISTS YEARLY_PARTICIPATION_NON_DESC CASCADE;
CREATE VIEW YEARLY_PARTICIPATION_NON_DESC AS 
  (SELECT Y.country_id, year, participationRatio
    FROM YEARLY_PARTICIPATION Y JOIN COUNTRY_PARTICIPATION_NON_DESC C
    ON Y.country_id = C.country_id);

-- concatenate everything for the answer
DROP VIEW IF EXISTS ANSWER CASCADE;
CREATE VIEW ANSWER AS 
  (SELECT country.name as countryName, year, participationRatio
    FROM YEARLY_PARTICIPATION_NON_DESC Y JOIN country 
    ON Y.country_id = country.id);    
 
-- the answer to the query 
insert into q3 
SELECT * FROM ANSWER;
