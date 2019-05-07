--FUNCTIONS

-- fonction qui libère un local ou occupe un local
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

-- vérifie si projet idP est attribué à un local
CREATE OR REPLACE FUNCTION estAttribuer(idP INTEGER) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (0 < (SELECT count(*) FROM AttribuerLocal
            WHERE idProjet = idP)
           );
END;
$$ language plpgsql;

-- verifie les projet qui debute le mois s'ils sont attribués à un local sinon NOTICE
CREATE OR REPLACE FUNCTION verifierLocal(idP INTEGER, debutP TIMESTAMP, now TIMESTAMP) RETURNS VOID AS $$
DECLARE
    moisDbP INT;
    moisNow INT;
BEGIN
    SELECT EXTRACT(MONTH FROM debutP::TIMESTAMP) INTO moisDbP;
    SELECT EXTRACT(MONTH FROM now::TIMESTAMP) INTO moisNow;

    IF (moisDbP = moisNow) THEN
        IF(NOT estAttribuer(idP)) THEN
            RAISE notice 'Projet % non attribué à un local !!', idP;
        END IF;
    END IF;
END;
$$ language plpgsql;

-- verifie projet si delaiFini Archive libere local sinon rien
CREATE OR REPLACE FUNCTION verifierProjet(idP INTEGER) RETURNS VOID AS $$
DECLARE
  now  TIMESTAMP;
  dFin TIMESTAMP;
  idB INTEGER;
  budgetP INTEGER;
  local INTEGER;

BEGIN

    SELECT dateCourante INTO now FROM DateCourante;
    SELECT budget INTO budgetP FROM Projet
    WHERE idProjet = idP;

    SELECT dateFin INTO dFin FROM Projet
    WHERE idProjet = idP;


    IF (delaiFini(dFin, now)) THEN
        SELECT idLocal INTO local FROM AttribuerLocal
        WHERE idProjet = idP;

        INSERT INTO Archive VALUES ('CLOTURE', getCurrentDate(), idP);
        PERFORM libererLocal(local, TRUE);

        DELETE FROM AttribuerLocal
        WHERE idProjet = idProjet AND idLocal = local;

        IF (reussite(idP)) THEN
            SELECT idBeneficiare INTO idB FROM Proposer
            WHERE idProjet = idP;

            RAISE NOTICE 'Projet % reussi', idP;

            UPDATE Beneficiaire SET benefice = (budgetP*0.4)
            WHERE idBeneficiare = idB;
            RAISE NOTICE 'benefice touché!!';
        ELSE
            RAISE NOTICE 'Projet % echoué', idP;
        END IF;
    END IF;

END;
$$ language plpgsql;


-- mis a jour status Developpeur
CREATE OR REPLACE FUNCTION misAjourStatuDev(idP INTEGER, s VARCHAR) RETURNS VOID AS $$
BEGIN
    UPDATE Developpeur SET status = s
    WHERE idDeveloppeur = idP;
END;
$$ language plpgsql;

-- mis à jour status dev peut etre changement de status
CREATE OR REPLACE FUNCTION misAjourNbProjet(idP INTEGER) RETURNS VOID AS $$
DECLARE
	nbProjet INTEGER;

BEGIN

    UPDATE Personne SET nombreProjet = (nombreProjet + 1)
    WHERE idPersonne = idP;

    SELECT nombreProjet INTO nbProjet FROM Personne
    WHERE idPersonne = idP;

    IF (10 < nbProjet) THEN
        PERFORM misAjourStatuDev(idP, 'AMATEUR');
        RAISE notice 'Developpeur % est devenu Amateur', idP;
    ELSIF (40 < nbProjet) THEN
        PERFORM changementStatuDev(idP);
    END IF;

END;
$$ language plpgsql;

-- mis à jour budget après chaque don
CREATE OR REPLACE FUNCTION misAjourBudget(idP INTEGER, montant INTEGER) RETURNS VOID AS $$
BEGIN
    UPDATE Projet SET budget = (budget + montant)
    WHERE idProjet = idP;
END;
$$ language plpgsql;

-- verifie si Developpeur
CREATE OR REPLACE FUNCTION estDeveloppeur(idP INTEGER) RETURNS BOOLEAN AS $$
DECLARE
  n INTEGER;
BEGIN
    SELECT count(*) INTO n FROM Developpeur
    WHERE idDeveloppeur = idP;

    RETURN (0 < n);
END;
$$ language plpgsql;

-- verifie si beneficiaire
CREATE OR REPLACE FUNCTION estBeneficaire(idB INTEGER) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (0 < (SELECT count(*) FROM Beneficiaire
            WHERE idBeneficiare = idB));
END;
$$ language plpgsql;

-- verifie si localEstLibre pour TRIGGER AttribuerLocal
CREATE OR REPLACE FUNCTION localEstLibre(idL INTEGER) RETURNS BOOLEAN AS $$
BEGIN
    RETURN (SELECT libre FROM Local
            WHERE idLocal = idL);
END;
$$ language plpgsql;

-- changement status dev integre Expert as CODEUR
CREATE OR REPLACE FUNCTION changementStatuDev(idD INTEGER) RETURNS VOID AS $$
DECLARE
    p Developpeur%ROWTYPE;
BEGIN

    SELECT * INTO p FROM Developpeur
    WHERE idDeveloppeur = idD;

    INSERT INTO Expert (nom, prenom, email, dateEmbauche, fonction)
    VALUES (p.nom, p.prenom, p.email, getCurrentDate(), 'CODEUR');

    RAISE NOTICE 'Le Developpeur % Integre notre équipe de CODEUR', idD;

    DELETE FROM Developpeur
    WHERE idDeveloppeur = idD;
END;
$$ language plpgsql;

-- changement status beneficiaire integre Expert as DECISION
CREATE OR REPLACE FUNCTION changementStatuBenef(idB INTEGER) RETURNS VOID AS $$
DECLARE
    p Beneficiaire%ROWTYPE;
BEGIN

    SELECT * INTO p FROM Beneficiaire
    WHERE idBeneficiare = idB;


    INSERT INTO Expert (nom, prenom, email, dateEmbauche, fonction)
    VALUES (p.nom, p.prenom, p.email, getCurrentDate(), 'DECISION');

    RAISE NOTICE 'Le beneficiaire % Integre notre équipe de DECISION', idB;

    DELETE FROM Beneficiaire
    WHERE idBeneficiare = idB;
END;
$$ language plpgsql;

-- si projet reussi
CREATE OR REPLACE FUNCTION reussite(idP INTEGER) RETURNS BOOLEAN AS $$
DECLARE
  budgetEt INTEGER;
  budgetP  INTEGER;

BEGIN
    SELECT budget INTO budgetP FROM Projet
    WHERE idProjet = idP;

    SELECT budget INTO budgetEt FROM EtudeProjet
    WHERE idProjet = idP;


    IF ((budgetEt- budgetP) > 0) THEN
      RETURN FALSE;
    ELSE
      RETURN TRUE;
    END IF;
END;
$$ language plpgsql;

-- si projet fini
CREATE OR REPLACE FUNCTION delaiFini(finProjet TIMESTAMP , now TIMESTAMP) RETURNS BOOLEAN AS $$
BEGIN
    IF ((finProjet::TIMESTAMP - now::TIMESTAMP) = '00:00:00') THEN
      RETURN TRUE;
    ELSE
      RETURN FALSE;
    END IF;
END;
$$ language plpgsql;

-- date courante
CREATE OR REPLACE FUNCTION getCurrentDate() RETURNS TIMESTAMP AS $$
BEGIN
    RETURN (SELECT dateCourante FROM DateCourante);
END
$$ language plpgsql;
