# Ski Resort System

**COMP 345 Database Management Systems - Final Project Reference Implementation**

---

## Table of Contents

* [Ski Resort System](https://www.google.com/search?q=%23ski-resort-system)
* [Table of Contents](https://www.google.com/search?q=%23table-of-contents)
* [Overview](https://www.google.com/search?q=%23overview)
* [System Requirements](https://www.google.com/search?q=%23system-requirements)
* [Quick Start](https://www.google.com/search?q=%23quick-start)
* [Testing & Validation](https://www.google.com/search?q=%23testing--validation-08_transactionssql)
* [How to Run the Tests](https://www.google.com/search?q=%231-how-to-run-the-tests)
* [Test Coverage & Expected Results](https://www.google.com/search?q=%232-test-coverage--expected-results)
* [Sample Output](https://www.google.com/search?q=%233-sample-output)
* [ACID Compliance Rationale](https://www.google.com/search?q=%234-acid-compliance-rationale)





---

## Overview

This project implements a ski resort management system that handles:

* **Ski Pass Management**: Issuing and tracking ski passes for visitors.
* **Lift Operations**: Managing ski lift usage and maintenance.
* **Resort Facilities**: Overseeing various resort amenities and services.
* **User Management**: Handling user accounts and permissions.
* **Reporting**: Generating reports on resort usage and performance.
* **Database Integration**: Storing and retrieving data using a relational database.

---

## System Requirements

### Required Software

* **MySQL**: Version 8.0 or higher
* **Python 3.8+**: For running scripts
* **Git**: For version control

## Quick Start

After cloning the repository, follow these steps to set up the system:

```bash
# 1. Setup Python Virtual Environment
python3 -m venv env

# 2. Activate Virtual Environment
# On MacOS/Linux
source env/bin/activate 
# On Windows
.\env\Scripts\activate.bat

# 3. Install Required Python Packages
pip install -r requirements.txt

# 4. Setup MySQL Credentials
export MYSQL_USER=root
export MYSQL_PASSWORD=your_password

# 5. Run the setup script
python3 scripts/load.py

# 6. Verify installation
mysql -u $MYSQL_USER -p$MYSQL_PASSWORD -e "SHOW TABLES IN ski_resort;"

```

### Expected Output

After successful setup, you should see:

```text
✓ MySQL connection successful
✓ Database dropped (if it existed) - starting fresh
✓ Schema creation (tables, constraints) completed
✓ Sample data insertion completed
✓ Database objects created: Tables: 16, Views: 0, Procedures: 0, Functions: 0, Triggers: 0

Table                           Row Count
------------------------------------------
Customers                           50
Pass_Types                          10
Instructors                         12
Trails                              15
Lifts                               12
Lift_Access                         26
Equipment                           41
Lift_Tickets                        40
Scheduled_Lessons                   15
Rentals                             20
Enrollments                         60
Rental_Items                        77
Maintenance_Staff                   15
Lift_Maintenance_Logs               12
Equipment_Maintenance_Logs          15
Trail_Maintenance_Logs              15

```

---

## 🧪 Testing & Validation (`08_transactions.sql`)

To ensure data integrity and reliability, we have implemented an advanced transaction test suite using Stored Procedures. This script verifies **ACID properties**, **Isolation Levels**, and **Error Handling Patterns**.

### **1. How to Run the Tests**

Run the transaction tests directly using the MySQL command line tool.

```bash
# Run from the project root directory
mysql -u root -p ski_resort < sql/08_transactions.sql

```

*(If on macOS/Linux and `mysql` is not in your path, use `/usr/local/mysql/bin/mysql`)*

### **2. Test Coverage & Expected Results**

The script executes 4 advanced test scenarios involving Stored Procedures and Handlers.

| Test Case | Feature Tested | Concept | Description | Expected Outcome |
| --- | --- | --- | --- | --- |
| **Test 1** | `trg_prevent_overbooking` | **Consistency** | Uses `DECLARE ... HANDLER` to catch the error when adding an 11th student to a 10-person class. | **PASS** (Prints "✅ SUCCESS: Overbooking blocked!") |
| **Test 2** | `SERIALIZABLE` Isolation | **Isolation** | Sets isolation level to `SERIALIZABLE` to prevent phantom reads during capacity checks. | **PASS** (Enrollment counter increments correctly) |
| **Test 3** | Full Rollback | **Atomicity** | Attempts a rental with one valid item and one broken item. The error handler performs a full `ROLLBACK`. | **PASS** (Prints "✅ SUCCESS: Transaction Rolled Back") |
| **Test 4** | Savepoints | **Savepoints** | Uses a `SAVEPOINT` to partially rollback a failed helmet rental while keeping the successful ski rental. | **PASS** (Transaction commits with Skis only) |

### **3. Sample Output**

When running the script, you will see clean status messages instead of raw errors, proving that our Error Handlers are working correctly.

```text
Status
=== INITIALIZING TEST SUITE ===

Test_Case
--- TEST 1: Overbooking Protection (with Error Handler) ---
Test_Result
✅ SUCCESS: Overbooking blocked! Expected error caught.

Test_Case
--- TEST 2: Enrollment Counter & Isolation Levels ---
Step 1: Initial Count (Expect 0)
0
Step 2: After Insert (Expect 1)
1

Test_Case
--- TEST 3: Atomicity - Full Rollback on Bad Data ---
Test_Result
✅ SUCCESS: Transaction Rolled Back due to broken item.
Orphaned Rentals (Should be 0)
0

Test_Case
--- TEST 4: Savepoints - Partial Rollback ---
Log
ℹ️ Info: Helmet unavailable, rolling back to savepoint...
Test_Result
✅ Transaction Committed with Skis only.
ItemCount
1
Status
--- ALL TESTS COMPLETED ---

```

### **4. ACID Compliance Rationale**

* **Atomicity:** Demonstrated in **Test 3**, where a failure in one part of the transaction (broken item) triggers a `ROLLBACK` of the entire order, including the parent rental record.
* **Consistency:** Demonstrated in **Test 1**, where business rules (Capacity limits) are enforced by Triggers and safely caught by Stored Procedure handlers.
* **Isolation:** Demonstrated in **Test 2**, by explicitly setting `SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE` to ensure data integrity during high-concurrency read/write operations.
* **Durability:** Ensured by the database engine (InnoDB) defaults; committed transactions (like the Skis in Test 4) persist even after the partial rollback of the Helmet.
