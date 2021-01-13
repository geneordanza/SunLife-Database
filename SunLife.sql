
--                           [ TABLE OF CONTENTS ]
-- SQLite Default Settings
-- Schema for Table Creation

-- Trigger for computing Age columns
-- Trigger for computing FRONT-END deduction

-- Trigger for computing Deductions/NetInv/Shares in Investments table

-- Trigger for computing FundValue/GainLoss/ROI in Investment w/ INDEX_FUND
-- Trigger for computing FundValue/GainLoss/ROI in Investment w/ EQUITY_FUND
-- Trigger for computing FundValue/GainLoss/ROI in Investment w/ MM_FUND
-- Trigger for computing FundValue/GainLoss/ROI in Investment w/ WEIF_FUND

-- Trigger for updating FundValue/GainLoss/ROI in Investment w/ INDEX_FUND
-- Trigger for updating FundValue/GainLoss/ROI in Investment w/ EQUITY_FUND
-- Trigger for updating FundValue/GainLoss/ROI in Investment w/ MM_FUND
-- Trigger for updating FundValue/GainLoss/ROI in Investment w/ WEIF_FUND

-- Test Data for Sun Life Database
-- Debugging Output


--                      [ ---------------------------- ]

-- SQLite Default Settings
PRAGMA foreign_keys = ON;
.echo off
.mode col
.headers on
.nullvalue NULL
.print ''

--                      [ ---------------------------- ]

-- Schema for Table Creation

DROP TABLE IF EXISTS Clients;
DROP TABLE IF EXISTS FundTypes;
DROP TABLE IF EXISTS Investments;
DROP TABLE IF EXISTS NAVPS;

-- Table Schemas
CREATE TABLE IF NOT EXISTS Clients (
  Client_ID integer primary key,
  Title text,
  FirstName text,
  LastName text,
  Email text,
  Phone text,
  Birthday date,
  Age integer,
  Address text,
  Province text,
  Description text
);

CREATE TABLE IF NOT EXISTS FundTypes (
  Fund_ID text primary key,
  Name text,
  Minimum integer,
  Tolerance text,
  Description text
);

CREATE TABLE IF NOT EXISTS NAVPS (
  NAVPS_ID integer primary key,
  Timestamp date default (date('now', 'localtime')),
  Fund_ID text
     CONSTRAINTS CHECK (Fund_ID IN
       ("BOND_FUND", "BALANCE_FUND", "EQUITY_FUND", "MM_FUND",
        "INDEX_FUND", "WEIF_FUND")
     ),
  LNAVPS integer,
  Note text,

  FOREIGN KEY (Fund_ID) REFERENCES FundTypes(Fund_ID)
);

CREATE TABLE IF NOT EXISTS Investments (
  Invest_ID integer primary key,
  Client_ID integer,
  Fund_ID text,
  TransactType text
     CONSTRAINTS CHECK (TransactType IN
       ("SUBSCRIPTION", "SWITCHIN", "SWITCHOUT", "REDEMPTION")
     ),
  ApplicationID integer
     CONSTRAINTS CHECK(length (ApplicationID) == 14),
  TransactDate date
     CONSTRAINTS CHECK(TransactDate == strftime('%Y-%m-%d', TransactDate)),
  SalesLoadType text
     CONSTRAINTS CHECK (SalesLoadType IN
       ('FRONT-END', 'BACK-END', 'NOLOAD', 'ADVISOR')
     ),
  SalesLoadDeduct integer,
  Deduction integer,
  GrossInv integer,
  NetInv integer,
  ANAVPS integer,
  Shares integer,
  LNAVPS integer,
  FundValue real,
  ROI real,
  GainLoss real,

  FOREIGN KEY (Fund_ID) REFERENCES FundTypes(Fund_ID),
  FOREIGN KEY (Client_ID) REFERENCES Clients(Client_ID)
);


--                      [ ---------------------------- ]

-- Trigger for computing Age columns

CREATE TRIGGER IF NOT EXISTS trg_compute_age
AFTER INSERT ON Clients
BEGIN
  UPDATE Clients set Age = cast(strftime('%Y.%m%d', 'now')
                              - strftime('%Y.%m%d', new.Birthday) as int)
  WHERE Age = 0;
END;

-- Trigger for computing FRONT-END deduction

CREATE TRIGGER IF NOT EXISTS trg_compute_frontend_deduction
AFTER UPDATE ON Investments
WHEN new.SalesLoadType == 'FRONT-END'
BEGIN
      UPDATE Investments set SalesLoadDeduct = .0224
      WHERE new.GrossInv <= 100000 and SalesLoadDeduct IS NULL;
END;

--                      [ ---------------------------- ]

-- Trigger for computing Deductions/NetInv/Shares in Investments table
-- After new data is inserted in Investments table
CREATE TRIGGER IF NOT EXISTS trg_compute_deduction
AFTER INSERT ON Investments
BEGIN
  UPDATE Investments set Deduction = SalesLoadDeduct * new.GrossInv
  WHERE Deduction IS NULL;
  UPDATE Investments set NetInv = new.GrossInv - Deduction
  WHERE NetInv IS NULL;
  UPDATE Investments set Shares = round(NetInv / ANAVPS)
  WHERE Shares IS NULL;
END;


--                      [ ---------------------------- ]

-- Trigger for computing FundValue/GainLoss/ROI in Investment w/ INDEX_FUND
-- When there's new data in Investments and FundValue/GainLoss/ROI is still
-- empty, run the Trigger to compute these values
CREATE TRIGGER IF NOT EXISTS trg_fundvalue_indexfund
AFTER INSERT ON NAVPS
WHEN new.Fund_ID == 'INDEX_FUND'
BEGIN
  UPDATE Investments set LNAVPS = new.LNAVPS
  WHERE LNAVPS IS NULL AND Fund_ID = 'INDEX_FUND';
  UPDATE Investments set FundValue = cast(Shares as integer) * LNAVPS
  WHERE FundValue IS NULL;
  UPDATE Investments set GainLoss = FundValue - GrossInv
  WHERE GainLoss IS NULL;
  UPDATE Investments set ROI = (GainLoss / GrossInv) * 100
  WHERE ROI IS NULL;
END;

-- Trigger for computing FundValue/GainLoss/ROI in Investment w/ EQUITY_FUND
-- When there's new data in Investments and FundValue/GainLoss/ROI is still
-- empty, run the Trigger to compute these values
CREATE TRIGGER IF NOT EXISTS trg_fundvalue_equityfund
AFTER INSERT ON NAVPS
WHEN new.Fund_ID == 'EQUITY_FUND'
BEGIN
  UPDATE Investments set LNAVPS = new.LNAVPS
  WHERE LNAVPS IS NULL AND Fund_ID = 'EQUITY_FUND';
  UPDATE Investments set FundValue = cast(Shares as integer) * LNAVPS
  WHERE FundValue IS NULL;
  UPDATE Investments set GainLoss = FundValue - GrossInv
  WHERE GainLoss IS NULL;
  UPDATE Investments set ROI = (GainLoss / GrossInv) * 100
  WHERE ROI IS NULL;
END;

-- Trigger for computing FundValue/GainLoss/ROI in Investment w/ MM_FUND
-- When there's new data in Investments and FundValue/GainLoss/ROI is still
-- empty, run the Trigger to compute these values
CREATE TRIGGER IF NOT EXISTS trg_fundvalue_mmfund
AFTER INSERT ON NAVPS
WHEN new.Fund_ID == 'MM_FUND'
BEGIN
  UPDATE Investments set LNAVPS = new.LNAVPS
  WHERE LNAVPS IS NULL AND Fund_ID = 'MM_FUND';
  UPDATE Investments set FundValue = cast(Shares as integer) * LNAVPS
  WHERE FundValue IS NULL;
  UPDATE Investments set GainLoss = FundValue - GrossInv
  WHERE GainLoss IS NULL;
  UPDATE Investments set ROI = (GainLoss / GrossInv) * 100
  WHERE ROI IS NULL;
END;

-- Trigger for computing FundValue/GainLoss/ROI in Investment w/ WEIF_FUND
-- When there's new data in Investments and FundValue/GainLoss/ROI is still
-- empty, run the Trigger to compute these values
CREATE TRIGGER IF NOT EXISTS trg_fundvalue_weiffund
AFTER INSERT ON NAVPS
WHEN new.Fund_ID == 'WEIF_FUND'
BEGIN
  UPDATE Investments set LNAVPS = new.LNAVPS
  WHERE LNAVPS IS NULL AND Fund_ID = 'WEIF_FUND';
  UPDATE Investments set FundValue = cast(Shares as integer) * LNAVPS
  WHERE FundValue IS NULL;
  UPDATE Investments set GainLoss = FundValue - GrossInv
  WHERE GainLoss IS NULL;
  UPDATE Investments set ROI = (GainLoss / GrossInv) * 100
  WHERE ROI IS NULL;
END;

--       [ --------------------------------------------------------- ]

-- Trigger for updating FundValue/GainLoss/ROI in Investment w/ INDEX_FUND
-- Update previous/existing FundValue/GainLoss/ROI using latest LNAVPS
CREATE TRIGGER IF NOT EXISTS trg_LatestNAVPS_indexfund
AFTER INSERT ON NAVPS
WHEN new.Fund_ID == 'INDEX_FUND'
BEGIN
  UPDATE Investments set LNAVPS = new.LNAVPS
  WHERE Fund_ID = 'INDEX_FUND';
  UPDATE Investments set FundValue = cast(Shares as integer) * LNAVPS;
  UPDATE Investments set GainLoss = FundValue - GrossInv;
  UPDATE Investments set ROI = (GainLoss / GrossInv) * 100;
END;

-- Trigger for updating FundValue/GainLoss/ROI in Investment w/ EQUITY_FUND
-- Update previous/existing FundValue/GainLoss/ROI using latest LNAVPS
CREATE TRIGGER IF NOT EXISTS trg_LatestNAVPS_equityfund
AFTER INSERT ON NAVPS
WHEN new.Fund_ID == 'EQUITY_FUND'
BEGIN
  UPDATE Investments set LNAVPS = new.LNAVPS
  WHERE Fund_ID = 'EQUITY_FUND';
  UPDATE Investments set FundValue = cast(Shares as integer) * LNAVPS;
  UPDATE Investments set GainLoss = FundValue - GrossInv;
  UPDATE Investments set ROI = (GainLoss / GrossInv) * 100;
END;

-- Trigger for updating FundValue/GainLoss/ROI in Investment w/ MM_FUND
-- Update previous/existing FundValue/GainLoss/ROI using latest LNAVPS
CREATE TRIGGER IF NOT EXISTS trg_LatestNAVPS_mmfund
AFTER INSERT ON NAVPS
WHEN new.Fund_ID == 'MM_FUND'
BEGIN
  UPDATE Investments set LNAVPS = new.LNAVPS
  WHERE Fund_ID = 'MM_FUND';
  UPDATE Investments set FundValue = cast(Shares as integer) * LNAVPS;
  UPDATE Investments set GainLoss = FundValue - GrossInv;
  UPDATE Investments set ROI = (GainLoss / GrossInv) * 100;
END;


-- Trigger for updating FundValue/GainLoss/ROI in Investment w/ WEIF_FUND
-- Update previous/existing FundValue/GainLoss/ROI using latest LNAVPS
CREATE TRIGGER IF NOT EXISTS trg_LatestNAVPS_weiffund
AFTER INSERT ON NAVPS
WHEN new.Fund_ID == 'WEIF_FUND'
BEGIN
  UPDATE Investments set LNAVPS = new.LNAVPS
  WHERE Fund_ID = 'WEIF_FUND';
  UPDATE Investments set FundValue = cast(Shares as integer) * LNAVPS;
  UPDATE Investments set GainLoss = FundValue - GrossInv;
  UPDATE Investments set ROI = (GainLoss / GrossInv) * 100;
END;


--                      [ ---------------------------- ]

-- Test Data for Sun Life Database
INSERT INTO Clients (
  Title, FirstName, LastName, Email, Phone, Birthday, Age, Address, Province,
  Description
)
VALUES
('Ms', 'Beverly', 'Surname1', 'bev@gmail.com', '123456', '1980-01-01', 0, '01 Test St, Mabalacat', 'Pampanga', 'Client 2'),
('Mrs', 'Rosie', 'Surname2', 'rosie@gmail.com', '123456', '1990-03-01', 0, '01 Test St, Mabalacat', 'Pampanga', 'Client 3'),
('Dr', 'Cristy', 'Surname3', 'christy@gmail.com', '123456', '1985-03-01', 0, '01 Test St, Mabalacat', 'Pampanga', 'Client 4'),
('Ms', 'Jessalie', 'Surname4', 'jessalie@gmail.com', '123456', '1987-03-01', 0, '01 Test St, Mabalacat', 'Pampanga', 'Client 5'),
('Ms', 'Cristina', 'Surname5', 'cristina@gmail.com', '123456', '1995-03-01', 0, '01 Test St, Mabalacat', 'Pampanga', 'Client 5');

INSERT INTO FundTypes (Fund_ID, Name, Minimum, Tolerance, Description)
VALUES
('BOND_FUND', 'Bond Fund', 0, 'Low to Moderate', 'Earn modest returns from your investments'),
('BALANCE_FUND', 'Balance Fund', 0, 'Low to Moderate', 'Mix of fixed income and investments with high growth potential'),
( 'EQUITY_FUND', 'Equity Fund', 1000, 'Moderate to High', 'Mutual fun designed for long-term capital growth'),
('MM_FUND', 'Money Market Fund', 100, 'Low', 'Provide potential higher annual returns than your standard savings account'),
('GS_FUND', 'GS Fund', 0, 'Low to Moderate', 'Minimal yield guarantee but are considered as one of the safest investment outlets'),
('INDEX_FUND', 'Index Fund', 0, 'Moderate to High', 'Mirror the performance of the Philippine Stock Exchange Index (PSEi).'),
('WEIF_FUND', 'WIEFF Fund', 0, 'High', 'Global equities market in a single fund while enabling you to invest in Philippine pesos');

INSERT INTO Investments
  (Client_ID, Fund_ID, TransactType, ApplicationID, TransactDate, SalesLoadType,
   SalesLoadDeduct, GrossInv, ANAVPS)
VALUES
  (2, 'INDEX_FUND', 'SUBSCRIPTION', 20008837810036, '2020-10-20', 'FRONT-END',
   NULL, 1000, 0.7876),
  (2, 'INDEX_FUND', 'SUBSCRIPTION', 20008837810037, '2020-10-05', 'FRONT-END',
   NULL, 1000, 0.7751),
  (3, 'INDEX_FUND', 'SUBSCRIPTION', 20008837810037, '2020-09-07', 'FRONT-END',
   NULL, 5000, 0.7656),
  (3, 'INDEX_FUND', 'SUBSCRIPTION', 20008837810037, '2020-08-20', 'FRONT-END',
   NULL, 5000, 0.7659),
  (1, 'INDEX_FUND', 'SUBSCRIPTION', 20008837810031, '2020-10-20', 'BACK-END',
   0, 1000, 0.7876),
  (1, 'INDEX_FUND', 'SUBSCRIPTION', 20008837810032, '2020-09-23', 'BACK-END',
   0, 1000, 0.7601),
  (1, 'EQUITY_FUND', 'SUBSCRIPTION', 20008837810034, '2020-10-13', 'BACK-END',
   0, 467.56, 3.0671),
  (1, 'MM_FUND', 'SUBSCRIPTION', 20008837810033, '2020-10-08', 'NOLOAD',
   0, 50000, 1.2913),
  (1, 'WEIF_FUND', 'SUBSCRIPTION', 20008837810035, '2020-09-23', 'BACK-END',
   0, 50000, 0.9925);

-- FRONT-END deduction for less than 100k is .0224

INSERT INTO NAVPS (Fund_ID, LNAVPS, Note)
VALUES
  ('INDEX_FUND', 0.8159, 'Latest NAVPS for Index Fund'),
  ('MM_FUND', 1.2929, 'Latest NAVPS for Index Fund'),
  ('WEIF_FUND', 0.9936, 'Latest NAVPS for Index Fund'),
  ('EQUITY_FUND', 3.2473, 'Latest NAVPS for Index Fund');


--                      [ ---------------------------- ]

-- Debugging Output

.print '                                ** Investment Table **'
.print
.w 10 14 11 8 10 10 7 11 8
select c.FirstName, i.ApplicationID, i.Fund_ID,
       i.GrossInv as Gross,
       printf('%.2f', i.Deduction) as Deduction,
       printf('%.2f', i.NetInv) as 'Net Inv',
       cast(i.Shares as integer) as Shares,
       printf('%.2f', i.FundValue) as 'Fund Value',
       printf('%.2f', i.ROI) as 'ROI',
       printf('%.2f', i.GainLoss) as 'Gain/Loss'
from Investments i, Clients c
where i.Client_ID = c.Client_id;
.print

.w 10 14 12 13 13 8 8 7
select c.FirstName, i.ApplicationID, i.TransactDate, i.TransactType,
       i.SalesLoadType, i.ANAVPS, i.LNAVPS, i.SalesLoadDeduct
from Investments i, Clients c
where i.Client_ID = c.Client_id;
.print

select * from FundTypes;
.print
