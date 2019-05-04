CREATE OR REPLACE FUNCTION delaiFini(finProjet TIMESTAMP , now TIMESTAMP) RETURNS BOOLEAN AS $$
BEGIN
    IF ((finProjet::TIMESTAMP - now::TIMESTAMP) = '00:00:00') THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION getCurrentDate() RETURNS TIMESTAMP AS $$
BEGIN
    RETURN (SELECT dateCourante FROM DateCourante);
END
$$ language plpgsql;

CREATE OR REPLACE FUNCTION proposerProjet() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'DELETE') THEN
        INSERT INTO Archive SELECT 'SUPRESSION', getCurrentDate(), OLD.*;
        RETURN NULL;
    ELSIF (TG_OP = 'UPDATE') THEN
        INSERT INTO Archive SELECT 'PROPOSITION', getCurrentDate(), NEW.*;
        INSERT INTO Proposer SELECT getCurrentDate(), NEW.*;
        RETURN NEW;
    ELSIF (TG_OP = 'INSERT') THEN
        UPDATE Personne SET nombreProjet = nombreProjet + 1
                        WHERE idPersonne = NEW.idPersonne;
        INSERT INTO Archive SELECT 'PROPOSITION', getCurrentDate(), NEW.*;
        INSERT INTO Proposer SELECT NEW.*;
        RETURN NEW;
    END IF;
    RETURN NULL; -- le résultat est ignoré car il s'agit d'un trigger AFTER
END;
$$ language plpgsql;

CREATE TRIGGER tProposerProjet
    AFTER INSERT OR UPDATE OR DELETE ON Projet
    FOR EACH ROW EXECUTE PROCEDURE proposerProjet();

CREATE OR REPLACE FUNCTION apresEtude() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Archive SELECT 'ETUDE', getCurrentDate(), NEW.*;
    IF (NEW.decision) THEN
        INSERT INTO AttribuerLocal SELECT getCurrentDate(), NEW.idLocal, NEW.idProjet;
        RETURN NEW;
    ELSE
        DELETE FROM Projet
        WHERE idProjet = NEW.idProjet;
        RETURN NULL;
    END IF;
END;
$$ language plpgsql;

CREATE TRIGGER tApresEtude
    AFTER INSERT ON EtudeProjet
    FOR EACH ROW EXECUTE PROCEDURE apresEtude();

CREATE OR REPLACE FUNCTION apresAttribution() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO Archive SELECT 'ATTRIBUTION', getCurrentDate(), NEW.idProjet;
    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER tApresAttribution
    AFTER INSERT ON AttribuerLocal
    FOR EACH ROW EXECUTE PROCEDURE apresEtude();

CREATE OR REPLACE FUNCTION misAjour() RETURNS TRIGGER AS $$
BEGIN
  --à continuer demain
END;
$$ language plpgsql;

CREATE TRIGGER tMisAjour
    AFTER UPDATE OF dateCourante ON DateCourante
    FOR EACH ROW EXECUTE PROCEDURE misAjour();
