-- Allocated staff

-- A supervisor may supervise a minimum of five and a maximum of ten members of staff, at any one time.
-- A secretary may support one or more workgroups at the same branch (not in text)
-- A supervisee may be in only one workgroup at a time



-- Property for rent

-- A member of staff may supervise a maximum of ten properties for rent at any one time.
-- The monthly rent for a property should be reviewed annually
-- Property records are kept for at least three years after being withdrawn from rental and may then be deleted


-- Lease Agreement

-- The length of a lease is from 3 to 12 months
-- The deposit amount is twice the monthly rent

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
