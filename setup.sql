drop table if exists reminders;
create table reminders (
  id INTEGER PRIMARY KEY,
  phonenumber varchar(100),
  event_id int,
  done boolean,
  time varchar(14)
);

drop table if exists calls;
create table calls (
  id INTEGER PRIMARY KEY,
  caller_id varchar(100),
  time varchar(14)
);
