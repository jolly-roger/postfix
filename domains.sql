create sequence id_domains_seq minvalue 0 start 0;


create table domains (
	id integer primary key not null default nextval('id_domains_seq'),	
	domain varchar(256)
);


create sequence id_maildirs_seq minvalue 0 start 0;


create table maildirs (
	id integer primary key not null default nextval('id_maildirs_seq'),	
	path varchar(256)
);

alter table mailboxes add column maildir_id integer;
ALTER TABLE mailboxes ALTER COLUMN maildir_id SET NOT NULL;
alter table mailboxes drop column active;


create sequence id_users_seq minvalue 0 start 0;


create table users (
	id integer primary key not null default nextval('id_users_seq'),	
	name varchar(256)
);




CREATE OR REPLACE FUNCTION postfix_getmaildir(username varchar(256)) returns varchar(256) AS
$BODY$
declare
    maildir varchar(256);
BEGIN
    select into maildir md.path from mailboxes as mb
        inner join maildirs as md
            on mb.maildir_id = md.id
        inner join users as u
            on mb.user_id = u.id
        inner join domains as d
            on mb.domain_id = d.id
        where (u.name || '@' || d.domain) = username limit 1;
        
    return maildir;
END;
$BODY$
  LANGUAGE plpgsql;
  
  
  
  
  
  CREATE OR REPLACE FUNCTION addtodo(todoname varchar(256), userid bigint) returns boolean AS
$BODY$
declare
    new_todo_id bigint;
    local_user_id bigint;
    local_priority integer;
BEGIN
    insert into todo (name) values (todoname) returning id_todo into new_todo_id;
    insert into todo_user values (new_todo_id, (select * from getuserid(userid)));
    
    select into local_priority priority from todo where id_todo = new_todo_id;
    
    perform setpriority(new_todo_id, local_priority);
    
    return true;
END;
$BODY$
  LANGUAGE plpgsql;
  
  
  
  
  
  
  
  
  
  

user_query = SELECT '/home/vmail/%d/%u' as home, 'maildir:/home/vmail/%d/%u' as mail, 5000 AS uid, 5000 AS gid,
concat('dirsize:storage=',  quota) AS quota FROM mailbox WHERE username = '%u' AND active = '1'


create type dovecot_user as (
    home varchar(256),
    mail varchar(256),
    uid integer,
    gid integer
);


CREATE OR REPLACE FUNCTION dovecot_getuser(user_name varchar(256)) returns setof dovecot_users AS
$BODY$
BEGIN
    return query select * from dovecot_users where "user" = user_name limit 1;
END;
$BODY$
  LANGUAGE plpgsql;



password_query = SELECT username as user, password, '/home/vmail/%d/%u' as userdb_home,
'maildir:/home/vmail/%d/%u' as userdb_mail, 5000 as  userdb_uid, 5000 as userdb_gid FROM mailbox
WHERE username = '%u' AND active = '1'



create type dovecot_password as (
    "user" varchar(256),
    password varchar(256),
    userdb_home varchar(256),
    userdb_mail varchar(256),
    userdb_uid integer,
    userdb_gid integer
);


CREATE OR REPLACE FUNCTION dovecot_getpassword(user_name varchar(256)) returns dovecot_password AS
$BODY$
declare
    result_password dovecot_password;
BEGIN
    select cast((u.name || '@' || d.domain) as varchar(256)) as "user", u.password as password,
        cast(('/home/mailer/' || md.path) as varchar(256)) as userdb_home,
        cast(('maildir:/home/mailer/' || md.path) as varchar(256)) as userdb_mail,
        5003 as userdb_uid, 5003 as userdb_gid
        into result_password
        from mailboxes as mb
        inner join maildirs as md
            on mb.maildir_id = md.id
        inner join users as u
            on mb.user_id = u.id
        inner join domains as d
            on mb.domain_id = d.id
        where (u.name || '@' || d.domain) = user_name limit 1;
    create or replace view dovecot_passwords as
    select cast((u.name || '@' || d.domain) as varchar(256)) as "user", u.password as password,
        cast(('/home/mailer/' || md.path) as varchar(256)) as userdb_home,
        cast(('maildir:/home/mailer/' || md.path) as varchar(256)) as userdb_mail,
        5003 as userdb_uid, 5003 as userdb_gid
        from mailboxes as mb
        inner join maildirs as md
            on mb.maildir_id = md.id
        inner join users as u
            on mb.user_id = u.id
        inner join domains as d
            on mb.domain_id = d.id;
    return result_password;
END;
$BODY$create or replace view dovecot_passwords as
    select cast((u.name || '@' || d.domain) as varchar(256)) as "user", u.password as password,
        cast(('/home/mailer/' || md.path) as varchar(256)) as userdb_home,
        cast(('maildir:/home/mailer/' || md.path) as varchar(256)) as userdb_mail,
        5003 as userdb_uid, 5003 as userdb_gid
        from mailboxes as mb
        inner join maildirs as md
            on mb.maildir_id = md.id
        inner join users as u
            on mb.user_id = u.id
        inner join domains as d
            on mb.domain_id = d.id;
  LANGUAGE plpgsql;
  
  
create or replace view dovecot_users as 
    select cast((u.name || '@' || d.domain) as varchar(256)) as "user",
        cast(('/home/mailer/' || md.path) as varchar(256)) as home,
        cast(('maildir:/home/mailer/' || md.path) as varchar(256)) as mail, 5003 as uid, 5003 as gid
        from mailboxes as mb
        inner join maildirs as md
            on mb.maildir_id = md.id
        inner join users as u
            on mb.user_id = u.id
        inner join domains as d
            on mb.domain_id = d.id;


create or replace view dovecot_passwords as
    select cast((u.name || '@' || d.domain) as varchar(256)) as "user", u.password as password,
        cast(('/home/mailer/' || md.path) as varchar(256)) as userdb_home,
        cast(('maildir:/home/mailer/' || md.path) as varchar(256)) as userdb_mail,
        5003 as userdb_uid, 5003 as userdb_gid
        from mailboxes as mb
        inner join maildirs as md
            on mb.maildir_id = md.id
        inner join users as u
            on mb.user_id = u.id
        inner join domains as d
            on mb.domain_id = d.id;
            
            
            
            
create table alias_domain_mailbox (
	alias_id integer,	
	domain_id integer,
    mailbox_id integer
);

create or replace view postfix_aliases as
    select cast((a.alias || '@' || d.domain) as varchar(256)) as alias,
    cast((u.name || '@' || d.domain) as varchar(256)) as address
    from mailboxes as m
    inner join aliases as a
        on m.user_id = a.user_id
    inner join domains as d
        on m.domain_id = d.id
    inner join users as u
        on m.user_id = u.id;
        
        
insert into alias_domain_mailbox (alias_id, domain_id, mailbox_id) select 0, domain_id, id from mailboxes where user_id = 3;

CREATE OR REPLACE FUNCTION postfix_resolve_alias(address_alias varchar(256)) returns varchar(256) AS
$BODY$
declare
    address varchar(256);
BEGIN
    select into address pa.address from postfix_aliases as pa where pa.alias = address_alias limit 1;
    
    if address is not NULL then
        return address;
    else
        return null;
    end if;
END;
$BODY$
  LANGUAGE plpgsql;
  
  
CREATE OR REPLACE FUNCTION postfix_resolve_alias(address_alias varchar(256)) returns setof varchar(256) AS
$BODY$
BEGIN
    return query select pa.address from postfix_aliases as pa where pa.alias = address_alias;
END;
$BODY$
  LANGUAGE plpgsql;
  
create table alias_user (
	alias_id integer,	
    user_id integer
);


create or replace view postfix_aliases as
    select cast((a.alias || '@' || d.domain) as varchar(256)) as alias,
    cast((u.name || '@' || d.domain) as varchar(256)) as address
    from mailboxes as m
    inner join alias_user as au
        on m.user_id = au.user_id
    inner join aliases as a
        on au.alias_id = a.id
    inner join domains as d
        on m.domain_id = d.id
    inner join users as u
        on m.user_id = u.id;


CREATE OR REPLACE FUNCTION public.postfix_getmaildir(username character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare
    maildir varchar(256);
BEGIN
    select into maildir md.path from mailboxes as mb
        inner join maildirs as md
            on mb.maildir_id = md.id
        inner join users as u
            on mb.user_id = u.id
        inner join domains as d
            on mb.domain_id = d.id
        where (u.name || '@' || d.domain) = username or u.name = username limit 1;
        
    return maildir;
END;
$function$;


CREATE OR REPLACE FUNCTION public.postfix_getmaildir(username character varying)
 RETURNS character varying
 LANGUAGE plpgsql
AS $function$
declare
    maildir varchar(256);
BEGIN
    select into maildir md.path from mailboxes as mb
        inner join maildirs as md
            on mb.maildir_id = md.id
        inner join users as u
            on mb.user_id = u.id
        inner join domains as d
            on mb.domain_id = d.id
        where (u.name || '@' || d.domain) = username or u.name = username limit 1;
        
    return maildir;
END;
$function$;


SELECT (((u.name::text || '@'::text) || d.domain::text))::character varying(256) AS "user", (('/home/mailer/'::text || md.path::text))::character varying(256) AS home, (('maildir:/home/mailer/'::text || md.path::text))::character varying(256) AS mail, 5003 AS uid, 5003 AS gid
   FROM mailboxes mb
   JOIN maildirs md ON mb.maildir_id = md.id
   JOIN users u ON mb.user_id = u.id
   JOIN domains d ON mb.domain_id = d.id
   

create or replace view dovecot_users as
SELECT u.name AS "user", (('/home/mailer/'::text || md.path::text))::character varying(256) AS home, (('maildir:/home/mailer/'::text || md.path::text))::character varying(256) AS mail, 5003 AS uid, 5003 AS gid
   FROM mailboxes mb
   JOIN maildirs md ON mb.maildir_id = md.id
   JOIN users u ON mb.user_id = u.id
   group by u.name, md.path;
   
   
   
SELECT (((u.name::text || '@'::text) || d.domain::text))::character varying(256) AS "user", u.password, (('/home/mailer/'::text || md.path::text))::character varying(256) AS userdb_home, (('maildir:/home/mailer/'::text || md.path::text))::character varying(256) AS userdb_mail, 5003 AS userdb_uid, 5003 AS userdb_gid
   FROM mailboxes mb
   JOIN maildirs md ON mb.maildir_id = md.id
   JOIN users u ON mb.user_id = u.id
   JOIN domains d ON mb.domain_id = d.id;
   

create or replace view dovecot_passwords as   
SELECT u.name AS "user", u.password, (('/home/mailer/'::text || md.path::text))::character varying(256) AS userdb_home, (('maildir:/home/mailer/'::text || md.path::text))::character varying(256) AS userdb_mail, 5003 AS userdb_uid, 5003 AS userdb_gid
   FROM mailboxes mb
   JOIN maildirs md ON mb.maildir_id = md.id
   JOIN users u ON mb.user_id = u.id
   group by u.name, md.path, u.password;
    







