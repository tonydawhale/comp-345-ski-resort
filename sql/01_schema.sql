DROP DATABASE IF EXISTS ski_resort;
CREATE DATABASE ski_resort CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE ski_resort;

-- 1. Customers Table
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    DOB DATE NOT NULL,
    CONSTRAINT chk_dob_range CHECK (DOB < '2022-01-01') -- Customers must be older than 3 years as of 2025
);

-- 2. Pass Types (Catalog)
CREATE TABLE Pass_Types (
    PassTypeID INT PRIMARY KEY AUTO_INCREMENT,
    PassName VARCHAR(50) NOT NULL,
    CurrentPrice DECIMAL(10,2) CHECK (CurrentPrice >= 0),
    AgeGroup ENUM('Child', 'Adult', 'Senior') NOT NULL,
);

-- 3. Lift Tickets (Transactions)
CREATE TABLE Lift_Tickets (
    TicketID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT,
    PassTypeID INT,
    PurchaseDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    ValidDate DATE NOT NULL,
    SalePrice DECIMAL(10,2) CHECK (SalePrice >= 0),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (PassTypeID) REFERENCES Pass_Types(PassTypeID)
);

-- 4. Instructors
CREATE TABLE Instructors (
    InstructorID INT PRIMARY KEY AUTO_INCREMENT,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Specialty ENUM('Skiing', 'Snowboarding') NOT NULL
);

-- 5. Scheduled Lessons
CREATE TABLE Scheduled_Lessons (
    LessonID INT PRIMARY KEY AUTO_INCREMENT,
    InstructorID INT,
    StartTime TIMESTAMP NOT NULL,
    MaxCapacity INT DEFAULT 10 CHECK (MaxCapacity > 0),
    FOREIGN KEY (InstructorID) REFERENCES Instructors(InstructorID)
);

-- 6. Lesson Enrollments
CREATE TABLE Enrollments (
    EnrollmentID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    LessonID INT NOT NULL,
    PaymentStatus ENUM('Paid', 'Pending', 'Cancelled') NOT NULL DEFAULT 'Pending',
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (LessonID) REFERENCES Scheduled_Lessons(LessonID)
);

-- 7. Equipment Inventory
CREATE TABLE Equipment (
    EquipmentID INT PRIMARY KEY AUTO_INCREMENT,
    EquipmentType ENUM('Ski', 'Snowboard', 'Boots', 'Poles') NOT NULL,
    Status ENUM('Available', 'Rented', 'Maintenance') NOT NULL DEFAULT 'Available'
);

-- 8. Rental Transactions
CREATE TABLE Rentals (
    RentalID INT PRIMARY KEY AUTO_INCREMENT,
    CustomerID INT NOT NULL,
    RentalDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    ReturnDate DATETIME,
    TotalPrice DECIMAL(10,2) CHECK (TotalPrice >= 0),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID),
    FOREIGN KEY (EquipmentID) REFERENCES Equipment(EquipmentID)
);

-- 9. Rental Items
CREATE TABLE Rental_Items (
    RentalItemID INT PRIMARY KEY AUTO_INCREMENT,
    RentalID INT NOT NULL,
    EquipmentID INT NOT NULL,
    FOREIGN KEY (RentalID) REFERENCES Rentals(RentalID),
    FOREIGN KEY (EquipmentID) REFERENCES Equipment(EquipmentID)
)

-- 10. Lifts (Infrastructure)
CREATE TABLE Lifts (
    LiftID INT PRIMARY KEY AUTO_INCREMENT,
    LiftName VARCHAR(50) NOT NULL,
    Capacity INT CHECK (Capacity BETWEEN 1 AND 10),
    Status ENUM('Operational', 'Hold', 'Maitenance', 'Closed') NOT NULL DEFAULT 'Closed',
    ElevationGain INT CHECK (ElevationGain >= 0)
);

-- 11. Trails (Infrastructure)
CREATE TABLE Trails (
    TrailID INT PRIMARY KEY AUTO_INCREMENT,
    TrailName VARCHAR(50) NOT NULL UNIQUE,
    Difficulty ENUM('Green', 'Blue', 'Black', 'Double Black') NOT NULL,
    IsGroomed BOOLEAN NOT NULL DEFAULT FALSE,
    ServiceByLiftID INT,
    FOREIGN KEY (ServiceByLiftID) REFERENCES Lifts(LiftID)
);

-- 12. Maintenance Logs
CREATE TABLE Maintenance_Logs (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    LiftID INT NOT NULL,
    ReportedDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    Description TEXT NOT NULL,
    Priority ENUM('Low', 'Medium', 'High') NOT NULL,
    ResolvedDate DATETIME,
    TechnicianName VARCHAR(100),
    FOREIGN KEY (LiftID) REFERENCES Lifts(LiftID),
    CONSTRAINT chk_resolution CHECK (ResolvedDate >= ReportedDate)
);