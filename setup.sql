create table reminders (
  id INTEGER PRIMARY KEY,
  phonenumber varchar(100),
  event_id int,
  done boolean,
  time varchar(14)
);

create table calls (
  id INTEGER PRIMARY KEY,
  caller_id varchar(100),
  time varchar(14)
);

create table ratings (
    id INTEGER PRIMARY KEY,
    time varchar(14)
);

create table single_ratings (
    id INTEGER PRIMARY KEY,
    rating_id INTEGER,
    category VARCHAR(40),
    rating INTEGER
);

create table audio_ratings (
    id INTEGER PRIMARY KEY,
    rating_id INTEGER,
    filename VARCHAR(80)
);
