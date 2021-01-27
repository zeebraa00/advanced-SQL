-- 2016314728  Jeong Jae Heon
-- DB HW1


-- (1)
-- Find which building is most used for courses? You may assume there will be no tie.
select building
from section
group by building
order by count(building) desc limit 0,1;

--> Taylor


-- (2)
-- Find which building is second most used for courses? Again, there will be no tie.
select building
from section
group by building
order by count(building) desc limit 1,1;

--> Packard


-- (3)
-- Show which instructor is advising how many students in each department.
-- You need to show ID, instructor name, department name, and the number of students.
-- Even if an instructor is not advising any student from any department, your query need to show NULL and 0 in the last two columns.
select instructor.ID, instructor.name, student.dept_name, count(advisor.s_ID) as number_of_students
from instructor left outer join advisor on instructor.ID=advisor.i_ID
                left outer join student on advisor.s_ID=student.ID
group by instructor.ID, instructor.name, student.dept_name;

-->
-- +-------+------------+------------+--------------------+
-- | ID    | name       | dept_name  | number_of_students |
-- +-------+------------+------------+--------------------+
-- | 10101 | Srinivasan | Comp. Sci. |                  1 |
-- | 12121 | Wu         | NULL       |                  0 |
-- | 15151 | Mozart     | NULL       |                  0 |
-- | 22222 | Einstein   | Physics    |                  2 |
-- | 32343 | El Said    | NULL       |                  0 |
-- | 33456 | Gold       | NULL       |                  0 |
-- | 45565 | Katz       | Comp. Sci. |                  2 |
-- | 58583 | Califieri  | NULL       |                  0 |
-- | 76543 | Singh      | Finance    |                  1 |
-- | 76766 | Crick      | Biology    |                  1 |
-- | 83821 | Brandt     | NULL       |                  0 |
-- | 98345 | Kim        | Elec. Eng. |                  2 |
-- +-------+------------+------------+--------------------+


-- (4)
-- Find the names of students who took the courses that were offered in Painter building in 2009.
select name
from student
where ID in (
    select ID
    from takes
    where course_id in (select course_id from section where building='Painter' and year=2009));
 
-->
-- +--------+
-- | name   |
-- +--------+
-- | Tanaka |
-- +--------+


-- (5)
-- Find the names of instructors who taught the prerequisite courses of the courses that Williams took in 2009.
-- Note that it does not matter when instructors taught prerequisite courses.
-- Show the name of instructor and the name of prerequisite course.
select instructor.name as instructor_name, course.title as prerequisite_course_name
from instructor, course
where course.course_id in (
    select prereq_id from prereq where course_id in (
        select course_id from course where course_id in (
            select course_id from takes where takes.ID = (
                select ID from student where student.name='Williams') and year=2009)))
    and instructor.ID in (select ID from teaches where course_id=course.course_id);

-->
-- +-----------------+----------------------------+
-- | instructor_name | prerequisite_course_name   |
-- +-----------------+----------------------------+
-- | Srinivasan      | Intro. to Computer Science |
-- | Katz            | Intro. to Computer Science |
-- +-----------------+----------------------------+


-- (6)
-- Compute the average GPA of students in ’Comp. Sci.’ department.
-- If there are 10 students in ’Comp. Sci.’ department, the output table should have 10 rows.
-- Show the student ID, name, and GPA.
-- Please ignore tot_cred column of student table.
-- Please use a stored function to convert letter grades to numbers.
DELIMITER //
create function convert_grade(grade varchar(2)) returns numeric(3,2)
    begin
        declare converted numeric(3,2);
            CASE
                WHEN grade='A+' then set converted = 4.3;
                WHEN grade='A' then set converted = 4.0;
                WHEN grade='A-' then set converted = 3.7;
                WHEN grade='B+' then set converted = 3.3;
                WHEN grade='B' then set converted = 3.0;
                WHEN grade='B-' then set converted = 2.7;
                WHEN grade='C+' then set converted = 2.3;
                WHEN grade='C' then set converted = 2.0;
                WHEN grade='C-' then set converted = 1.7;
                WHEN grade='D+' then set converted = 1.3;
                WHEN grade='D' then set converted = 1.0;
                WHEN grade='D-' then set converted = 0.7;
                ELSE set converted = 0.0;
            END CASE;
        return converted;
    end //
DELIMITER ;

select ID, name, round(sum(credits*convert_grade(grade))/sum(credits),2) as average_gpa
from takes natural join course natural join student 
where ID in (select ID from student where dept_name='Comp. Sci.')
group by ID;

-->
-- +-------+----------+-------------+
-- | ID    | name     | average_gpa |
-- +-------+----------+-------------+
-- | 00128 | Zhang    |        3.87 |
-- | 12345 | Shankar  |        3.43 |
-- | 54321 | Williams |        3.50 |
-- | 76543 | Brown    |        4.00 |
-- +-------+----------+-------------+


-- (7)
-- Create a trigger that rejects a course registration if a student tries to register for a course but its classroom is full. 
-- Hint: check the capacity of classroom table.


DELIMITER //
create trigger reject_registration before insert on takes
for each row
begin
    declare full numeric(4,0);
    declare status numeric(4,0);

    set full = (select capacity 
                    from section natural join classroom
                    where course_id = new.course_id and sec_id = new.sec_id and semester = new.semester);
    set status = (select count(ID)
                    from takes natural join section
                    where course_id = new.course_id and sec_id = new.sec_id and semester=new.semester
                    group by course_id, semester, year, sec_id);

    CASE 
        WHEN status=full then set new.ID = NULL;
    end CASE;
end//
DELIMITER ;


-- (8)
-- Create a trigger that adds a new advising relationship into ’advisor’ table when a new stu- dent is added to ’student’ table.
-- If there are multiple instructors in the student’s department, the most paid instructor (e.g., Brandt in Comp. Sci.) becomes the advisor.

DELIMITER //
create trigger new_advisor after insert on student
for each row
begin
	CASE 
        WHEN new.dept_name is not null then insert advisor(s_ID, i_ID)
            with maximum(dept_name,salary) as (select dept_name, max(salary) from instructor group by dept_name)
            select new.ID, inst.ID
            from instructor as inst natural join maximum
            where inst.salary = maximum.salary and new.dept_name = inst.dept_name;
	end CASE;
end//
DELIMITER ;