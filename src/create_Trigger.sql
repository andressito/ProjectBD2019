--- TRIGGER

-- TRIGGER après operation DELETE UPDATE projet
CREATE OR REPLACE FUNCTION fOnProjet() RETURNS TRIGGER AS $$

BEGIN
    IF (TG_OP = 'DELETE') THEN
        RAISE notice 'projet % supprimé',OLD.idProjet;
        RETURN NULL;

    ELSIF (TG_OP = 'UPDATE') THEN

        IF (reussite(NEW.idProjet)) THEN
            RAISE notice 'budget atteint!!';
        ELSE
            RAISE notice 'don reçu';
        END IF;
    END IF;
    RETURN NULL;
END;
$$ language plpgsql;

CREATE TRIGGER tOnProjet
    AFTER UPDATE OR DELETE ON Projet
    FOR EACH ROW EXECUTE PROCEDURE fOnProjet();

-- TRIGGER en PROPOSITION après INSERT
CREATE OR REPLACE FUNCTION fOnProposer() RETURNS TRIGGER AS $$
DECLARE
  nbProjet INTEGER;
BEGIN

    INSERT INTO Archive (operation, dateArchive, idProjet) VALUES ('PROPOSITION', getCurrentDate(), NEW.idProjet);

    UPDATE Personne SET nombreProjet = nombreProjet + 1
                    WHERE idPersonne = NEW.idBeneficiare;

    SELECT nombreProjet INTO nbProjet FROM Personne
    WHERE idPersonne = NEW.idBeneficiare;

    IF (10 < nbProjet) THEN
        PERFORM changementStatuBenef(NEW.idBeneficiare);
    END IF;
    RETURN NEW;--
END;
$$ language plpgsql;

CREATE TRIGGER tOnProposer
    AFTER INSERT ON Proposer
    FOR EACH ROW EXECUTE PROCEDURE fOnProposer();

-- avant INSERT Proposer si beneficiaire
CREATE OR REPLACE FUNCTION fAvantProposer() RETURNS TRIGGER AS $$
BEGIN
    IF (NOT estBeneficaire(NEW.idBeneficiare)::BOOLEAN) THEN
        RAISE notice 'not not';
        RETURN NULL;
    END IF;
    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER tAvantProposer
    BEFORE INSERT ON Proposer
    FOR EACH ROW EXECUTE PROCEDURE fAvantProposer();

-- après Etude
CREATE OR REPLACE FUNCTION apresEtude() RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.decision) THEN
        INSERT INTO Archive (operation, dateArchive, idProjet) VALUES ('ETUDE', getCurrentDate(), NEW.idProjet);
        RETURN NEW;
    ELSE
        DELETE FROM Projet
        WHERE idProjet = NEW.idProjet;
        RETURN NULL;
    END IF;
END;
$$ language plpgsql;

CREATE TRIGGER tApresEtude
    BEFORE INSERT ON EtudeProjet
    FOR EACH ROW EXECUTE PROCEDURE apresEtude();

-- après ATTRIBUTION local occupé
CREATE OR REPLACE FUNCTION apresAttribution() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Archive (operation, dateArchive, idProjet) VALUES ('ATTRIBUTION', getCurrentDate(), NEW.idProjet);
    PERFORM libererLocal(NEW.idLocal, FALSE);
    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER tApresAttribution
    AFTER INSERT ON AttribuerLocal
    FOR EACH ROW EXECUTE PROCEDURE apresAttribution();


-- avant ATTRIBUTION check localEstLibre
CREATE OR REPLACE FUNCTION avantAttribution() RETURNS TRIGGER AS $$
BEGIN
    IF (localEstLibre(NEW.idLocal)) THEN
        RAISE NOTICE 'local % libre bien attribué',NEW.idLocal;
        RETURN NEW;
    ELSE
        RAISE NOTICE 'local % occupé pas attirbué',NEW.idLocal;
        RETURN NULL;
    END IF;
END;
$$ language plpgsql;

CREATE TRIGGER tAvantAttribution
    BEFORE INSERT ON AttribuerLocal
    FOR EACH ROW EXECUTE PROCEDURE avantAttribution();

-- mis à jour apès changement de date
CREATE OR REPLACE FUNCTION misAjour() RETURNS TRIGGER AS $$
DECLARE
    idP INTEGER;
    now TIMESTAMP;
    dbPr TIMESTAMP;
BEGIN
    SELECT dateCourante INTO now FROM DateCourante;

    FOR idP IN SELECT idProjet FROM EtudeProjet
      LOOP
          SELECT dateDebut INTO dbPr FROM Projet;
          PERFORM verifierLocal(idP, dbPr, now);
          PERFORM verifierProjet(idP);
    END LOOP;

    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER tMisAjour
    AFTER UPDATE OF dateCourante ON DateCourante
    FOR EACH ROW EXECUTE PROCEDURE misAjour();

-- après participation INSERT ou UPDATE
CREATE OR REPLACE FUNCTION participation() RETURNS TRIGGER AS $$

BEGIN

    INSERT INTO Archive (operation, dateArchive, idProjet) VALUES ('PARTICIPATION', getCurrentDate(), NEW.idProjet);

    UPDATE Projet SET budget = budget + NEW.don
    WHERE idProjet = NEW.idProjet;

    IF (estDeveloppeur(NEW.idPersonne)) THEN
        PERFORM misAjourNbProjet(NEW.idPersonne);
    END IF;

    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER tParticipation
    AFTER INSERT OR UPDATE ON Participer
    FOR EACH ROW EXECUTE PROCEDURE participation();
