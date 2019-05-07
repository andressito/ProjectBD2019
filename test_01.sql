--Proposer
insert into Proposer values (1, 1, '2018-06-05 20:00:00');
insert into Proposer values (2, 2, '2018-06-05 20:00:00');
insert into Proposer values (3, 2, '2018-06-05 20:00:00');

-- ETUDE
insert INTO EtudeProjet values(2, 1, FALSE, now(), 10000, 3);

insert INTO EtudeProjet values(2, 2, TRUE, now(), 10000, 3);
insert INTO EtudeProjet values(2, 3, TRUE, now(), 10000, 3);

-- ATTRIBUTION local
insert INTO AttribuerLocal values(now(), 1, 2);
insert INTO AttribuerLocal values(now(), 1, 3);


-- Participer
insert into Participer values (10, 2, now(), 20);

-- mis a jour date
UPDATE dateCourante SET dateCourante = '2019-06-05 20:00:00';
