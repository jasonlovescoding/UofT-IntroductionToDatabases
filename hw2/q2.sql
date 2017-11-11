-- Winners

SET SEARCH_PATH TO parlgov;
drop table if exists q2 cascade;

-- You must not change this table definition.

create table q2(
countryName VARCHaR(100),
partyName VARCHaR(100),
partyFamily VARCHaR(100),
wonElections INT,
mostRecentlyWonElectionId INT,
mostRecentlyWonElectionYear INT
);


-- You may find it convenient to do this for each of the views
-- that define your intermediate steps.  (But give them better names!)
DROP VIEW IF EXISTS intermediate_step CASCADE;

-- Define views for your intermediate steps here.
create view winning_count as
select count(election_result.id) as wonElections, election_result.party_id, party.country_id,
party.name as partyName, country.name as countryName, party_family.family as partyFamily
from election_result, party, country, party_family
where election_result.party_id = party.id
and party.country_id = country.id
and party.id = party_family.party_id
group by election_result.party_id, partyName, partyFamily, party.country_id, countryName;

create view average_winning_count as
select avg(wonElections) as average_count, country_id
from winning_count
group by country_id;

create view mostRecentlyWonElection as
select winning_count.party_id, max(election.e_date) as mostRecentlyWonElectionYear, election.id as mostRecentlyWonElectionId
from election, election_result, winning_count
where election.id = election_result.id
and election_result.party_id = winning_count.party_id
group by winning_count.party_id, election.id;
-- the answer to the query 
insert into q2
select countryName, partyName, partyFamily, wonElections, cast(to_char(mostRecentlyWonElectionYear, 'yyyy')as integer) as mostRecentlyWonElectionYear, mostRecentlyWonElectionId
from winning_count, average_winning_count, mostRecentlyWonElection
where winning_count.party_id = mostRecentlyWonElection.party_id
and winning_count.country_id = average_winning_count.country_id
and winning_count.wonElections-3 >average_winning_count.average_count;