-- ---------------------------------------------------------------------
-- 1. BRANCH
-- ---------------------------------------------------------------------
CREATE TABLE BRANCH (
    Branch_ID       SERIAL PRIMARY KEY,
    Branch_Name     VARCHAR(100) NOT NULL,
    Address         VARCHAR(255),
    City            VARCHAR(100) NOT NULL,
    IFSC_Code       VARCHAR(15)  NOT NULL UNIQUE,
    Phone           VARCHAR(20)
);

-- ---------------------------------------------------------------------
-- 2. EMPLOYEE  
-- ---------------------------------------------------------------------
CREATE TABLE EMPLOYEE (
    Employee_ID     SERIAL PRIMARY KEY,
    First_Name      VARCHAR(50) NOT NULL,
    Last_Name       VARCHAR(50) NOT NULL,
    Branch_ID       INT NOT NULL REFERENCES BRANCH(Branch_ID),
    Position        VARCHAR(30) NOT NULL
                     CHECK (Position IN ('Teller','Loan_Officer','Manager','Admin')),
    Phone           VARCHAR(20),
    Email           VARCHAR(100) NOT NULL UNIQUE,
    Hire_Date       DATE NOT NULL DEFAULT CURRENT_DATE
);

-- ---------------------------------------------------------------------
-- 3. CUSTOMER
-- ---------------------------------------------------------------------
CREATE TABLE CUSTOMER (
    Customer_ID     SERIAL PRIMARY KEY,
    First_Name      VARCHAR(50) NOT NULL,
    Last_Name       VARCHAR(50) NOT NULL,
    DOB             DATE NOT NULL,
    Address         VARCHAR(255),
    Phone           VARCHAR(20),
    Email           VARCHAR(100) NOT NULL UNIQUE,
    Created_At      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- 4. LOGIN 
-- ---------------------------------------------------------------------
CREATE TABLE LOGIN (
    Login_ID        SERIAL PRIMARY KEY,
    Username        VARCHAR(50) NOT NULL UNIQUE,
    Password_Hash   VARCHAR(255) NOT NULL,
    Role            VARCHAR(10) NOT NULL CHECK (Role IN ('customer','employee','admin')),
    Customer_ID     INT REFERENCES CUSTOMER(Customer_ID),
    Employee_ID     INT REFERENCES EMPLOYEE(Employee_ID),
    Created_At      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_login_owner CHECK (
        (Role = 'customer' AND Customer_ID IS NOT NULL AND Employee_ID IS NULL)
        OR
        (Role IN ('employee','admin') AND Employee_ID IS NOT NULL AND Customer_ID IS NULL)
    )
);

-- ---------------------------------------------------------------------
-- 5. ACCOUNT_TYPE 
-- ---------------------------------------------------------------------
CREATE TABLE ACCOUNT_TYPE (
    Account_Type_ID SERIAL PRIMARY KEY,
    Type_Name       VARCHAR(30) NOT NULL UNIQUE,
    Interest_Rate   DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    Min_Balance     DECIMAL(12,2) NOT NULL DEFAULT 0.00
);

-- ---------------------------------------------------------------------
-- 6. ACCOUNT
-- ---------------------------------------------------------------------
CREATE TABLE ACCOUNT (
    Account_ID      SERIAL PRIMARY KEY,
    Account_Number  VARCHAR(20) NOT NULL UNIQUE,
    Customer_ID     INT NOT NULL REFERENCES CUSTOMER(Customer_ID),
    Branch_ID       INT NOT NULL REFERENCES BRANCH(Branch_ID),
    Account_Type_ID INT NOT NULL REFERENCES ACCOUNT_TYPE(Account_Type_ID),
    Balance         DECIMAL(14,2) NOT NULL DEFAULT 0.00 CHECK (Balance >= 0),
    Status          VARCHAR(15) NOT NULL DEFAULT 'Active'
                     CHECK (Status IN ('Active','Frozen','Closed')),
    Opened_Date     DATE NOT NULL DEFAULT CURRENT_DATE
);

-- ---------------------------------------------------------------------
-- 7. TRANSACTION  
-- ---------------------------------------------------------------------
CREATE TABLE TRANSACTION (
    Transaction_ID   SERIAL PRIMARY KEY,
    Account_ID       INT NOT NULL REFERENCES ACCOUNT(Account_ID),
    Employee_ID      INT REFERENCES EMPLOYEE(Employee_ID),
    Transaction_Type VARCHAR(20) NOT NULL
                      CHECK (Transaction_Type IN
                             ('Deposit','Withdrawal','Transfer_In','Transfer_Out','Loan_Payment')),
    Amount           DECIMAL(14,2) NOT NULL CHECK (Amount > 0),
    Balance_After    DECIMAL(14,2) NOT NULL,
    Status           VARCHAR(10) NOT NULL DEFAULT 'Completed'
                      CHECK (Status IN ('Completed','Failed','Pending')),
    Txn_Timestamp    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ---------------------------------------------------------------------
-- 8. FUND_TRANSFER 
-- ---------------------------------------------------------------------
CREATE TABLE FUND_TRANSFER (
    Transfer_ID           SERIAL PRIMARY KEY,
    From_Account_ID       INT NOT NULL REFERENCES ACCOUNT(Account_ID),
    To_Account_ID         INT NOT NULL REFERENCES ACCOUNT(Account_ID),
    Amount                DECIMAL(14,2) NOT NULL CHECK (Amount > 0),
    Employee_ID           INT REFERENCES EMPLOYEE(Employee_ID),
    Debit_Transaction_ID  INT NOT NULL REFERENCES TRANSACTION(Transaction_ID),
    Credit_Transaction_ID INT NOT NULL REFERENCES TRANSACTION(Transaction_ID),
    Status                VARCHAR(10) NOT NULL DEFAULT 'Completed'
                           CHECK (Status IN ('Completed','Failed','Pending')),
    Transfer_Timestamp    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_transfer_accounts CHECK (From_Account_ID <> To_Account_ID)
);

-- ---------------------------------------------------------------------
-- 9. LOAN_TYPE 
-- ---------------------------------------------------------------------
CREATE TABLE LOAN_TYPE (
    Loan_Type_ID      SERIAL PRIMARY KEY,
    Type_Name         VARCHAR(30) NOT NULL UNIQUE,
    Interest_Rate     DECIMAL(5,2) NOT NULL,
    Max_Tenure_Months INT NOT NULL
);

-- ---------------------------------------------------------------------
-- 10. LOAN
-- ---------------------------------------------------------------------
CREATE TABLE LOAN (
    Loan_ID          SERIAL PRIMARY KEY,
    Customer_ID      INT NOT NULL REFERENCES CUSTOMER(Customer_ID),
    Branch_ID        INT NOT NULL REFERENCES BRANCH(Branch_ID),
    Loan_Type_ID     INT NOT NULL REFERENCES LOAN_TYPE(Loan_Type_ID),
    Employee_ID      INT REFERENCES EMPLOYEE(Employee_ID),
    Principal_Amount DECIMAL(14,2) NOT NULL CHECK (Principal_Amount > 0),
    Interest_Rate    DECIMAL(5,2) NOT NULL,
    Tenure_Months    INT NOT NULL CHECK (Tenure_Months > 0),
    EMI_Amount       DECIMAL(12,2) NOT NULL,
    Status           VARCHAR(15) NOT NULL DEFAULT 'Applied'
                      CHECK (Status IN ('Applied','Approved','Rejected','Active','Closed')),
    Start_Date       DATE,
    End_Date         DATE
);

-- ---------------------------------------------------------------------
-- 11. LOAN_PAYMENT  
-- ---------------------------------------------------------------------
CREATE TABLE LOAN_PAYMENT (
    Payment_ID       SERIAL PRIMARY KEY,
    Loan_ID          INT NOT NULL REFERENCES LOAN(Loan_ID),
    Account_ID       INT NOT NULL REFERENCES ACCOUNT(Account_ID),
    Employee_ID      INT REFERENCES EMPLOYEE(Employee_ID),
    Transaction_ID   INT NOT NULL REFERENCES TRANSACTION(Transaction_ID),
    Amount           DECIMAL(12,2) NOT NULL CHECK (Amount > 0),
    Payment_Date     DATE NOT NULL DEFAULT CURRENT_DATE,
    Status           VARCHAR(10) NOT NULL DEFAULT 'Completed'
                      CHECK (Status IN ('Completed','Failed','Pending'))
);


-- =====================================================================
-- SECTION 2: INDEXES
-- =====================================================================
CREATE INDEX idx_account_customer      ON ACCOUNT(Customer_ID);
CREATE INDEX idx_transaction_account   ON TRANSACTION(Account_ID);
CREATE INDEX idx_transaction_employee  ON TRANSACTION(Employee_ID);
CREATE INDEX idx_transaction_timestamp ON TRANSACTION(Txn_Timestamp);
CREATE INDEX idx_loan_customer         ON LOAN(Customer_ID);
CREATE INDEX idx_loanpayment_loan      ON LOAN_PAYMENT(Loan_ID);


-- =====================================================================
-- SECTION 3: SAMPLE / DUMMY DATA
-- =====================================================================

INSERT INTO BRANCH (Branch_Name, Address, City, IFSC_Code, Phone) VALUES
('Guwahati Main Branch', 'GS Road', 'Guwahati', 'ACAD0001001', '9000000001'),
('Dispur Branch',        'Dispur Circle', 'Guwahati', 'ACAD0001002', '9000000002'),
('Silchar Branch',       'Park Road', 'Silchar', 'ACAD0001003', '9000000003');


INSERT INTO EMPLOYEE (First_Name, Last_Name, Branch_ID, Position, Phone, Email) VALUES
('Anita', 'Sharma', 1, 'Teller',       '9111100001', 'anita.sharma@acadbank.test'),
('Rahul', 'Das',    1, 'Loan_Officer', '9111100002', 'rahul.das@acadbank.test'),
('Priya', 'Bora',   2, 'Manager',      '9111100003', 'priya.bora@acadbank.test'),
('Sanjay','Gogoi',  3, 'Teller',       '9111100004', 'sanjay.gogoi@acadbank.test'),
('Meera', 'Kalita', 1, 'Admin',        '9111100005', 'meera.kalita@acadbank.test');

INSERT INTO CUSTOMER (First_Name, Last_Name, DOB, Address, Phone, Email) VALUES
('Arjun', 'Verma',   '1995-03-12', 'Zoo Road, Guwahati',   '9222200001', 'arjun.verma@example.test'),
('Sneha', 'Kumar',   '1998-07-25', 'Fancy Bazar, Guwahati','9222200002', 'sneha.kumar@example.test'),
('Vikram','Choudhury','1990-11-02','Dispur, Guwahati',     '9222200003', 'vikram.c@example.test'),
('Ritu',  'Saikia',  '2000-01-18', 'Silchar Town',         '9222200004', 'ritu.saikia@example.test');

INSERT INTO LOGIN (Username, Password_Hash, Role, Customer_ID, Employee_ID) VALUES
('arjun.verma',  '$2b$12$placeholderhash0000000000000000000000000001', 'customer', 1, NULL),
('sneha.kumar',  '$2b$12$placeholderhash0000000000000000000000000002', 'customer', 2, NULL),
('vikram.c',     '$2b$12$placeholderhash0000000000000000000000000003', 'customer', 3, NULL),
('ritu.saikia',  '$2b$12$placeholderhash0000000000000000000000000004', 'customer', 4, NULL),
('anita.sharma', '$2b$12$placeholderhash0000000000000000000000000005', 'employee', NULL, 1),
('rahul.das',    '$2b$12$placeholderhash0000000000000000000000000006', 'employee', NULL, 2),
('priya.bora',   '$2b$12$placeholderhash0000000000000000000000000007', 'employee', NULL, 3),
('meera.kalita', '$2b$12$placeholderhash0000000000000000000000000008', 'admin',    NULL, 5);

INSERT INTO ACCOUNT_TYPE (Type_Name, Interest_Rate, Min_Balance) VALUES
('Savings',       3.50, 500.00),
('Current',       0.00, 1000.00),
('Fixed_Deposit', 6.50, 10000.00);

INSERT INTO LOAN_TYPE (Type_Name, Interest_Rate, Max_Tenure_Months) VALUES
('Personal',  12.00, 60),
('Home',       8.50, 240),
('Auto',      10.00, 84),
('Education',  7.50, 120);

INSERT INTO ACCOUNT (Account_Number, Customer_ID, Branch_ID, Account_Type_ID, Balance, Status) VALUES
('AC10001001', 1, 1, 1, 25000.00, 'Active'),
('AC10001002', 2, 1, 1, 15000.00, 'Active'),
('AC10001003', 3, 2, 2, 50000.00, 'Active'),
('AC10001004', 4, 3, 1, 8000.00,  'Active');


