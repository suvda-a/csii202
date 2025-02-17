create type paymentmethod_type as enum ('Cash', 'Credit', 'Cheque', 'Standing Order');
create type boolean_type as enum('Yes', 'No');
create type sex_type as enum('M','F');
create type position_type as enum('Manager','Supervisor', 'Deputy', 'Assistant', 'Secretary');
create type property_type as enum ('B', 'C', 'D', 'E', 'F', 'M', 'S');

create table Branch(
	BranchNo varchar(3) not null 
		check(BranchNo ~ '^B[1-9][0-9]{0,1}$'),
	Street varchar(25) not null,
	Area varchar(15) null,
	City varchar(15) not null,
	Postcode varchar(8) null,
	TelephoneNo varchar(13) null,
	FaxNo varchar(13) null,
	ManagerStaffNo varchar(5) null,
	ManagerStartDate date null,
	BonusPayment numeric null,
	CarAllowance numeric null,

	primary key (BranchNo),

	unique (TelephoneNo),
	unique (FaxNo)
);
	
create table Staff(
	StaffNo varchar(5) not null 
		check (StaffNo ~ '^S[A-Z][1-9][0-9]{0,2}$'),
	FirstName varchar(20) not null,
	LastName varchar(20) not null,
	Address varchar(50) not null,
	TelephoneNo varchar(13) null,
	Sex sex_type not null,
	DateOfBirth date null,
	Position position_type not null,
	Salary numeric not null,
	DateJoined date not null,
	NationalInsuranceNo varchar(10) not null ,
	TypingSpeed integer null 
		check (Position <> 'Secretary' or (TypingSpeed is not null and TypingSpeed > 0)),
	BranchNo varchar(3) not null,
	
	primary key (StaffNo),
	
	unique (NationalInsuranceNo),
	
	foreign key (BranchNo) references Branch(BranchNo) 
		on delete no action
);

create table NextOfKin(
	StaffNo varchar(5) not null, 
	NextOfKinName varchar(30) not null, 
	Relationship varchar(20) null, 
	Address varchar(50) null,
	TelephoneNo varchar(13) null,

	primary key(StaffNo, NextOfKinName),

	foreign key (StaffNo) references Staff(StaffNo) 
		on delete CASCADE
);



-- A supervisor may supervise a minimum of five and a maximum of ten members of staff, at any one time.
-- A secretary may support one or more workgroups at the same branch (not in text)
-- A supervisee may be in only one workgroup at a time.
create table AllocatedStaff (
	SuperviseeStaffNo varchar(5) not null, 
	SupervisorStaffNo varchar(5) not null ,
	SecretaryStaffNo varchar(5) not null,
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
create table PropertyForRent (
	PropertyNo varchar(5)
		not null
		check (PropertyNo ~ '^P[A-Z][1-9][0-9]{0,2}$'), 
	OwnerNo varchar(5) not null,
	Street varchar(25) not null, 
	Area varchar(15) null, 
	City varchar(15) not null, 
	Postcode varchar(8) null, 
	Type property_type not null 
		default 'F',
	Rooms integer null
		check(Rooms between 1 and 15)
		default 4, 
	Rent numeric null
		default 600, 
	PrivateOwnerNo varchar(5) null, 
	BusinessOwnerNo varchar(5) null, 
	StaffNo varchar(5) null,
	BranchNo varchar(3) not null, 
	Picture bytea null, 
	Comments varchar(255) null, 
	Withdrawn date null, 
	DeleteRecord boolean null,
	
	primary key (PropertyNo),
	
	foreign key (StaffNo) references Staff (StaffNo) 
		on delete set null 
		on update CASCADE,
	foreign key (BranchNo) references Branch (BranchNo) 
		on delete set default
		on update CASCADE
);

create table PrivateOwner(
	PrivateOwnerNo varchar(5) not null
		check(PrivateOwnerNo ~ '^CO[1-9][0-9]{0,2}$'),
	FirstName varchar(20) not null,
	LastName varchar(20) not null,
	Address varchar(50) not null,
	TelephoneNo varchar(13), 

	primary key (PrivateOwnerNo)
);

create table BusinessOwner (
	BusinessOwnerNo varchar(5) not null
		check(BusinessOwnerNo ~ '^CB[1-9][0-9]{0,2}$'), 
	BusinessName varchar(30) not null, 
	BusinessType varchar(20) not null,
	Address varchar(50) not null,
	TelephoneNo varchar(13), 
	ContactName varchar(30),

	primary key (BusinessOwnerNo),

	unique (TelephoneNo)
);



-- The length of a lease is from 3 to 12 months
-- The deposit amount is twice the monthly rent
create table LeaseAgreement(
	LeaseNo varchar(8) not null
		check(LeaseNo ~ '^L[1-9][0-9]{0,4}$'), 
	RenterNo varchar(8) not null, 
	PropertyNo varchar(5) not null
		references PropertyForRent(PropertyNo), 
	PaymentMethod varchar(15) not null,
	Rent numeric not null, 
	DepositAmount numeric not null, 
	DepositPaid boolean_type not null, 
	RentStart date not null, 
	RentFinish date not null ,
	
	primary key (LeaseNo),
	
	unique (PropertyNo),
	unique (RentStart),
		
	foreign key (PropertyNo) references PropertyForRent(PropertyNo) 
		on delete no action
		on update CASCADE
);



-- Create the trigger function to calculate DepositAmount
create or replace function set_default_deposit_amount() 
returns trigger as $$
begin
  -- Set DepositAmount to 2 * Rent if it's NULL
  if new.DepositAmount is null then
    new.DepositAmount := new.Rent * 2;
  end if;
  return new;
end;
$$ language plpgsql;

-- Create the trigger to call the function on insert
create trigger before_insert_leaseagreement
before insert on LeaseAgreement
for each row
execute function set_default_deposit_amount();

create table Renter(
	RenterNo varchar(5) not null
		check (RenterNo ~ '^CR[1-9][0-9]{0,2}$'), 
	FirstName varchar(20) not null , 
	LastName varchar(20) not null , 
	Address varchar(50) not null , 
	TelephoneNo varchar(13) null ,
	PreferredType property_type null, 
	MaximumRent numeric null, 
	BranchNo varchar(5),
	
	primary key (RenterNo),
	
	foreign key (BranchNo) references Branch (BranchNo) 
		on delete no action 
		on update CASCADE
);

create table Viewing(
	PropertyNo varchar(5) not null, 
	RenterNo varchar(5) not null, 
	DateViewed date not null, 
	Comments varchar(50) null ,
	
	primary key (PropertyNo, RenterNo, DateViewed),

	foreign key (PropertyNo) references PropertyForRent (PropertyNo) 
		on delete CASCADE
		on update CASCADE,
	foreign key (RenterNo) references Renter (RenterNo) 
		on delete CASCADE 
		on update CASCADE
);

--the reason for the alterations are so that they could be referred before the table made
alter table Branch
	add foreign key (ManagerStaffNo) references Staff(StaffNo)
		on delete set null
		on update CASCADE;
alter table LeaseAgreement
	add foreign key (RenterNo) references Renter (RenterNo) 
		on delete no action 
		on update CASCADE;
alter table PropertyForRent
	add foreign key (OwnerNo) references PrivateOwner(PrivateOwnerNo) 
		on delete no action 
		on update CASCADE,    
	add foreign key (OwnerNo) references BusinessOwner(BusinessOwnerNo) 
    	on delete no action
		on update CASCADE;

-- Properties should be inspected at least once over a six month period.
create table Inspection(
	PropertyNo varchar(5) not null, 
	StaffNo varchar(5) not null, 
	DateInspected date not null , 
	Comments varchar(255) null,

	primary key (PropertyNo, StaffNo),
	
	foreign key (PropertyNo) references PropertyForRent (PropertyNo) 
		on delete CASCADE 
		on update CASCADE,
	foreign key (StaffNo) references Staff (StaffNo) 
		on delete set null 
		on update CASCADE
);
