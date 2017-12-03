-- since there are inter-connected constraints across relations,
-- for instance, if you just insert to class, since each class must have at
-- least one student, you need to have its inclass tuple there before this
-- insertion; if you just insert to inclass, that class must be in class
-- relation as the foreign key constraints must hold.
-- So you will need to insert them simutaneously: with.. as.. transaction
WITH Student_data_insert AS (
  INSERT INTO Student VALUES 
  ('0998801234', 'Lena', 'Headey'),
  ('0010784522', 'Peter', 'Dinklage'),
  ('0997733991', 'Emilia', 'Clarke'),
  ('5555555555', 'Kit', 'Harrington'),
  ('1111111111', 'Sophie', 'Turner'),
  ('2222222222', 'Maisie', 'Williams')
), Class_data_insert AS (
  INSERT INTO Class VALUES
  (1, 8, 'Mr. Higgins', 120),
  (2, 5, 'Miss Nyers', 366)
), inClass_data_insert AS (
  INSERT INTO inClass VALUES
  ('0998801234', 1),
  ('0010784522', 1),
  ('0997733991', 1),
  ('5555555555', 1),
  ('1111111111', 1),
  ('2222222222', 2)
), Quiz_data_insert AS (
  INSERT INTO Quiz VALUES
  ('Pr1-220310', 'Citizenship Test Practise Questions', DATE '2017-10-01', TIME '13:30', TRUE, 1)
), Question_data_insert AS (
  INSERT INTO Question VALUES
  (782, 'What do you promise when you take the oath of citizenship?', NULL, 782, NULL),
  (566, 'The Prime Minister, Justin Trudeau, is Canada''s Head of State.', 566, NULL, NULL),
  (601, 'During the "Quiet Revolution," Quebec experienced rapid change. In what decade did this occur? (Enter the year that began the decade, e.g., 1840.)', NULL, NULL, 601),
  (625, 'What is the Underground Railroad?', NULL, 625, NULL),
  (790, 'During the War of 1812 the Americans burned down the Parliament Buildings in York (now Toronto). What did the British and Canadians do in return?', NULL, 790, NULL)
), tfQuestion_data_insert AS (
  INSERT INTO tfQuestion VALUES
  (566, FALSE)
), mcQuestion_data_insert AS (
  INSERT INTO mcQuestion VALUES
  (782),
  (625),
  (790)
), numQuestion_data_insert AS (
  INSERT INTO numQuestion VALUES
  (601, 1960)
  RETURNING *
), hasQuestion_data_insert AS (
  INSERT INTO hasQuestion VALUES
  ('Pr1-220310', 601, 2),
  ('Pr1-220310', 566, 1),
  ('Pr1-220310', 790, 3),
  ('Pr1-220310', 625, 2)
), Option_data_insert AS (
  INSERT INTO Option VALUES
  (1, true, 'To pledge your loyalty to the Sovereign, Queen Elizabeth II', NULL, 782),
  (2, false, 'To pledge your allegiance to the flag and fulfill the duties of a Canadian', NULL, 782),
  (3, false, 'To pledge your allegiance to the flag and fulfill the duties of a Canadian', 'Think regally.', 782),
  (4, false, 'To pledge your loyalty to Canada from sea to sea', NULL, 782),
  (5, false, 'The first railway to cross Canada', 'The Underground Railroad was generally south to north, not east-west.', 625),
  (6, false, 'The CPR''s secret railway line', 'The Underground Railroad was secret, but it had nothing to do with trains.', 625),
  (7, false, 'The TTC subway system', 'The TTC is relatively recent; the Underground Railroad was in operation over 100 years ago.', 625),
  (8, true, 'A network used by slaves who escaped the United States into Canada', NULL, 625),
  (9, false, 'They attacked American merchant ships', NULL, 790),
  (10, false, 'They expanded their defence system, including Fort York', NULL, 790),
  (11, true, 'They burned down the White House in Washington D.C.', NULL, 790),
  (12, false, 'They captured Niagara Falls', NULL, 790)
), Hint_data_insert AS (
  INSERT INTO Hint VALUES
  (1, 1800, 1900, 'The Quiet Revolution happened during the 20th Century.', 601),
  (2, 2000, 2010, 'The Quiet Revolution happened some time ago.', 601),
  (3, 2020, 3000, 'The Quiet Revolution has already happened!', 601)
), Response_data_insert AS (
  INSERT INTO Response VALUES
  (1, '0998801234', 'Pr1-220310', 601, NULL, NULL, 1),
  (2, '0998801234', 'Pr1-220310', 566, 2, NULL, NULL),
  (3, '0998801234', 'Pr1-220310', 790, NULL, 3, NULL),
  (4, '0998801234', 'Pr1-220310', 625, NULL, 4, NULL),
  (5, '0010784522', 'Pr1-220310', 601, NULL, NULL, 5),
  (6, '0010784522', 'Pr1-220310', 566, 6, NULL, NULL),
  (7, '0010784522', 'Pr1-220310', 790, NULL, 7, NULL),
  (8, '0010784522', 'Pr1-220310', 625, NULL, 8, NULL),
  (9 , '0997733991', 'Pr1-220310', 601, NULL, NULL, 9),
  (10, '0997733991', 'Pr1-220310', 566, 10, NULL, NULL),
  (11, '0997733991', 'Pr1-220310', 790, NULL, 11, NULL),
  (12, '0997733991', 'Pr1-220310', 625, NULL, 12, NULL),
  (14, '5555555555', 'Pr1-220310', 566, 14, NULL, NULL),
  (15, '5555555555', 'Pr1-220310', 790, NULL, 15, NULL)
), tfResponse_data_insert AS (
  INSERT INTO tfResponse VALUES
  (2, False),
  (6, False),
  (10, True),
  (14, False)
), mcResponse_data_insert AS (
  INSERT INTO mcResponse VALUES
  (3, 10),
  (7, 11),
  (11, 11),
  (15, 12),
  (4, 8),
  (8, 8),
  (12, 6)
), numResponse_data_insert AS (
  INSERT INTO numResponse VALUES
  (1, 1950),
  (5, 1960),
  (9, 1960)
)
  SELECT NULL AS "Data insertion success.";
; 
