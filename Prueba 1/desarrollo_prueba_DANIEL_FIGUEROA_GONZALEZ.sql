/*
NOMBRE: DANIEL FIGUEROA GONZALEZ
SECCION: 005V
*/

-- DECLARACION VARIABLES BIND
VAR b_vtope NUMBER;
VAR b_vcolacion NUMBER;
VAR b_mes NUMBER;
VAR b_ano NUMBER;
DECLARE
-- DECLARACION VARIABLES ESCALARES
    v_min NUMBER;
    v_max NUMBER;
    v_codagt agente.cod_agente%TYPE;
    v_rutagt agente.rut_agente%TYPE;
    v_sueldobruto sueldo.sueldo_bruto%TYPE;
    v_vasignacion NUMBER;
    v_annos NUMBER;
    v_porcentaje NUMBER;
    v_vmovilizacion NUMBER(8);
    v_pormovi NUMBER;
    v_vcontratos NUMBER(8);
    v_totalcontra NUMBER;
    v_vescolar NUMBER(8);
    v_porescolar NUMBER;
    v_totalafp NUMBER;
    v_totalsalud NUMBER;
    v_vsalud NUMBER(8);
    v_porsalud NUMBER;
    v_vafp NUMBER(8);
    v_porafp NUMBER;
BEGIN
-- INGRESAR VALOR VARIABLES BIND/TRUNCAS TABLAS
    EXECUTE IMMEDIATE('TRUNCATE TABLE HABER_CALC_MES');
    EXECUTE IMMEDIATE('TRUNCATE TABLE DESCTO_CALC_MES');
    :b_vtope:=&tope_comision;
    :b_vcolacion:=&colacion;
    :b_mes :=&mes_proceso;
    :b_ano :=&ano_proceso;
-- SE DEFINEN LAS VARIABLES PARA EL BUCLE
    SELECT MIN(cod_agente), MAX(cod_agente)
        INTO v_min, v_max
        FROM agente;
-- BUCLE WHILE QUE RECCORRE A LA TABLA "AGENTE"
    WHILE v_min<=v_max loop
        select 
        agt.cod_agente,
        agt.rut_agente,
        sue.sueldo_bruto
        into 
        v_codagt,
        v_rutagt,
        v_sueldobruto
        FROM agente agt JOIN sueldo sue
        ON agt.id_sueldo = sue.id_sueldo
        WHERE agt.cod_agente =v_min;
-- OBTENER AÑOS DE ANTIGUEDAD y % CORRESPONDIENTE
    BEGIN
        SELECT trunc(months_between(sysdate,fecing_agente)/12),pra.porcentaje
        INTO v_annos,v_porcentaje
        FROM agente agt LEFT JOIN porcentaje_anos pra
        ON trunc(months_between(sysdate,agt.fecing_agente)/12) BETWEEN pra.annos_inf and pra.annos_sup
        WHERE cod_agente=v_codagt;
        IF v_porcentaje is null THEN v_porcentaje:=0;
        END IF;
    END;
-- CALCULO ASIGNACION POR ANTIGUEDAD
        v_vasignacion:=ROUND((v_sueldobruto*v_porcentaje)/100);
        
-- OBTENER % DE MOVILIZACION
    BEGIN
        SELECT porc_mov 
        INTO v_pormovi
        FROM porc_movilizacion
        WHERE v_sueldobruto between sueldo_base_inf and sueldo_base_sup;
    END;
-- CALCULO BONO MOVILIZACION
    v_vmovilizacion :=ROUND((v_sueldobruto*v_pormovi)/100);
    
-- TOTAL CONTRATOS POR AGENTES   
    BEGIN
        SELECT COUNT(con.num_contrato)
        INTO v_totalcontra
        FROM agente agt LEFT JOIN contrato con
        ON con.cod_agente=agt.cod_agente
        WHERE agt.cod_agente=v_codagt;
        IF v_totalcontra > :b_vtope THEN v_totalcontra:=:b_vtope;
        END IF;
    END;
-- CALCULO COMISION POR CONTRATO
    v_vcontratos:=ROUND((v_sueldobruto*v_totalcontra)/100);
    
-- PORCENTAJE DE ESCOLARIDAD
    BEGIN 
        SELECT ase.porc_asig_escolaridad
        INTO v_porescolar
        FROM agente agt LEFT JOIN asig_escolaridad ase
        ON agt.id_escolaridad=ase.id_escolaridad
        WHERE agt.cod_agente=v_codagt;
    END;
-- CALCULO ASIGNACION ESCOLAR
        v_vescolar := ROUND(v_sueldobruto*v_porescolar)/100;
    
-- IDENTIFICAR % DE AFP
    BEGIN 
        v_totalafp:= ROUND(v_sueldobruto+v_vcontratos+v_vescolar);
        SELECT af.porc_descto_afp
        INTO v_porafp
        FROM agente agt LEFT JOIN afp af
        ON agt.cod_afp = af.cod_afp
        WHERE agt.cod_agente=v_codagt;
    END;
-- VALOR DESCUENTO AFP
        v_vafp :=ROUND((v_totalafp*v_porafp)/100);
    
-- IDENTIFICAR % DE SALUD
    BEGIN 
        v_totalsalud:= ROUND(v_sueldobruto+v_vasignacion+v_vmovilizacion);
        SELECT sa.porc_descto_salud
        INTO v_porsalud
        FROM agente agt LEFT JOIN salud sa
        ON agt.cod_salud = sa.cod_salud
        WHERE agt.cod_agente=v_codagt;
    END;
-- VALOR DESCUENTO SALUD
        v_vsalud:=ROUND((v_totalsalud*v_porsalud)/100);
        
-- INSERTAR DATOS A HABER_CALC_MES
    INSERT INTO haber_calc_mes
    VALUES (v_codagt,v_rutagt,:b_mes,:b_ano, v_sueldobruto,v_vasignacion,v_vmovilizacion,:b_vcolacion,v_vcontratos,v_vescolar);
        
-- INSERTAR DATOS DESCTO_CALC_MES
    INSERT INTO descto_calc_mes
    VALUES (v_codagt,v_rutagt,:b_mes,:b_ano,v_vsalud,v_vafp);

-- SALIDA DE PRUEBA DBMS_OUTPUT.PUT_LINE(v_codagt ||'-'||v_rutagt||'-'||:b_mes||'-'||:b_ano||'-'||v_sueldobruto||'-'||v_vasignacion||'-'||v_vmovilizacion||'-'||:b_vcolacion||'-'||v_vcontratos||'-'||v_vescolar||' espacio '||v_vsalud||'-'||v_vafp);
        v_min:=v_min+10;
    END LOOP;
COMMIT;
END;

