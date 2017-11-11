-- Left-right

SET SEARCH_PATH TO parlgov;
drop table if exists q4 cascade;

-- You must not change this table definition.


CREATE TABLE q4(
        countryName VARCHAR(50),
        r0_2 INT,
        r2_4 INT,
        r4_6 INT,
        r6_8 INT,
        r8_10 INT
);

-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
create view position0_2 as
select country.name as countryName, count(party_position.party_id) as r0_2
from party_position, party, country
where party_position.party_id = party.id
and party.country_id = country.id
and Left_right >= 0
and Left_right < 2
group by country.name;

create view position2_4 as
select country.name as countryName, count(party_position.party_id) as r2_4
from party_position, party, country
where party_position.party_id = party.id
and party.country_id = country.id
and Left_right >= 2
and Left_right < 4
group by country.name;

create view position4_6 as
select country.name as countryName, count(party_position.party_id) as r4_6
from party_position, party, country
where party_position.party_id = party.id
and party.country_id = country.id
and Left_right >= 4
and Left_right < 6
group by country.name;

create view position6_8 as
select country.name as countryName, count(party_position.party_id) as r6_8
from party_position, party, country
where party_position.party_id = party.id
and party.country_id = country.id
and Left_right >= 6
and Left_right < 8
group by country.name;

create view position8_10 as
select country.name as countryName, count(party_position.party_id) as r8_10
from party_position, party, country
where party_position.party_id = party.id
and party.country_id = country.id
and Left_right >= 8
and Left_right < 10
group by country.name;
-- the answer to the query 
INSERT INTO q4 

select position0_2.countryName, r0_2, r2_4, r4_6, r6_8, r8_10
from position0_2, position2_4, position4_6, position6_8, position8_10
where position0_2.countryName = position2_4.countryName
and position0_2.countryName = position4_6.countryName
and position0_2.countryName = position6_8.countryName
and position0_2.countryName = position8_10.countryName;