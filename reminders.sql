drop table if exists reminders;
create table reminders (
  phonenumber varchar(100),
  event_id int,
  done boolean,
  time varchar(14)
);

