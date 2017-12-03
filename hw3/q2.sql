-- hints for true-false question must be counted as NULL
DROP VIEW IF EXISTS tfqHints CASCADE;
CREATE VIEW tfqHints AS (
  SELECT qID, NULL AS numHints
  FROM Question 
  WHERE tfqID IS NOT NULL
);
-- multiple-choice questions
DROP VIEW IF EXISTS mcqs CASCADE;
CREATE VIEW mcqs AS (
  SELECT *
  FROM Question
  WHERE mcqID IS NOT NULL
);
-- count of hints for m-c questions
DROP VIEW IF EXISTS mcqHints CASCADE;
CREATE VIEW mcqHints AS (
  SELECT qID, COUNT(DISTINCT o.hint) AS numHints
  FROM mcqs q LEFT JOIN Option o ON o.mcqid = q.mcqid 
  GROUP BY q.qID
);
-- numeric questions
DROP VIEW IF EXISTS numqs CASCADE;
CREATE VIEW numqs AS (
  SELECT *
  FROM Question
  WHERE numqID IS NOT NULL
);
-- count for hints for num questions
DROP VIEW IF EXISTS numqHints CASCADE;
CREATE VIEW numqHints AS (
  SELECT qID, COUNT(DISTINCT hID) AS numHints
  FROM numqs q LEFT JOIN Hint h ON q.numqID = h.numqID
  GROUP BY q.qID
);
-- union the answer for diff types of questions, and truncate the text to 
-- make TA's life easier :)
(SELECT t.qID, left(q.text, 50) as text, t.numHints FROM tfqHints t JOIN Question q ON t.qID = q.qID)
UNION 
(SELECT m.qID, left(q.text, 50) as text, m.numHints FROM mcqHints m JOIN Question q ON m.qID = q.qID)
UNION 
(SELECT n.qID, left(q.text, 50) as text, n.numHints FROM numqHints n JOIN Question q ON n.qID = q.qID);

