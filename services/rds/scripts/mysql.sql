drop table if exists pessoa;
create table pessoa(
    id char(36)primary key,
    nome varchar(100) not null,
    data_nascimento date);

insert into pessoa values(uuid(), 'Fábio', '1990-01-01');
insert into pessoa values(uuid(), 'João da Silva', '1990-01-01');
insert into pessoa values(uuid(), 'Pedro Sampaio', '1990-01-01');
insert into pessoa values(uuid(), 'Mario Gomes', '1990-01-01');

select count(*) from pessoa;

-- delete from pessoa;

show processlist;