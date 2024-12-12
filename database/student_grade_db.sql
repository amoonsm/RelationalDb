-- GOAL: Create a table with student ID, student names, a grade percentage, and a letter grade

-- Set up the schema
CREATE DATABASE student_grade;

-- Import tables from CSV files here: https://github.com/amoonsm/RelationalDb/tree/main/database

-- Create a table with the necessary fields
DROP TABLE IF EXISTS student_grade.student_with_letter;
CREATE TABLE student_grade.student_with_letter (
	student_id int,
    student_name varchar(255)
);

-- Insert ids and names of students who did not drop the course
INSERT INTO student_grade.student_with_letter (student_id, student_name)
SELECT id, first_last_name
FROM student_grade.student_record
WHERE enrolled_status = 'Enrolled';

-- Create a table with scores of manually graded assignments (writing assignment). Students are split up by their discussion section
DROP TABLE IF EXISTS student_grade.student_writing_points;
CREATE TABLE student_grade.student_writing_points AS
	SELECT *
    FROM (SELECT *
			FROM student_grade.writing_section_1
            UNION
            SELECT *
            FROM student_grade.writing_section_2) AS writing_total
		;
            
-- Create a table with scores of auto-graded assignments (midterm and final)
DROP TABLE IF EXISTS student_grade.student_scantron_points;
CREATE TABLE student_grade.student_scantron_points AS
	SELECT *
    FROM (SELECT  midterm.first_last_name AS name_on_midterm,
					midterm.student_id AS id_on_midterm,
					midterm.score AS midterm_total,
					final.first_last_name AS name_on_final,
					final.student_id AS id_on_final,
					final.score AS final_total
			FROM student_grade.midterm_score AS midterm
			LEFT JOIN student_grade.final_score AS final
				ON midterm.student_id = final.student_id
			UNION
			SELECT midterm.first_last_name AS name_on_midterm,
					midterm.student_id AS id_on_midterm,
					midterm.score AS midterm_total,
					final.first_last_name AS name_on_final,
					final.student_id AS id_on_final,
					final.score AS final_total
			FROM student_grade.midterm_score AS midterm
			RIGHT JOIN student_grade.final_score AS final
				ON midterm.student_id = final.student_id) AS scantron_total
			;
					
 -- Create a table with scores of midterm, final, and writing. 
 DROP TABLE IF EXISTS student_grade.student_total_percentage;
CREATE TABLE student_grade.student_total_percentage AS
	SELECT *,
    ROUND((midterm_total + final_total + writing_total) / 2) AS grade_percentage #Add a field with grade percentage. Because the maximum total point is 200, divide by 2 to get a percentage
    FROM (SELECT current_student.student_id,
					current_student.student_name,
					IFNULL(autograded.midterm_total,0) AS midterm_total, #Assign a score of zero if student did not take the midterm
                    IFNULL(autograded.final_total,0) AS final_total,   #Assign a score of zero if student did not take the final
                    manual.score AS writing_total
            FROM student_grade.student_with_letter AS current_student
            LEFT JOIN student_grade.student_scantron_points AS autograded
				ON current_student.student_id = autograded.id_on_midterm
					OR current_student.student_id = autograded.id_on_final
			LEFT JOIN student_grade.student_writing_points AS manual
				ON current_student.student_name = manual.first_last_name) AS total_points
;
            
-- Calculate the grade percentage from the total points derived in the previous table
SELECT current_student.student_id,
		current_student.student_name,
        points.grade_percentage,
		CASE
			WHEN points.grade_percentage BETWEEN 90 AND 100 THEN 'A'
            WHEN points.grade_percentage BETWEEN 80 AND 90 THEN 'B'
			WHEN points.grade_percentage BETWEEN 70 AND 80 THEN 'C'
            WHEN points.grade_percentage BETWEEN 60 AND 70 THEN 'D'
            WHEN points.grade_percentage < 60 THEN 'F'
		END AS letter_grade
FROM student_grade.student_with_letter AS current_student
RIGHT JOIN student_grade.student_total_percentage AS points
	ON current_student.student_id = points.student_id
;





