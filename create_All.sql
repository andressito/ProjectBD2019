DROP TABLE IF EXISTS DateCourante CASCADE;
DROP TABLE IF EXISTS EtudeProjet CASCADE;
DROP TABLE IF EXISTS Participer CASCADE;
DROP TABLE IF EXISTS Proposer CASCADE;
DROP TABLE IF EXISTS Archive CASCADE;
DROP TABLE IF EXISTS AttribuerLocal CASCADE;
DROP TABLE IF EXISTS Projet CASCADE;
DROP TABLE IF EXISTS Local CASCADE;
DROP TABLE IF EXISTS Expert CASCADE;
DROP TABLE IF EXISTS Developpeur CASCADE;
DROP TABLE IF EXISTS Beneficiaire CASCADE;
DROP TABLE IF EXISTS Personne CASCADE;

CREATE TABLE DateCourante(
  dateCourante TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Personne(
  idPersonne   SERIAL PRIMARY KEY,
  nom          VARCHAR NOT NULL,
  prenom       VARCHAR NOT NULL,
  email        VARCHAR NOT NULL,
  nombreProjet integer default 0
);

CREATE TABLE Expert(
  idExpert SERIAL PRIMARY KEY,
  dateEmbauche timestamp,
  salaire INTEGER NOT NULL,
  fonction varchar not null check ( fonction in ('DECISION','CODEUR'))
)INHERITS (Personne);

CREATE TABLE Developpeur(
  idDeveloppeur SERIAL PRIMARY KEY,
  status VARCHAR DEFAULT 'Debutant'
)INHERITS (Personne);

CREATE TABLE Beneficiaire(
    idBeneficiare SERIAL PRIMARY KEY,
    status VARCHAR DEFAULT 'Debutant',
    benefice integer default 0
)INHERITS (Personne);

CREATE TABLE Projet(
  idProjet    SERIAL PRIMARY KEY,
  nom         VARCHAR,
  description VARCHAR,
  dateDebut   TIMESTAMP,
  dateFin     TIMESTAMP,
  budget      INTEGER DEFAULT 0,
  reussite    boolean default false
);

CREATE TABLE Local(
  idLocal SERIAL PRIMARY KEY,
  capacite INTEGER not null,
  nom VARCHAR not null,
  libre boolean default false
);

CREATE TABLE EtudeProjet(
  idExpert    integer REFERENCES  Personne(idPersonne) ON DELETE CASCADE,
  idProjet    integer REFERENCES Projet(idProjet) ON DELETE CASCADE,
  decision    boolean not null,
  dateEtude   TIMESTAMP not null,
  budget      integer,
  duree       integer,
  PRIMARY KEY (idExpert,idProjet)
);

CREATE TABLE Participer(
  idPersonne   integer references Personne(idPersonne) ON DELETE CASCADE,
  idProjet     integer references Projet(idProjet) ON DELETE CASCADE,
  dateDon      timestamp,
  don          integer default 10,
  PRIMARY KEY (idPersonne,idProjet)
);

create table Proposer(
    idbeneficiare integer references beneficiaire(idbeneficiare)ON DELETE CASCADE,
    idProjet integer references Projet(idProjet) ON DELETE CASCADE,
    date timestamp,
    PRIMARY KEY (idbeneficiare,idProjet)
);

CREATE TABLE Archive(
  idArchive   SERIAL PRIMARY KEY,
  operation   varchar check (operation in ('PROPOSITION','ETUDE','ATTRIBUTION','PARTICIPATION','CLOTURE','SUPRESSION')),
  dateArchive TIMESTAMP,
  idProjet    integer references Projet(idProjet) ON DELETE CASCADE
);

CREATE TABLE AttribuerLocal(
  dateAttribution timestamp,
  idLocal         integer references Local(idLocal) ON DELETE CASCADE,
  idProjet        integer references Projet(idProjet) ON DELETE CASCADE,
  primary key (idLocal,idProjet)
);
