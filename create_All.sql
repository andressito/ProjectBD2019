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
  dateCourante TIMESTAMP DEFAULT CURRENT_DATE
);

CREATE TABLE Personne(
  idPersonne   SERIAL PRIMARY KEY,
  nom          VARCHAR NOT NULL,
  prenom       VARCHAR NOT NULL,
  email        VARCHAR NOT NULL,
  nombreProjet integer default 0
);

CREATE TABLE Expert(
  dateEmbauche timestamp,
  salaire      INTEGER NOT NULL,
  fonction     varchar not null check (fonction in ('DECISION','CODEUR'))
)INHERITS (Personne);

CREATE TABLE Developpeur(
  status VARCHAR DEFAULT 'Debutant'
)INHERITS (Personne);

CREATE TABLE Beneficiaire(
  status   VARCHAR DEFAULT 'Debutant',
  benefice integer default 0
)INHERITS (Personne);

CREATE TABLE Projet(
  idProjet    SERIAL PRIMARY KEY,
  nom         VARCHAR,
  description VARCHAR,
  dateDebut   TIMESTAMP,
  dateFin     TIMESTAMP,
  budget      INTEGER,
  reussite    boolean default false
);

CREATE TABLE Local(
  idLocal  SERIAL PRIMARY KEY,
  capacite INTEGER,
  occuper  boolean default false
);

CREATE TABLE EtudeProjet(
  idExpert    integer REFERENCES  Personne(idPersonne) ON DELETE CASCADE,
  idProjet    integer REFERENCES Projet(idProjet) ON DELETE CASCADE,
  idLocal     integer REFERENCES Local(idLocal) ON DELETE CASCADE,
  decision    boolean not null,
  dateEtude   TIMESTAMP not null,
  budget      integer ,
  duree       integer,
  PRIMARY KEY (idExpert,idProjet)
);

CREATE TABLE Participer(
  idParticiper SERIAL PRIMARY KEY,
  date         timestamp,
  don          integer default 0,
  idPersonne   integer references Personne(idPersonne) ON DELETE CASCADE,
  idProjet     integer references Projet(idProjet) ON DELETE CASCADE
);

create table Proposer(
  idBeneficiare integer references Personne(idPersonne)ON DELETE CASCADE,
  date          timestamp,
  idProjet      integer references Projet(idProjet) ON DELETE CASCADE,
  PRIMARY KEY (idBeneficiare,idProjet)
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
