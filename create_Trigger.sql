CREATE OR REPLACE FUNCTION misAjourStatuDev(idP SERIAL, s VARCHAR) RETURNS VOID AS $$
BEGIN
    UPDATE Developpeur SET status = s
    WHERE idPersonne = idP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION misAjourNbProjet(idP SERIAL) RETURNS VOID AS $$
DECLARE
	nbProjet INTEGER;

BEGIN

    UPDATE Personne SET nombreProjet = (nombreProjet + 1)
    WHERE idPersonne = idP;

    SELECT nombreProjet INTO nbProjet FROM Personne
    WHERE idPersonne = idP;

    IF (10 < nbProjet) THEN
        misAjourStatuDev(idP, 'Amateur');
        RAISE notice 'Developpeur % est devenu Amateur', idP;
    ELSIF (40 < nbProjet) THEN
        changementStatuDev(idP);
    END IF;

END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION misAjourBudget(idP SERIAL, montant INTEGER) RETURNS VOID AS $$
BEGIN
    UPDATE Projet SET budget = (budget + montant)
    WHERE idProjet = idP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION estDeveloppeur(idP SERIAL) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (0 < (SELECT count(*) FROM Developpeur
            WHERE idPersonne = idP));
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION localEstLibre(idL SERIAL) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT libre FROM Local
            WHERE idLocal = idL);
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION libererLocal(idL SERIAL, BOOLEAN etat) RETURNS VOID AS $$
BEGIN

    IF (etat) THEN
      RAISE notice 'le local % est libre', idL;
    ELSE
      RAISE notice 'le local % est occupé', idL;
    END IF;

    UPDATE Local SET libre = etat
    WHERE idLocal = idL;

END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION changementStatuDev(idD SERIAL) RETURNS VOID AS $$
BEGIN
    with p as (
      SELECT * FROM Developpeur
      WHERE idPersonne = idD
    )

    RAISE notic 'Le Developpeur % \n nom: % , prenom: % \n Integre notre équipe de CODEUR'
                , p.idPersonne, p.nom, p.prenom;

    INSERT INTO Expert (idPersonne, nom, prenom, email, dateEmbauche, fonction)
    VALUES (p.idPersonne, p.nom, p.prenom, p.email, getCurrentDate(), 'CODEUR');

    DELETE FROM Developpeur
    WHERE idPersonne = idD;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION changementStatuBenef(idB SERIAL) RETURNS VOID AS $$
BEGIN
    with p as (
      SELECT * FROM Beneficiaire
      WHERE idPersonne = idB
    )

    RAISE notic 'Le beneficiaire % \n nom: % , prenom: % \n Integre notre équipe de DECISION'
                , p.idPersonne, p.nom, p.prenom;

    INSERT INTO Expert (idPersonne, nom, prenom, email, dateEmbauche, fonction)
    VALUES (p.idPersonne, p.nom, p.prenom, p.email, getCurrentDate(), 'DECISION');

    DELETE FROM Beneficiaire
    WHERE idPersonne = idB;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION reussite(budgetProjet INTEGER , budgetEtude INTEGER) RETURNS BOOLEAN AS $$
BEGIN
    IF (budgetEtude <= budgetProjet) THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
END;
$$ language plpgsql;

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

CREATE OR REPLACE FUNCTION fOnProjet() RETURNS TRIGGER AS $$
DECLARE
  budgetP  INTEGER;
  budgetEt INTEGER;
  nbProjet INTEGER;
BEGIN
    IF (TG_OP = 'DELETE') THEN

        INSERT INTO Archive SELECT 'SUPRESSION', getCurrentDate(), OLD.*;
        RETURN NULL;

    ELSIF (TG_OP = 'UPDATE') THEN

        SELECT budget INTO budgetP FROM Projet
        WHERE idProjet = NEW.idProjet;
        SELECT budget INTO budgetEt FROM EtudeProjet
        WHERE idProjet = NEW.idProjet;

        IF (reussite(budgetP, budgetEt)) THEN
            RAISE notice 'budget atteint!!';
        ELSE
            RAISE notice 'don reçu % $ restant', (budgetEt - budgetP);
        END IF;
        RETURN NEW;

    ELSIF (TG_OP = 'INSERT') THEN

        UPDATE Personne SET nombreProjet = nombreProjet + 1
                        WHERE idPersonne = NEW.idPersonne;

        INSERT INTO Archive SELECT 'PROPOSITION', getCurrentDate(), NEW.*;
        INSERT INTO Proposer SELECT NEW.idPersonne, NEW.idProjet, getCurrentDate();

        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ language plpgsql;

CREATE TRIGGER tOnProjet
    AFTER INSERT OR UPDATE OR DELETE ON Projet
    FOR EACH ROW EXECUTE PROCEDURE fOnProjet();

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
  --reste à faire
END;
$$ language plpgsql;

CREATE TRIGGER tMisAjour
    AFTER UPDATE OF dateCourante ON DateCourante
    FOR EACH ROW EXECUTE PROCEDURE misAjour();

CREATE OR REPLACE FUNCTION participation() RETURNS TRIGGER AS $$

BEGIN

    INSERT INTO Archive SELECT 'PARTICIPATION', getCurrentDate(), NEW.idProjet;

    UPDATE Projet SET budget = (budget + NEW.don)
    WHERE idProjet = NEW.idProjet;

    IF (estDeveloppeur(NEW.idPersonne)) THEN
        EXECUTE misAjourNbProjet(NEW.idPersonne);
    END IF;

    RETURN NEW;
END;
$$ language plpgsql;

CREATE TRIGGER tParticipation
    AFTER INSERT OR UPDATE ON Participer
    FOR EACH ROW EXECUTE PROCEDURE participation();
