					######''''''	Final Project: Advanced SQL Techniques	''''''######

			# Exercise 1: Using Joins 
            
# Question 1 : Write and execute a SQL query to list the school names, community names and average attendance
# for communities with a hardship index of 98.

SELECT socio.HARDSHIP_INDEX ,P_SL.NAME_OF_SCHOOL , P_SL.COMMUNITY_AREA_NAME, P_SL.AVERAGE_STUDENT_ATTENDANCE 
FROM Chicago_public_schools AS P_SL
LEFT JOIN 
chicago_socioeconomic_data AS socio 
ON P_SL.COMMUNITY_AREA_NAME = socio.COMMUNITY_AREA_NAME 
WHERE socio.HARDSHIP_INDEX = 98;

# Question 2: Write and execute a SQL query to list all crimes that took place at a school.
# Include case number, crime type and community name.
SELECT ch_crime.CASE_NUMBER, ch_crime.PRIMARY_TYPE,socio.COMMUNITY_AREA_NAME,ch_crime.LOCATION_DESCRIPTION 
FROM chicago_crime AS ch_crime
LEFT JOIN 
chicago_socioeconomic_data AS socio
ON ch_crime.COMMUNITY_AREA_NUMBER = socio.COMMUNITY_AREA_NUMBER
WHERE ch_crime.LOCATION_DESCRIPTION LIKE '%SCHOOL%'
ORDER BY 2,3;

			# Exercise 2: Creating a View
  # Q1: For privacy reasons, you have been asked to create a view that enables users to select just the school name and the icon fields
  # from the CHICAGO_PUBLIC_SCHOOLS table. By providing a view, you can ensure that users cannot see the actual scores given to a school,
  # just the icon associated with their score.You should define new names for the view columns to obscure the use of scores and icons
  # in the original table.
  
CREATE VIEW Chicago_p_schools_v (
  School_Name,Safety_Rating,
  Family_Rating,Environment_Rating,
  Instruction_Rating,Leaders_Rating,
  Teachers_Rating ) AS 
SELECT NAME_OF_SCHOOL,Safety_Icon,
Family_Involvement_Icon,Environment_Icon,	
Instruction_Icon,Leaders_Icon,	
Teachers_Icon FROM chicago_public_schools;

SELECT School_Name,Leaders_Rating FROM Chicago_p_schools_v; 
			
            # Exercise 3: Creating a Stored Procedure
# The icon fields are calculated based on the value in the corresponding score field. You need to make sure that when a
# score field is updated,the icon field is updated too. To do this, you will write a stored procedure that receives the
# school id and a leaders score as input parameters, calculates the icon setting and updates the fields appropriately.

# Inside your stored procedure, write a SQL statement to update 
# the Leaders_Score field in the CHICAGO_PUBLIC_SCHOOLS table for the school 
# identified by in_School_ID to the value in the in_Leader_Score parameter.

DELIMITER $$
CREATE PROCEDURE UPDATE_LEADERS_SCORE(IN in_School_ID INT , IN in_Leader_Score INT )
BEGIN
UPDATE CHICAGO_PUBLIC_SCHOOLS
SET Leaders_Score = in_Leader_Score
WHERE School_ID = in_School_ID;
END $$
DELIMITER ;

CALL UPDATE_LEADERS_SCORE(610185,85);
SELECT School_ID,Leaders_Score FROM ibm.chicago_public_schools WHERE School_ID = 610185 ;
#leaders_score was nda before calling the procedure for school_ID that equals 610185.


# Question 3
# Inside your stored procedure, write a SQL IF statement to update the Leaders_Icon field in 
# the CHICAGO_PUBLIC_SCHOOLS table for the school identified by in_School_ID using 
# the following information:

# Score lower limit	Score upper limit	Icon
# 80	99	Very strong
# 60	79	Strong
# 40	59	Average
# 20	39	Weak
# 0	19	Very weak

DELIMITER $$
CREATE PROCEDURE UPDATE_Leaders_Icon(IN in_School_ID INT , IN in_Leader_Score INT )
BEGIN

IF in_Leader_Score >= 0 AND in_Leader_Score <= 19 THEN
UPDATE chicago_public_schools
SET Leaders_Icon = "Very weak"
WHERE School_ID = in_School_ID ;

ELSEIF  in_Leader_Score <= 39 THEN
UPDATE chicago_public_schools
SET Leaders_Icon = "Weak"
WHERE School_ID = in_School_ID ;

ELSEIF in_Leader_Score <= 59 THEN
UPDATE chicago_public_schools
SET Leaders_Icon = "Average"
WHERE School_ID = in_School_ID ;

ELSEIF in_Leader_Score <= 79 THEN
UPDATE chicago_public_schools
SET Leaders_Icon = "Strong"
WHERE School_ID = in_School_ID ;

ELSEIF in_Leader_Score <= 99 THEN
UPDATE chicago_public_schools
SET Leaders_Icon = "Very weak"
WHERE School_ID = in_School_ID ;
END IF;
END $$
DELIMITER ;

# Exercise 4: Using Transactions
# You realise that if someone calls your code with a score outside of the allowed range (0-99), 
# then the score will be updated with the invalid data and the icon will remain at its previous value. 
# There are various ways to avoid this problem, one of which is using a transaction.

# Question 1 Update your stored procedure definition. Add a generic ELSE clause to the IF statement that rolls back the current work
# if the score did not fit any of the preceding categories.

#Question 2 Update your stored procedure definition again. Add a statement to commit the current unit of work at the end of the procedure.

DELIMITER $$
CREATE PROCEDURE UPDATE_Leaders_Icon(IN in_School_ID INT , IN in_Leader_Score INT )
BEGIN
  
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       ROLLBACK;
       RESIGNAL;
   END; 
   
   IF in_Leader_Score >= 0 AND in_Leader_Score <= 19 THEN
      UPDATE chicago_public_schools
      SET Leaders_Icon = "Very weak"
      WHERE School_ID = in_School_ID ;
      
   ELSEIF  in_Leader_Score <= 39 THEN
      UPDATE chicago_public_schools
      SET Leaders_Icon = "Weak"
      WHERE School_ID = in_School_ID ;
      
   ELSEIF in_Leader_Score <= 59 THEN
      UPDATE chicago_public_schools
      SET Leaders_Icon = "Average"
      WHERE School_ID = in_School_ID ;
      
   ELSEIF in_Leader_Score <= 79 THEN
      UPDATE chicago_public_schools
      SET Leaders_Icon = "Strong"
      WHERE School_ID = in_School_ID ;
      
   ELSEIF in_Leader_Score < 100 THEN
      UPDATE chicago_public_schools
      SET Leaders_Icon = "Very strong"
      WHERE School_ID = in_School_ID ;
      
   ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid value for in_Leader_Score. Value must be between 0 and 99.';
   END IF;
 COMMIT; 
END $$
DELIMITER ;







