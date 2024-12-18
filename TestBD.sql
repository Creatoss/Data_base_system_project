---------------------------tableau_lieu-----------------------------------------
BEGIN
    ajouter_lieu(
        p_nomLieu => 'Théâtre Municipal',
        p_Adresse => '10 Rue Habib Bourguiba',
        p_capacite => 1200
    );
END;
/ 
select * from lieu 

begin 
    supprimer_lieu(p_idlieu => 18 ) ;
end ; 
/
begin 
modifier_lieu (p_idlieu => 23 , p_nom_lieu => 'theatre renove' ;
end 
/

DECLARE
   v_cursor SYS_REFCURSOR;
BEGIN
   v_cursor := search_lieu( p_capacite => 3000);
   afficher_resultats_lieu(p_cursor => v_cursor);
END;
/
------------------------tableau_spectacle---------------------------------------

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

BEGIN  
    annuler_spectacle(p_idSpec => 42 ) ;
END;
/

BEGIN
   chercher_spectacle(p_titre => 'Festivale');
END;
/
select * from rubrique

--------------------tableau_rubrique--------------------------------------------
BEGIN
    ajouter_rubrique(
        p_idSpec => 44 ,
        p_idArt => 9,
        p_h_debutR => 18.50,
        p_dureeRub => 1 , 
        p_Rtype => 'musique'
    );
END;

BEGIN
    modifier_rubrique(
        p_idRub => 5,        
        p_idArt => 10,       
        p_h_debutR => 18.00, 
        p_dureeRub => 1.5    
    );
END;
/

BEGIN
    supprimer_rubrique(p_idRub => 1 );  
END;
/

BEGIN
    rechercher_rubrique(p_nomArt => 'sam'); 
END;
/

