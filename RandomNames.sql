Use OrderProcessing
GO

drop table if exists #FirstNames

CREATE TABLE #FirstNames (
    Id INT IDENTITY(1, 1) PRIMARY KEY,
    FirstName NVARCHAR(50) NOT NULL,
    Language NVARCHAR(50) NOT NULL
)

INSERT INTO #FirstNames (FirstName, Language)
VALUES
    ('John', 'English'),
    ('Emily', 'English'),
    ('Michael', 'English'),
    ('Sophia', 'English'),
    ('Liam', 'English'),
    ('Hannah', 'English'),
    ('Ella', 'English'),
    ('Luca', 'Italian'),
    ('Mia', 'Italian'),
    ('Alessandro', 'Italian'),
    ('Emma', 'Italian'),
    ('David', 'German'),
    ('Laura', 'German'),
    ('Maximilian', 'German'),
    ('Giulia', 'Italian'),
    ('Sophie', 'German'),
    ('Leo', 'German'),
    ('Matteo', 'Italian'),
    ('Isabella', 'Italian'),
    ('William', 'English'),
    ('Olivia', 'English'),
    ('Benjamin', 'German'),
    ('Leon', 'German'),
    ('Lina', 'German'),
    ('Lorenzo', 'Italian'),
    ('Hugo', 'German'),
    ('Noah', 'German'),
    ('Ava', 'English'),
    ('Stella', 'German');


drop table if exists #Surnames

CREATE TABLE #Surnames (
    Id INT IDENTITY(1, 1) PRIMARY KEY,
    Surname NVARCHAR(50) NOT NULL,
    Language NVARCHAR(50) NOT NULL
);

INSERT INTO #Surnames (Surname, Language)
VALUES
    ('Smith', 'English'),
    ('Johnson', 'English'),
    ('Brown', 'English'),
    ('Taylor', 'English'),
    ('Miller', 'English'),
    ('Anderson', 'English'),
    ('Davis', 'English'),
    ('Wilson', 'English'),
    ('Moore', 'English'),
    ('Martin', 'English'),
    ('Harris', 'English'),
    ('Thompson', 'English'),
    ('White', 'English'),
    ('Clark', 'English'),
    ('Walker', 'English'),
    ('Hall', 'English'),
    ('Young', 'English'),
    ('Lee', 'English'),
    ('King', 'English'),
    ('Green', 'English'),
    ('Lewis', 'English'),
    ('Baker', 'English'),
    ('Wright', 'English'),
    ('Evans', 'English'),
    ('Turner', 'English'),
    ('Parker', 'English'),
    ('Cook', 'English'),
    ('Murphy', 'English'),
    ('Hill', 'English'),
    ('Adams', 'English');

drop table if exists #CityCountry
CREATE TABLE #CityCountry (
    Id INT IDENTITY(1, 1) PRIMARY KEY,
    City NVARCHAR(100) NOT NULL,
    Country NVARCHAR(100) NOT NULL
);

INSERT INTO #CityCountry (City, Country)
VALUES
    ('New York', 'United States'),
    ('London', 'United Kingdom'),
    ('Paris', 'France'),
    ('Berlin', 'Germany'),
    ('Rome', 'Italy'),
    ('Tokyo', 'Japan'),
    ('Sydney', 'Australia'),
    ('Toronto', 'Canada'),
    ('Amsterdam', 'Netherlands'),
    ('Madrid', 'Spain'),
    ('Beijing', 'China'),
    ('Moscow', 'Russia'),
    ('Dubai', 'United Arab Emirates'),
    ('Mumbai', 'India'),
    ('Sao Paulo', 'Brazil'),
    ('Cairo', 'Egypt'),
    ('Buenos Aires', 'Argentina'),
    ('Johannesburg', 'South Africa'),
    ('Stockholm', 'Sweden'),
    ('Oslo', 'Norway');

drop table if exists #StreetNames 
CREATE TABLE #StreetNames (
    Id INT IDENTITY(1, 1) PRIMARY KEY,
    StreetName NVARCHAR(100) NOT NULL
);

INSERT INTO #StreetNames (StreetName)
VALUES
    ('Main Street'),
    ('Oak Avenue'),
    ('Maple Road'),
    ('Cedar Lane'),
    ('Elm Street'),
    ('Pine Avenue'),
    ('Birch Road'),
    ('Willow Lane'),
    ('River Street'),
    ('Lake Avenue'),
    ('Forest Road'),
    ('Hill Lane'),
    ('Meadow Street'),
    ('Sunset Avenue'),
    ('Park Road'),
    ('Grove Lane'),
    ('Highland Street'),
    ('Spring Avenue'),
    ('Brook Road'),
    ('Valley Lane');

--FirstName, LastName, IsGuest, IsEnabled, DOB, EmailAddress

DROP TABLE IF EXISTS #EmailDomains
CREATE TABLE #EmailDomains
(
    Domain VARCHAR(20)
)
INSERT INTO #EmailDomains(Domain)
VALUES
('outlook.com'),
('google.com'),
('icloud.com'),
('onet.pl')
GO
DROP FUNCTION IF EXISTS dbo.GenerateRandomDOB
GO
CREATE FUNCTION dbo.GenerateRandomDOB(@Random FLOAT)
RETURNS DATE
AS
BEGIN
    DECLARE @MinAge INT = 18;
    DECLARE @MaxAge INT = 65;
    DECLARE @StartDate DATE = DATEADD(YEAR, -@MaxAge, GETDATE());
    DECLARE @EndDate DATE = DATEADD(YEAR, -@MinAge, GETDATE());
    DECLARE @RandomDOB DATE;
    

    SELECT @RandomDOB = DATEADD(DAY,@Random * DATEDIFF(DAY, @StartDate, @EndDate), @StartDate);

    RETURN @RandomDOB;
END;
GO


DECLARE @NumberOfCustomers INT =337 /*needs to be less than 400*/
DECLARE @Counter int =1
WHILE @Counter<=@NumberOfCustomers
BEGIN
Drop table if exists #CustomerId
CREATE TABLE #CustomerId(Id int )
DECLARE @RAND FLOAT=RAND()


Insert into dbo.Customer(FirstName,LastName,DOB,EmailAddress)
OUTPUT inserted.Id into #CustomerId

SELECT TOP (1)
FirstName,
Surname,
DOB,
EmailAddress
FROM (
select  
FirstName,
Surname,
dbo.GenerateRandomDOB(@RAND) as DOB,
CONCAT(FirstName,'.',Surname,'@',D.Domain) as EmailAddress
from #FirstNames F
CROSS JOIN #Surnames S
CROSS JOIN #EmailDomains D
)D
WHERE NOT EXISTS(SELECT 1 FROM dbo.Customer C WHERE C.EmailAddress=D.EmailAddress AND C.FirstName=D.FirstName AND C.LastName=D.Surname)
IF @@ROWCOUNT=0 BREAK

DECLARE @FlatNumber int =FLOOR(RAND() * 100) + 1

--CustomerId, AddressType, AddressLevel1, AddressLevel2, City, CountryCode)
INSERT INTO dbo.CustomerAddress(CustomerId,AddressType,AddressLevel1,AddressLevel2,City,CountryCode)

SELECT TOP (1)
(SELECT Id FROM #CustomerId),
'Delivery',
CONCAT('Flat ', @FlatNumber),
StreetName,
City,
Country
FROM #CityCountry CT
CROSS APPLY #StreetNames ST
WHERE NOT EXISTS
    (
        SELECT 1 
        FROM dbo.CustomerAddress A 
        WHERE 
            A.AddressLevel1=CONCAT('Flat ', @FlatNumber) 
        AND AddressLevel2=StreetName and A.City=CT.City 
        AND A.CountryCode=CT.Country
    )
ORDER BY NEWID()
SET @Counter=@Counter+1
END
