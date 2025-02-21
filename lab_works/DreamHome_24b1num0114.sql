-- types
create type payment_method_type as enum ('Cash', 'Credit', 'Cheque', 'Standing Order');
create type boolean_type as enum ('Yes', 'No');
create type sex_type as enum ('M','F');
create type position_type as enum ('Manager','Supervisor', 'Deputy', 'Assistant', 'Secretary');


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

    primary key (BranchNo),

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

    primary key (StaffNo),

    unique (NationalInsuranceNo),

    foreign key (BranchNo) references Branch (BranchNo)
        on delete no action
);

create table NextOfKin
(
    StaffNo       varchar(5)  not null,
    NextOfKinName varchar(30) not null,
    Relationship  varchar(20) null,
    Address       varchar(50) null,
    TelephoneNo   varchar(13) null,

    primary key (StaffNo, NextOfKinName),

    foreign key (StaffNo) references Staff (StaffNo)
        on delete CASCADE
);

-- A supervisor may supervise a minimum of five and a maximum of ten members of staff, at any one time.
-- A secretary may support one or more workgroups at the same branch (not in text)
-- A supervisee may be in only one workgroup at a time.
create table AllocatedStaff
(
    SuperviseeStaffNo varchar(5) not null,
    SupervisorStaffNo varchar(5) not null,
    SecretaryStaffNo  varchar(5) not null,
    primary key (SuperviseeStaffNo),

    foreign key (SuperviseeStaffNo) references Staff (StaffNo)
        on delete CASCADE
        on update CASCADE,
    foreign key (SupervisorStaffNo) references Staff (StaffNo)
        on delete set null
        on update CASCADE,
    foreign key (SecretaryStaffNo) references Staff (StaffNo)
        on delete set null
        on update CASCADE
);

-- A member of staff may supervise a maximum of ten properties for rent at any one time.
-- The monthly rent for a property should be reviewed annually
-- Property records are kept for at least three years after being withdrawn from rental and may then be deleted
CREATE TABLE PropertyForRent
(
    PropertyNo      VARCHAR(5)   NOT NULL CHECK (PropertyNo ~ '^P[A-Z][1-9][0-9]{0,2}$'),
    Street          VARCHAR(25)  NOT NULL,
    Area            VARCHAR(15)  NULL,
    City            VARCHAR(15)  NOT NULL,
    Postcode        VARCHAR(8)   NULL,
    Type            CHAR(1)      NOT NULL                  DEFAULT 'F' CHECK (Type IN ('B', 'C', 'D', 'E', 'F', 'M', 'S', 'H')),
    Rooms           INTEGER CHECK (Rooms BETWEEN 1 AND 15) DEFAULT 4,
    Rent            NUMERIC                                DEFAULT 600,
    PrivateOwnerNo  VARCHAR(5)   NULL,
    BusinessOwnerNo VARCHAR(5)   NULL,
    StaffNo         VARCHAR(5)   NULL,
    BranchNo        VARCHAR(3)   NOT NULL,
    Picture         BYTEA        NULL,
    Comments        VARCHAR(255) NULL,
    Withdrawn       DATE         NULL,
    DeleteRecord    BOOLEAN      NULL,

    PRIMARY KEY (PropertyNo),

    FOREIGN KEY (StaffNo) REFERENCES Staff (StaffNo)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    FOREIGN KEY (BranchNo) REFERENCES Branch (BranchNo)
        ON DELETE SET DEFAULT
        ON UPDATE CASCADE
);

CREATE TABLE PrivateOwner
(
    PrivateOwnerNo VARCHAR(5)  NOT NULL CHECK (PrivateOwnerNo ~ '^CO[1-9][0-9]{0,2}$'),
    FirstName      VARCHAR(20) NOT NULL,
    LastName       VARCHAR(20) NOT NULL,
    Address        VARCHAR(50) NOT NULL,
    TelephoneNo    VARCHAR(13),

    PRIMARY KEY (PrivateOwnerNo)
);

CREATE TABLE BusinessOwner
(
    BusinessOwnerNo VARCHAR(5)  NOT NULL CHECK (BusinessOwnerNo ~ '^CB[1-9][0-9]{0,2}$'),
    BusinessName    VARCHAR(30) NOT NULL,
    BusinessType    VARCHAR(20) NOT NULL,
    Address         VARCHAR(50) NOT NULL,
    TelephoneNo     VARCHAR(13) UNIQUE,
    ContactName     VARCHAR(30),

    PRIMARY KEY (BusinessOwnerNo)
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

    primary key (LeaseNo),

    unique (PropertyNo),
    unique (RentStart),

    foreign key (PropertyNo) references PropertyForRent (PropertyNo)
        on delete no action
        on update CASCADE
);

create table Renter
(
    RenterNo      varchar(5)    not null
        check (RenterNo ~ '^CR[1-9][0-9]{0,2}$'),
    FirstName     varchar(20)   not null,
    LastName      varchar(20)   not null,
    Address       varchar(50)   not null,
    TelephoneNo   varchar(13)   null,
    PreferredType property_type null,
    MaximumRent   numeric       null,
    BranchNo      varchar(5) NOT NULL,

    primary key (RenterNo),

    foreign key (BranchNo) references Branch (BranchNo)
        on delete no action
        on update CASCADE
);

create table Viewing
(
    PropertyNo varchar(5)  not null,
    RenterNo   varchar(5)  not null,
    DateViewed date        not null,
    Comments   varchar(50) null,

    primary key (PropertyNo, RenterNo, DateViewed),

    foreign key (PropertyNo) references PropertyForRent (PropertyNo)
        on delete CASCADE
        on update CASCADE,
    foreign key (RenterNo) references Renter (RenterNo)
        on delete CASCADE
        on update CASCADE
);

-- Properties should be inspected at least once over a six-month period.
create table Inspection
(
    PropertyNo    varchar(5)   not null,
    StaffNo       varchar(5)   not null,
    DateInspected date         not null,
    Comments      varchar(255) null,

    primary key (PropertyNo, StaffNo),

    foreign key (PropertyNo) references PropertyForRent (PropertyNo)
        on delete CASCADE
        on update CASCADE,
    foreign key (StaffNo) references Staff (StaffNo)
        on delete set null
        on update CASCADE
);

--the reason for the alterations are so that they could be referred before the table made
alter table Branch
    add foreign key (ManagerStaffNo) references Staff (StaffNo)
        on delete set null
        on update CASCADE;

alter table LeaseAgreement
    add foreign key (RenterNo) references Renter (RenterNo)
        on delete no action
        on update CASCADE;

alter table PropertyForRent
    add FOREIGN KEY (PrivateOwnerNo) REFERENCES PrivateOwner (PrivateOwnerNo)
        ON DELETE NO ACTION
        ON UPDATE CASCADE,

    add FOREIGN KEY (BusinessOwnerNo) REFERENCES BusinessOwner (BusinessOwnerNo)
        ON DELETE NO ACTION
        ON UPDATE cascade;

insert into branch (branchno, street, area, city, postcode, telephoneno, faxno)
values ('B5', '22 deer rd', 'Sidcup', 'London', 'SW1 4EH', '0171-886-1212', '0171-886-1214'),
       ('B7', '16 Argilly St', 'Dyce', 'Aberdeen', 'AB2 3Su', '01224-67125', '01224-67111'),
       ('B3', '163 Main St', 'Partick', 'Glasgow', 'G11 9Qx', '0141-339-2178', '0141-339-4439'),
       ('B4', '32 Mains RD', 'leight', 'Bristol', 'BS99 1NZ', '0117-916-1170', '0117-776-1114'),
       ('B2', '56Clover Dr', 'null', 'London', 'NW10 6EU', '0181-963-1030', '0181-453-7992');

insert into staff (staffno, firstname, lastname, address, telephoneno, sex, dateofbirth, position, salary, nationalinsuranceno, branchno)
values  ('SG14', 'David', 'Ford', '63 AshbySt, Partick, Glasgow G11', '0141-339-2177', 'M', '1958-03-24', 'Deputy', 18000,  'WI220658D',  'B3'),
        ('SG5', 'Susan', 'Brand', '5Gt Western Rd, Glasgow G12', '011-334-2001', 'F', '1940-06-03', 'Manager', 24000,  'WK588932E', 'B3'),
        ('SL21', 'John', 'white', '19 Taylor St, Crandford, London', '0171-884-5112', 'M', '1945-10-01', 'Manager', 30000, 'WK442011B', 'B3'),
        ('SL41', 'Julie', 'lee', '28 Malvern St, Kilburn NW2', null, 'F', '1965-06-13', 'Assistant', 9000, 'WA290573K', 'B7'),
        ('SA9', 'Mary', 'Howe', '2 Elm Pl, Aberdeen AB2 su', null, 'F', '1970-02-19', 'Assistant', 9000, 'WM532187D', 'B5'),
        ('SG37', 'Ann', 'Beech', '81 George St, Glasgow PA1 2Jr', '0141-848-3345', 'F', '1960-11-10', 'Assistant', 12000, 'WI432514C', 'B5');

insert into public.privateowner (privateownerno, firstname, lastname, address)
values  ('CO46', 'John', 'Doe', '16 Holhead'),
        ('CO87', 'Anna', 'bey', '6 Argyll St'),
        ('CO40', 'Sarah', 'Smith', '6 Lawrence St'),
        ('CO93', 'Mona', 'Lisa', '18 Dale Rd');

insert into propertyforrent (propertyno, street, area, city, postcode, type, rooms, rent, privateownerno, staffno, branchno)
values  ('PA14', '16 Holhead', 'Dee', 'Aberdeen', 'AB7 5SU', 'H', 6, 650, 'CO46', 'SA9', 'B7'),
        ('PL94', '6 Argyll St', 'Kilburn', 'London', 'NW2', 'F', 4, 400, 'CO87', 'SL41', 'B5'),
        ('PG4', '6 Lawrence St', 'Partick', 'Glasgow', 'G11 9QX', 'F', 3, 350, 'CO40', 'SG14', 'B3'),
        ('PG36', '2 Manor Rd', null, 'Glasgow', 'G32 4QX', 'F', 3, 375, 'CO93', 'SG37', 'B3'),
        ('PG21', '18 DaleRd', 'Hyndland', 'Glasgow', 'G12', 'H', 5, 600, 'CO87', 'SG37', 'B3'),
        ('PG16', '5 Novar Dr', 'Hyndland', 'Glasgow', 'G12 9AX', 'F', 4, 450, 'CO93', 'SG14', 'B3');

insert into public.renter (renterno, firstname, lastname, address, branchno)
values  ('CR56', 'Renter', 'NA', 'Address of renter', 'B3'),
        ('CR62', 'Renter_2', 'NA', 'Address of renter_2', 'B2'),
        ('CR76', 'Renter_3', 'NA', 'Address of renter_3', 'B5');

insert into viewing (propertyno, renterno, dateviewed, comments)
values  ('PA14', 'CR56', '1998-05-24', 'too small'),
        ('PG4', 'CR76', '1998-04-20', 'too remote'),
        ('PG4', 'CR56', '1998-05-26', null),
        ('PA14', 'CR62', '1998-05-14', 'no dining room'),
        ('PG36', 'CR56', '1998-04-28', null);