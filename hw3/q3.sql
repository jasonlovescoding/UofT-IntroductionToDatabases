-- correct responses to t-f questions
DROP VIEW IF EXISTS tfqCorrects CASCADE;
CREATE VIEW tfqCorrects AS (
  SELECT r.sID, r.qID
  FROM Response r JOIN tfResponse tfr 
       ON r.tfrID = tfr.tfrID JOIN tfQuestion tfq
       ON r.qID = tfq.tfqID
  WHERE tfr.response = tfq.answer
);
-- correct responses to m-c questions
DROP VIEW IF EXISTS mcqCorrects CASCADE;
CREATE VIEW mcqCorrects AS (
  SELECT r.sID, r.qID
  FROM Response r JOIN mcResponse mcr 
       ON r.mcrID = mcr.mcrID JOIN Option o
       ON mcr.response = o.oid AND o.correct
);
-- correct responses to num questions
DROP VIEW IF EXISTS numqCorrects CASCADE;
CREATE VIEW numqCorrects AS (
  SELECT r.sID, r.qID
  FROM Response r JOIN numResponse numr 
       ON r.numrID = numr.numrID JOIN numQuestion numq
       ON r.qID = numq.numqID
  WHERE numr.response = numq.answer
);
-- combine correct reponses to all questions
DROP VIEW IF EXISTS corrects CASCADE;
CREATE VIEW corrects AS (
  (SELECT * FROM tfqCorrects)
  UNION
  (SELECT * FROM mcqCorrects)
  UNION
  (SELECT * FROM numqCorrects)
);
-- students who enrolled the course we are interested in
DROP VIEW IF EXISTS enrolled CASCADE;
CREATE VIEW enrolled AS (
  SELECT sID
  FROM inClass ic JOIN Class c ON ic.cID = c.cID
  WHERE c.grade = 8 AND c.room = 120 AND teacher = 'Mr. Higgins'
);
-- only take the correct reponses to questions in that quiz we are interested in
-- and count the weights up to get the score
DROP VIEW IF EXISTS scores CASCADE;
CREATE VIEW scores AS (
  SELECT e.sID, SUM(weight) AS total_grade
  FROM corrects c JOIN hasQuestion h ON c.qID = h.qID AND qzid = 'Pr1-220310'
  RIGHT JOIN enrolled e ON c.sID = e.sID
  GROUP BY e.sID
);
-- chain up with student's lastname as final answer
SELECT s1.sID, lastname, coalesce(total_grade, 0) as total_grade
FROM scores s1 JOIN Student s2 ON s1.sID = s2.sID;
