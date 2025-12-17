# Ski Resort System

**COMP 345 Database Management Systems - Final Project Reference Implementation**

---

## Table of Contents

- [Ski Resort System](#ski-resort-system)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [System Requirements](#system-requirements)
    - [Required Software](#required-software)
  - [Quick Start](#quick-start)
    - [Expected Output](#expected-output)

---

## Overview

This project implements a ski resort management system that handles:

- **Ski Pass Management**: Issuing and tracking ski passes for visitors.
- **Lift Operations**: Managing ski lift usage and maintenance.
- **Resort Facilities**: Overseeing various resort amenities and services.
- **User Management**: Handling user accounts and permissions.
- **Reporting**: Generating reports on resort usage and performance.
- **Database Integration**: Storing and retrieving data using a relational database.

---

## System Requirements

### Required Software

- **MySQL**: Version 8.0 or higher
- **Python 3.8+**: For running scripts
- **Git**: For version control

## Quick Start

After cloning the repository, follow these steps to set up the system:
```bash
# 1. Setup Python Virtual Environment
python3 -m venv env

# 2. Activate Virtual Environment
# On MacOS/Linux
source env/bin/activate # OR
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

```
✓ MySQL connection successful
✓ Database dropped (if it existed) - starting fresh
✓ Schema creation (tables, constraints) completed
✓ Sample data insertion completed
✓ Database objects created: Tables: 16, Views: 0, Procedures: 0, Functions: 0, Triggers: 0

Table                           Row Count
------------------------------------------
Customers                              50
Pass_Types                             10
Instructors                            12
Trails                                 15
Lifts                                  12
Lift_Access                            26
Equipment                              41
Lift_Tickets                           40
Scheduled_Lessons                      15
Rentals                                20
Enrollments                            60
Rental_Items                           77
Maintenance_Staff                      15
Lift_Maintenance_Logs                  12
Equipment_Maintenance_Logs             15
Trail_Maintenance_Logs                 15
```