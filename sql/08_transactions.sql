-- ============================================================================
-- TRANSACTION TEST SCRIPT (Advanced)
-- Purpose: Verify ACID properties, Trigger Logic, and Constraints
-- Updates: Includes Isolation Levels, Savepoints, and Handler Error Trapping
-- ============================================================================
USE ski_resort;

-- Cleanup any previous test artifacts
DROP PROCEDURE IF EXISTS Test_Overbooking_Handler;
DROP PROCEDURE IF EXISTS Test_Atomicity_Rollback;
DROP PROCEDURE IF EXISTS Test_Savepoint_Logic;

SELECT '=== INITIALIZING TEST SUITE ===' AS Status;

-- ============================================================================
-- TEST 1: CONSISTENCY & ERROR HANDLING
-- Feature: Trigger `trg_prevent_overbooking`
-- Feedback Implemented: Replaced INSERT IGNORE with DECLARE ... HANDLER
-- ============================================================================
SELECT '--- TEST 1: Overbooking Protection (with Error Handler) ---' AS Test_Case;

DELIMITER $$

CREATE PROCEDURE Test_Overbooking_Handler()
BEGIN
    DECLARE output_message VARCHAR(255);
    -- 1. Declare a handler for the specific SQLSTATE '45000' (our custom trigger error)
    DECLARE EXIT HANDLER FOR SQLSTATE '45000'
    BEGIN
        SET output_message = '✅ SUCCESS: Overbooking blocked! Expected error caught.';
        SELECT output_message AS Test_Result;
        ROLLBACK; -- Clean up any partial work if needed
    END;

    START TRANSACTION;
        -- Setup: Create a full lesson (Capacity 1, Enrolled 1)
        INSERT INTO Scheduled_Lessons (InstructorID, StartTime, MaxCapacity, CurrentEnrollment, LessonType)
        VALUES (1, NOW() + INTERVAL 5 DAY, 1, 1, 'Private');
        
        SET @lesson_id = LAST_INSERT_ID();

        -- Action: Try to add a 2nd student (Should Trigger Error)
        INSERT INTO Enrollments (CustomerID, LessonID, PaymentStatus)
        VALUES (1, @lesson_id, 'Paid');
        
        -- If we get here, the test FAILED because the error didn't happen
        SELECT '❌ FAILURE: Enrollment succeeded but should have failed!' AS Test_Result;
    COMMIT;
END$$

DELIMITER ;

CALL Test_Overbooking_Handler();


-- ============================================================================
-- TEST 2: AUTOMATION & ISOLATION LEVELS
-- Feature: Trigger `trg_after_enrollment...` & Isolation
-- Feedback Implemented: Explicit SET TRANSACTION ISOLATION LEVEL
-- ============================================================================
SELECT '--- TEST 2: Enrollment Counter & Isolation Levels ---' AS Test_Case;

-- We use SERIALIZABLE to ensure that when we read the count, no one else can insert
-- This prevents "Phantom Reads" during capacity checks.
SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;

START TRANSACTION;

    -- 1. Create a fresh lesson
    INSERT INTO Scheduled_Lessons (InstructorID, StartTime, MaxCapacity, CurrentEnrollment)
    VALUES (1, NOW() + INTERVAL 6 DAY, 10, 0);
    SET @iso_lesson_id = LAST_INSERT_ID();

    -- 2. Verify Initial State
    SELECT CurrentEnrollment AS 'Step 1: Initial Count (Expect 0)' 
    FROM Scheduled_Lessons WHERE LessonID = @iso_lesson_id;

    -- 3. Enroll Student (Trigger should fire)
    INSERT INTO Enrollments (CustomerID, LessonID, PaymentStatus)
    VALUES (2, @iso_lesson_id, 'Paid');

    -- 4. Verify Increment
    SELECT CurrentEnrollment AS 'Step 2: After Insert (Expect 1)' 
    FROM Scheduled_Lessons WHERE LessonID = @iso_lesson_id;

COMMIT;

-- Reset to default for other tests
SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;


-- ============================================================================
-- TEST 3: ATOMICITY (ALL OR NOTHING)
-- Feature: Rollback on Failure
-- Feedback Implemented: Demonstrate full rollback on partial failure
-- ============================================================================
SELECT '--- TEST 3: Atomicity - Full Rollback on Bad Data ---' AS Test_Case;

DELIMITER $$

CREATE PROCEDURE Test_Atomicity_Rollback()
BEGIN
    DECLARE exit_msg VARCHAR(255);
    
    -- Handler: If anything goes wrong, we rollback EVERYTHING
    DECLARE EXIT HANDLER FOR SQLSTATE '45000'
    BEGIN
        ROLLBACK;
        SET exit_msg = '✅ SUCCESS: Transaction Rolled Back due to broken item.';
        SELECT exit_msg AS Test_Result;
    END;

    START TRANSACTION;
        -- 1. Create a Rental Header (This is valid!)
        INSERT INTO Rentals (CustomerID, TotalPrice) VALUES (1, 100.00);
        SET @new_rental_id = LAST_INSERT_ID();

        -- 2. Add Valid Item (Ski) - Assume ID 1 is available
        UPDATE Equipment SET Status = 'Available' WHERE EquipmentID = 1;
        INSERT INTO Rental_Items (RentalID, EquipmentID, UnitPrice) VALUES (@new_rental_id, 1, 50.00);

        -- 3. Add BROKEN Item (Maintenance) - Assume ID 2 is broken
        -- This should fire the trigger, raise error 45000, and hit our Handler
        UPDATE Equipment SET Status = 'Maintenance' WHERE EquipmentID = 2;
        INSERT INTO Rental_Items (RentalID, EquipmentID, UnitPrice) VALUES (@new_rental_id, 2, 50.00);

        -- We should never reach here
        COMMIT;
        SELECT '❌ FAILURE: Broken item was accepted.' AS Test_Result;
END$$

DELIMITER ;

CALL Test_Atomicity_Rollback();

-- Verification: The Rental Header (@new_rental_id) should NOT exist
-- because the error on item 2 should have killed the whole transaction.
SELECT COUNT(*) AS 'Orphaned Rentals (Should be 0)' 
FROM Rentals 
WHERE RentalID = @new_rental_id;


-- ============================================================================
-- TEST 4: SAVEPOINTS (PARTIAL ROLLBACK)
-- Feature: Savepoints
-- Feedback Implemented: Show partial rollback while preserving outer transaction
-- ============================================================================
SELECT '--- TEST 4: Savepoints - Partial Rollback ---' AS Test_Case;

DELIMITER $$

CREATE PROCEDURE Test_Savepoint_Logic()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '45000' 
    BEGIN
        -- Don't exit, just note the error
        SELECT 'ℹ️ Info: Helmet unavailable, rolling back to savepoint...' AS Log;
    END;

    START TRANSACTION;
        -- 1. Create Rental
        INSERT INTO Rentals (CustomerID, TotalPrice) VALUES (3, 200.00);
        SET @sp_rental_id = LAST_INSERT_ID();

        -- 2. Rent Skis (Success)
        UPDATE Equipment SET Status = 'Available' WHERE EquipmentID = 1;
        INSERT INTO Rental_Items (RentalID, EquipmentID, UnitPrice) VALUES (@sp_rental_id, 1, 50.00);

        -- 3. SET SAVEPOINT!
        SAVEPOINT HelmetBooking;

        -- 4. Try to rent broken Helmet (Fail)
        UPDATE Equipment SET Status = 'Maintenance' WHERE EquipmentID = 3;
        
        -- We manually check or let trigger fail. Let's simulate a check here for clarity
        -- or just let the trigger fail. The Handler above catches it.
        -- Attempt insert:
        INSERT INTO Rental_Items (RentalID, EquipmentID, UnitPrice) VALUES (@sp_rental_id, 3, 20.00);
        
        -- 5. Logic: If we are here and the handler fired, we need to rollback to savepoint
        -- (In a real app logic, this decision happens in app code, but here we simulate)
        ROLLBACK TO SAVEPOINT HelmetBooking;

        -- 6. Commit the Skis (but not the helmet)
    COMMIT;
    
    SELECT '✅ Transaction Committed with Skis only.' AS Test_Result;
END$$

DELIMITER ;

CALL Test_Savepoint_Logic();

-- Verify: Rental should exist, have 1 item (Skis), not 2
SELECT RentalID, Count(*) as ItemCount 
FROM Rental_Items 
WHERE RentalID = @sp_rental_id 
GROUP BY RentalID;

SELECT '--- ALL TESTS COMPLETED ---' AS Status;