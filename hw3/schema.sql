/*********************************************************
1. All constraints can be enforced, the question is whether they can be enforced by relation itself or by triggers.
2. I enforced all of them, as they all look reasonable to me. Anomaly would emerge if I did not enforce them. And I use
   in-relation 'NOT NULL' or 'CHECK' to enforce them whenever possible. Otherwise I use a trigger when it can be challenged (update/insert/delete). Details below.

• Each student has a unique student ID, which is a 10-digit number, and a first and last name, and is in zero
or more classes.
- Enforced in Student relation itself: attributes NOT NULL. 10-digit is enforced by SIMILAR TO [0-9]{10} regex to allow 
  preceding zeros. Student's class falls in inClass relation, where I do not make any assumption on the number of enrolled class.

• A class has a room, and one or more students who are in that class.
- one-class-one-room enforced in Class. one-or-more students involves 2 relations: class and inclass,
so it cannot be enforced by a simple CHECK, I use a trigger instead.

• There can be multiple classes for the same grade.
- I put no constraint on the grade side. A class can have any one grade.

• A room can have two classes in it (for example, if we have a grade 2-3 split class), but never more than one
teacher.
- Enforced by a trigger because it involves multiple tuples of Class relation. I allow up to 2 classes with the same teacher sharing a room.

• Our question bank includes three types of question: true-false, multiple choice, and numeric. Numeric questions
can only have integer answers.
- integer answers are enforced by its attribute type. the question type involves a classicla subtype design:
  the super class has a unique ID, and 3 types (we have 3 subtypes here) of subIDs. subID is not NULL if this question
  falls into that subtype, and it can only have exactly one NOT NULL subtype ID. the subtypeID equals the superclass ID.
  For each subtype there is a individual entity set, its subtype ID references superclass ID.
  Because the type ID only involves in-row attributes, it can be enforced by a simple CHECK.
  This subtype design creates some (but not much) redundancy on NULL attributes but makes the implementation very simple and intuitive. 
  So I made this trade off.

• Questions are identified by their unique question ID.
- qID is the primary key.

• All questions have question text and a single correct answer.
- text is a NOT NULL attribute. based on the subtype of the question, single-answer constraint is enforced differently.
  t-f question has its own attribute answer.
  m-c question has only one option that is correct. this is enforced by a trigger because it involves multiple tuples.
  num question has its own attribute answer.

• A multiple choice question has answer options (e.g., “Saskatoon”), and there are always at least two. The correct answer must be one of the options.
- mc-question to option is one-to-many, so I put a qID attribut on Option side to indicate the question it belongs to. A trigger will check there must be exactly one correct for a question. 
  In the same trigger about mulitple-choice, it also checks there must be one with correct attribute as true.

• An incorrect answer to a multiple-choice or numeric question may have one hint associated with it. Correct
answers do not have hints.
- An option has attribute hint that can be null. But a CHECK guarantees that if the correct attribute is true, its hint must be null.
  Thanks to the design for m-c question hints as an attribute, the hints here can be dedicated to num questions. It has lowerbound and upper bound attributes,
  and a trigger will check the answer for the question it corresponds to, so that the correct answer does not have a hint which includes its numeric value.

• A quiz has a unique ID, a title, a due date and time, one or more questions from the question bank, and a class to which it is assigned.
- Attributes for them NOT NULL. many-to-many involves a hasQuestion relation, where a trigger checks each quiz must have at least one question (one tuple in hasQuestion).
  Class is an NOT NULL attribute of the quiz.

• The instructor can choose whether or not students should be shown a hint (if there is one in the test bank)
when they give a wrong answer to a question. This is a single flag for the whole quiz rather than one per
question.
- There is a showhint attribute of each quiz entity. 

• Each question on a quiz has a weight: an integer that indicates how much a correct answer contributes to the
student’s total score on the quiz. The same question could occur in multiple different quizzes with different
weights.
- hasQuestion has attribute weight, which allows a question to have different weights across quizes.
  Its primary key is quiz's ID and question's ID, which allows a question to be in many quizes.

• The database records student responses to the quiz.
- A response entity set records the responses. Like questions, it is has a subtype design. 
  Here I made a trade-off on redundancy. The response can be uniquely indexed by question ID, student ID and quiz ID (which, who and where).
  But this primary key will make the subtype design much worse since it has multiple attributes. I instead use a single integer ID for response,
  and make that triplet unique. This keeps subtype design simple and avoids worsening redundancy. (there will be much more NULL redundancy if I make a 
  triplet primary key on its subtypes)
  An additional trigger guarantees the type checks. e.g. if the response is to a num question, its qID also corresponds to a num question. 

• Only a student in the class that was assigned a quiz can answer questions on that quiz
- a trigger checks the responses's sID qzID pair, which must appear in inClass relation.
  also, a trigger checks the qID qzID pair must be in hasQuestion relation, so that a question answered must be in that quiz (not required in the spec, but I think it is otherwise anomaly).

• A student may not have answered all the questions. It’s even possible that they answered none
- I do not assume anything on sID, qID pair in response relation. A student may answer or not answer a question.
  But because of the uniqueness of sID, qID, qzID pair, the student's answer of a question in a quiz is unique.

In my design, the redundancy mostly comes from NULL attributes in subtype design. This is well justified above.
It can also come from intermediate relations, which is minimized by this design:
For one-to-one/one-to-many correspondence, I avoid the usage of an intermediate relation and use attributes within.
I use intermediate relation on many-to-many correspondence only. Whenever the information to check the constraint is visible within a row, I use a CHECK.
Only when it involves cross-row/cross-table information would I use a trigger.
And the trigger is only activated when the constraint can be challenged. e.g. I do not trigger on the 2-class-1-room constraint on delete of Class, since it cannot challenge the constraint. 

since there are inter-connected constraints across relations,
for instance, if you just insert to class, since each class must have at
least one student, you need to have its inclass tuple there before this
insertion; if you just insert to inclass, that class must be in class
relation as the foreign key constraints must hold.
So you will need to insert them simutaneously.
I choose to use with.. as.. transaction for data insertion.
**********************************************************/

drop schema if exists quizschema cascade;
create schema quizschema;
set search_path to quizschema;

-- Student and class part
CREATE TABLE Student (
    sID VARCHAR(10) primary key,
    firstname VARCHAR(50) NOT NULL,
    lastname VARCHAR(50) NOT NULL,
    -- 10-digit sID
    CHECK (
      sID SIMILAR TO '[0-9]{10}' 
    )
);


CREATE TABLE Class (
    cID INT primary key,
    grade INT NOT NULL,
    teacher VARCHAR(100) NOT NULL,
    -- one class must correpond to one room 
    room INT NOT NULL
);

-- a room may have 0/1/2 class(s), and when there is 2, they must share a teacher
CREATE OR REPLACE FUNCTION valid_classroom() 
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT TRUE
             FROM Class C1 JOIN Class C2 ON C1.cID != C2.cID AND C1.room = C2.room AND C1.teacher != C2.teacher
            ) THEN
    RAISE EXCEPTION 'Classes sharing one room must share one teacher.';
  ELSIF EXISTS (SELECT TRUE
                FROM (SELECT room, COUNT(DISTINCT cID) as classCount
                      FROM Class
                      GROUP BY room
                     ) classroom
                WHERE classroom.classCount > 2
               ) THEN
    RAISE EXCEPTION 'At most 2 classes can share one room.';
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- enforce the constraint with a trigger
CREATE TRIGGER valid_classroom
AFTER INSERT OR UPDATE ON Class
  FOR EACH ROW EXECUTE PROCEDURE valid_classroom();

CREATE TABLE inClass (
    -- many-student-to-many-class
    sID VARCHAR(10) references Student(sID) ON UPDATE CASCADE ON DELETE CASCADE,
    cID INT references Class(cID) ON UPDATE CASCADE ON DELETE CASCADE,
    primary key(sID, cID)
);
-- a student can be in 0 class
-- but a class has at least one student
CREATE OR REPLACE FUNCTION valid_class()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT TRUE
             FROM ((SELECT cID FROM Class) EXCEPT (SELECT cID FROM inClass)) AS C
              ) THEN
      RAISE EXCEPTION 'Each class must have at least one student';
  END IF;  
  RETURN NULL;  
END;
$$ LANGUAGE plpgsql;

-- enforce this constraint with a trigger
CREATE TRIGGER valid_class_on_class
AFTER INSERT OR UPDATE ON Class
  FOR EACH ROW EXECUTE PROCEDURE valid_class();
-- the constraint also relates inclass relation
CREATE TRIGGER valid_class_on_inclass
AFTER DELETE OR UPDATE ON inClass
  FOR EACH ROW EXECUTE PROCEDURE valid_class();

-- Question and quiz part
CREATE TABLE Question (
    qID INT primary key,
    text TEXT NOT NULL,
    tfqID INT,
    mcqID INT,
    numqID INT,
    -- subtype question ID must be not null for exactly one of them
    CHECK (
        ( 
            (tfqID IS NOT NULL AND tfqID = qID)
            AND (mcqID IS NULL)
            AND (numqID IS NULL)
        )
        OR
        (
            (mcqID IS NOT NULL AND mcqID = qID)
            AND (tfqID IS NULL)
            AND (numqID IS NULL)
        )
        OR
        (
            (numqID IS NOT NULL AND numqID = qID)
            AND (tfqID IS NULL)
            AND (mcqID IS NULL)
        )
    )   
);

CREATE TABLE tfQuestion (
   tfqID INT references Question(qID) ON UPDATE CASCADE ON DELETE CASCADE,
   answer BOOL NOT NULL,
   primary key(tfqID)
);

CREATE TABLE mcQuestion (
    mcqID INT references Question(qID) ON UPDATE CASCADE ON DELETE CASCADE,
    primary key(mcqID)
);

CREATE TABLE numQuestion (
    numqID INT references Question(qID) ON UPDATE CASCADE ON DELETE CASCADE,
    answer INT NOT NULL,
    primary key(numqID)
);
-- mutual foreign key constraints, so that question set is at equal size of all
-- subtyped question sets combined
ALTER TABLE Question ADD CONSTRAINT tfq foreign key(tfqID) references tfQuestion(tfqID) ON UPDATE CASCADE ON DELETE CASCADE; 
ALTER TABLE Question ADD CONSTRAINT mcq foreign key(mcqID) references mcQuestion(mcqID)ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE Question ADD CONSTRAINT numq foreign key(numqID) references numQuestion(numqID) ON UPDATE CASCADE ON DELETE CASCADE;

CREATE TABLE Option (
    oID INT primary key,
    -- I assume one option can only correpond to one question, so it must be
    -- correct or incorrect, not 'maybe'
    -- this is because if an option correspond to multiple questions, it may
    -- cause anomaly when updated (you may not want to update the option for all
    -- questions. and you still could do so in this case where options are
    -- one-on-one to the question)
    correct BOOL NOT NULL,

    text TEXT NOT NULL,
    hint TEXT,
    mcqID INT references mcQuestion(mcqID) ON UPDATE CASCADE ON DELETE CASCADE,
    -- correct answer cannot have hint
    CHECK (
      mcqID IS NOT NULL AND
      ((correct AND hint IS NULL)
      OR
      (NOT correct))
    )
);

-- enforce >=2 options, and each question has only 1 correct answer
CREATE OR REPLACE FUNCTION multiple_choice()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT TRUE
             FROM (SELECT mcqID, COUNT(DISTINCT oID) AS optionCount
                   FROM Option
                   GROUP BY mcqID
                  ) AS mc 
             WHERE mc.optionCount < 2
            ) THEN
    RAISE EXCEPTION 'Each multiple-choice problem must multiple choices.';
  ELSIF EXISTS (SELECT TRUE
                FROM ((SELECT mcqID 
                       FROM mcQuestion 
                      ) EXCEPT 
                      (SELECT mcqID
                       FROM Option 
                     )) AS leftover
               )    
            THEN
    RAISE EXCEPTION 'Each multiple-choice problem must have some choice.';
  ELSIF EXISTS (SELECT TRUE
             FROM (SELECT o1.mcqID
                   FROM Option o1 JOIN Option o2 ON o1.correct AND o2.correct AND o1.mcqID = o2.mcqID AND o1.oid != o2.oid 
                  ) AS mc 
            ) THEN
    RAISE EXCEPTION 'Each multiple-choice problem must have exactly one correct answer.';
  END IF;
  RETURN NULL;
END
$$ LANGUAGE plpgsql;
-- enforce this constraint with a trigger
CREATE TRIGGER multiple_choice_on_option
AFTER INSERT OR UPDATE OR DELETE ON Option
FOR EACH ROW
  EXECUTE PROCEDURE multiple_choice();
-- this constraint (each question must have >=2 options) also relates mcQuesion
CREATE TRIGGER multiple_choice_on_mcQuestion
AFTER INSERT OR UPDATE ON mcQuestion
FOR EACH ROW
  EXECUTE PROCEDURE multiple_choice();

CREATE TABLE Hint (
    -- multiple-choice hints are included inside options
    -- here the hint is for numeric questions
    hid INT primary key,
    lowerbound INT NOT NULL,
    upperbound INT NOT NULL,
    text TEXT NOT NULL,
    numqID INT references numQuestion(numqID) ON UPDATE CASCADE ON DELETE CASCADE,
    -- each hint must follow exactly one question, the trade-off follows the
    -- same logic for 'correct' attribute in Option
    CHECK (
      numqID IS NOT NULL
      AND (lowerbound <= upperbound)
    )
);

-- enforce no hint for correct answer
CREATE OR REPLACE FUNCTION hint_only_for_incorrect()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT TRUE
             FROM Hint h JOIN numQuestion n ON h.numqID = n.numqID
             WHERE h.lowerbound <= n.answer AND h.upperbound > n.answer
            ) THEN
    RAISE EXCEPTION 'There should be no hint for correct answer for a numerical question.';
  END IF;
  RETURN NULL;
END
$$ LANGUAGE plpgsql;
-- here I use a trigger to enforce that, unlike in multiple-choice questions
-- this is because here the constraint involves attributes from both Hint and
-- numQuestion, which cannot be obtained by a simple CHECK
CREATE TRIGGER hint_only_for_incorrect_on_hint
AFTER INSERT OR UPDATE ON Hint
FOR EACH ROW
  EXECUTE PROCEDURE hint_only_for_incorrect();

CREATE TRIGGER hint_only_for_incorrect_on_numquestion
AFTER UPDATE ON numQuestion --WHEN (OLD.answer IS DISTINCT FROM NEW.answer)
FOR EACH ROW 
  EXECUTE PROCEDURE hint_only_for_incorrect();

CREATE TABLE Quiz (
    qzID TEXT primary key,
    title TEXT NOT NULL,
    due_date DATE NOT NULL,
    due_time TIME NOT NULL,
    show_hint BOOL NOT NULL,
    -- a quiz must follow a class
    cID INT references Class(cID) NOT NULL 
);

CREATE TABLE hasQuestion (
    -- quiz-question is many-to-many
    qzID TEXT references Quiz(qzID) ON UPDATE CASCADE ON DELETE CASCADE,
    qID INT references Question(qID) ON UPDATE CASCADE ON DELETE CASCADE,
    -- using a intermediate relation gives me the flexibility to assign
    -- a different weight to a question across quizes
    weight INT NOT NULL,
    primary key(qzID, qID)
);

-- a quiz must have at least 1 question
CREATE FUNCTION no_empty_quiz()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT TRUE 
             FROM ((SELECT qzID FROM Quiz) EXCEPT (SELECT qzID FROM hasQuestion)) AS qz
            ) THEN
    RAISE EXCEPTION 'A quiz must have at least 1 question.';
  END IF;
  RETURN NULL;
END
$$ LANGUAGE plpgsql;
-- insert/update on quiz may challenge this constraint, must trigger
CREATE TRIGGER no_empty_quiz_on_quiz
AFTER INSERT OR UPDATE ON Quiz
FOR EACH ROW
  EXECUTE PROCEDURE no_empty_quiz();
-- delete/update on hasquestion may challenge this constratin, must trigger
CREATE TRIGGER no_empty_quiz_on_hasQuestion
AFTER DELETE OR UPDATE ON hasQuestion
FOR EACH ROW
  EXECUTE PROCEDURE no_empty_quiz();

-- student-response mix part
CREATE TABLE Response (
    rID INT primary key,
    sID VARCHAR(10) references Student(sID) ON UPDATE CASCADE ON DELETE CASCADE,
    qzID TEXT references Quiz(qzID) ON UPDATE CASCADE ON DELETE CASCADE,
    qID INT references Question(qID)  ON UPDATE CASCADE ON DELETE CASCADE,
    -- actually, sID-qzID-qID triplet can already make a primary key
    -- but that would make subtype implementation very complicated
    -- so I choose to use another single-int primary key
    unique(sID, qzID, qID),
    tfrID INT,
    mcrID INT,
    numrID INT
    -- subtype constraints, just like question
    CHECK (
        (sID IS NOT NULL AND qzID IS NOT NULL AND qID IS NOT NULL)
        AND
        ((
            (tfrID IS NOT NULL AND tfrID = rID)
            AND (mcrID IS NULL)
            AND (numrID IS NULL)
        )
        OR
        (
            (mcrID IS NOT NULL AND mcrID = rID)
            AND (tfrID IS NULL)
            AND (numrID IS NULL)
            
        )
        OR
        (
            (numrID IS NOT NULL AND numrID = rID)
            AND (tfrID IS NULL)
            AND (mcrID IS NULL)
        
        ))
    )
);

-- force response's qID corresponds to its type of response 
-- (e.g. if qID is a numqID, then rID must be a numrID)
CREATE FUNCTION response_typecheck()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT TRUE
             FROM (SELECT r.qID 
                   FROM Response r JOIN mcQuestion mc ON r.qID = mc.mcqID
                   WHERE r.tfrID IS NOT NULL 
                  ) tf2mc
            ) THEN
    RAISE EXCEPTION 'Respond to true-false question qID corresponds to multiple-choice.';
  ELSIF EXISTS (SELECT TRUE
             FROM (SELECT r.qID 
                   FROM Response r JOIN numQuestion num ON r.qID = num.numqID
                   WHERE r.tfrID IS NOT NULL
                  ) tf2num
            ) THEN
    RAISE EXCEPTION 'Respond to true-false question qID corresponds to numeric.';
  ELSIF EXISTS (SELECT TRUE
             FROM (SELECT r.qID 
                   FROM Response r JOIN tfQuestion tf ON r.qID = tf.tfqID
                   WHERE r.mcrID IS NOT NULL
                  ) mc2tf
            ) THEN
    RAISE EXCEPTION 'Respond to multiple-choice question qID corresponds to true-false.';
  ELSIF EXISTS (SELECT TRUE
             FROM (SELECT r.qID 
                   FROM Response r JOIN numQuestion num ON r.qID = num.numqID
                   WHERE r.mcrID IS NOT NULL
                  ) mc2num
            ) THEN
    RAISE EXCEPTION 'Respond to multiple-choice question qID corresponds to numeric.';
  ELSIF EXISTS (SELECT TRUE
             FROM (SELECT r.qID 
                   FROM Response r JOIN tfQuestion tf ON r.qID = tf.tfqID
                   WHERE r.numrID IS NOT NULL
                  ) num2tf
            ) THEN
    RAISE EXCEPTION 'Respond to numeric question qID corresponds to true-false.';
  ELSIF EXISTS (SELECT TRUE
             FROM (SELECT r.qID 
                   FROM Response r JOIN mcQuestion mc ON r.qID = mc.mcqID
                   WHERE r.numrID IS NOT NULL
                  ) num2mc
            ) THEN
    RAISE EXCEPTION 'Respond to numeric question qID corresponds to multiple-choice.';
  END IF;
  RETURN NULL;  
END
$$ LANGUAGE plpgsql;
-- insert/update on response may challenge the constraint
CREATE TRIGGER response_typecheck_on_response
AFTER INSERT OR UPDATE ON Response
FOR EACH ROW
  EXECUTE PROCEDURE response_typecheck();
-- update on different question set may challenge this constraint
CREATE TRIGGER response_typecheck_on_tfquestion
AFTER UPDATE ON tfQuestion
FOR EACH ROW
  EXECUTE PROCEDURE response_typecheck();

CREATE TRIGGER response_typecheck_on_mcquestion
AFTER UPDATE ON mcQuestion
FOR EACH ROW
  EXECUTE PROCEDURE response_typecheck();

CREATE TRIGGER response_typecheck_on_numquestion
AFTER UPDATE ON numQuestion
FOR EACH ROW
  EXECUTE PROCEDURE response_typecheck();

-- only student in that class can take that quiz
CREATE FUNCTION response_inclass()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT TRUE
             FROM ((SELECT r.sID, q.cID
                    FROM Response r JOIN Quiz q ON r.qzID = q.qzID
                   )
                   EXCEPT
                   (SELECT sID, cID
                    FROM inClass 
                   )
                  ) unenrolled
            ) THEN 
    RAISE EXCEPTION 'Only a student enrolled in class can respond to the quiz questions.';
  END IF;
  RETURN NULL;
END
$$ LANGUAGE plpgsql;

-- the update on quiz can challenge that constraint
CREATE TRIGGER response_inclass_on_quiz
AFTER UPDATE ON Quiz
FOR EACH ROW 
  EXECUTE PROCEDURE response_inclass();
-- similar for response, inclass relation
CREATE TRIGGER response_inclass_on_response
AFTER UPDATE OR INSERT ON Response
FOR EACH ROW
  EXECUTE PROCEDURE response_inclass();

CREATE TRIGGER response_inclass_on_inclass
AFTER UPDATE OR DELETE ON inClass
FOR EACH ROW
  EXECUTE PROCEDURE response_inclass();

-- only question in that quiz can be answered
CREATE FUNCTION response_inquiz()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (SELECT TRUE
             FROM ((SELECT qID, qzID
                    FROM Response
                   ) EXCEPT 
                   (SELECT qID, qzID
                    FROM hasQuestion
                   )) leftover 
            ) THEN
    RAISE EXCEPTION 'Only a question in that quiz can be answered.';
  END IF;
  RETURN NULL;  
END
$$ LANGUAGE plpgsql;

-- enforce it
CREATE TRIGGER response_inquiz_on_response
AFTER INSERT OR UPDATE ON Response
FOR EACH ROW
  EXECUTE PROCEDURE response_inquiz();

CREATE TRIGGER response_inquiz_on_hasquestion
AFTER DELETE OR UPDATE ON hasQuestion
FOR EACH ROW
  EXECUTE PROCEDURE response_inquiz();

CREATE TABLE tfResponse (
    tfrID INT references Response(rID) ON UPDATE CASCADE ON DELETE CASCADE,
    response BOOL NOT NULL,
    primary key(tfrID)
);

CREATE TABLE mcResponse (
    mcrID INT references Response(rID) ON UPDATE CASCADE ON DELETE CASCADE,
    response INT NOT NULL,
    primary key(mcrID)
);

CREATE TABLE numResponse(
    numrID INT references Response(rID) ON UPDATE CASCADE ON DELETE CASCADE,
    response INT NOT NULL,
    primary key(numrID)
);
-- mutual-reference constraint, as subtypes set combined must equal superclass set
ALTER TABLE Response ADD CONSTRAINT tfr foreign key(tfrID) references tfResponse(tfrID) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE Response ADD CONSTRAINT mcr foreign key(mcrID) references mcResponse(mcrID) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE Response ADD CONSTRAINT numr foreign key(numrID) references numResponse(numrID) ON UPDATE CASCADE ON DELETE CASCADE;


