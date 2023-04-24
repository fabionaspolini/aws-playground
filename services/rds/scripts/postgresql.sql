--create database lambda_test;

drop table if exists pessoa;
create table pessoa(
    id uuid primary key,
    nome varchar(100) not null,
    data_nascimento date);

insert into pessoa values(gen_random_uuid(), 'Fábio', '1990-01-01');
insert into pessoa values(gen_random_uuid(), 'João da Silva', '1990-01-01');
insert into pessoa values(gen_random_uuid(), 'Pedro Sampaio', '1990-01-01');
insert into pessoa values(gen_random_uuid(), 'Mario Gomes', '1990-01-01');

select * from pessoa;

--delete from pessoa;
