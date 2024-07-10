Create database Bank;
use Bank;

--Creating outlets table 

Create table Outlets(
OutletName varchar(50),
LocationID int identity(91120,1) NOT NULL,
postal_code varchar(50),
country varchar(50),
district varchar(50),
Town_or_city varchar(100),
CONSTRAINT Outlets_pk PRIMARY KEY (LocationID)
);

create index out_ind on Outlets (LocationID);
--Creating Outlets Contacts table

Create table Outlets_Contacts(
LocationID int NOT NULL ,
Contact_Number bigint NOT NULL,
CONSTRAINT Location_Contacts_pk PRIMARY KEY(Contact_Number,LocationID),
CONSTRAINT Location_Contacts_fk FOREIGN KEY(LocationID) REFERENCES Outlets (LocationID)
);

--Creating Employee table

 Create table Employees(
 Employee_Number int IDENTITY(2022000,2) NOT NULL ,
 First_Name varchar(155),
 Last_Name varchar(255),
 Job_Title varchar(50),
 postal_code varchar(50),
 country varchar(50),
 district varchar(50),
 Town_or_city varchar(100),
 Location varchar(50),
 ManagerID int NOT NULL,
 LocationID int NOT NULL,
 CONSTRAINT Employees_pk PRIMARY KEY (Employee_Number),
 CONSTRAINT E_fk FOREIGN KEY (ManagerID) REFERENCES Employees (Employee_Number),
 CONSTRAINT Employees_fk FOREIGN KEY(LocationID) REFERENCES Outlets (LocationID)
 );

--Creating Employees contact table

Create table Employees_Contacts(
Employee_Number int NOT NULL ,
Contact_Number bigint NOT NULL,
CONSTRAINT Employees_Contacts_pk PRIMARY KEY(Contact_Number,Employee_Number),
CONSTRAINT Employees_Contacts_fk FOREIGN KEY(Employee_Number) REFERENCES Employees (Employee_Number)
);

--Account table creation

 Create table Account(
 Account_number bigint IDENTITY(808000160000,60) NOT NULL,
 LocationID int NOT NULL,
 Account_Type varchar(100),
 interest_rate FLOAT,
 Withdrawal_limit money,
 CONSTRAINT Account_pk PRIMARY KEY (Account_number),
 CONSTRAINT Account_fk FOREIGN KEY(LocationID) REFERENCES Outlets (LocationID)
 );
 Alter table Account
 ADD Balance money;
  
Create index Account_index on Account(Account_number);

--Customer table creation

Create table Customer(
CustomerID int IDENTITY(200,1) NOT NULL,
First_Name varchar(50),
Last_name varchar(255),
DOB date,
postal_code varchar(50),
country varchar(50),
district varchar(50),
Town_or_city varchar(50),
CONSTRAINT Customer_pk PRIMARY KEY (CustomerID),
CONSTRAINT chk_DOB CHECK(DOB>'1945-01-01')
);

Create index C_index on Customer(CustomerID);

--creating customer contact table

Create table Customer_Contacts(
CustomerID int NOT NULL ,
Contact_Number bigint NOT NULL,
CONSTRAINT Customer_Contacts_pk PRIMARY KEY(Contact_Number,CustomerID),
CONSTRAINT Customer_Contacts_fk FOREIGN KEY(CustomerID) REFERENCES Customer (CustomerID)
);

--creation of customer account

Create table Customer_Account(
CustomerID int NOT NULL foreign key references Customer (CustomerID), 
Account_number bigint NOT NULL foreign key references Account (Account_number),
Date_created DATETIME,
Balance money,
CONSTRAINT Customer_Account_pk PRIMARY KEY (CustomerID,Account_number) 
);
Alter table Customer_Account
Drop COLUMN Balance;

Create index CAccount_index on Customer_Account(CustomerID,Account_number);

--creation of private cutomers table

Create table Private_Customers(
PCustomerID int NOT NULL,
LocationID int NOT NULL ,
Company varchar(100),
constraint pc_pk PRIMARY KEY (PCustomerID, LocationID),
CONSTRAINT pc_fk FOREIGN KEY (PCustomerID) REFERENCES Customer (CustomerID),
CONSTRAINT pc_fk2 FOREIGN KEY(LocationID) REFERENCES Outlets (LocationID)
);

--NORMAL CUSTOMER TABLE CREATION

Create table Normal_Customers(
NCustomerID int NOT NULL, 
LocationID int NOT NULL ,
SourceOfIncome varchar(100),
constraint nc_pk PRIMARY KEY (NCustomerID, LocationID),
CONSTRAINT nc_fk Foreign Key (NCustomerID) REFERENCES Customer (CustomerID),
CONSTRAINT nc_fk2 FOREIGN KEY(LocationID) REFERENCES Outlets (LocationID)
);

--loan table creation

Create table Loan(
LoanID int identity(10,3) NOT NULL,
LocationID int not null Foreign key references Outlets (LocationID),
Account_Number bigint not null foreign key  REFERENCES Account (Account_Number),
CustomerID int not null Foreign Key (CustomerID) REFERENCES Customer (CustomerID),
status varchar(50) DEFAULT 'REJECTED',
Amount money,
LoanPeriod varchar(20),
interestRate float,
DeadlineForPayment date,
Constraint Loan_pk PRIMARY KEY (LoanID)
);

-- loan payment table creation

Create table Loan_MonthlyRepayment(
LoanID int NOT NULL,
MonthlyRepaymentAmount int not null,
date date,
constraint lm_fk  FOREIGN KEY (LoanID) REFERENCES Loan (LoanID)
);
																   
--creating card account table

Create table Cards(
CardNumber bigint identity (56001223000,29) Not Null,
CardType varchar(50) NOT NULL CHECK (CardType = 'Debit Card' or  CardType = 'Credit Card'),
LocationID INT NOT NULL FOREIGN KEY(LocationID) REFERENCES Outlets (LocationID),
Constraint CardAccount_pk PRIMARY KEY (CardNumber),
);
--creating customer card table

Create table Customer_Card(
CardNumber bigint NOT NULL Foreign Key (CardNumber) REFERENCES CardS (CardNumber),
CustomerID int NOT NULL Foreign Key (CustomerID) REFERENCES Customer (CustomerID),
DateCreated Date,
CONSTRAINT CC_PK PRIMARY KEY (CardNumber, CustomerID)
);

create index ccard_inex on Customer_Card(CustomerID, CardNumber);

--creating transactions table

Create table Transactions
(
CardNumber bigint  not null ,
Account_Number bigint NOT NULL,
TransactionID int identity(100,1) NOT NULL,
Date datetime,
Amount money,
Balance money,
typeOfTransaction varchar(20),
Charges float,
TaxDeducted float,
CONSTRAINT Transactions_pk PRIMARY KEY (TransactionID),
Constraint Transaction_fk Foreign key (Account_Number) REFERENCES Account (Account_Number)
);
Alter table Transactions 
ADD constraint trans_fk Foreign Key (CardNumber) REFERENCES Cards (CardNumber);


--TRIGGERS TO ENFORCE BUSINESS RULES

--a trigger created to not allow normal customers loan above a million

create trigger LoanMaxAmount
ON Loan
For  INSERT
AS
begin
DECLARE @amount money
SELECT @amount= inserted.Amount
FROM   inserted INNER JOIN Customer 
ON     inserted.CustomerID = Customer.CustomerID INNER JOIN
       Normal_Customers ON Customer.CustomerID = Normal_Customers.NCustomerID
if (@amount>1000000)
 PRINT 'The maximum unsecured loan by a normal customer should be less than 1,000,000'
  rollback transaction
END

--a trigger not to allow customers to have more than one loan

create trigger CustomerLoan
on Loan
FOR insert
as
BEGIN
Select * 
from Loan INNER JOIN inserted 
on inserted.LoanID= Loan.LoanID
PRINT'This Customer already have a loan'
 rollback transaction
end
RETURN

INSERT INTO Loan (LocationID, Account_number,CustomerID,Amount,LoanPeriod,interestRate,DeadlineForPayment) VALUES (91120,808000160420,202,90000,'23 Months',0.4,'2021-02-03');

--a trigger when loan is about to complete 3 months

create trigger LoanMonth
on Loan
after insert, UPDATE
AS
declare @months varchar
declare @M varchar(150)
BEGIN
Select @months= LoanPeriod
From Loan
if( @months like '2 Months')
 PRINT 'The loan is almost 3 months'
end
RETURN

--a trigger when withdrawal is done on negative balance

CREATE TRIGGER WithdrawalBalance
on Transactions
for INSERT, UPDATE
AS
declare @bal money
SELECT  @bal= Account.Balance
FROM  Account INNER JOIN
      inserted
ON inserted.Account_Number = Account.Account_number 
where typeOfTransaction like 'W%'
BEGIN
if( @bal<0)
   Print 'You have insuffitients balance to complete this Transaction'
  ROLLBACK TRANSACTION
end 

--INSERTING INTO TABLES



--inserting values inside outlets table
SET IDENTITY_INSERT Outlets on
go
 INSERT INTO  Outlets (OutletName,LocationID,postal_code, country, district, Town_or_city) VALUES ('NewRoad Complex',91120,'P.O Box 18','Lesotho','Maseru','Ha Foso');
 INSERT INTO Outlets  (OutletName,LocationID,postal_code, country, district, Town_or_city) VALUES ('Wellies',91121,'P.O Box 10','Lesotho','Maseru','Khubetsoana');
 INSERT INTO Outlets  (OutletName,LocationID,postal_code, country, district, Town_or_city) VALUES ('Masuwe Complex',91129,'P.O Box 20','Lesotho','Maseru','Maseru');
 INSERT INTO Outlets  (OutletName,LocationID,postal_code, country, district, Town_or_city) VALUES ('Senate Road',91122,'P.O Box 70','Lesotho','Maseru','Mazenod');
 INSERT INTO Outlets  (OutletName,LocationID,postal_code, country, district, Town_or_city) VALUES ('Road501',91123,'P.O Box 80','Lesotho','Maseru','Roma');
 INSERT INTO Outlets  (OutletName,LocationID,postal_code, country, district, Town_or_city) VALUES ('Maseru mall',91124,'P.O Box 90','Lesotho','Maseru','Ha Thetsane');
 INSERT INTO Outlets  (OutletName,LocationID,postal_code, country, district, Town_or_city) VALUES ('Maseru complex',91125,'P.O Box 30','Lesotho','Maseru','Lithabaneng');
 INSERT INTO Outlets  (OutletName,LocationID,postal_code, country, district, Town_or_city) VALUES ('Pioneer mall',91126,'P.O Box 03','Lesotho','Maseru','Mantshebo');
 INSERT INTO Outlets  (OutletName,LocationID,postal_code, country, district, Town_or_city) VALUES ('Sefika complex',91127,'P.O Box 01','Lesotho','Maseru','Abia');
 INSERT INTO Outlets  (OutletName,LocationID,postal_code, country, district, Town_or_city) VALUES ('Queen Heart',91128,'P.O Box 50','Lesotho','Maseru','Masianokeng');

 SET IDENTITY_INSERT Outlets off
 go

  SELECT * FROM Outlets

  --inserting into outlets contacts table
  
  INSERT INTO Outlets_Contacts VALUES (91128, 26650990034),
                                      (91128, 26622316429), 
									  (91127, 26656880011),
									  (91126, 26651283900),
									  (91125, 26667002328),
									  (91124, 26658009323),
									  (91124, 26669023446),
									  (91123, 26622178890),
									  (91122, 26652900023),
									  (91121, 26668902340),
									  (91120, 26653891289);

Select FORMAT(Contact_Number,'+### #### ####') AS Phone_Number,LocationID
FROM Outlets_Contacts;

 --insering values inside employee table

  SET IDENTITY_INSERT Employees on
 go

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022000,91129,'Thetsane Park','Joyce','Johnson','Manager','P.O Box 89','Lesotho','Maseru',2022000,'Thetsane');

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022001,91129,'Thetsane Usave', 'John', 'Boycott','Teller','P.O Box 09','Lesotho','Maseru',2022000,'Thetsane');

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022002,91121,'Lower Thetsane','Kay','Dion','Manager','P.O Box 59','Lesotho','Maseru',2022002,'Thetsane');

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022003,91121,'Hailey street','Abby','Johnson','Teller','P.O Box 49','Lesotho','Leribe',2022002,'Hlotse');

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022004,91123,'Hlotse','Hailey','Booan','Teller','P.O Box 19','Lesotho','Maseru',2022004,'Thetsane');

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022005,91123, 'New street','Holly','Ray','Manager','P.O Box 90','Lesotho','Leribe',2022004,'Maputsoe');

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022006,91124, 'Maseru','Lavi','Relo','Marketing','P.O Box 50','Lesotho','Maseru',2022006,'Thetsane');

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022007,91124, 'Maputsoe road','Jill','Polo','Maneger','P.O Box 78','Lesotho','Maseru',2022006,'Maputsoe');

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022008,91127, 'Maseli','Lory','Hailey','Receptionist','P.O Box 909','Lesotho','Maseru',2022007,'Abia');

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022009,91127, 'New road','Shelly','Brown','Manager','P.O Box 799','Lesotho','Leribe',2022007,'Peka');

INSERT INTO Employees(Employee_Number,LocationID,Location, First_Name, Last_Name, Job_Title,postal_code,country,district,ManagerID,Town_or_city ) VALUES (2022010,91127, 'Caledon','Paul','Kinya','Marketing','P.O Box 89','Lesotho','Butha Buthe',2022007,'Caledon');
 set identity_insert Employees off

SELECT * FROM Employees
DELETE FROM Employees;
--inserting values inside employees contact table

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022000,26666096667);

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022000,26667866696);

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022002,26654367886);

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022002,26650777088);

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022004,26664388445);

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022010,26656798700);

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022006,26622332492);

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022006,26654890111);

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022010,26660666890);

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022008,26656432199);

INSERT INTO Employees_Contacts(Employee_Number,Contact_Number) VALUES (2022001,26650098770);

--output when contact numbers are formated

Select FORMAT(Contact_Number,'+### #### ####') AS Phone_Number,Employee_Number
FROM Employees_Contacts;

UPDATE Employees_Contacts
SET Contact_Number=26650787722
where Employee_Number=2022001;

SELECT  FORMAT(Contact_Number,'+### #### ####') AS Phone_Number
 FROM Employees_Contacts WHERE Employee_Number = 2022001;

--insertion on Account table

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91129,'Current Account',NULL,25000.00,43211);

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES  (91129,'Saving Account',4.5,NULL,89003);

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES  (91122,'Call Account',NULL,NULL,784566);

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES  (91120,'Current Account',NULL,25000.00,873422);

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES  (91125,'Saving Account',8.0,NULL,569877);

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES  (91125,'Saving Account',7.5,NULL,89744);
 
 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91124,'Current Account',NULL,900.00,29.90);

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES  (91120,'Call Account',NULL,NULL,8900);

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES  (91127,'Call Account',NULL,NULL,785690);

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91129,'Fixed Deposit Account',NULL,NULL,0);
 
 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91125,'Current Account',NULL,4000.00,87.00);
 
 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91129,'Current Account',NULL,5000.00,8977);
 
 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91129,'Saving Account',5.5,NULL,6700);
 
 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91122,'Call Account',NULL,NULL,8943211);
 
 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91120,'Current Account',NULL,2000.00,56.9);

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES  (91121,'Saving Account',2.0,NULL,780099);

 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91122,'Saving Account',2.5,NULL,6789000);
 
 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91123,'Current Account',NULL,3000.00,90877);
 
 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91124,'Call Account',NULL,NULL,0);
 
 INSERT INTO Account (LocationID, Account_Type, interest_rate,Withdrawal_limit,Balance) VALUES (91125,'Call Account',NULL,NULL,89000);

 Select FORMAT(Balance,'M### ### ### ###') AS Balance,Account_number
FROM Account
select * from account
 delete from Account;

 --inserting into customer table

INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Jones','Jolly','2000-02-01','P.O Box 09','Lesotho','Butha Buthe','Caledon');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Pill','Jones','2003-12-18','P.O Box 09','Lesotho','Maseru','Thetsane');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Moler','Rolles','2001-04-27','P.O Box 28','Lesotho','Leribe','Maputsoe');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('jill','Jones','1998-04-12','P.O Box 709','Lesotho','Leribe','Maputsoe');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Sones','Gassy','1999-07-12','P.O Box 22','Lesotho','Maseru','Abia');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Bill','Show','1989-07-12','P.O Box 908','Lesotho','Maseru','Thetsane');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Queen','Libra','1990-07-12','P.O Box 178','Lesotho','Maseru','Roma');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Rose','Sweet','1998-07-12','P.O Box `108','Lesotho','Leribe','Hlotse');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Belle','Lolly','1997-07-12','P.O Box 100','Lesotho','Maseru','Thetsane');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Bill','Silver','1993-12-18','P.O Box 13','Lesotho','Maseru','Thetsane');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Coler','Bulles','2001-04-27','P.O Box 18','Lesotho','Leribe','Maputsoe');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Mill','Queens','1988-04-12','P.O Box 09','Lesotho','Leribe','Maputsoe');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Polly','Bassy','1999-07-07','P.O Box 122','Lesotho','Maseru','Abia');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Anna','Chow','1989-07-02','P.O Box 95','Lesotho','Maseru','Thetsane');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Phoenix','Phon','1990-04-22','P.O Box 158','Lesotho','Maseru','Roma');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Row','West','1998-03-12','P.O Box `158','Lesotho','Leribe','Hlotse');
INSERT INTO Customer (First_Name,Last_name,DOB,postal_code,country,district,Town_or_city) VALUES ('Lox','Jolly','1997-03-13','P.O Box 130','Lesotho','Maseru','Thetsane');

SELECT * FROM Customer;

--inserting into customer contact number table

INSERT INTO Customer_Contacts (CustomerID, Contact_Number) VALUES (200, 26651365340),
                                                                  (201, 26662256254),
								  (202, 26653147162),
								  (203, 26664038070),
								  (204, 26655129988),
								  (205, 26666210896),
								  (216, 26657301704),
								  (215, 26668492612),
								  (214, 26659583520),
								  (213, 26660674438),
								  (211, 26651765346),
								  (212, 26662856254),
								  (210, 26653947162);

SELECT  FORMAT(Contact_Number,'+### #### ####') AS Phone_Number, CustomerID
 FROM Customer_Contacts

--inserting values inside customer account table

INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (214,808000160360, SYSDATETIME());               
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (202,808000160420,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (208,808000160480,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (201,808000160600,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (205,808000160540,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (204,808000160000,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (206,808000160060,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (209,808000160120,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (207,808000160180,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (203,808000160240,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (209,808000160300,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (210,808000160660,SYSDATETIME());               
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (211,808000160720,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (212,808000160840,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (213,808000160900,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (215,808000161020,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (216,808000161080,SYSDATETIME());
INSERT INTO Customer_Account (CustomerID,Account_number,Date_created) VALUES (210,808000161140,SYSDATETIME());


select * from customer_account;

Truncate table customer_account;

--inserting values inside private customer the table

INSERT INTO Private_Customers (PCustomerID,LocationID, Company) VALUES (202,91120,'White Jyp');
INSERT INTO Private_Customers (PCustomerID,LocationID, Company) VALUES (202,91122, 'Queen Arts');
INSERT INTO Private_Customers (PCustomerID,LocationID, Company) VALUES (204, 91124, 'Belle Sword');
INSERT INTO Private_Customers (PCustomerID,LocationID, Company) VALUES (206, 91126, 'Daisy inc');
INSERT INTO Private_Customers (PCustomerID,LocationID, Company) VALUES (208,91128, 'OP Jewels');
INSERT INTO Private_Customers (PCustomerID,LocationID, Company) VALUES (210,91120,'Hearts Jyp');
INSERT INTO Private_Customers (PCustomerID,LocationID, Company) VALUES (212,91122, 'Rulers Arts');
INSERT INTO Private_Customers (PCustomerID,LocationID, Company) VALUES (214, 91124, 'Born Sword');
INSERT INTO Private_Customers (PCustomerID,LocationID, Company) VALUES (216, 91126, 'Monster inc');
INSERT INTO Private_Customers (PCustomerID,LocationID, Company) VALUES (216,91128, 'Teen fashion');

SELECT * FROM Private_Customers;

--INSERTING VALUES IN NORMAL CUSTOMERS TABLE

INSERT INTO Normal_Customers (NCustomerID,LocationID,SourceOfIncome) VALUES (201,91121,'Parents');

INSERT INTO Normal_Customers (NCustomerID,LocationID,SourceOfIncome) VALUES (203,91123,'Work'); 

INSERT INTO Normal_Customers (NCustomerID,LocationID,SourceOfIncome) VALUES (205,91125,'Trading');

INSERT INTO Normal_Customers (NCustomerID,LocationID,SourceOfIncome) VALUES (207,91127,'Parents');

INSERT INTO Normal_Customers (NCustomerID,LocationID,SourceOfIncome) VALUES (209,91129,'Government');

INSERT INTO Normal_Customers (NCustomerID,LocationID,SourceOfIncome) VALUES (211,91121,'Work');

INSERT INTO Normal_Customers (NCustomerID,LocationID,SourceOfIncome) VALUES (213,91123,'Work');

INSERT INTO Normal_Customers (NCustomerID,LocationID,SourceOfIncome) VALUES (215,91125,'Government');

INSERT INTO Normal_Customers (NCustomerID,LocationID,SourceOfIncome) VALUES (216,91127,'Self');

INSERT INTO Normal_Customers (NCustomerID,LocationID,SourceOfIncome) VALUES (216,91129,'Government');


SELECT * FROM Normal_Customers;


--inserting into loan table

INSERT INTO Loan (LocationID, Account_number,CustomerID,Amount,LoanPeriod,interestRate,DeadlineForPayment) VALUES (91125,808000160600,201,70000,'6 Months',0.9,'2022-03-03');
INSERT INTO Loan (LocationID, Account_number,CustomerID,Amount,LoanPeriod,interestRate,DeadlineForPayment) VALUES (91125,808000160240,203,89000,'8 Months',0.2,'2022-01-31');
INSERT INTO Loan (LocationID, Account_number,CustomerID,Amount,LoanPeriod,interestRate,DeadlineForPayment) VALUES (91129,808000160000,204,2000,'12 Months',0.8,'2022-02-27');
INSERT INTO Loan (LocationID, Account_number,CustomerID,Amount,LoanPeriod,interestRate,DeadlineForPayment) VALUES (91129,808000160720,211,10000,'12 Months',0.8,'2021-04-09');
INSERT INTO Loan (LocationID, Account_number,CustomerID,Amount,LoanPeriod,interestRate,DeadlineForPayment) VALUES (91122,808000160120,209,10000,'13 Months',0.8,'2021-03-07');
INSERT INTO Loan (LocationID, Account_number,CustomerID,Amount,LoanPeriod,interestRate,DeadlineForPayment) VALUES (91129,808000160540,205,50000,'23 Months',0.8,'2022-03-07');
INSERT INTO Loan (LocationID, Account_number,CustomerID,Amount,LoanPeriod,interestRate,DeadlineForPayment) VALUES (91127,808000160480,208,50000,'23 Months',0.8,'2022-03-07');
INSERT INTO Loan (LocationID, Account_number,CustomerID,Amount,LoanPeriod,interestRate,DeadlineForPayment) VALUES (91120,808000160420,202,90000,'23 Months',0.4,'2021-02-03');

SELECT * FROM Loan;
Truncate Table Loan;

--INSERTING INTO LOAN PAYMENT TABLE

INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRepaymentAmount) VALUES (13,'2021-09-03',11700);
INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRePaymentAmount) VALUES (13,'2021-10-03',11700);
INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRePaymentAmount) VALUES (13,'2021-11-03',11700);
INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRePaymentAmount) VALUES (13,'2021-12-03',11700);
INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRePaymentAmount) VALUES (13,'2022-01-03',11700);
INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRePaymentAmount) VALUES (13,'2022-02-03',0);
INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRePaymentAmount) VALUES (16,'2021-07-03',11125);
INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRePaymentAmount) VALUES (16,'2021-08-03',11125);
INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRePaymentAmount) VALUES (16,'2021-09-03',11125);
INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRePaymentAmount) VALUES (16,'2021-10-03',11125);
INSERT INTO  Loan_MonthlyRepayment (LoanID,date,MonthlyRePaymentAmount) VALUES (16,'2021-11-03',0);

SELECT * FROM Loan_MonthlyRepayment;
TRUNCATE table Loan_MonthlyRepayment;

--insert into card account table

INSERT INTO Cards (CardType,LocationID) VALUES ('Debit Card',91120);
INSERT INTO Cards (CardType,LocationID) VALUES ('Debit Card',91121);
INSERT INTO Cards (CardType,LocationID) VALUES ('Debit Card',91122);
INSERT INTO Cards (CardType,LocationID) VALUES ('Credit Card',91122);
INSERT INTO Cards (CardType,LocationID) VALUES ('Credit Card',91123);
INSERT INTO Cards (CardType,LocationID) VALUES ('Debit Card',91124);
INSERT INTO Cards (CardType,LocationID) VALUES ('Debit Card',91125);
INSERT INTO Cards (CardType,LocationID) VALUES ('Credit Card',91126);
INSERT INTO Cards (CardType,LocationID) VALUES ('Credit Card',91127);
INSERT INTO Cards (CardType,LocationID) VALUES ('Credit Card',91128);

SELECT * FROM Cards;

--inserting into carstomer card table


INSERT INTO Customer_Card (CardNumber, CustomerID, DateCreated) VALUES(56001223000,201,'2022-03-03');

INSERT INTO Customer_Card (CardNumber, CustomerID, DateCreated) VALUES(56001223029,201,'2022-01-31');

INSERT INTO Customer_Card (CardNumber, CustomerID, DateCreated) VALUES(56001223058,202,'2022-02-27');

INSERT INTO Customer_Card (CardNumber, CustomerID, DateCreated) VALUES(56001223087,203,'2022-03-03');

INSERT INTO Customer_Card (CardNumber, CustomerID, DateCreated) VALUES (56001223116,204,'2022-03-03');

INSERT INTO Customer_Card (CardNumber, CustomerID, DateCreated) VALUES(56001223145,205,'2022-02-27');

INSERT INTO Customer_Card (CardNumber, CustomerID, DateCreated) VALUES(56001223174,206,'2022-01-31');

INSERT INTO Customer_Card (CardNumber, CustomerID, DateCreated) VALUES(56001223203,207,'2022-03-10');

INSERT INTO Customer_Card (CardNumber, CustomerID, DateCreated) VALUES(56001223232,208,'2022-02-27');

INSERT INTO Customer_Card (CardNumber, CustomerID, DateCreated) VALUES(56001223261,209,'2022-03-03');

SELECT * FROM Customer_Card ORDER BY CustomerID;

--inserting into transactions table
SET IDENTITY_INSERT Transactions ON
go

INSERT INTO Transactions (CardNumber, Account_number,TransactionID,Date,typeOfTransaction,Amount,Charges,TaxDeducted) Values (56001223000,808000160600,100,'2022-02-01','Withdrawal',400,0.01,NULL);
INSERT INTO Transactions (CardNumber, Account_number,TransactionID,Date,typeOfTransaction,Amount,Charges,TaxDeducted) Values (56001223029,808000160240,101,'2022-03-12','Deposit',1000,NULL,0.12);
INSERT INTO Transactions (CardNumber, Account_number,TransactionID,Date,typeOfTransaction,Amount,Charges,TaxDeducted) Values (56001223058,808000160300,102,'2022-03-12','Deposit',800,NULL,0.12);
INSERT INTO Transactions (CardNumber, Account_number,TransactionID,Date,typeOfTransaction,Amount,Charges,TaxDeducted) Values (56001223087,808000160240,103,'2022-03-12','Withdrawal',900,0.01,NULL);
INSERT INTO Transactions (CardNumber, Account_number,TransactionID,Date,typeOfTransaction,Amount,Charges,TaxDeducted) Values (56001223145,808000160360,104,'2022-03-12','Withdrawal',2000,0.01,NULL);
INSERT INTO Transactions (CardNumber, Account_number,TransactionID,Date,typeOfTransaction,Amount,Charges,TaxDeducted) Values (56001223145,808000160360,105,'2022-03-12','Deposit',1900,NULL,0.12);
INSERT INTO Transactions (CardNumber, Account_number,TransactionID,Date,typeOfTransaction,Amount,Charges,TaxDeducted) Values (56001223029,808000160240,106,'2022-03-12','Withdrawal',100,0.01,NULL);
INSERT INTO Transactions (CardNumber, Account_number,TransactionID,Date,typeOfTransaction,Amount,Charges,TaxDeducted) Values (56001223000,808000160600,107,'2022-03-12','Deposit',8000,NULL,0.12);
INSERT INTO Transactions (CardNumber, Account_number,TransactionID,Date,typeOfTransaction,Amount,Charges,TaxDeducted) Values (56001223000,808000160600,108,'2022-03-12','Withdrawal',500,0.01,NULL);
INSERT INTO Transactions (CardNumber, Account_number,TransactionID,Date,typeOfTransaction,Amount,Charges,TaxDeducted) Values (56001223058,808000160300,109,'2022-03-12','Withdrawal',700,0.01,NULL);

SET IDENTITY_INSERT Transactions OFF
go

UPDATE Transactions
SET Balance = Account.Balance-(Amount*charges)
from Transactions, Account
where typeOfTransaction like 'W%' AND Transactions.Account_Number = Account.Account_Number
UPDATE Transactions
SET Balance = Account.Balance-(Amount*TaxDeducted)
from Transactions, Account
where typeOfTransaction like 'D%' AND Transactions.Account_Number = Account.Account_Number

select* from transactions

--Stored Procedures

Alter table Loan
Add Defaults varchar(50);

alter PROCEDURE DefalingCustomers
as
BEGIN
SELECT DefaultingCustomers.LoanID,Loan.LoanID
FROM   DefaultingCustomers, Loan
WHERE   DefaultingCustomers.LoanID = Loan.LoanID
 UPDATE Loan
 SET Defaults= 'Defaulting'
 WHERE LoanID IN (SELECT DefaultingCustomers.LoanID
                      FROM DefaultingCustomers INNER JOIN Loan
					  on DefaultingCustomers.LoanID = Loan.LoanID);
PRINT 'Customers are defaulting on their payments'
   
END

exec DefalingCustomers;
SELECT * FROM Loan

Create PROC TransactionForCustomer
AS
BEGIN
SELECT Transactions.TransactionID, Transactions.Date, Transactions.Amount, Transactions.Balance, Transactions.typeOfTransaction, Transactions.CardNumber,Customer_Account.CustomerID
FROM   Transactions INNER JOIN
       Account ON Transactions.Account_Number = Account.Account_number INNER JOIN
       Customer_Account ON Account.Account_number = Customer_Account.Account_number
WHERE CustomerID=201
END

EXEC TransactionForCustomer 

CREATE PROCEDURE CustLoan
as
BEGIN
 UPDATE Loan
 SET Status = 'APPROVED'
 WHERE Account_number IN (SELECT Account.Account_number 
                      FROM Account INNER JOIN Loan
                      ON Loan.Account_Number = Account.Account_number
					  WHERE Account.Balance>0.00);
END
EXEC CustLoan;


--OUTPUTS
--1.
Create VIEW CustomerAccountInformation
AS
SELECT Customer.CustomerID,Customer.First_Name,Customer.Last_name,Account.LocationID,
Account.Account_number,Customer_Account.Date_created
FROM  Customer_Account INNER JOIN
      Customer ON Customer_Account.CustomerID = Customer.CustomerID INNER JOIN
      Account ON Customer_Account.Account_number =Account.Account_number
GO

SELECT * FROM CustomerAccountInformation;

--2.
CREATE VIEW CustomerBalances
AS
SELECT dbo.Customer.CustomerID, dbo.Customer.First_Name, dbo.Customer.Last_name, dbo.Account.LocationID, dbo.Account.Account_Type, dbo.Account.Balance
FROM   dbo.Customer_Account INNER JOIN
       dbo.Customer ON dbo.Customer_Account.CustomerID = dbo.Customer.CustomerID INNER JOIN
       dbo.Account ON dbo.Customer_Account.Account_number = dbo.Account.Account_number

GO
SELECT * FROM CustomerBalances;
--3
CREATE VIEW [dbo].[LoanApprovalStatus]
AS
SELECT        status, LoanID, LocationID
FROM            dbo.Loan
WHERE        status = 'Approved'

GO

--4.
Create VIEW InterestPaid
AS
SELECT        LoanID, Amount, Amount*interestRate AS InterestPaid
FROM            dbo.Loan
Go

--5.
CREATE VIEW DefaultingCustomers
AS
SELECT  dbo.Loan.LocationID, dbo.Customer.First_Name, dbo.Customer.Last_name, dbo.Loan_MonthlyRepayment.MonthlyRepaymentAmount, dbo.Loan_MonthlyRepayment.LoanID
FROM    dbo.Loan INNER JOIN
         dbo.Loan_MonthlyRepayment ON dbo.Loan.LoanID = dbo.Loan_MonthlyRepayment.LoanID INNER JOIN
          dbo.Customer ON dbo.Loan.CustomerID = dbo.Customer.CustomerID
WHERE     (dbo.Loan_MonthlyRepayment.MonthlyRepaymentAmount = 0)
GO



--Database Functions

--Running Balance function

Alter FUNCTION RunningBAL (@CustomerID int)
RETURNS @RunningBalance TABLE
(
   CustomerID int,
   Account_Number bigint ,
   LocationID int,
   RunningBalance money, 
   MaxBal int,
   AvgBal int,
   MinBal int
   )
AS
BEGIN
declare @DepositAmount money
declare @WithdrawalAmount money
SELECT @DepositAmount = Amount From Transactions where typeOfTransaction like 'D%'
SELECT @WithdrawalAmount = Amount From Transactions where typeOfTransaction like 'W%'
INSERT @RunningBalance
SELECT        dbo.Customer_Account.CustomerID, dbo.Account.Account_number, dbo.Account.LocationID, (Account.Balance- @WithdrawalAmount)+ @DepositAmount, MAX((Account.Balance- @WithdrawalAmount)+ @DepositAmount), MIN((Account.Balance- @WithdrawalAmount)+ @DepositAmount), AVG((Account.Balance- @WithdrawalAmount)+ @DepositAmount)
FROM            dbo.Account INNER JOIN
                         dbo.Transactions ON dbo.Account.Account_number = dbo.Transactions.Account_Number INNER JOIN
                         dbo.Customer_Account ON dbo.Account.Account_number = dbo.Customer_Account.Account_number
WHERE   Customer_Account.CustomerID= @CustomerID
GROUP BY Customer_Account.CustomerID, Account.Account_number, Account.LocationID, Account.Balance
RETURN
END

SELECT *
FROM RunningBAL(201)


--Reports
--Customers who have cards and accounts

SELECT        dbo.Account.LocationID, dbo.Account.Account_Type, dbo.Cards.CardNumber, dbo.Cards.CardType, dbo.Customer.CustomerID, dbo.Customer.First_Name, dbo.Customer.Last_name, dbo.Customer_Account.Account_number, 
                         dbo.Customer_Contacts.Contact_Number
FROM            dbo.Account INNER JOIN
                         dbo.Customer_Account ON dbo.Account.Account_number = dbo.Customer_Account.Account_number INNER JOIN
                         dbo.Customer ON dbo.Customer_Account.CustomerID = dbo.Customer.CustomerID INNER JOIN
                         dbo.Customer_Card ON dbo.Customer.CustomerID = dbo.Customer_Card.CustomerID INNER JOIN
                         dbo.Cards ON dbo.Customer_Card.CardNumber = dbo.Cards.CardNumber INNER JOIN
                         dbo.Customer_Contacts ON dbo.Customer.CustomerID = dbo.Customer_Contacts.CustomerID


--customers who have loan 
SELECT         dbo.Customer.Last_name, dbo.Account.Account_number, dbo.Account.Account_Type, dbo.Loan.*, dbo.InterestPaid.InterestPaid
FROM            dbo.Customer INNER JOIN
                         dbo.Customer_Account ON dbo.Customer.CustomerID = dbo.Customer_Account.CustomerID INNER JOIN
                         dbo.Account ON dbo.Customer_Account.Account_number = dbo.Account.Account_number INNER JOIN
                         dbo.Loan ON dbo.Customer.CustomerID = dbo.Loan.CustomerID AND dbo.Account.Account_number = dbo.Loan.Account_Number INNER JOIN
                         dbo.Outlets ON dbo.Account.LocationID = dbo.Outlets.LocationID AND dbo.Loan.LocationID = dbo.Outlets.LocationID INNER JOIN
                         dbo.InterestPaid ON dbo.Loan.LoanID = dbo.InterestPaid.LoanID


--outlets normal customers go to
SELECT        dbo.Customer.First_Name, dbo.Customer.Last_name, dbo.Outlets.OutletName, dbo.Normal_Customers.NCustomerID, dbo.Normal_Customers.LocationID
FROM            dbo.Normal_Customers INNER JOIN
                         dbo.Customer ON dbo.Normal_Customers.NCustomerID = dbo.Customer.CustomerID INNER JOIN
                         dbo.Outlets ON dbo.Normal_Customers.LocationID = dbo.Outlets.LocationID

--private customers who have cards
SELECT        dbo.Customer.First_Name, dbo.Customer.Last_name, dbo.Private_Customers.Company, dbo.Customer_Card.CardNumber, dbo.Private_Customers.LocationID, 
dbo.Private_Customers.PCustomerID
FROM            dbo.Customer_Card INNER JOIN
                         dbo.Customer ON dbo.Customer_Card.CustomerID = dbo.Customer.CustomerID INNER JOIN
                         dbo.Private_Customers ON dbo.Customer.CustomerID = dbo.Private_Customers.PCustomerID



--private customer loan and application amount

SELECT        dbo.Outlets.OutletName, dbo.Private_Customers.PCustomerID, dbo.Private_Customers.Company, dbo.Loan.LoanID, dbo.Loan.Amount
FROM            dbo.Loan INNER JOIN
                         dbo.Outlets ON dbo.Loan.LocationID = dbo.Outlets.LocationID INNER JOIN
                         dbo.Private_Customers ON dbo.Outlets.LocationID = dbo.Private_Customers.LocationID

CREATE LOGIN BankSYS WITH
PASSWORD = '456';

CREATE USER UserBank FOR LOGIN BankSYS;

GRANT SELECT ON CustomerAccountInformation TO UserBank
GRANT SELECT ON CustomerBalances TO UserBank
GRANT SELECT ON DefaultingCustomers TO UserBank
GRANT SELECT ON InterestPaid TO UserBank
GRANT SELECT ON LoanApprovalStatus TO UserBank

EXECUTE AS USER = 'UserBank'
GO
SELECT * FROM LoanApprovalStatus;
SELECT * FROM InterestPaid;
