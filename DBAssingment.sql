USE master;

IF DB_ID('OrderProcessing') is not null 
BEGIN

EXEC msdb.dbo.sp_delete_database_backuphistory @database_name = N'OrderProcessing'

USE [master]

ALTER DATABASE [OrderProcessing] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
DROP DATABASE [OrderProcessing]

END

CREATE DATABASE OrderProcessing
GO

USE OrderProcessing
GO

CREATE TABLE dbo.Customer
(
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    FirstName NVARCHAR(100),
    LastName NVARCHAR(100),
    IsGuest BIT NOT NULL DEFAULT 0,
    IsEnabled BIT NOT NULL DEFAULT 1,
    DOB DATE NOT NULL,
    EmailAddress NVARCHAR(200) NOT NULL,
    CreatedDate DATETIME DEFAULT SYSUTCDATETIME(),
    CONSTRAINT NAME_CHECK CHECK(
                                    (IsGuest=1 AND FirstName IS NULL AND LastName IS NULL)
                                OR (IsGuest=0 AND FirstName IS NOT NULL AND LastName IS NOT NULL)
                              ),
    CONSTRAINT EMAIL_CHECK CHECK(CHARINDEX('@',EmailAddress)>0),
    CONSTRAINT DOB_CHECK CHECK(DATEDIFF(YEAR,DOB,GETDATE())>=18)

)
GO
CREATE UNIQUE NONCLUSTERED INDEX NCIX_UQ_CUSTOMER ON dbo.Customer(EmailAddress);
GO

CREATE TABLE dbo.CustomerAddress
(
    Id INT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    CustomerId INT NOT NULL,
    AddressType VARCHAR(10) NOT NULL,
    AddressLevel1 NVARCHAR(100) NOT NULL,
    AddressLevel2 NVARCHAR(100) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    CountryCode VARCHAR(100) NOT NULL,
    CONSTRAINT Address_Type_Check CHECK ( (CHARINDEX('Delivery',AddressType)>0) OR (CHARINDEX('Billing',AddressType)>0) ),
    CONSTRAINT FK_CAD_CUST FOREIGN KEY (CustomerId) REFERENCES dbo.Customer(Id)
)
GO

CREATE TABLE dbo.Product 
(
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(255) NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    CN22Category NVARCHAR(50) NOT NULL,
    ProductType NVARCHAR(50) NOT NULL,
    ManufacturedBy NVARCHAR(255) NOT NULL
)
GO
CREATE UNIQUE NONCLUSTERED INDEX NCIX_UQ_PROD on dbo.Product(Name);
GO
CREATE TABLE dbo.OrderStatus
(

    Id SMALLINT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    [Description] VARCHAR(10) NOT NULL,

)
GO
CREATE TABLE dbo.OrderHeader
(
    Id UNIQUEIDENTIFIER  PRIMARY KEY CLUSTERED,
    WebsiteId VARCHAR(10) NOT NULL,
    CreatedDate DATETIME NOT NULL DEFAULT SYSUTCDATETIME(),
    CustomerId INT NOT NULL,
    CustomerAddressId INT NOT NULL,
    OrderStatusId SMALLINT NOT NULL,
    DispatchedDate DATETIME NULL,
    UpdateDate DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_OH_CUST FOREIGN KEY (CustomerId) REFERENCES dbo.Customer(Id),
    CONSTRAINT FK_OH_CAD FOREIGN KEY (CustomerAddressId) REFERENCES dbo.CustomerAddress(Id),
    CONSTRAINT FK_OH_STAT FOREIGN KEY (OrderStatusId) REFERENCES dbo.OrderStatus(Id)
)
GO
CREATE NONCLUSTERED INDEX NCIX_CUST_LOOKUP ON dbo.OrderHeader(CustomerId)
GO
CREATE NONCLUSTERED INDEX NCIX_CAD_LOOKUP ON dbo.OrderHeader(CustomerAddressId)
GO
CREATE NONCLUSTERED INDEX NCIX_STAT_LOOKUP ON dbo.OrderHeader(OrderStatusId)
GO

CREATE TABLE dbo.OrderLine
(
    OrderId UNIQUEIDENTIFIER NOT NULL,
    ProductId INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT PK_OL PRIMARY KEY CLUSTERED(OrderId,ProductId),
    CONSTRAINT FK_OL_OH FOREIGN KEY (OrderId) REFERENCES dbo.OrderHeader(Id)
)
CREATE NONCLUSTERED INDEX NCIX_OID on dbo.OrderLine(OrderId)

GO

INSERT INTO dbo.OrderStatus([Description])
VALUES
('Placed'),
('Picked'),
('Packed'),
('Dispatched'),
('Cancelled')

GO

GO
SET IDENTITY_INSERT dbo.Product ON ;
INSERT INTO Product (Id, Name, Price, CN22Category, ProductType, ManufacturedBy)
VALUES
    (1, 'Lipstick', 9.99, 'Cosmetics', 'Makeup', 'ABC Beauty Co.'),
    (2, 'Moisturizer', 15.49, 'Skin Care', 'Cream', 'XYZ Skincare Inc.'),
    (3, 'Shampoo', 8.75, 'Hair Care', 'Shampoo', 'HairCare Ltd.'),
    (4, 'Perfume', 24.99, 'Fragrance', 'Eau de Parfum', 'Fragrance World'),
    (5, 'Nail Polish', 12.00, 'Cosmetics', 'Nail', 'Nail Artisans'),
    (6, 'Sunscreen', 19.95, 'Skin Care', 'Lotion', 'SunSafe Ltd.'),
    (7, 'Hair Conditioner', 7.99, 'Hair Care', 'Conditioner', 'HairCare Ltd.'),
    (8, 'Foundation', 14.50, 'Cosmetics', 'Makeup', 'ABC Beauty Co.'),
    (9, 'Face Mask', 9.99, 'Skin Care', 'Mask', 'XYZ Skincare Inc.'),
    (10, 'Cologne', 17.25, 'Fragrance', 'Eau de Toilette', 'Fragrance World'),
    (11, 'Mascara', 11.49, 'Cosmetics', 'Makeup', 'ABC Beauty Co.'),
    (12, 'Hand Cream', 22.95, 'Skin Care', 'Cream', 'XYZ Skincare Inc.'),
    (13, 'Hair Gel', 6.99, 'Hair Care', 'Gel', 'HairCare Ltd.'),
    (14, 'Eye Shadow', 13.75, 'Cosmetics', 'Makeup', 'ABC Beauty Co.'),
    (15, 'Body Lotion', 18.50, 'Skin Care', 'Lotion', 'XYZ Skincare Inc.'),
    (16, 'Cleanser', 8.49, 'Skin Care', 'Cleanser', 'XYZ Skincare Inc.'),
    (17, 'Hair Serum', 16.00, 'Hair Care', 'Serum', 'HairCare Ltd.'),
    (18, 'Blush', 9.95, 'Cosmetics', 'Makeup', 'ABC Beauty Co.'),
    (19, 'Lip Balm', 14.99, 'Cosmetics', 'Lip Care', 'XYZ Skincare Inc.'),
    (20, 'Eau de Cologne', 23.25, 'Fragrance', 'Eau de Cologne', 'Fragrance World');

    SET IDENTITY_INSERT dbo.Product OFF;
GO

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
    ('Manchester', 'United Kingdom'),
    ('Liverpool', 'United Kingdom'),
    ('Warrington', 'United Kingdom'),
    ('Preston', 'United Kingdom'),
    ('Runcorn', 'United Kingdom'),
    ('Chester', 'United Kingdom'),
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
DECLARE @CustomerCounter int =1
WHILE @CustomerCounter<=@NumberOfCustomers
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
SET @CustomerCounter=@CustomerCounter+1
END



DECLARE @NumberOfOrders INT = 1000;

CREATE TABLE #SelectedCustomers (CustomerId INT);
CREATE TABLE #SelectedProducts (ProductId INT);

INSERT INTO #SelectedCustomers (CustomerId)
SELECT  C.Id
FROM dbo.Customer C
ORDER BY NEWID();



INSERT INTO #SelectedProducts (ProductId)
SELECT TOP (@NumberOfOrders * 2) Id
FROM dbo.Product
ORDER BY NEWID();

DECLARE @Counter INT = 1;

WHILE @Counter <= @NumberOfOrders
BEGIN
    DECLARE @CustomerId INT;
    DECLARE @NumberOfProducts int =(SELECT FLOOR(RAND() * 40) + 1 )
    DECLARE @OrderStatusId smallint=(SELECT top (1) Id from dbo.OrderStatus Order By NEWID())
    DECLARE @DispatchStatusId SMALLINT=(SELECT Id from dbo.OrderStatus WHERE [Description]='Dispatched')
    SELECT TOP 1 @CustomerId = CustomerId FROM #SelectedCustomers ORDER BY NEWID();
    DECLARE @DispatchDate DATETIME=(SELECT DATEADD(DAY,-FLOOR(RAND() * 40) + 1,SYSUTCDATETIME()))


    DECLARE @OrderId UNIQUEIDENTIFIER;
    SET @OrderId = NEWID();
    INSERT INTO dbo.OrderHeader (Id,WebsiteId, CreatedDate, CustomerId, CustomerAddressId, OrderStatusId, DispatchedDate, UpdateDate)
    VALUES
        (
            @OrderId,
            'Website1', 
            CASE 
                WHEN @OrderStatusId=@DispatchStatusId
                THEN DATEADD(DAY,-FLOOR(RAND() * 7) + 1,@DispatchDate)
                ELSE SYSUTCDATETIME() 
            END, 
            @CustomerId, 
            (SELECT Id FROM dbo.CustomerAddress WHERE CustomerId = @CustomerId AND AddressType = 'Delivery'), 
            @OrderStatusId, 
            CASE 
                WHEN @DispatchStatusId=@OrderStatusId 
                THEN @DispatchDate 
                ELSE NULL 
            END, 
            SYSUTCDATETIME());

    

    INSERT INTO dbo.OrderLine (OrderId, ProductId, Quantity, UnitPrice)
    SELECT TOP (@NumberOfProducts)
        @OrderId,
        P.Id,
        FLOOR(RAND() * 5) + 1,
        Price
    FROM dbo.Product P
    ORDER BY NEWID()

    SET @Counter = @Counter + 1;
END;

DROP TABLE IF EXISTS #SelectedCustomers;
DROP TABLE IF EXISTS #SelectedProducts;



GO
CREATE VIEW dbo.vw_GetDistinctGBCity

AS

/*
9.zdefiniowane 1 widoku (CREATE VIEW), który pokaże dane z wykorzystaniem funkcji DISTINCT oraz filtrowania wierszy WHERE.
*/

SELECT DISTINCT 
City
FROM dbo.CustomerAddress
WHERE CountryCode='United Kingdom'

GO

CREATE VIEW dbo.vw_GetCustomerAge

AS

/*
10.  zdefiniowane 1 widoku (CREATE VIEW), który pokaże dane z wykorzystaniem wbudowanych funkcji daty i czasu np. DATEDIFF, YEAR itd.
*/

SELECT 
*,
DATEDIFF(YEAR,DOB,GETDATE()) as CustomerAge
FROM dbo.Customer

go

CREATE VIEW dbo.vw_GetEamilDomain

AS

/*
11.  zdefiniowane 1 widoku (CREATE VIEW), który pokaże dane z wykorzystaniem wbudowanych  funkcji operacji na tekście np. SUBSTRING, CHARINDEX, LEFT itd.
*/

SELECT 
*,
LEFT(SUBSTRING(EmailAddress,CHARINDEX('@',EmailAddress)+1,LEN(EmailAddress)-CHARINDEX('@',EmailAddress)+1),CHARINDEX('.',SUBSTRING(EmailAddress,CHARINDEX('@',EmailAddress)+1,LEN(EmailAddress)-CHARINDEX('@',EmailAddress)+1))-1) EmailDomain
FROM dbo.Customer

GO
CREATE VIEW dbo.vw_CustomerAgeBucket

AS
/*
12.  zdefiniowane 1 widoku (CREATE VIEW), który pokaże dane z wykorzystaniem funkcji CASE.
*/

SELECT 
*,
CASE 
    WHEN CustomerAge<30 THEN 'Under 30'
    WHEN CustomerAge<40 THEN 'Under 40'
    WHEN CustomerAge<50 THEN 'Under 50'
    ELSE 'Over 50'
END as AgeBucket
FROM dbo.vw_GetCustomerAge

go

CREATE VIEW dbo.vw_GetCustomerOrderSequence
as 
/*zdefiniowane 1 widoku, który pokaże dane połączone (JOIN) z co najmniej 4 tabel oraz wykorzysta FUNKCJE OKNA.*/

SELECT 
CASE WHEN IsGuest=1 THEN 'Guest Customer' ELSE  CONCAT(C.FirstName,' ',C.LastName) END AS CustomerName, 
C.EmailAddress,
OH.Id as OrderId,
OH.WebsiteId,
CA.CountryCode,
OH.CreatedDate as OrderDate,
OST.[Description] as OrderStatusDescription,
ROW_NUMBER() OVER(partition by C.id Order By OH.CreatedDate ASC) as OrderSequence
FROM dbo.OrderHeader OH
inner join dbo.Customer C on C.Id=OH.CustomerId
inner join dbo.CustomerAddress CA on CA.Id=OH.CustomerAddressId
Inner join dbo.OrderStatus OST on OST.Id=OH.OrderStatusId
go


GO
CREATE VIEW dbo.vw_CustomerSpend
AS

/*
14.   zdefiniowane 1 widoku, który pokaże dane zgrupowane (GROUP BY), wykorzysta funkcję agregującą (np. SUM, COUNT) oraz połączy dane z 2 tabel (JOIN).
*/

SELECT 
CASE WHEN IsGuest=1 THEN 'Guest Customer' ELSE  CONCAT(C.FirstName,' ',C.LastName) END AS CustomerName, 
C.EmailAddress,
COUNT(DISTINCT(OH.Id)) as NumberOfOrders,
SUM(OL.Quantity*UnitPrice) As TotalValue
FROM dbo.OrderHeader OH 
inner join dbo.Customer C on C.Id=OH.CustomerId
inner join dbo.OrderLine OL on OL.OrderId=OH.Id

group by 
CASE WHEN IsGuest=1 THEN 'Guest Customer' ELSE  CONCAT(C.FirstName,' ',C.LastName) END ,
C.EmailAddress
GO


CREATE VIEW dbo.vw_OutstandingOrders

AS

/*15. zdefiniowane 1 widoku, który pokaże dane połączone (wykorzystać JOIN) z co najmniej 4 tabel i wykona PODZAPYTANIE w kaluzuli FROM, WHERE lub SELECT.*/

SELECT 
OH.Id as OrderId,
CASE WHEN IsGuest=1 THEN 'Guest Customer' ELSE  CONCAT(C.FirstName,' ',C.LastName) END AS CustomerName, 
AddressLevel1,
AddressType,
City,
CountryCode,
ProductId,
P.Name as ProductName,
Quantity*UnitPrice as LineValue
FROM dbo.OrderHeader OH
inner join Customer C on C.Id=OH.CustomerId
inner join dbo.CustomerAddress A on A.Id=OH.CustomerAddressId
Inner join dbo.OrderLine OL on OL.OrderId=OH.Id
Inner join dbo.Product P on P.Id=OL.ProductId
WHERE EXISTS(SELECT 1 FROM dbo.OrderStatus OST WHERE OST.Id=OH.OrderStatusId and OST.[Description] NOT in ('Dispatched','Cancelled'))

GO



CREATE PROCEDURE dbo.usp_UpsertProduct
(
    @Name NVARCHAR(255),
    @Price DECIMAL(10, 2),
    @CN22Category NVARCHAR(50),
    @ProductType NVARCHAR(50),
    @ManufacturedBy NVARCHAR(255),
    @ProductId INT NULL 
)

AS

/*16. zdefiniowane 1 dowolnej procedury składowanej, która będzie miała minimum 3 parametry oraz będzie modyfikowała dane (np. dopisanie nowego klienta lub produktu).*/

BEGIN TRY
IF NOT EXISTS(SELECT 1 FROM dbo.Product P WHERE Name=@Name)
    BEGIN 
        INSERT INTO dbo.Product(Name,Price,CN22Category,ProductType,ManufacturedBy)
        VALUES(@Name,@Price,@CN22Category,@ProductType,@ManufacturedBy)
    END

IF EXISTS(SELECT 1 FROM dbo.Product P WHERE P.Id=@ProductId)
BEGIN
    UPDATE DST
        SET
            DST.Name=@Name,
            DST.CN22Category=@CN22Category,
            DST.ManufacturedBy=@ManufacturedBy,
            DST.Price=@Price,
            DST.ProductType=@ProductType

    FROM dbo.Product DST
    WHERE DST.Id=@ProductId
END

END TRY

BEGIN CATCH
    IF @@TRANCOUNT>0 
    BEGIN 
        ROLLBACK
    END
    SELECT
     ERROR_NUMBER() AS ErrorNumber  
    ,ERROR_SEVERITY() AS ErrorSeverity  
    ,ERROR_STATE() AS ErrorState  
    ,ERROR_PROCEDURE() AS ErrorProcedure  
    ,ERROR_LINE() AS ErrorLine  
    ,ERROR_MESSAGE() AS ErrorMessage;  

END CATCH

GO

CREATE FUNCTION dbo_fnGetCustomerOrdersValueInTimeAndStatus
(
    @CustomerId INT,
    @DateTo DATETIME,
    @Status VARCHAR(10)

)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @TotalOrderValue DECIMAL(10, 2);

    SELECT @TotalOrderValue = SUM(ol.Quantity * p.Price)
    FROM dbo.OrderHeader oh
    INNER JOIN dbo.OrderLine ol ON oh.Id = ol.OrderId
    INNER JOIN dbo.Product p ON ol.ProductId = p.Id
    WHERE oh.CustomerId = @CustomerId
      AND oh.CreatedDate <= @DateTo
      AND oh.OrderStatusId = (SELECT Id FROM dbo.OrderStatus WHERE [Description] = @Status);

    RETURN ISNULL(@TotalOrderValue, 0);
END;

GO


CREATE VIEW dbo.vw_getValueOfCustomerDispatchedOrders

as

SELECT 
CASE WHEN IsGuest=1 THEN 'Guest Customer' ELSE  CONCAT(C.FirstName,' ',C.LastName) END AS CustomerName, 
C.EmailAddress,
A.AddressLevel1,
A.AddressLevel2,
A.City,
A.CountryCode,
dbo.dbo_fnGetCustomerOrdersValueInTimeAndStatus(C.Id,GETDATE(),'Dispatched') As DispatchedValue
FROM dbo.Customer C 
inner join dbo.CustomerAddress A on C.Id=A.CustomerId
WHERE AddressType NOT LIKE'Billing%' 


GO
