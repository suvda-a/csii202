-- types
create type payment_method_type as enum ('Cash', 'Credit', 'Cheque', 'Standing Order');
create type boolean_type as enum ('Yes', 'No');
create type sex_type as enum ('M','F');
create type position_type as enum ('Manager','Supervisor', 'Deputy', 'Assistant', 'Secretary');

-- tables
create table Branch
(
    BranchNo         varchar(3)  not null
        check (BranchNo ~ '^B[1-9][0-9]{0,1}$'),
    Street           varchar(25) not null,
    Area             varchar(15) null,
    City             varchar(15) not null,
    Postcode         varchar(8)  null,
    TelephoneNo      varchar(13) null,
    FaxNo            varchar(13) null,
    ManagerStaffNo   varchar(5)  null,
    ManagerStartDate date        null,
    BonusPayment     numeric     null,
    CarAllowance     numeric     null,

    PRIMARY KEY (BranchNo),

    unique (TelephoneNo),
    unique (FaxNo)
);

create table Staff
(
    StaffNo             varchar(5)    not null
        check (StaffNo ~ '^S[A-Z][1-9][0-9]{0,2}$'),
    FirstName           varchar(20)   not null,
    LastName            varchar(20)   not null,
    Address             varchar(50)   not null,
    TelephoneNo         varchar(13)   null,
    Sex                 sex_type      not null,
    DateOfBirth         date          null,
    Position            position_type not null,
    Salary              numeric       not null,
    DateJoined          date          null,
    NationalInsuranceNo varchar(10)   not null,
    TypingSpeed         integer       null
        check (Position <> 'Secretary' or (TypingSpeed is not null and TypingSpeed > 0)),
    BranchNo            varchar(3)    not null,

    PRIMARY KEY (StaffNo),

    unique (NationalInsuranceNo),

    FOREIGN KEY (BranchNo) references Branch (BranchNo)
        ON DELETE NO ACTION
);

create table NextOfKin
(
    StaffNo       varchar(5)  not null,
    NextOfKinName varchar(30) not null,
    Relationship  varchar(20) null,
    Address       varchar(50) null,
    TelephoneNo   varchar(13) null,

    PRIMARY KEY (StaffNo, NextOfKinName),

    FOREIGN KEY (StaffNo) references Staff (StaffNo)
        ON DELETE CASCADE
);

-- A supervisor may supervise a minimum of five and a maximum of ten members of staff, at any one time.
-- A secretary may support one or more workgroups at the same branch (not in text)
-- A supervisee may be in only one workgroup at a time.
create table AllocatedStaff
(
    SuperviseeStaffNo varchar(5) not null,
    SupervisorStaffNo varchar(5) not null,
    SecretaryStaffNo  varchar(5) not null,
    PRIMARY KEY (SuperviseeStaffNo),

    FOREIGN KEY (SuperviseeStaffNo) references Staff (StaffNo)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (SupervisorStaffNo) references Staff (StaffNo)
        ON DELETE SET NULL
        ON UPDATE CASCADE,
    FOREIGN KEY (SecretaryStaffNo) references Staff (StaffNo)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

-- A member of staff may supervise a maximum of ten properties for rent at any one time.
-- The monthly rent for a property should be reviewed annually
-- Property records are kept for at least three years after being withdrawn from rental and may then be deleted
create table PropertyForRent
(
    PropertyNo      varchar(5)   not null CHECK (PropertyNo ~ '^P[A-Z][1-9][0-9]{0,2}$'),
    Street          varchar(25)  not null,
    Area            varchar(15)  null,
    City            varchar(15)  not null,
    Postcode        varchar(8)   null,
    Type            char(1)      not null                  DEFAULT 'F' CHECK (Type IN ('B', 'C', 'D', 'E', 'F', 'M', 'S', 'H')),
    Rooms           INTEGER CHECK (Rooms BETWEEN 1 AND 15) DEFAULT 4,
    Rent            NUMERIC                                DEFAULT 600,
    PrivateOwnerNo  varchar(5)   null,
    BusinessOwnerNo varchar(5)   null,
    StaffNo         varchar(5)   null,
    BranchNo        varchar(3)   not null,
    Picture         BYTEA        null,
    Comments        varchar(255) null,
    Withdrawn       date         null,
    DeleteRecord    BOOLEAN      null,

    PRIMARY KEY (PropertyNo),

    FOREIGN KEY (StaffNo) references Staff (StaffNo)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    FOREIGN KEY (BranchNo) references Branch (BranchNo)
        ON DELETE SET DEFAULT
        ON UPDATE CASCADE
);

create table PrivateOwner
(
    PrivateOwnerNo varchar(5)  not null CHECK (PrivateOwnerNo ~ '^CO[1-9][0-9]{0,2}$'),
    FirstName      varchar(20) not null,
    LastName       varchar(20) not null,
    Address        varchar(50) not null,
    TelephoneNo    varchar(13),

    PRIMARY KEY (PrivateOwnerNo)
);

create table BusinessOwner
(
    BusinessOwnerNo varchar(5)  not null CHECK (BusinessOwnerNo ~ '^CB[1-9][0-9]{0,2}$'),
    BusinessName    varchar(30) not null,
    BusinessType    varchar(20) not null,
    Address         varchar(50) not null,
    TelephoneNo     varchar(13),
    ContactName     varchar(30),

    PRIMARY KEY (BusinessOwnerNo),
    unique (TelephoneNo)
);

-- The length of a lease is from 3 to 12 months
-- The deposit amount is twice the monthly rent
create table LeaseAgreement
(
    LeaseNo       varchar(8)          not null
        check (LeaseNo ~ '^L[1-9][0-9]{0,4}$'),
    RenterNo      varchar(8)          not null,
    PropertyNo    varchar(5)          not null
        references PropertyForRent (PropertyNo),
    PaymentMethod payment_method_type not null,
    Rent          numeric             not null,
    DepositAmount numeric             not null,
    DepositPaid   boolean_type        not null,
    RentStart     date                not null,
    RentFinish    date                not null,

    PRIMARY KEY (LeaseNo),

    unique (PropertyNo),
    unique (RentStart),

    FOREIGN KEY (PropertyNo) references PropertyForRent (PropertyNo)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

create table Renter
(
    RenterNo      varchar(5)  not null
        check (RenterNo ~ '^CR[1-9][0-9]{0,2}$'),
    FirstName     varchar(20) not null,
    LastName      varchar(20) not null,
    Address       varchar(50) not null,
    TelephoneNo   varchar(13) null,
    PreferredType char(1)     null DEFAULT 'F' CHECK (PreferredType IN ('B', 'C', 'D', 'E', 'F', 'M', 'S', 'H')),
    MaximumRent   numeric     null,
    BranchNo      varchar(5)  not null,

    PRIMARY KEY (RenterNo),

    FOREIGN KEY (BranchNo) references Branch (BranchNo)
        ON DELETE NO ACTION
        ON UPDATE CASCADE
);

create table Viewing
(
    PropertyNo varchar(5)  not null,
    RenterNo   varchar(5)  not null,
    DateViewed date        not null,
    Comments   varchar(50) null,

    PRIMARY KEY (PropertyNo, RenterNo, DateViewed),

    FOREIGN KEY (PropertyNo) references PropertyForRent (PropertyNo)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (RenterNo) references Renter (RenterNo)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);

-- Properties should be inspected at least once over a six-month period.
create table Inspection
(
    PropertyNo    varchar(5)   not null,
    StaffNo       varchar(5)   not null,
    DateInspected date         not null,
    Comments      varchar(255) null,

    PRIMARY KEY (PropertyNo, StaffNo),

    FOREIGN KEY (PropertyNo) references PropertyForRent (PropertyNo)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    FOREIGN KEY (StaffNo) references Staff (StaffNo)
        ON DELETE SET NULL
        ON UPDATE CASCADE
);

--the reason for the alterations are so that they could be referred before the table made
alter table Branch
    add FOREIGN KEY (ManagerStaffNo) references Staff (StaffNo)
        ON DELETE SET NULL
        ON UPDATE CASCADE;

alter table LeaseAgreement
    add FOREIGN KEY (RenterNo) references Renter (RenterNo)
        ON DELETE NO ACTION
        ON UPDATE CASCADE;

alter table PropertyForRent
    add FOREIGN KEY (PrivateOwnerNo) references PrivateOwner (PrivateOwnerNo)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    add FOREIGN KEY (BusinessOwnerNo) references BusinessOwner (BusinessOwnerNo)
        ON DELETE NO ACTION
        ON UPDATE CASCADE;

INSERT INTO branch (branchno, street, area, city, postcode, telephoneno, faxno)
VALUES ('B5', '22 deer rd', 'Sidcup', 'London', 'SW1 4EH', '0171-886-1212', '0171-886-1214'),
       ('B7', '16 Argilly St', 'Dyce', 'Aberdeen', 'AB2 3Su', '01224-67125', '01224-67111'),
       ('B3', '163 Main St', 'Partick', 'Glasgow', 'G11 9Qx', '0141-339-2178', '0141-339-4439'),
       ('B4', '32 Mains RD', 'leight', 'Bristol', 'BS99 1NZ', '0117-916-1170', '0117-776-1114'),
       ('B2', '56Clover Dr', 'null', 'London', 'NW10 6EU', '0181-963-1030', '0181-453-7992')
;

INSERT INTO staff (staffno, firstname, lastname, address, telephoneno, sex, dateofbirth, position, salary, nationalinsuranceno, branchno)
VALUES  ('SG14', 'David', 'Ford', '63 AshbySt, Partick, Glasgow G11', '0141-339-2177', 'M', '1958-03-24', 'Deputy', 18000,  'WI220658D',  'B3'),
        ('SG5', 'Susan', 'Brand', '5Gt Western Rd, Glasgow G12', '011-334-2001', 'F', '1940-06-03', 'Manager', 24000,  'WK588932E', 'B3'),
        ('SL21', 'John', 'white', '19 Taylor St, Crandford, London', '0171-884-5112', 'M', '1945-10-01', 'Manager', 30000, 'WK442011B', 'B3'),
        ('SL41', 'Julie', 'lee', '28 Malvern St, Kilburn NW2', null, 'F', '1965-06-13', 'Assistant', 9000, 'WA290573K', 'B7'),
        ('SA9', 'Mary', 'Howe', '2 Elm Pl, Aberdeen AB2 su', null, 'F', '1970-02-19', 'Assistant', 9000, 'WM532187D', 'B5'),
        ('SG37', 'Ann', 'Beech', '81 George St, Glasgow PA1 2Jr', '0141-848-3345', 'F', '1960-11-10', 'Assistant', 12000, 'WI432514C', 'B5')
;

INSERT INTO privateowner (privateownerno, firstname, lastname, address)
VALUES ('CO46', 'John', 'Doe', '16 Holhead'),
       ('CO87', 'Anna', 'bey', '6 Argyll St'),
       ('CO40', 'Sarah', 'Smith', '6 Lawrence St'),
       ('CO93', 'Mona', 'Lisa', '18 Dale Rd')
;

INSERT INTO propertyforrent (propertyno, street, area, city, postcode, type, rooms, rent, privateownerno, staffno, branchno)
VALUES  ('PA14', '16 Holhead', 'Dee', 'Aberdeen', 'AB7 5SU', 'H', 6, 650, 'CO46', 'SA9', 'B7'),
        ('PL94', '6 Argyll St', 'Kilburn', 'London', 'NW2', 'F', 4, 400, 'CO87', 'SL41', 'B5'),
        ('PG4', '6 Lawrence St', 'Partick', 'Glasgow', 'G11 9QX', 'F', 3, 350, 'CO40', 'SG14', 'B3'),
        ('PG36', '2 Manor Rd', null, 'Glasgow', 'G32 4QX', 'F', 3, 375, 'CO93', 'SG37', 'B3'),
        ('PG21', '18 DaleRd', 'Hyndland', 'Glasgow', 'G12', 'H', 5, 600, 'CO87', 'SG37', 'B3'),
        ('PG16', '5 Novar Dr', 'Hyndland', 'Glasgow', 'G12 9AX', 'F', 4, 450, 'CO93', 'SG14', 'B3')
;

INSERT INTO renter (renterno, firstname, lastname, address, branchno)
VALUES  ('CR56', 'Renter', 'NA', 'Address of renter', 'B3'),
        ('CR62', 'Renter_2', 'NA', 'Address of renter_2', 'B2'),
        ('CR76', 'Renter_3', 'NA', 'Address of renter_3', 'B5')
;

INSERT INTO viewing (propertyno, renterno, dateviewed, comments)
VALUES  ('PA14', 'CR56', '1998-05-24', 'too small'),
        ('PG4', 'CR76', '1998-04-20', 'too remote'),
        ('PG4', 'CR56', '1998-05-26', null),
        ('PA14', 'CR62', '1998-05-14', 'no dining room'),
        ('PG36', 'CR56', '1998-04-28', null)
;