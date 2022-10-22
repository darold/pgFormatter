--
-- PostgreSQL database dump
--
-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2
SET statement_timeout = 0;

SET lock_timeout = 0;

SET idle_in_transaction_session_timeout = 0;

SET client_encoding = 'UTF8';

SET standard_conforming_strings = ON;

SET check_function_bodies = FALSE;

SET client_min_messages = warning;

SET row_security = OFF;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--
CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;

--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--
COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';

SET search_path = public, pg_catalog;

--
-- Name: add(integer, integer); Type: FUNCTION; Schema: public; Owner: gilles
--
CREATE FUNCTION ADD (integer, integer)
    RETURNS integer
    LANGUAGE sql
    IMMUTABLE STRICT
    AS $_$
    SELECT
        $1 + $2;
$_$;

ALTER FUNCTION public.add (integer, integer) OWNER TO gilles;

--
-- Name: check_password(text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text, text); Type: FUNCTION; Schema: public; Owner: gilles
--
CREATE FUNCTION check_password (uname1 text, pass1 text, uname2 text, pass2 text, uname3 text, pass3 text, uname4 text, pass4 text, uname5 text, pass5 text, uname6 text, pass6 text, uname7 text, pass7 text, uname8 text, pass8 text, uname9 text, pass9 text)
    RETURNS boolean
    LANGUAGE plpgsql
    SECURITY DEFINER
    SET search_path TO admin, pg_temp
    AS $_$
DECLARE
    passed boolean;
BEGIN
    SELECT
        (pwd = $2) INTO passed
    FROM
        pwds
    WHERE
        username = $1;
    RETURN passed;
END;
$_$;

ALTER FUNCTION public.check_password (uname1 text, pass1 text, uname2 text, pass2 text, uname3 text, pass3 text, uname4 text, pass4 text, uname5 text, pass5 text, uname6 text, pass6 text, uname7 text, pass7 text, uname8 text, pass8 text, uname9 text, pass9 text) OWNER TO gilles;

--
-- Name: dup(integer); Type: FUNCTION; Schema: public; Owner: gilles
--
CREATE FUNCTION dup (integer, OUT f1 integer, OUT f2 text)
    RETURNS record
    LANGUAGE sql
    AS $_$
    SELECT
        $1,
        CAST($1 AS text) || ' is text'
$_$;

ALTER FUNCTION public.dup (integer, OUT f1 integer, OUT f2 text) OWNER TO gilles;

--
-- Name: increment(integer); Type: FUNCTION; Schema: public; Owner: gilles
--
CREATE FUNCTION INCREMENT (i integer)
    RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN i + 1;
END;
$$;

ALTER FUNCTION public.increment (i integer) OWNER TO gilles;

--
-- Name: peuple_stock(integer, integer); Type: FUNCTION; Schema: public; Owner: userdb
--
CREATE FUNCTION peuple_stock (annee_debut integer, annee_fin integer)
    RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_annee integer;
    v_nombre integer;
    v_contenant_id integer;
    v_vin_id integer;
    compteur bigint := 0;
    annees integer;
    contenants integer;
    vins integer;
    tuples_a_generer integer;
BEGIN
    -- vider la table de stock
    TRUNCATE TABLE stock;
    -- calculer le nombre d'annees
    SELECT
        (annee_fin - annee_debut) + 1 INTO annees;
    -- nombre de contenants
    SELECT
        count(*)
    FROM
        contenant INTO contenants;
    -- nombre de vins
    SELECT
        count(*)
    FROM
        vin INTO vins;
    -- calcul des combinaisons
    SELECT
        annees * contenants * vins INTO tuples_a_generer;
    --on boucle sur tous les millesimes: disons 1930 a 2000
    -- soit 80 annees
    FOR v_annee IN annee_debut..annee_fin LOOP
        -- on boucle sur les contenants possibles
        FOR v_contenant_id IN 1..contenants LOOP
            -- idem pour l'id du vin
            FOR v_vin_id IN 1..vins LOOP
                -- on prends un nombre de bouteilles compris entre 6 et 18
                SELECT
                    round(random() * 12) + 6 INTO v_nombre;
                -- insertion dans la table de stock
                INSERT INTO stock (vin_id, contenant_id, annee, nombre)
                    VALUES (v_vin_id, v_contenant_id, v_annee, v_nombre);
                IF (((compteur % 1000) = 0) OR (compteur = tuples_a_generer)) THEN
                    RAISE NOTICE 'stock : % sur % tuples generes', compteur, tuples_a_generer;
                END IF;
                compteur := compteur + 1;
            END LOOP;
            --fin boucle vin
        END LOOP;
        -- fin boucle contenant
    END LOOP;
    --fin boucle annee
    RETURN compteur;
END;
$$;

ALTER FUNCTION public.peuple_stock (annee_debut integer, annee_fin integer) OWNER TO userdb;

--
-- Name: peuple_vin(); Type: FUNCTION; Schema: public; Owner: userdb
--
CREATE FUNCTION peuple_vin ()
    RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_recoltant_id integer;
    v_appellation_id integer;
    v_type_vin_id integer;
    recoltants integer;
    appellations integer;
    types_vins integer;
    tuples_a_generer integer;
    compteur bigint := 0;
BEGIN
    -- vider la table de stock, qui depend de vin, puis vin
    DELETE FROM stock;
    DELETE FROM vin;
    -- compter le nombre de recoltants
    SELECT
        count(*)
    FROM
        recoltant INTO recoltants;
    -- compter le nombre d'appellations
    SELECT
        count(*)
    FROM
        appellation INTO appellations;
    -- compter le nombre de types de vins
    SELECT
        count(*)
    FROM
        type_vin INTO types_vins;
    -- calculer le nombre de combinaisons possibles
    SELECT
        (recoltants * appellations * types_vins) INTO tuples_a_generer;
    --on boucle sur tous les recoltants
    FOR v_recoltant_id IN 1..recoltants LOOP
        -- on boucle sur les appelations
        FOR v_appellation_id IN 1..appellations LOOP
            -- on boucle sur les types de vins
            FOR v_type_vin_id IN 1..types_vins LOOP
                -- insertion dans la table de vin
                INSERT INTO vin (recoltant_id, appellation_id, type_vin_id)
                    VALUES (v_recoltant_id, v_appellation_id, v_type_vin_id);
                IF (((compteur % 1000) = 0) OR (compteur = tuples_a_generer)) THEN
                    RAISE NOTICE 'vins : % sur % tuples generes', compteur, tuples_a_generer;
                END IF;
                compteur := compteur + 1;
            END LOOP;
            --fin boucle type vin
        END LOOP;
        -- fin boucle appellations
    END LOOP;
    --fin boucle recoltants
    RETURN compteur;
END;
$$;

ALTER FUNCTION public.peuple_vin () OWNER TO userdb;

--
-- Name: trous_stock(); Type: FUNCTION; Schema: public; Owner: userdb
--
CREATE FUNCTION trous_stock ()
    RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    stock_total integer;
    echantillon integer;
    vins_disponibles integer;
    contenants_disponibles integer;
    v_vin_id integer;
    v_contenant_id integer;
    v_tuples bigint := 0;
    annee_min integer;
    annee_max integer;
    v_annee integer;
BEGIN
    -- on compte le nombre de tuples dans stock
    SELECT
        count(*)
    FROM
        stock INTO stock_total;
    RAISE NOTICE 'taille du stock %', stock_total;
    -- on calcule la taille de l'echantillon a
    -- supprimer de la table stock
    SELECT
        round(stock_total / 10) INTO echantillon;
    RAISE NOTICE 'taille de l''echantillon %', echantillon;
    -- on compte le nombre de vins disponibles
    SELECT
        count(*)
    FROM
        vin INTO vins_disponibles;
    RAISE NOTICE '% vins disponibles', vins_disponibles;
    -- on compte le nombre de contenants disponibles
    SELECT
        count(*)
    FROM
        contenant INTO contenants_disponibles;
    RAISE NOTICE '% contenants disponibles', contenants_disponibles;
    -- on recupere les bornes min/max de annees
    SELECT
        min(annee),
        max(annee)
    FROM
        stock INTO annee_min,
        annee_max;
    -- on fait une boucle correspondant a 1% des tuples
    -- de la table stock
    FOR v_tuples IN 1..echantillon LOOP
        -- selection d'identifiant, au hasard
        --select round(random()*contenants_disponibles) into v_contenant_id;
        v_contenant_id := round(random() * contenants_disponibles);
        --select round(random()*vins_disponibles) into v_vin_id;
        v_vin_id := round(random() * vins_disponibles);
        v_annee := round(random() * (annee_max - annee_min)) + (annee_min);
        -- si le tuple est deja efface, ce n'est pas grave..
        DELETE FROM stock
        WHERE contenant_id = v_contenant_id
            AND vin_id = v_vin_id
            AND annee = v_annee;
        IF (((v_tuples % 100) = 0) OR (v_tuples = echantillon)) THEN
            RAISE NOTICE 'stock : % sur % echantillon effaces', v_tuples, echantillon;
        END IF;
    END LOOP;
    --fin boucle v_tuples
    RETURN echantillon;
END;
$$;

ALTER FUNCTION public.trous_stock () OWNER TO userdb;

--
-- Name: trous_vin(); Type: FUNCTION; Schema: public; Owner: userdb
--
CREATE FUNCTION trous_vin ()
    RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    vin_total integer;
    echantillon integer;
    v_vin_id integer;
    v_tuples bigint := 0;
    v_annee integer;
BEGIN
    -- on compte le nombre de tuples dans vin
    SELECT
        count(*)
    FROM
        vin INTO vin_total;
    RAISE NOTICE '% vins disponibles', vin_total;
    -- on calcule la taille de l'echantillon a
    -- supprimer de la table vin
    SELECT
        round(vin_total / 10) INTO echantillon;
    RAISE NOTICE 'taille de l''echantillon %', echantillon;
    -- on fait une boucle correspondant a 10% des tuples
    -- de la table vin
    FOR v_tuples IN 1..echantillon LOOP
        -- selection d'identifiant, au hasard
        v_vin_id := round(random() * vin_total);
        -- si le tuple est deja efface, ce n'est pas grave..
        -- TODO remplacer ce delete par un trigger on delete cascade
        --      voir dans druid le schema???
        DELETE FROM stock
        WHERE vin_id = v_vin_id;
        DELETE FROM vin
        WHERE id = v_vin_id;
        IF (((v_tuples % 100) = 0) OR (v_tuples = echantillon)) THEN
            RAISE NOTICE 'vin : % sur % echantillon effaces', v_tuples, echantillon;
        END IF;
    END LOOP;
    --fin boucle v_tuples
    RETURN echantillon;
END;
$$;

ALTER FUNCTION public.trous_vin () OWNER TO userdb;

SET default_tablespace = '';

SET default_with_oids = FALSE;

--
-- Name: appellation; Type: TABLE; Schema: public; Owner: userdb
--
CREATE TABLE appellation (
    id integer NOT NULL,
    libelle text NOT NULL,
    region_id integer
)
WITH (
    autovacuum_enabled = OFF
);

ALTER TABLE appellation OWNER TO userdb;

--
-- Name: appellation_id_seq; Type: SEQUENCE; Schema: public; Owner: userdb
--
CREATE SEQUENCE appellation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE appellation_id_seq OWNER TO userdb;

--
-- Name: appellation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: userdb
--
ALTER SEQUENCE appellation_id_seq OWNED BY appellation.id;

--
-- Name: contenant; Type: TABLE; Schema: public; Owner: userdb
--
CREATE TABLE contenant (
    id integer NOT NULL,
    contenance real NOT NULL,
    libelle text
)
WITH (
    autovacuum_enabled = OFF,
    fillfactor = '20'
);

ALTER TABLE contenant OWNER TO userdb;

--
-- Name: contenant_id_seq; Type: SEQUENCE; Schema: public; Owner: userdb
--
CREATE SEQUENCE contenant_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE contenant_id_seq OWNER TO userdb;

--
-- Name: contenant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: userdb
--
ALTER SEQUENCE contenant_id_seq OWNED BY contenant.id;

--
-- Name: recoltant; Type: TABLE; Schema: public; Owner: userdb
--
CREATE TABLE recoltant (
    id integer NOT NULL,
    nom text,
    adresse text
)
WITH (
    autovacuum_enabled = OFF
);

ALTER TABLE recoltant OWNER TO userdb;

--
-- Name: recoltant_id_seq; Type: SEQUENCE; Schema: public; Owner: userdb
--
CREATE SEQUENCE recoltant_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE recoltant_id_seq OWNER TO userdb;

--
-- Name: recoltant_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: userdb
--
ALTER SEQUENCE recoltant_id_seq OWNED BY recoltant.id;

--
-- Name: region; Type: TABLE; Schema: public; Owner: userdb
--
CREATE TABLE region (
    id integer NOT NULL,
    libelle text NOT NULL
)
WITH (
    autovacuum_enabled = OFF
);

ALTER TABLE region OWNER TO userdb;

--
-- Name: region_id_seq; Type: SEQUENCE; Schema: public; Owner: userdb
--
CREATE SEQUENCE region_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE region_id_seq OWNER TO userdb;

--
-- Name: region_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: userdb
--
ALTER SEQUENCE region_id_seq OWNED BY region.id;

--
-- Name: stock; Type: TABLE; Schema: public; Owner: userdb
--
CREATE TABLE stock (
    vin_id integer NOT NULL,
    contenant_id integer NOT NULL,
    annee integer NOT NULL,
    nombre integer NOT NULL
)
WITH (
    autovacuum_enabled = OFF
);

ALTER TABLE stock OWNER TO userdb;

--
-- Name: type_vin; Type: TABLE; Schema: public; Owner: userdb
--
CREATE TABLE type_vin (
    id integer NOT NULL,
    libelle text NOT NULL
)
WITH (
    autovacuum_enabled = OFF
);

ALTER TABLE type_vin OWNER TO userdb;

--
-- Name: type_vin_id_seq; Type: SEQUENCE; Schema: public; Owner: userdb
--
CREATE SEQUENCE type_vin_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE type_vin_id_seq OWNER TO userdb;

--
-- Name: type_vin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: userdb
--
ALTER SEQUENCE type_vin_id_seq OWNED BY type_vin.id;

--
-- Name: vin; Type: TABLE; Schema: public; Owner: userdb
--
CREATE TABLE vin (
    id integer NOT NULL,
    recoltant_id integer,
    appellation_id integer NOT NULL,
    type_vin_id integer NOT NULL
)
WITH (
    autovacuum_enabled = OFF
);

ALTER TABLE vin OWNER TO userdb;

--
-- Name: vin_id_seq; Type: SEQUENCE; Schema: public; Owner: userdb
--
CREATE SEQUENCE vin_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE vin_id_seq OWNER TO userdb;

--
-- Name: vin_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: userdb
--
ALTER SEQUENCE vin_id_seq OWNED BY vin.id;

--
-- Name: appellation id; Type: DEFAULT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY appellation
    ALTER COLUMN id SET DEFAULT nextval('appellation_id_seq'::regclass);

--
-- Name: contenant id; Type: DEFAULT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY contenant
    ALTER COLUMN id SET DEFAULT nextval('contenant_id_seq'::regclass);

--
-- Name: recoltant id; Type: DEFAULT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY recoltant
    ALTER COLUMN id SET DEFAULT nextval('recoltant_id_seq'::regclass);

--
-- Name: region id; Type: DEFAULT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY region
    ALTER COLUMN id SET DEFAULT nextval('region_id_seq'::regclass);

--
-- Name: type_vin id; Type: DEFAULT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY type_vin
    ALTER COLUMN id SET DEFAULT nextval('type_vin_id_seq'::regclass);

--
-- Name: vin id; Type: DEFAULT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY vin
    ALTER COLUMN id SET DEFAULT nextval('vin_id_seq'::regclass);

--
-- Name: appellation appellation_libelle_key; Type: CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY appellation
    ADD CONSTRAINT appellation_libelle_key UNIQUE (libelle);

--
-- Name: appellation appellation_pkey; Type: CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY appellation
    ADD CONSTRAINT appellation_pkey PRIMARY KEY (id);

--
-- Name: contenant contenant_pkey; Type: CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY contenant
    ADD CONSTRAINT contenant_pkey PRIMARY KEY (id);

--
-- Name: recoltant recoltant_pkey; Type: CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY recoltant
    ADD CONSTRAINT recoltant_pkey PRIMARY KEY (id);

--
-- Name: region region_pkey; Type: CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY region
    ADD CONSTRAINT region_pkey PRIMARY KEY (id);

--
-- Name: stock stock_pkey; Type: CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_pkey PRIMARY KEY (vin_id, contenant_id, annee);

--
-- Name: type_vin type_vin_pkey; Type: CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY type_vin
    ADD CONSTRAINT type_vin_pkey PRIMARY KEY (id);

--
-- Name: vin vin_pkey; Type: CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY vin
    ADD CONSTRAINT vin_pkey PRIMARY KEY (id);

--
-- Name: appellation appellation_region_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY appellation
    ADD CONSTRAINT appellation_region_id_fkey FOREIGN KEY (region_id) REFERENCES region (id) ON DELETE CASCADE;

--
-- Name: stock stock_contenant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_contenant_id_fkey FOREIGN KEY (contenant_id) REFERENCES contenant (id) ON DELETE CASCADE;

--
-- Name: stock stock_vin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY stock
    ADD CONSTRAINT stock_vin_id_fkey FOREIGN KEY (vin_id) REFERENCES vin (id) ON DELETE CASCADE;

--
-- Name: vin vin_appellation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY vin
    ADD CONSTRAINT vin_appellation_id_fkey FOREIGN KEY (appellation_id) REFERENCES appellation (id) ON DELETE CASCADE;

--
-- Name: vin vin_recoltant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY vin
    ADD CONSTRAINT vin_recoltant_id_fkey FOREIGN KEY (recoltant_id) REFERENCES recoltant (id) ON DELETE CASCADE;

--
-- Name: vin vin_type_vin_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: userdb
--
ALTER TABLE ONLY vin
    ADD CONSTRAINT vin_type_vin_id_fkey FOREIGN KEY (type_vin_id) REFERENCES type_vin (id) ON DELETE CASCADE;

--
-- PostgreSQL database dump complete
--
