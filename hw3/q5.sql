-- similar to Q3, correct responses to different types of questions 
DROP VIEW IF EXISTS tfqCorrects CASCADE;
CREATE VIEW tfqCorrects AS (
  SELECT r.sID, r.qID
  FROM Response r JOIN tfResponse tfr 
       ON r.tfrID = tfr.tfrID JOIN tfQuestion tfq
       ON r.qID = tfq.tfqID
  WHERE r.qzID = 'Pr1-220310' AND tfr.response = tfq.answer
);

DROP VIEW IF EXISTS tfqIncorrects CASCADE;
CREATE VIEW tfqIncorrects AS (
  SELECT r.sID, r.qID
  FROM Response r JOIN tfResponse tfr 
       ON r.tfrID = tfr.tfrID JOIN tfQuestion tfq
       ON r.qID = tfq.tfqID
  WHERE r.qzID = 'Pr1-220310' AND tfr.response != tfq.answer
);

DROP VIEW IF EXISTS mcqCorrects CASCADE;
CREATE VIEW mcqCorrects AS (
  SELECT r.sID, r.qID
  FROM Response r JOIN mcResponse mcr 
       ON r.mcrID = mcr.mcrID JOIN Option o
       ON mcr.response = o.oid AND o.correct
  WHERE r.qzID = 'Pr1-220310' 
);
-- similar to Q3, except we are collecting incorrect responses (answered but
-- missed the correct answer, very similar to correct)
DROP VIEW IF EXISTS mcqIncorrects CASCADE;
CREATE VIEW mcqIncorrects AS (
  SELECT r.sID, r.qID
  FROM Response r JOIN mcResponse mcr 
       ON r.mcrID = mcr.mcrID JOIN Option o
       ON mcr.response = o.oid AND NOT o.correct
  WHERE r.qzID = 'Pr1-220310' 
);

DROP VIEW IF EXISTS numqCorrects CASCADE;
CREATE VIEW numqCorrects AS (
  SELECT r.sID, r.qID
  FROM Response r JOIN numResponse numr 
       ON r.numrID = numr.numrID JOIN numQuestion numq
       ON r.qID = numq.numqID
  WHERE r.qzID = 'Pr1-220310' AND numr.response = numq.answer
);

DROP VIEW IF EXISTS numqIncorrects CASCADE;
CREATE VIEW numqIncorrects AS (
  SELECT r.sID, r.qID
  FROM Response r JOIN numResponse numr 
       ON r.numrID = numr.numrID JOIN numQuestion numq
       ON r.qID = numq.numqID
  WHERE r.qzID = 'Pr1-220310' AND numr.response != numq.answer
);
-- similar to Q4, take enrolled students and included questions
-- minus should-be-there tuples with already-there tuples
-- to get unanswered tuples
DROP VIEW IF EXISTS enrolled CASCADE;
CREATE VIEW enrolled AS (
  SELECT sID
  FROM inClass ic JOIN Class c ON ic.cID = c.cID
  WHERE c.grade = 8 AND c.room = 120 AND c.teacher = 'Mr. Higgins'
);

-- Questions in pr1-220310
DROP VIEW IF EXISTS included CASCADE;
CREATE VIEW included AS (
  SELECT DISTINCT qID
  FROM hasQuestion
  WHERE qzID = 'Pr1-220310'
);

DROP VIEW IF EXISTS unanswered CASCADE;
CREATE VIEW unanswered AS (
  (SELECT sID, qID
   FROM enrolled, included
  )
  EXCEPT
  (SELECT sID, qID
   FROM Response
   WHERE qzID = 'Pr1-220310'
  )
);
-- count every case up (unanswered, correct, incorrect)
DROP VIEW IF EXISTS unansweredCount CASCADE;
CREATE VIEW unansweredCount AS (
  SELECT i.qID, COUNT(DISTINCT u.sID) AS unansweredCount
  FROM unanswered u RIGHT JOIN included i ON u.qID = i.qID
  GROUP BY i.qID
);
-- notice that each count should be including all questions
-- so that the final concatenation does not suffer from NULL
-- if one question is unanswered, or correctly/incorrectly answered by all
-- students
DROP VIEW IF EXISTS corrects CASCADE;
CREATE VIEW corrects AS (
  (SELECT * FROM tfqCorrects)
  UNION
  (SELECT * FROM mcqCorrects)
  UNION
  (SELECT * FROM numqCorrects)
);

DROP VIEW IF EXISTS correctCount CASCADE;
CREATE VIEW correctCount AS (
  SELECT i.qID, COUNT(DISTINCT c.sID) AS correctCount
  FROM corrects c RIGHT JOIN included i ON c.qID = i.qID
  GROUP BY i.qID
);

DROP VIEW IF EXISTS incorrects CASCADE;
CREATE VIEW incorrects AS (
  (SELECT * FROM tfqIncorrects)
  UNION
  (SELECT * FROM mcqIncorrects)
  UNION
  (SELECT * FROM numqIncorrects)
);

DROP VIEW IF EXISTS incorrectCount CASCADE;
CREATE VIEW incorrectCount AS (
  SELECT i.qID, COUNT(DISTINCT ic.sID) AS incorrectCount
  FROM incorrects ic RIGHT JOIN included i ON ic.qID = i.qID
  GROUP BY i.qID
);
-- chain everything up to get the final answer
SELECT u.qID, u.unansweredCount, c.correctCount, i.incorrectCount
FROM unansweredCount u JOIN correctCount c ON u.qID = c.qID
     JOIN incorrectCount i ON c.qID = i.qID;

