-- students enrolled that course
DROP VIEW IF EXISTS enrolled CASCADE;
CREATE VIEW enrolled AS (
  SELECT sID
  FROM inClass ic JOIN Class c ON ic.cID = c.cID
  WHERE c.grade = 8 AND c.room = 120 AND c.teacher = 'Mr. Higgins'
);

-- Questions in quiz pr1-220310
DROP VIEW IF EXISTS included CASCADE;
CREATE VIEW included AS (
  SELECT DISTINCT qID
  FROM hasQuestion
  WHERE qzID = 'Pr1-220310'
);

-- all should-be-there pairs minus all already-there pairs
-- gives me the unanswered pairs (sID qID pair) 
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
-- chain up with question text to get the final answer
SELECT sID, q.qID, left(text, 50) AS text
FROM unanswered u JOIN Question q
     ON u.qID = q.qID;
