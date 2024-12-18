--************* TABLE LIEU ******************

CREATE TABLE Lieu
	(idLieu INTEGER PRIMARY KEY,
	NomLieu VARCHAR2 (30) NOT NULL,
	Adresse VARCHAR2 (100) NOT NULL,
    capacite NUMBER NOT NULL);

************** TABLE ARTISTE ******************


CREATE TABLE Artiste
	(idArt INTEGER PRIMARY KEY,
	NomArt VARCHAR2 (30) NOT NULL,
	PrenomArt VARCHAR2 (30) NOT NULL,
        specialite VARCHAR2 (10) NOT NULL);

************** TABLE SPECTACLE******************

CREATE TABLE SPECTACLE 
	(idSpec INTEGER PRIMARY KEY,
	Titre VARCHAR2 (40) NOT NULL,
         dateS DATE NOT NULL,
         h_debut NUMBER(4,2) NOT NULL,
	 dureeS NUMBER(4,2) NOT NULL,
         nbrSpectateur INTEGER NOT NULL,
	 idLieu INTEGER,
	
	CONSTRAINT chk_spect_durees CHECK (dureeS BETWEEN 1 AND 4),
    CONSTRAINT FK_spect_Lieux FOREIGN KEY(idLieu)REFERENCES Lieu (idLieu));

************** TABLE RUBRIQUE******************

CREATE TABLE Rubrique
	(idRub INTEGER PRIMARY KEY, 
	 idSpec INTEGER NOT NULL, 
	 idArt INTEGER NOT NULL, 
	 H_debutR NUMBER(4,2) NOT NULL, 
         dureeRub NUMBER(4,2) NOT NULL, 
         Rtype VARCHAR2(10), 
CONSTRAINT fk_rub_spect FOREIGN KEY(idSpec) REFERENCES SPECTACLE(idSpec) ON DELETE CASCADE,
CONSTRAINT fk_rub_art FOREIGN KEY(idArt)  REFERENCES Artiste(idArt) ON DELETE CASCADE );

 
************** TABLE BILLETS******************
CREATE TABLE BILLET
	(idBillet INTEGER PRIMARY KEY,
	categorie VARCHAR2(10),
	prix NUMBER(5,2) NOT NULL,

	idspec INTEGER NOT NULL ,
	Vendu VARCHAR(3) NOT NULL, 

CONSTRAINT chk_billet_PRIX CHECK(prix BETWEEN 10 AND 300),
CONSTRAINT fk_billet_spec FOREIGN KEY (idspec)REFERENCES spectacle,
CONSTRAINT chk_billet_vendu CHECK(vendu IN ('Oui','Non'))
);

CREATE TABLE Client (
    idClt INT PRIMARY KEY,          
    nomClt VARCHAR2(100) NOT NULL, 
    prenomClt VARCHAR2(100),
    tel VARCHAR2(15),               
    email VARCHAR2(100) NOT NULL,   
    motP VARCHAR2(255) NOT NULL,    
    CONSTRAINT email_format CHECK (email LIKE '%_@__%.__%'), 
    
    
    CONSTRAINT tel_format CHECK (LENGTH(tel) BETWEEN 12 AND 15 AND tel LIKE '+216%')  
);

SELECT constraint_name
FROM user_cons_columns
WHERE table_name = 'CLIENT' AND column_name = 'TEL';

ALTER TABLE Client
DROP CONSTRAINT tel_format;

ALTER TABLE Client
ADD CONSTRAINT tel_start CHECK (tel LIKE '2%' OR tel LIKE '4%' OR tel LIKE '5%' OR tel LIKE '9%');


ALTER TABLE Lieu
ADD CONSTRAINT capacite_check CHECK (capacite BETWEEN 100 AND 2000);


ALTER TABLE Artiste
ADD CONSTRAINT specialite_check CHECK (specialite IN ('danseur', 'acteur', 'musicien', 'magicien', 'imitateur', 'humoriste', 'chanteur'));

ALTER TABLE Rubrique
ADD CONSTRAINT type_check CHECK (Rtype IN ('comédie', 'théâtre', 'danse', 'imitation', 'magie', 'musique', 'chant'));

ALTER TABLE Billet
ADD CONSTRAINT categorie_check CHECK (categorie IN ('Gold', 'Silver', 'Normale'));

CREATE SEQUENCE client_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE lieu_seq
START WITH 17
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE artiste_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE spectacle_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE rubrique_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

CREATE SEQUENCE billet_seq
START WITH 1
INCREMENT BY 1
NOCACHE
NOCYCLE;

DROP SEQUENCE spectacle_seq;

CREATE SEQUENCE spectacle_seq
START WITH 17
INCREMENT BY 1
NOCACHE
NOCYCLE;
select * from lieu 


--function to auto increment nombre of spectatorswhen a tickets get sold--
CREATE OR REPLACE TRIGGER update_spectateur_count
AFTER UPDATE ON Billet
FOR EACH ROW
WHEN (NEW.vendu = 'Oui' AND OLD.vendu = 'Non') 
BEGIN
    UPDATE Spectacle
    SET nbrSpectateur = nbrSpectateur + 1
    WHERE idSpec = :NEW.idSpec; 
END;
 
CREATE OR REPLACE TRIGGER trg_check_spectacle_capacity
BEFORE INSERT OR UPDATE ON Spectacle
FOR EACH ROW
DECLARE
    v_capacite NUMBER; -- Variable pour stocker la capacité maximale du lieu
BEGIN
    -- Récupérer la capacité du lieu
    SELECT capacite 
    INTO v_capacite
    FROM Lieu
    WHERE idLieu = :NEW.idLieu;

    -- Vérifier si le nombre de spectateurs dépasse la capacité
    IF :NEW.nbrSpectateur > v_capacite THEN
        RAISE_APPLICATION_ERROR(-20002, 'Erreur : Le nombre de spectateurs dépasse la capacité maximale du lieu.');
    END IF;
END;
/

CREATE OR REPLACE TRIGGER check_spectacle_date
BEFORE INSERT OR UPDATE ON Spectacle
FOR EACH ROW
BEGIN
    -- Check if the date of the Spectacle is in the future
    IF :NEW.dateS <= SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20004, 'The date of the spectacle must be in the future.');
    END IF;
END;

CREATE OR REPLACE TRIGGER check_venue_availability
BEFORE UPDATE ON Spectacle
DECLARE
    v_conflicts NUMBER;
BEGIN
    -- Validation globale pour toutes les lignes affectées
    SELECT COUNT(*)
    INTO v_conflicts
    FROM Spectacle
    WHERE idLieu IN (SELECT DISTINCT idLieu FROM Spectacle)
      AND dateS IN (SELECT DISTINCT dateS FROM Spectacle);

    -- Si des conflits sont détectés
    IF v_conflicts > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Lieu Déja Reservé .');
    END IF;
END;
/
Drop trigger check_venue_availability

CREATE OR REPLACE TRIGGER check_rubrique_count
BEFORE INSERT OR UPDATE ON Rubrique
FOR EACH ROW
DECLARE
    v_count INTEGER;
BEGIN

    SELECT COUNT(*)
    INTO v_count
    FROM Rubrique
    WHERE idSpec = :NEW.idSpec;
    
    IF v_count >= 3 THEN
        RAISE_APPLICATION_ERROR(-20006, 'A spectacle can have no more than 3 rubriques.');
    END IF;
END;
/


CREATE OR REPLACE TRIGGER check_rubrique_duration
BEFORE INSERT OR UPDATE ON Rubrique
FOR EACH ROW
DECLARE
    v_spect_duration NUMBER;
BEGIN
    SELECT dureeS
    INTO v_spect_duration
    FROM Spectacle
    WHERE idSpec = :NEW.idSpec;

    IF :NEW.dureeRub > v_spect_duration THEN
        RAISE_APPLICATION_ERROR(-20008, 'The rubrique duration exceeds the duration of the spectacle.');
    END IF;
END;



-- Désactiver les triggers sur la table Billet
ALTER TRIGGER update_spectateur_count DISABLE;

-- Désactiver les triggers sur la table Spectacle
ALTER TRIGGER trg_check_spectacle_capacity DISABLE;
ALTER TRIGGER check_spectacle_date DISABLE;
ALTER TRIGGER check_venue_availability DISABLE;

-- Désactiver les triggers sur la table Rubrique
ALTER TRIGGER check_rubrique_count  DISABLE ; 
ALTER TRIGGER check_rubrique_duration DISABLE;

SELECT trigger_name, status
FROM user_triggers
WHERE trigger_name = 'TRG_UPDATE_RUBRIQUES';
SELECT *
FROM user_dependencies
WHERE name = 'TRG_UPDATE_RUBRIQUES';

dROP TRIGGER TRG_UPDATE_RUBRIQUES ;

ALTER TRIGGER TRG_UPDATE_RUBRIQUES COMPILE ;

----------------------------------FUNCTIONS------------------------------------


---------------------------------Ajouter Lieu----------------------------------
CREATE OR REPLACE PROCEDURE ajouter_lieu (
    p_nomLieu IN Lieu.nomLieu%TYPE,
    p_Adresse IN Lieu.Adresse%TYPE,
    p_capacite IN Lieu.capacite%TYPE
) IS
    -- Exception personnalisée pour une capacité invalide
    e_capacite_invalide EXCEPTION;
BEGIN
    -- Vérification de la capacité
    IF p_capacite < 100 OR p_capacite > 2000 THEN
        RAISE e_capacite_invalide;
    END IF;

    -- Insertion dans la table Lieu
    INSERT INTO Lieu (idLieu, nomLieu, Adresse, capacite)
    VALUES (lieu_seq.NEXTVAL, p_nomLieu, p_Adresse, p_capacite);

    DBMS_OUTPUT.PUT_LINE('Lieu ajouté avec succès');
EXCEPTION
    WHEN e_capacite_invalide THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : La capacité doit être comprise entre 100 et 2000.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur inconnue : ' || SQLERRM);
END ajouter_lieu;
/

BEGIN
    ajouter_lieu(
        p_nomLieu => 'Théâtre Municipal',
        p_Adresse => '10 Rue Habib Bourguiba',
        p_capacite => 1200
    );
END;
/
select * from lieu ; 
SELECT lieu_seq.NEXTVAL FROM dual;


---------------------------------Supprimer Lieu----------------------------------
CREATE OR REPLACE PROCEDURE supprimer_lieu (
    p_idLieu IN Lieu.idLieu%TYPE
) IS
    v_spectacle_count NUMBER;
BEGIN
    -- Vérifier si des spectacles sont liés au lieu
    SELECT COUNT(*)
    INTO v_spectacle_count
    FROM Spectacle
    WHERE idLieu = p_idLieu;

    IF v_spectacle_count = 0 THEN
        -- Suppression physique si aucun spectacle n'est lié
        DELETE FROM Lieu
        WHERE idLieu = p_idLieu;
        
        DBMS_OUTPUT.PUT_LINE('Lieu supprimé physiquement.');
    ELSE
        -- Suppression logique (changement de statut)
        UPDATE Lieu
        SET status = 'DELETED'
        WHERE idLieu = p_idLieu;

        DBMS_OUTPUT.PUT_LINE('Lieu marqué comme "DELETED".');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END supprimer_lieu;
/


DROP PROCEDURE supprimer_lieu;

CREATE OR REPLACE PROCEDURE supprimer_lieu (
    p_idLieu IN Lieu.idLieu%TYPE
) IS
    v_spectacle_count NUMBER;
    v_lieu_exists NUMBER;
BEGIN
    -- Vérifier si l'idLieu existe dans la table Lieu
    SELECT COUNT(*)
    INTO v_lieu_exists
    FROM Lieu
    WHERE idLieu = p_idLieu;

    IF v_lieu_exists = 0 THEN
        -- Lever une exception si l'ID du lieu n'existe pas
        RAISE_APPLICATION_ERROR(-20010, 'Le lieu avec l''ID ' || p_idLieu || ' n''existe pas.');
    END IF;

    -- Vérifier si des spectacles sont liés au lieu
    SELECT COUNT(*)
    INTO v_spectacle_count
    FROM Spectacle
    WHERE idLieu = p_idLieu;

    IF v_spectacle_count = 0 THEN
        -- Suppression physique si aucun spectacle n'est lié
        DELETE FROM Lieu
        WHERE idLieu = p_idLieu;

        DBMS_OUTPUT.PUT_LINE('Lieu supprimé physiquement.');
    ELSE
        -- Suppression logique (changement de statut)
        UPDATE Lieu
        SET status = 'DELETED'
        WHERE idLieu = p_idLieu;

        DBMS_OUTPUT.PUT_LINE('Lieu marqué comme "DELETED".');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END supprimer_lieu;
/

BEGIN
    supprimer_lieu(p_idLieu => 24);
END;
/
BEGIN
    supprimer_lieu(p_idLieu => 18);
END;
/

set serverout on 
BEGIN 
    DBMS_OUTPUT.PUT_LINE('Lieu marqué comme "DELETED"' );
END;
/

INSERT INTO Spectacle (idSpec, Titre, dateS, h_debut, dureeS, nbrSpectateur, idLieu)
VALUES (spectacle_seq.NEXTVAL, 'Spectacle de danse', TO_DATE('2024-12-20', 'YYYY-MM-DD'), 18.00, 2.00, 0, 23);
 
select * from spectacle 
BEGIN
    supprimer_lieu(p_idLieu => 23);
END;
/
select * from lieu ; 

DELETE FROM Spectacle
WHERE idLieu = 23;

------------------------Modifier lieu ------------------------------------------
CREATE OR REPLACE PROCEDURE modifier_lieu (
    p_idLieu IN Lieu.idLieu%TYPE,
    p_nomLieu IN Lieu.nomLieu%TYPE DEFAULT NULL,
    p_capacite IN Lieu.capacite%TYPE DEFAULT NULL
) IS
    v_lieu_exists NUMBER;  -- Declare the variable to check if the place exists
BEGIN
    -- Check if the idLieu exists in the Lieu table
    SELECT COUNT(*)
    INTO v_lieu_exists
    FROM Lieu
    WHERE idLieu = p_idLieu and status = 'ACTIVE';

    IF v_lieu_exists = 0 THEN
        -- If no rows are found, raise an application error indicating the lieu does not exist
        RAISE_APPLICATION_ERROR(-20011, 'Le lieu avec l''ID ' || p_idLieu || ' n''existe pas.');
    END IF;

    -- Update the lieu if it exists
    UPDATE Lieu
    SET 
        nomLieu = NVL(p_nomLieu, nomLieu),  -- Don't modify if p_nomLieu is NULL
        capacite = NVL(p_capacite, capacite) -- Don't modify if p_capacite is NULL
    WHERE idLieu = p_idLieu;

    DBMS_OUTPUT.PUT_LINE('Lieu mis à jour avec succès.');

EXCEPTION
    WHEN OTHERS THEN
        -- Handle any other unexpected errors
        DBMS_OUTPUT.PUT_LINE('Erreur inattendue : ' || SQLERRM);
END modifier_lieu;
/


Drop procedure modifier_lieu

---Test----------------
----ID n'existe pas ------
BEGIN
    modifier_lieu(p_idLieu => 23, p_nomLieu => 'Théâtre rénové');
END;
/

--ID existant -----------
BEGIN
    modifier_lieu(p_idLieu => 24, p_nomLieu => 'Théâtre rénové');
END;
/
BEGIN
    modifier_lieu(p_idLieu => 24, p_nomLieu => 'Théâtre rénové', p_capacite => 1500);
END;
/

select * from lieu 

-----------------------search_lieu----------------------------------------------

CREATE OR REPLACE FUNCTION search_lieu (
    p_nomLieu IN VARCHAR2 DEFAULT NULL,
    p_capacite IN NUMBER DEFAULT NULL
) RETURN SYS_REFCURSOR IS
    v_cursor SYS_REFCURSOR;  -- Déclare la variable pour le curseur
BEGIN
    -- Exécution de la requête pour rechercher les lieux
    OPEN v_cursor FOR
        SELECT idLieu, NomLieu, Adresse, capacite, status
        FROM Lieu
        WHERE status = 'ACTIVE' -- Seulement les lieux actifs
        AND (p_nomLieu IS NULL OR LOWER(NomLieu) LIKE '%' || LOWER(p_nomLieu) || '%') -- Recherche par nom (insensible à la casse)
        AND (p_capacite IS NULL OR capacite = p_capacite); -- Recherche par capacité (exacte)

    -- Retourner le curseur
    RETURN v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        -- Gestion des erreurs
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
        RETURN NULL; -- Retourner NULL en cas d'erreur
END search_lieu;
/

CREATE OR REPLACE PROCEDURE afficher_resultats (
    p_cursor IN SYS_REFCURSOR
) IS
    v_idLieu Lieu.idLieu%TYPE;
    v_nomLieu Lieu.nomLieu%TYPE;
    v_adresse Lieu.Adresse%TYPE;
    v_capacite Lieu.capacite%TYPE;
    v_status Lieu.status%TYPE;
    v_count INTEGER := 0; -- Compteur pour vérifier si des résultats ont été trouvés
BEGIN
    -- Parcourir le curseur pour afficher les résultats
    LOOP
        FETCH p_cursor INTO v_idLieu, v_nomLieu, v_adresse, v_capacite, v_status;
        EXIT WHEN p_cursor%NOTFOUND;

        -- Afficher les résultats
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_idLieu || ' | Nom: ' || v_nomLieu || ' | Adresse: ' || v_adresse || ' | Capacité: ' || v_capacite);
        v_count := v_count + 1;
    END LOOP;

    -- Vérifier si aucun résultat n'a été trouvé
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Aucun résultat correspondant.');
    END IF;

    -- Fermer le curseur
    CLOSE p_cursor;

EXCEPTION
    WHEN OTHERS THEN
        -- Gestion des erreurs
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
        -- Fermer le curseur en cas d'erreur
        IF p_cursor%ISOPEN THEN
            CLOSE p_cursor;
        END IF;
END afficher_resultats ;
/

DECLARE
    v_cursor SYS_REFCURSOR;
BEGIN
    -- Appel de la fonction search_lieu pour obtenir un curseur
    v_cursor := search_lieu(p_nomLieu => 'Le Colisée');

    -- Appeler la fonction afficher_resultats_lieu pour afficher les résultats
    afficher_resultats(p_cursor => v_cursor);
END;
/
--------------------------------------------- Tableau Spectacle ---------------------------------
---------------------------- ajouter_Spectacle ---------------------------------
DROP PROCEDURE ajouter_spectacle 
CREATE OR REPLACE PROCEDURE ajouter_spectacle (
    p_titre IN VARCHAR2,
    p_dateS IN DATE,
    p_h_debut IN NUMBER,
    p_dureeS IN NUMBER,
    p_capacite IN NUMBER,
    p_idLieu IN NUMBER
) IS
    v_lieu_exists NUMBER; -- Variable pour vérifier l'existence du lieu
BEGIN
    -- Vérifier si le lieu existe
    SELECT COUNT(*)
    INTO v_lieu_exists
    FROM Lieu
    WHERE idLieu = p_idLieu and status ='ACTIVE';

    IF v_lieu_exists = 0 THEN
        -- Afficher une erreur si le lieu n'existe pas
        DBMS_OUTPUT.PUT_LINE('Erreur : Le lieu avec l''ID ' || p_idLieu || ' n''existe pas.');
        RETURN; -- Arrêter la procédure
    END IF;

    -- Insérer le spectacle
        INSERT INTO Spectacle (idSpec, Titre, dateS, h_debut, dureeS, nbrSpectateur, idLieu)
    VALUES (spectacle_seq.NEXTVAL, p_titre, p_dateS, p_h_debut, p_dureeS, p_capacite, p_idLieu);

    -- Message de succès
    DBMS_OUTPUT.PUT_LINE('Spectacle ajouté avec succès.');
EXCEPTION
    WHEN OTHERS THEN
        -- Gestion des erreurs
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END ajouter_spectacle;
/
ALTER TRIGGER trg_check_spectacle_capacity ENABLE ;
ALTER TRIGGER check_spectacle_date ENABLE;
ALTER TRIGGER check_venue_availability ENABLE;


BEGIN
    ajouter_spectacle(
        p_titre => 'festivale de sousse ',
        p_dateS => TO_DATE('2024-12-21', 'YYYY-MM-DD'),
        p_h_debut => 18.00,
        p_dureeS => 2.00,
        p_capacite => 200, -- Ajout avec succeés
        p_idLieu => 10 
    );
END;
/

select * from spectacle 
---------------------------- annuler_Spectacle ---------------------------------

CREATE OR REPLACE PROCEDURE annuler_spectacle (
    p_idSpec IN Spectacle.idSpec%TYPE -- Identifiant du spectacle à annuler
) IS
    v_exists NUMBER; -- Variable pour vérifier l'existence du spectacle
BEGIN
    -- Vérifier si le spectacle existe
    SELECT COUNT(*)
    INTO v_exists
    FROM Spectacle
    WHERE idSpec = p_idSpec;

    IF v_exists = 0 THEN
        -- Si le spectacle n'existe pas, afficher un message
        DBMS_OUTPUT.PUT_LINE('Erreur : Le spectacle avec l''ID ' || p_idSpec || ' n''existe pas.');
        RETURN; -- Arrêter la procédure
    END IF;

    -- Annuler le spectacle (mettre la dateS à NULL)
    UPDATE Spectacle
    SET dateS = NULL
    WHERE idSpec = p_idSpec;

    -- Afficher un message de succès
    DBMS_OUTPUT.PUT_LINE('Le spectacle avec l''ID ' || p_idSpec || ' a été annulé avec succès.');
EXCEPTION
    WHEN OTHERS THEN
        -- Gestion des erreurs
        DBMS_OUTPUT.PUT_LINE('Erreur lors de l''annulation du spectacle : ' || SQLERRM);
END annuler_spectacle;
/
BEGIN   --ID Inexistant 
    annuler_spectacle(p_idSpec => 42 ) ;
END;
/

SELECT * FROM spectacle
CREATE OR REPLACE PROCEDURE annuler_spectacle (
    p_idSpec IN Spectacle.idSpec%TYPE -- Identifiant du spectacle à annuler
) IS
    v_exists NUMBER; -- Variable pour vérifier l'existence du spectacle
BEGIN
    -- Vérifier si le spectacle existe
    SELECT COUNT(*)
    INTO v_exists
    FROM Spectacle
    WHERE idSpec = p_idSpec;

    IF v_exists = 0 THEN
        -- Si le spectacle n'existe pas, afficher un message
        DBMS_OUTPUT.PUT_LINE('Erreur : Le spectacle avec l''ID ' || p_idSpec || ' n''existe pas.');
        RETURN; -- Arrêter la procédure
    END IF

    -- Annuler le spectacle (mettre la dateS à NULL)
    UPDATE Spectacle
    SET dateS = NULL
    WHERE idSpec = p_idSpec;

    -- Afficher un message de succès
    DBMS_OUTPUT.PUT_LINE('Le spectacle avec l''ID ' || p_idSpec || ' a été annulé avec succès.');


EXCEPTION
    WHEN OTHERS THEN
        -- Réactiver le trigger en cas d'erreur
        EXECUTE IMMEDIATE 'ALTER TRIGGER CHECK_VENUE_AVAILABILITY ENABLE';
        DBMS_OUTPUT.PUT_LINE('Erreur lors de l''annulation du spectacle : ' || SQLERRM);
END annuler_spectacle;
/

ALTER TABLE spectacle MODIFY dateS NULL;
select * from spectacle 

------------------Modifier_spectacle--------------------------------------------


CREATE OR REPLACE PROCEDURE modifier_spectacle (
    p_idSpec IN NUMBER,
    p_titre IN VARCHAR2 DEFAULT NULL,
    p_dateS IN DATE DEFAULT NULL,
    p_h_debut IN NUMBER DEFAULT NULL,  -- h_debut is of type NUMBER(4,2)
    p_dureeS IN NUMBER DEFAULT NULL,
    p_nbrSpectateur IN NUMBER DEFAULT NULL,
    p_idLieu IN NUMBER DEFAULT NULL
) IS
     v_h_debut NUMBER(4,2);   -- Variable locale pour h_debut
    v_dureeS NUMBER(4,2);    -- Variable locale pour dureeS
    v_dateS DATE;            -- Variable locale pour dateS
    v_idLieu NUMBER;         -- Variable locale pour idLieu
    v_old_h_debut NUMBER(4,2);  -- Matches the h_debut data type
    v_old_dureeS NUMBER(4,2);
    v_old_dateS DATE;
    v_old_idLieu NUMBER;
    v_spectacle_annule NUMBER;
    v_lieu_exists NUMBER;
    v_spectacle_exists NUMBER;  -- Nouvelle variable pour vérifier si le spectacle existe
    v_conflicts NUMBER;           -- Variable pour vérifier les conflits
BEGIN
    -- Désactiver le trigger temporairement
    EXECUTE IMMEDIATE 'ALTER TRIGGER check_venue_availability DISABLE';

    -- Vérifier si le spectacle existe dans la table
    SELECT COUNT(*)
    INTO v_spectacle_exists
    FROM Spectacle
    WHERE idSpec = p_idSpec;

    IF v_spectacle_exists = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : Le spectacle avec l''ID ' || p_idSpec || ' n''existe pas.');
        RETURN;  -- Sortir de la procédure si le spectacle n'existe pas
    END IF;

    -- Vérifier si le spectacle est annulé (dateS NULL signifie spectacle annulé)
    SELECT COUNT(*)
    INTO v_spectacle_annule
    FROM Spectacle
    WHERE idSpec = p_idSpec AND dateS IS NULL;

    IF v_spectacle_annule > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : Le spectacle est déjà annulé.');
        RETURN;
    END IF;

    -- Récupérer les anciennes valeurs nécessaires avant modification
    SELECT h_debut, dureeS, dateS, idLieu
    INTO v_old_h_debut, v_old_dureeS, v_old_dateS, v_old_idLieu
    FROM Spectacle
    WHERE idSpec = p_idSpec;

       -- Initialiser les variables locales avec les paramètres ou les anciennes valeurs
    v_h_debut := NVL(p_h_debut, v_old_h_debut);
    v_dureeS := NVL(p_dureeS, v_old_dureeS);
    v_dateS := NVL(p_dateS, v_old_dateS);
    v_idLieu := NVL(p_idLieu, v_old_idLieu);

    -- Vérifier si le lieu est disponible à la date et l'heure spécifiées
    IF p_idLieu IS NOT NULL AND p_dateS IS NOT NULL AND p_h_debut IS NOT NULL AND p_dureeS IS NOT NULL THEN
        SELECT COUNT(*)
        INTO v_conflicts
        FROM Spectacle
        WHERE idLieu = p_idLieu
          AND dateS = p_dateS
          AND (
               (p_h_debut BETWEEN h_debut AND (h_debut + dureeS))
               OR ((p_h_debut + p_dureeS) BETWEEN h_debut AND (h_debut + dureeS))
              )
          AND idSpec != p_idSpec;  -- Exclure l'enregistrement en cours de modification

        IF v_conflicts > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Erreur : Le lieu est déjà réservé pour cette plage horaire.');
            RETURN;  -- Annuler la modification
        END IF;
    END IF;

    -- Mise à jour des informations du spectacle
    UPDATE Spectacle
    SET
        Titre = NVL(p_titre, Titre),  -- Utiliser la valeur fournie ou conserver l'ancienne
        dateS = p_dateS,              -- Utiliser la dateS mise à jour ou ancienne
        h_debut = p_h_debut,          -- Utiliser le h_debut mis à jour ou ancien
        dureeS = p_dureeS,            -- Utiliser la durée mise à jour ou ancienne
        idLieu = p_idLieu,            -- Utiliser le lieu mis à jour ou ancien
        nbrSpectateur = NVL(p_nbrSpectateur, nbrSpectateur) -- Idem pour le nombre de spectateurs
    WHERE idSpec = p_idSpec;

    -- Si h_debut ou dureeS ont changé, mettre à jour les rubriques associées
    IF p_h_debut != v_old_h_debut OR p_dureeS != v_old_dureeS THEN
        -- Mise à jour des rubriques liées au spectacle
        UPDATE Rubrique
        SET 
            H_debutR = H_debutR + (p_h_debut - v_old_h_debut),  -- Adjust H_debutR if h_debut changes
            dureeRub = dureeRub * (p_dureeS / v_old_dureeS)  -- Adjust dureeRub if dureeS changes
        WHERE idSpec = p_idSpec;
    END IF;

    -- Confirmer les modifications
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Spectacle modifié avec succès.');

    -- Réactiver le trigger
    EXECUTE IMMEDIATE 'ALTER TRIGGER check_venue_availability ENABLE';

EXCEPTION
    WHEN OTHERS THEN
        -- Gestion des erreurs
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Erreur lors de la modification du spectacle : ' || SQLERRM);

        -- Réactiver le trigger en cas d'erreur
        EXECUTE IMMEDIATE 'ALTER TRIGGER check_venue_availability ENABLE';
END modifier_spectacle;
/
select * from rubrique 
INSERT INTO Artiste (idArt, NomArt, PrenomArt, specialite)
VALUES (artiste_seq.NEXTVAL, 'Dupont', 'Jean', 'musicien');
select  * from artiste
INSERT INTO Rubrique (idRub, idSpec, idArt, H_debutR, dureeRub, type)
VALUES (
    rubrique_seq.NEXTVAL,  -- Génération automatique de l'ID via une séquence
    18,                    -- idSpec (le spectacle auquel la rubrique est associée)
    1,                     -- idArt (l'ID d'un artiste existant dans la table Artiste)
    19,                 -- H_debutR (l'heure de début de la rubrique, exemple)
    1.50,                  -- dureeRub (la durée de la rubrique, exemple)
    'musique'              -- type (exemple d'un type valide)
);
 select * from lieu 
select * from spectacle 
BEGIN
    modifier_spectacle(
        p_idSpec => 34 , 
        p_titre => 'festivale de Gafsa',
        p_dateS => TO_DATE('2024-12-20', 'YYYY-MM-DD'),
        p_h_debut => 20,  -- h_debut value as NUMBER(4,2)
        p_dureeS => 3.5,
        p_nbrSpectateur => 200,
        p_idLieu => 10 
    );
END;
/
/*
CREATE GLOBAL TEMPORARY TABLE temp_spectacle_changes (
    idSpec NUMBER,
    idLieu NUMBER,
    dateS DATE,
    h_debut NUMBER,
    dureeS NUMBER
) ON COMMIT PRESERVE ROWS;

drop table temp_spectacle_changes 

SELECT * FROM v$session WHERE status = 'ACTIVE';
SELECT * FROM v$transaction WHERE table_name = 'temp_spectacle_changes' ;

*/  
CREATE OR REPLACE TRIGGER check_venue_availability
BEFORE INSERT OR UPDATE ON Spectacle
FOR EACH ROW
DECLARE
    v_new_idLieu NUMBER;         -- Variable pour :NEW.idLieu
    v_new_dateS DATE;            -- Variable pour :NEW.dateS
    v_new_h_debut NUMBER(4,2);   -- Variable pour :NEW.h_debut
    v_new_dureeS NUMBER(4,2);    -- Variable pour :NEW.dureeS
    v_conflicts NUMBER;          -- Variable pour les conflits détectés
BEGIN
    -- Stocker les nouvelles valeurs dans des variables
    v_new_idLieu := :NEW.idLieu;
    v_new_dateS := :NEW.dateS;
    v_new_h_debut := :NEW.h_debut;
    v_new_dureeS := :NEW.dureeS;

    -- Vérifier si le lieu est déjà réservé à la date et l'heure spécifiées
    SELECT COUNT(*)
    INTO v_conflicts
    FROM Spectacle
    WHERE idLieu = v_new_idLieu   -- Utilisation des variables à la place de :NEW
      AND dateS = v_new_dateS
      AND (
           (v_new_h_debut BETWEEN h_debut AND (h_debut + dureeS))  -- Comparaison avec h_debut et dureeS existants
           OR ((v_new_h_debut + v_new_dureeS) BETWEEN h_debut AND (h_debut + dureeS))  -- Comparaison avec la plage horaire
          )
      AND idSpec != :NEW.idSpec;  -- Exclure l'enregistrement en cours de modification

    -- Lever une exception si des conflits sont détectés
    IF v_conflicts > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Erreur : Le lieu est déjà réservé pour cette plage horaire.');
    END IF;
END;
/


drop trigger check_venue_availability


select * from lieu 
select * from spectacle 
select * from rubrique 
/

SET SERVEROUT ON
----------------------Chercher_Spactacle----------------------------------------
CREATE OR REPLACE PROCEDURE chercher_spectacle (
    p_idSpec IN NUMBER DEFAULT NULL,  -- Identifiant du spectacle
    p_titre IN VARCHAR2 DEFAULT NULL  -- Titre du spectacle
) IS
    -- Déclaration d'un curseur pour récupérer les résultats
    v_cursor SYS_REFCURSOR;
    -- Variables pour stocker les résultats
    v_idSpec NUMBER;
    v_titre VARCHAR2(100);
    v_dateS DATE;
    v_h_debut NUMBER(4,2);
    v_dureeS NUMBER(4,2);
    v_nbrSpectateur NUMBER;
    v_idLieu NUMBER;
BEGIN
    -- Ouvrir le curseur en fonction des critères de recherche
    OPEN v_cursor FOR
    SELECT idSpec, Titre, dateS, h_debut, dureeS, nbrSpectateur, idLieu
    FROM Spectacle
    WHERE (p_idSpec IS NULL OR idSpec = p_idSpec)
      AND (p_titre IS NULL OR LOWER(Titre) LIKE '%' || LOWER(p_titre) || '%')
      AND dateS IS NOT NULL;  -- Exclure les spectacles annulés

    -- Récupérer les résultats et les afficher
    LOOP
        FETCH v_cursor INTO v_idSpec, v_titre, v_dateS, v_h_debut, v_dureeS, v_nbrSpectateur, v_idLieu;
        EXIT WHEN v_cursor%NOTFOUND;

        -- Afficher les résultats
        DBMS_OUTPUT.PUT_LINE('ID Spectacle     : ' || v_idSpec);
        DBMS_OUTPUT.PUT_LINE('Titre            : ' || v_titre);
        DBMS_OUTPUT.PUT_LINE('Date             : ' || TO_CHAR(v_dateS, 'YYYY-MM-DD'));
        DBMS_OUTPUT.PUT_LINE('Heure de Début   : ' || v_h_debut);
        DBMS_OUTPUT.PUT_LINE('Durée (heures)   : ' || v_dureeS);
        DBMS_OUTPUT.PUT_LINE('Nombre Spectateurs: ' || v_nbrSpectateur);
        DBMS_OUTPUT.PUT_LINE('ID Lieu          : ' || v_idLieu);
        DBMS_OUTPUT.PUT_LINE('----------------------------------');
    END LOOP;

    -- Fermer le curseur
    CLOSE v_cursor;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Aucun spectacle trouvé avec les critères donnés.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : ' || SQLERRM);
END chercher_spectacle;
/

update spectacle 
set DateS =  TO_DATE('2024-12-31', 'YYYY-MM-DD')
where idspec = 34 ;

BEGIN
   chercher_spectacle(p_titre => 'festi');
END;
/
select * from spectacle 

ALTER TRIGGER check_rubrique_count  Enable  ; 

CREATE OR REPLACE TRIGGER trg_check_rubrique_duration
BEFORE INSERT OR UPDATE ON Rubrique 
FOR EACH ROW
DECLARE
    v_dureeSpectacle NUMBER;  -- Durée totale du spectacle
    v_dureeRubriquesExistantes NUMBER;  -- Somme des durées des rubriques existantes
BEGIN
    -- Récupérer la durée totale du spectacle associé
    SELECT dureeS
    INTO v_dureeSpectacle
    FROM Spectacle
    WHERE idSpec = :NEW.idSpec;

    -- Calculer la somme des durées des rubriques déjà planifiées pour ce spectacle (exclure la rubrique en cours d'insertion ou de mise à jour)
    SELECT NVL(SUM(dureeRub), 0)
    INTO v_dureeRubriquesExistantes
    FROM Rubrique
    WHERE idSpec = :NEW.idSpec
      AND idRub != :NEW.idRub;  -- Exclure la rubrique actuelle (utile en cas de mise à jour)

    -- Vérifier que la durée de la nouvelle rubrique ne dépasse pas la durée restante du spectacle
    IF :NEW.dureeRub >= (v_dureeSpectacle - v_dureeRubriquesExistantes) THEN
        RAISE_APPLICATION_ERROR(-20004, 
            'Erreur : La durée de la rubrique (' || :NEW.dureeRub || 
            ') dépasse la durée restante du spectacle (' || (v_dureeSpectacle - v_dureeRubriquesExistantes) || ').');
    END IF;
END;
/

CREATE OR REPLACE PROCEDURE ajouter_rubrique (
    p_idSpec IN SPECTACLE.idSpec%TYPE,        -- ID du spectacle
    p_idArt IN Artiste.idArt%TYPE,            -- ID de l'artiste
    p_h_debutR IN Rubrique.H_debutR%TYPE,     -- Heure de début de la rubrique
    p_dureeRub IN Rubrique.dureeRub%TYPE,     -- Durée de la rubrique
    p_Rtype IN Rubrique.Rtype%TYPE            -- Type de la rubrique (comédie, théâtre, etc.)
) IS
    v_dateSpectacle SPECTACLE.dateS%TYPE;        -- Date du spectacle
    v_dureeSpectacle SPECTACLE.dureeS%TYPE;      -- Durée totale du spectacle
    v_dureeRubriquesExistantes NUMBER;           -- Somme des durées des rubriques existantes
    v_artisteDisponible NUMBER;                  -- Vérification de la disponibilité de l'artiste
    v_specialiteArtiste Artiste.specialite%TYPE; -- Spécialité de l'artiste
BEGIN
    -- Vérifier que le spectacle existe et récupérer ses informations
    BEGIN
        SELECT dateS, dureeS
        INTO v_dateSpectacle, v_dureeSpectacle
        FROM Spectacle
        WHERE idSpec = p_idSpec;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Erreur : Le spectacle avec l''ID ' || p_idSpec || ' n''existe pas.');
            RETURN; -- Quitter la procédure si l'erreur est levée
    END;

    -- Vérifier que l’artiste existe
    BEGIN
        SELECT specialite
        INTO v_specialiteArtiste
        FROM Artiste
        WHERE idArt = p_idArt;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Erreur : L’artiste avec l''ID ' || p_idArt || ' n''existe pas.');
            RETURN; -- Quitter la procédure si l'erreur est levée
    END;

    -- Vérifier que la spécialité de l’artiste correspond au type de la rubrique
    /*IF (LOWER(v_specialiteArtiste) NOT IN (LOWER(p_Rtype))) THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : La spécialité de l’artiste ne correspond pas au type de la rubrique.');
        RETURN; -- Quitter la procédure si l'erreur est levée
    END IF;*/

    -- Vérifier si la durée de la rubrique est inférieure à la durée restante du spectacle
    SELECT NVL(SUM(dureeRub), 0)
    INTO v_dureeRubriquesExistantes
    FROM Rubrique
    WHERE idSpec = p_idSpec;

    IF (v_dureeRubriquesExistantes + p_dureeRub) > v_dureeSpectacle THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : La durée de la rubrique dépasse la durée totale du spectacle.');
        RETURN; -- Quitter la procédure si l'erreur est levée
    END IF;

    -- Vérifier la disponibilité de l’artiste à la date et heure de la rubrique
    SELECT COUNT(*)
    INTO v_artisteDisponible
    FROM Rubrique r
    JOIN Spectacle s ON r.idSpec = s.idSpec
    WHERE r.idArt = p_idArt
    AND s.idSpec = p_idSpec
    AND s.dateS = v_dateSpectacle  -- Vérifie si la date du spectacle correspond
    AND (
       (p_h_debutR BETWEEN r.H_debutR AND (r.H_debutR + r.dureeRub)) -- Vérifie si l'heure de début de la nouvelle rubrique chevauche une rubrique existante
       OR 
       ((p_h_debutR + p_dureeRub) BETWEEN r.H_debutR AND (r.H_debutR + r.dureeRub))  -- Vérifie si la nouvelle rubrique chevauche la précédente
    );

-- Si l'artiste est déjà occupé, on retourne un message d'erreur
    IF v_artisteDisponible > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : L’artiste est déjà occupé à cette date et heure.');
        RETURN; -- Quitter la procédure
    END IF;


    -- Insérer la nouvelle rubrique
    INSERT INTO Rubrique (idRub, idSpec, idArt, H_debutR, dureeRub, Rtype)
    VALUES (rubrique_seq.NEXTVAL, p_idSpec, p_idArt, p_h_debutR, p_dureeRub, p_Rtype);

    -- Retourner un message de succès
    DBMS_OUTPUT.PUT_LINE('Rubrique ajoutée avec succès au spectacle.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur lors de l''ajout de la rubrique : ' || SQLERRM);
END ajouter_rubrique;
/

Drop function ajouter_rubrique 
    
BEGIN
    ajouter_rubrique(
        p_idSpec => 38 ,
        p_idArt => 10,
        p_h_debutR => 18.30,
        p_dureeRub => 0.1,
        p_Rtype => 'musique'
    );
END;


delete from rubrique where idrub = 4 ;

BEGIN
    ajouter_spectacle(
        p_titre => 'festivale de nour',
        p_dateS => TO_DATE('2025-01-01', 'YYYY-MM-DD'),
        p_h_debut => 18.00,
        p_dureeS => 2.00,
        p_capacite => 200, -- Ajout avec succeés
        p_idLieu => 10  
    );
END;
/
delete from artiste  where idart=2 ;
BEGIN
    ajouter_artiste(
        p_nomArt => 'KARIM',      -- Nom de l'artiste
        p_prenomArt => 'ELGHARBI',    -- Prénom de l'artiste
        p_specialite => 'acteur'  -- Spécialité de l'artiste
    );
END;
/
select * from spectacle 
select * from artiste 
select * from rubrique 

CREATE OR REPLACE PROCEDURE ajouter_artiste (
    p_nomArt IN Artiste.nomArt%TYPE,          -- Nom de l'artiste
    p_prenomArt IN Artiste.prenomArt%TYPE,    -- Prénom de l'artiste
    p_specialite IN Artiste.specialite%TYPE   -- Spécialité de l'artiste
) IS
BEGIN
    -- Insérer un nouvel artiste dans la table Artiste
    INSERT INTO Artiste (idArt, nomArt, prenomArt, specialite)
    VALUES (artiste_seq.NEXTVAL, p_nomArt, p_prenomArt, p_specialite);

    -- Confirmer l'ajout de l'artiste
    DBMS_OUTPUT.PUT_LINE('Artiste ajouté avec succès : ' || p_nomArt || ' ' || p_prenomArt);
EXCEPTION
    WHEN OTHERS THEN
        -- Gestion des erreurs
        DBMS_OUTPUT.PUT_LINE('Erreur lors de l''ajout de l''artiste : ' || SQLERRM);
END ajouter_artiste;
/


-----------------------------------Modifier rubrique ----------------------------------
    
CREATE OR REPLACE PROCEDURE modifier_rubrique (
    p_idRub IN Rubrique.idRub%TYPE,           -- ID de la rubrique à modifier
    p_idArt IN Artiste.idArt%TYPE,            -- Nouveau ID de l'artiste
    p_h_debutR IN Rubrique.H_debutR%TYPE,     -- Nouvelle heure de début de la rubrique
    p_dureeRub IN Rubrique.dureeRub%TYPE      -- Nouvelle durée de la rubrique
) IS
    v_dateSpectacle SPECTACLE.dateS%TYPE;      -- Date du spectacle
    v_dureeSpectacle SPECTACLE.dureeS%TYPE;    -- Durée du spectacle
    v_dureeRubriquesExistantes NUMBER;         -- Somme des durées des rubriques existantes
    v_artisteDisponible NUMBER;                -- Vérification de la disponibilité de l'artiste
    v_rubriquesCount NUMBER;                   -- Nombre de rubriques pour ce spectacle
    v_old_idArt Artiste.idArt%TYPE;            -- Ancien ID de l'artiste dans la rubrique
    v_old_h_debutR Rubrique.H_debutR%TYPE;     -- Ancienne heure de début
    v_old_dureeRub Rubrique.dureeRub%TYPE;     -- Ancienne durée de la rubrique
BEGIN
    -- Désactiver les triggers avant de commencer l'insertion
    EXECUTE IMMEDIATE 'ALTER TRIGGER CHECK_RUBRIQUE_COUNT DISABLE';
    EXECUTE IMMEDIATE 'ALTER TRIGGER trg_check_rubrique_duration DISABLE';

    -- Vérifier que la rubrique existe et récupérer ses informations
    BEGIN
        SELECT idArt, H_debutR, dureeRub
        INTO v_old_idArt, v_old_h_debutR, v_old_dureeRub
        FROM Rubrique
        WHERE idRub = p_idRub;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Erreur : Aucune rubrique trouvée avec l''ID ' || p_idRub);
            -- Réactiver les triggers avant de quitter
            EXECUTE IMMEDIATE 'ALTER TRIGGER CHECK_RUBRIQUE_COUNT ENABLE';
            EXECUTE IMMEDIATE 'ALTER TRIGGER trg_check_rubrique_duration ENABLE';
            RETURN;  -- Quitter la procédure si la rubrique n'existe pas
    END;

    -- Vérifier la date et la durée du spectacle
    SELECT s.dateS, s.dureeS
    INTO v_dateSpectacle, v_dureeSpectacle
    FROM Spectacle s
    WHERE s.idSpec = (SELECT idSpec FROM Rubrique WHERE idRub = p_idRub);

    -- Vérifier si le nombre de rubriques est déjà de 3
    SELECT COUNT(*)
    INTO v_rubriquesCount
    FROM Rubrique
    WHERE idSpec = (SELECT idSpec FROM Rubrique WHERE idRub = p_idRub);

    IF v_rubriquesCount >= 3 THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : Le spectacle a déjà 3 rubriques.');
        -- Réactiver les triggers avant de quitter
        EXECUTE IMMEDIATE 'ALTER TRIGGER CHECK_RUBRIQUE_COUNT ENABLE';
        EXECUTE IMMEDIATE 'ALTER TRIGGER trg_check_rubrique_duration ENABLE';
        RETURN;  -- Quitter la procédure si le nombre de rubriques est atteint
    END IF;

    -- Vérifier si la durée de la rubrique est inférieure à la durée restante du spectacle
    SELECT NVL(SUM(dureeRub), 0)
    INTO v_dureeRubriquesExistantes
    FROM Rubrique
    WHERE idSpec = (SELECT idSpec FROM Rubrique WHERE idRub = p_idRub);

    IF (v_dureeRubriquesExistantes + p_dureeRub) > v_dureeSpectacle THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : La durée de la rubrique dépasse la durée totale du spectacle.');
        -- Réactiver les triggers avant de quitter
        EXECUTE IMMEDIATE 'ALTER TRIGGER CHECK_RUBRIQUE_COUNT ENABLE';
        EXECUTE IMMEDIATE 'ALTER TRIGGER trg_check_rubrique_duration ENABLE';
        RETURN;  -- Quitter la procédure si la durée dépasse celle du spectacle
    END IF;

    -- Vérifier la disponibilité de l’artiste à la date et heure de la rubrique
    SELECT COUNT(*)
    INTO v_artisteDisponible
    FROM Rubrique r
    JOIN Spectacle s ON r.idSpec = s.idSpec
    WHERE r.idArt = p_idArt
      AND s.dateS = v_dateSpectacle
      AND (
           p_h_debutR BETWEEN r.H_debutR AND (r.H_debutR + r.dureeRub)  -- Vérifie si l'heure de début chevauche
           OR 
           (p_h_debutR + p_dureeRub) BETWEEN r.H_debutR AND (r.H_debutR + r.dureeRub)  -- Vérifie si la durée chevauche
      );

    -- Si l'artiste est déjà occupé, afficher un message d'erreur
    IF v_artisteDisponible > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : L’artiste est déjà occupé à cette date et heure.');
        -- Réactiver les triggers avant de quitter
        EXECUTE IMMEDIATE 'ALTER TRIGGER CHECK_RUBRIQUE_COUNT ENABLE';
        EXECUTE IMMEDIATE 'ALTER TRIGGER trg_check_rubrique_duration ENABLE';
        RETURN; -- Quitter la procédure si l'artiste est occupé
    END IF;

    -- Mettre à jour la rubrique avec les nouvelles valeurs
    UPDATE Rubrique
    SET idArt = p_idArt,
        H_debutR = p_h_debutR,
        dureeRub = p_dureeRub
    WHERE idRub = p_idRub;

    -- Confirmer les modifications
    DBMS_OUTPUT.PUT_LINE('Rubrique mise à jour avec succès.');

    -- Réactiver les triggers après modification
    EXECUTE IMMEDIATE 'ALTER TRIGGER CHECK_RUBRIQUE_COUNT ENABLE';
    EXECUTE IMMEDIATE 'ALTER TRIGGER trg_check_rubrique_duration ENABLE';
EXCEPTION
    WHEN OTHERS THEN
        -- Gestion des erreurs
        DBMS_OUTPUT.PUT_LINE('Erreur lors de la modification de la rubrique : ' || SQLERRM);
        -- Réactiver les triggers en cas d'erreur
        EXECUTE IMMEDIATE 'ALTER TRIGGER CHECK_RUBRIQUE_COUNT ENABLE';
        EXECUTE IMMEDIATE 'ALTER TRIGGER trg_check_rubrique_duration ENABLE';
END modifier_rubrique;
/



select * from rubrique 
select * from artiste 
select * from spectacle 
BEGIN
    modifier_rubrique(
        p_idRub => 3,        -- ID de la rubrique à modifier
        p_idArt => 10,        -- Nouveau ID de l'artiste
        p_h_debutR => 18.00, -- Nouvelle heure de début
        p_dureeRub => 1.5    -- Nouvelle durée de la rubrique
    );
END;
/

CREATE OR REPLACE PROCEDURE supprimer_rubrique (
    p_idRub IN Rubrique.idRub%TYPE  -- ID de la rubrique à supprimer
) IS
    v_idSpec SPECTACLE.idSpec%TYPE;      -- ID du spectacle associé à la rubrique
    v_dateSpectacle SPECTACLE.dateS%TYPE; -- Date du spectacle
BEGIN
    -- Vérifier que la rubrique existe et récupérer l'ID du spectacle associé
    BEGIN
        SELECT idSpec
        INTO v_idSpec
        FROM Rubrique
        WHERE idRub = p_idRub;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Erreur : Aucune rubrique trouvée avec l''ID ' || p_idRub);
            RETURN; -- Quitter la procédure si la rubrique n'existe pas
    END;

    -- Vérifier que le spectacle associé est dans les évènements à venir
    SELECT dateS
    INTO v_dateSpectacle
    FROM Spectacle
    WHERE idSpec = v_idSpec;

    IF v_dateSpectacle <= SYSDATE THEN
        DBMS_OUTPUT.PUT_LINE('Erreur : Le spectacle est déjà passé. Impossible de supprimer cette rubrique.');
        RETURN; -- Quitter la procédure si le spectacle est passé
    END IF;

    -- Supprimer la rubrique de la table Rubrique
    DELETE FROM Rubrique
    WHERE idRub = p_idRub;

    -- Confirmer la suppression
    DBMS_OUTPUT.PUT_LINE('Rubrique supprimée avec succès.');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur lors de la suppression de la rubrique : ' || SQLERRM);
END supprimer_rubrique;
/
BEGIN
    supprimer_rubrique(p_idRub => 1 );  -- Remplacer 1 par l'ID de la rubrique à supprimer
END;
/

select * from rubrique 
--------------------recherche rubrique -----------------------------------------

CREATE OR REPLACE PROCEDURE rechercher_rubrique (
    p_idSpec IN Rubrique.idSpec%TYPE DEFAULT NULL,     -- Identifiant du spectacle (optionnel)
    p_nomArt IN Artiste.nomArt%TYPE DEFAULT NULL       -- Nom partiel de l'artiste (optionnel)
) IS
    -- Déclaration d'un curseur pour stocker les résultats de la recherche
    CURSOR c_rubrique IS
        SELECT r.idRub, r.idSpec, r.idArt, r.H_debutR, r.dureeRub, r.Rtype, a.nomArt
        FROM Rubrique r
        JOIN Artiste a ON r.idArt = a.idArt
        WHERE (p_idSpec IS NULL OR r.idSpec = p_idSpec)   -- Filtrer par ID spectacle si fourni
          AND (p_nomArt IS NULL OR LOWER(a.nomArt) LIKE '%' || LOWER(p_nomArt) || '%'); -- Recherche partielle par nom artiste

    v_rubrique c_rubrique%ROWTYPE; -- Variable pour stocker chaque ligne du curseur
    v_count NUMBER := 0;           -- Compteur pour vérifier si des résultats existent
BEGIN
    -- Ouvrir le curseur et parcourir les résultats
    OPEN c_rubrique;
    LOOP
        FETCH c_rubrique INTO v_rubrique;
        EXIT WHEN c_rubrique%NOTFOUND;

        -- Afficher les détails de chaque rubrique trouvée
        DBMS_OUTPUT.PUT_LINE('ID Rubrique : ' || v_rubrique.idRub);
        DBMS_OUTPUT.PUT_LINE('ID Spectacle : ' || v_rubrique.idSpec);
        DBMS_OUTPUT.PUT_LINE('ID Artiste : ' || v_rubrique.idArt);
        DBMS_OUTPUT.PUT_LINE('Nom Artiste : ' || v_rubrique.nomArt); -- Affichage du nom de l'artiste
        DBMS_OUTPUT.PUT_LINE('Heure Début : ' || v_rubrique.H_debutR);
        DBMS_OUTPUT.PUT_LINE('Durée Rubrique : ' || v_rubrique.dureeRub);
        DBMS_OUTPUT.PUT_LINE('Type Rubrique : ' || v_rubrique.Rtype);
        DBMS_OUTPUT.PUT_LINE('-------------------------------------------');
        
        v_count := v_count + 1; -- Incrémenter le compteur
    END LOOP;
    CLOSE c_rubrique;

    -- Si aucun résultat n'est trouvé
    IF v_count = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Aucune rubrique ne correspond aux critères de recherche.');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erreur lors de la recherche de rubriques : ' || SQLERRM);
END rechercher_rubrique;
/


BEGIN
    rechercher_rubrique(p_nomArt => 'sam'); -- Recherche des artistes avec un nom contenant "dup"
END;
/
select * from artiste 
select * from rubrique  
