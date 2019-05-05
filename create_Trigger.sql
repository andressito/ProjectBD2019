CREATE OR REPLACE FUNCTION misAjourStatuDev(idP INTEGER, s VARCHAR) RETURNS VOID AS $$
BEGIN
    UPDATE Developpeur SET status = s
    WHERE idPersonne = idP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION misAjourNbProjet(idP INTEGER) RETURNS VOID AS $$
DECLARE
	nbProjet INTEGER;

BEGIN

    UPDATE Personne SET nombreProjet = (nombreProjet + 1)
    WHERE idPersonne = idP;

    SELECT nombreProjet INTO nbProjet FROM Personne
    WHERE idPersonne = idP;

    IF (10 < nbProjet) THEN
        EXECUTE misAjourStatuDev(idP, 'Amateur');
        RAISE notice 'Developpeur % est devenu Amateur', idP;
    ELSIF (40 < nbProjet) THEN
        EXECUTE changementStatuDev(idP);
    END IF;

END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION misAjourBudget(idP INTEGER, montant INTEGER) RETURNS VOID AS $$
BEGIN
    UPDATE Projet SET budget = (budget + montant)
    WHERE idProjet = idP;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION estDeveloppeur(idP INTEGER) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (0 < (SELECT count(*) FROM Developpeur
            WHERE idPersonne = idP));
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION localEstLibre(idL INTEGER) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT libre FROM Local
            WHERE idLocal = idL);
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION libererLocal(idL INTEGER, etat BOOLEAN) RETURNS VOID AS $$
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

CREATE OR REPLACE FUNCTION changementStatuDev(idD INTEGER) RETURNS VOID AS $$
BEGIN
    with p as (
      SELECT * FROM Developpeur
      WHERE idPersonne = idD
    )
    INSERT INTO Expert (idPersonne, nom, prenom, email, dateEmbauche, fonction)
    VALUES (p.idPersonne, p.nom, p.prenom, p.email, getCurrentDate(), 'CODEUR');

    RAISE NOTICE 'Le Developpeur % Integre notre équipe de CODEUR', idD;

    DELETE FROM Developpeur
    WHERE idPersonne = idD;
END;
$$ language plpgsql;

CREATE OR REPLACE FUNCTION changementStatuBenef(idB INTEGER) RETURNS VOID AS $$
BEGIN
    with p as (
      SELECT * FROM Beneficiaire
      WHERE idPersonne = idB
    )

    INSERT INTO Expert (idPersonne, nom, prenom, email, dateEmbauche, fonction)
    VALUES (p.idPersonne, p.nom, p.prenom, p.email, getCurrentDate(), 'DECISION');

    RAISE NOTICE 'Le beneficiaire % Integre notre équipe de DECISION', idB;

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
BEGIN
    IF (TG_OP = 'DELETE') THEN

        INSERT INTO Archive SELECT 'SUPRESSION', getCurrentDate(), OLD.idProjet;
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

    END IF;
    RETURN NULL;
END;
$$ language plpgsql;

CREATE TRIGGER tOnProjet
    AFTER UPDATE OR DELETE ON Projet
    FOR EACH ROW EXECUTE PROCEDURE fOnProjet();

CREATE OR REPLACE FUNCTION fOnProposer() RETURNS TRIGGER AS $$
DECLARE
  nbProjet INTEGER;
BEGIN

    INSERT INTO Archive SELECT 'PROPOSITION', getCurrentDate(), NEW.*;

    UPDATE Personne SET nombreProjet = nombreProjet + 1
                    WHERE idPersonne = NEW.idBeneficiare;

    SELECT nombreProjet INTO nbProjet FROM Personne
    WHERE idPersonne = NEW.idBeneficiare;

    IF (10 < nbProjet) THEN
        EXECUTE changementStatuBenef(NEW.idBeneficiare);
    END IF;
    RETURN NEW;--
END;
$$ language plpgsql;

CREATE TRIGGER tOnProposer
    AFTER INSERT ON Proposer
    FOR EACH ROW EXECUTE PROCEDURE fOnProposer();

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


CREATE OR REPLACE FUNCTION avantAttribution() RETURNS TRIGGER AS $$
BEGIN
    IF (localEstLibre(OLD.idLocal)) THEN
        RETURN NEW;
    ELSE
        RETURN NULL;
    END IF;
END;
$$ language plpgsql;

CREATE TRIGGER tAvantAttribution
    BEFORE INSERT ON AttribuerLocal
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
