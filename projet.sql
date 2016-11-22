DROP SCHEMA projet CASCADE;
DROP TYPE uwl;
CREATE SCHEMA projet;

/****************************************************************************/
/*********************************CREATE TABLE*******************************/
/****************************************************************************/


CREATE TABLE projet.factions(
	fac_num SERIAL PRIMARY KEY,
	fac_name VARCHAR(100) NOT NULL CHECK(fac_name<>''),
	fac_description TEXT  NULL
);

CREATE TABLE projet.super_heroes(
	sup_num SERIAL PRIMARY KEY,
	sup_lname VARCHAR(100) NULL CHECK(sup_lname<>''),
	sup_fname VARCHAR(100) NULL CHECK(sup_fname<>''),
	sup_name VARCHAR(100) NOT NULL CHECK(sup_name<>''),
	sup_type VARCHAR(100) NULL CHECK(sup_type<>''),
	sup_origin VARCHAR(100) NULL CHECK(sup_origin<>''),
	sup_power INTEGER NULL CHECK(sup_power <= 100), CHECK(sup_power >= 0),
	sup_active BOOLEAN NOT NULL DEFAULT true,
	sup_address VARCHAR(100) NULL,
	sup_faction INTEGER REFERENCES projet.factions(fac_num) NOT NULL
);

CREATE TABLE projet.agents(
	age_num SERIAL PRIMARY KEY,
	age_lname VARCHAR(100) NOT NULL CHECK(age_lname<>''),
	age_fname VARCHAR(100) NOT NULL CHECK(age_fname<>''),
	age_active BOOLEAN NOT NULL DEFAULT true,
	age_record_count INTEGER NOT NULL DEFAULT 1
);


CREATE TYPE uwl AS ENUM(
	'unknown',
	'win',
	'lose'
);

CREATE TABLE projet.battles(
	bat_num SERIAL PRIMARY KEY,
	bat_date TIMESTAMP NOT NULL,
	bat_posx INTEGER NOT NULL CHECK(bat_posx <= 100), CHECK(bat_posx >=0),
	bat_posy INTEGER NOT NULL CHECK(bat_posy <= 100), CHECK(bat_posy >=0)
);

CREATE TABLE projet.records(
	rec_num SERIAL PRIMARY KEY,
	rec_agent INTEGER REFERENCES projet.agents(age_num) NOT NULL,
	rec_super_hero INTEGER REFERENCES projet.super_heroes(sup_num) NOT NULL,
	rec_date TIMESTAMP NOT NULL,
	rec_posx INTEGER NOT NULL CHECK(rec_posx <= 100), CHECK(rec_posx >=0),
	rec_posy INTEGER NOT NULL CHECK(rec_posy <= 100), CHECK(rec_posy >=0),
	rec_battle INTEGER REFERENCES projet.battles(bat_num) NULL,
	rec_status uwl NULL
);

/*
CREATE TABLE projet.battle_faction(
	bf_num SERIAL PRIMARY KEY,
	bf_battle INTEGER REFERENCES projet.battles(bat_num) NOT NULL,
	bf_faction INTEGER REFERENCES projet.factions(fac_num) NOT NULL,
	bf_status uwl
);
*/

INSERT INTO projet.factions(fac_num, fac_name, fac_description)
	VALUES(1, 'Marvelle', NULL);

INSERT INTO projet.factions(fac_num, fac_name, fac_description)
	VALUES(2, 'Décé', NULL);

/****************************************************************************/
/*********************************SELECT*************************************/
/****************************************************************************/

/*
* GET ALL THE DANGEROUS ZONES
*/
CREATE VIEW projet.dangerous_zone AS
SELECT rec1.rec_posx AS rec1_posx, rec1.rec_posy AS rec1_posy, rec2.rec_posx AS rec2_posx, rec2.rec_posy AS rec2_posy
FROM projet.records rec1, projet.records rec2, projet.super_heroes sp1, projet.super_heroes sp2
WHERE sp1.sup_faction != sp2.sup_faction AND rec1.rec_super_hero = sp1.sup_num AND rec2.rec_super_hero = sp2.sup_num
AND((rec1.rec_posy = rec2.rec_posy
	AND(rec1.rec_posx = rec2.rec_posx - 1
		OR rec1.rec_posx = rec2.rec_posx + 1
		OR rec1.rec_posx = rec2.rec_posx))
	OR(rec1.rec_posx = rec2.rec_posx
		AND(rec1.rec_posy = rec2.rec_posy - 1
			OR rec1.rec_posy = rec2.rec_posy + 1
			OR rec1.rec_posy = rec2.rec_posy)));

CREATE VIEW projet.agent_data AS
SELECT ag.age_num AS "Agent Number", re.rec_num, re.rec_date,su.sup_name,re.rec_posx,re.rec_posy
FROM projet.agents ag, projet.records re, projet.super_heroes su
WHERE ag.age_num = re.rec_agent
AND su.sup_num = re.rec_super_hero
ORDER BY re.rec_date;


CREATE VIEW projet.agent_record_number AS
SELECT ag.age_num AS "Agent Number", count(re.rec_num),re.rec_date
FROM projet.agents ag, projet.records re
WHERE ag.age_num = re.rec_agent
GROUP BY re.rec_date, ag.age_num;


CREATE VIEW projet.super_heroes_ranking AS
SELECT su.sup_num AS "Super Number",su.sup_name,su.sup_fname,su.sup_lname,count(*)
FROM projet.super_heroes su, projet.records re
WHERE su.sup_num = re.rec_super_hero
AND re.rec_status = 'win'
GROUP BY su.sup_num;

/****************************************************************************/
/*********************************TRIGGER************************************/
/****************************************************************************/


CREATE OR REPLACE FUNCTION projet.procedureAddToAgent()
RETURNS TRIGGER AS $$
DECLARE
   old_count INTEGER;
BEGIN
	UPDATE projet.agents SET projet.agents.age_record_count = projet.agents.age_record_count+1
	WHERE projet.agents.age_num = NEW.rec_agent

	   RETURN NULL;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER triggerAddToAgent AFTER INSERT ON projet.records
FOR EACH ROW EXECUTE PROCEDURE projet.procedureAddToAgent();

/****************************************************************************/
/*********************************INSERT*************************************/
/****************************************************************************/

/*
* INSERT AN AGENT
*/

CREATE OR REPLACE FUNCTION projet.insertAgent(VARCHAR(100), VARCHAR(100)) RETURNS INTEGER AS $$
DECLARE
	agent_lname ALIAS FOR $1;
	agent_fname ALIAS FOR $2;
	id INTEGER:=0;
BEGIN
	INSERT INTO projet.agents VALUES
		(DEFAULT, agent_lname, agent_fname, DEFAULT)
		RETURNING id_operation INTO id;
	RETURN id;
END;
$$ LANGUAGE plpgsql;

/*
* INSERT A SIMPLE RECORD WITHOUT ANY BATTLE
*/
CREATE OR REPLACE FUNCTION projet.insertRecord(INTEGER, VARCHAR(100), VARCHAR(100), INTEGER, VARCHAR(100), TIMESTAMP, INTEGER, INTEGER, INTEGER) RETURNS INTEGER AS $$
DECLARE
	agent ALIAS FOR $1;
	agent_fname ALIAS FOR $2;
	agent_lname ALIAS FOR $3;
	super_hero ALIAS FOR $4;
	super_hero_name ALIAS FOR $5;
	date_rec ALIAS FOR $6;
	posx ALIAS FOR $7;
	posy ALIAS FOR $8;
	id INTEGER:=0;
BEGIN
	IF NOT EXISTS(SELECT * FROM projet.agents ag
		WHERE ag.age_num=agent AND ag.age_fname = agent_fname AND ag.age_lname = agent_lname) THEN
	RAISE foreign_key_violation;
	END IF;

	IF NOT EXISTS(SELECT * FROM projet.super_heroes sh
		WHERE sh.sup_num=super_hero AND sh.sup_name = super_hero_name) THEN
	RAISE foreign_key_violation;
	END IF;

	INSERT INTO projet.records VALUES
		(DEFAULT, agent, super_hero, date_rec, posx, posy, NULL, NULL)
		RETURNING id_operation INTO id;
	RETURN id;
END;
$$ LANGUAGE plpgsql;

/*
* INSERT A BATTLE
*/
CREATE OR REPLACE FUNCTION projet.insertBattle(INTEGER, INTEGER, INTEGER) RETURNS INTEGER AS $$
DECLARE
	date_rec ALIAS FOR $1;
	posx ALIAS FOR $2;
	posy ALIAS FOR $3;
	id INTEGER:=0;
BEGIN
	INSERT INTO projet.battles VALUES
		(DEFAULT, date_rec, posx, posy)
		RETURNING id_operation INTO id;
	RETURN id;
END;
$$ LANGUAGE plpgsql;

/*
* INSERT A RECORD WITH BATTLE
*/
CREATE OR REPLACE FUNCTION projet.insertRecordCombat(INTEGER, VARCHAR(100), VARCHAR(100), INTEGER, VARCHAR(100), TIMESTAMP, INTEGER, INTEGER, INTEGER, INTEGER, uwl) RETURNS INTEGER AS $$
DECLARE
	agent ALIAS FOR $1;
	agent_fname ALIAS FOR $2;
	agent_lname ALIAS FOR $3;
	super_hero ALIAS FOR $4;
	super_hero_name ALIAS FOR $5;
	date_rec ALIAS FOR $6;
	posx ALIAS FOR $7;
	posy ALIAS FOR $8;
	battle ALIAS FOR $9;
	status ALIAS FOR $10;
	id INTEGER:=0;
BEGIN
	IF NOT EXISTS(SELECT * FROM projet.agents ag
		WHERE ag.age_num=agent AND ag.age_fname = agent_fname AND ag.age_lname = agent_lname) THEN
	RAISE foreign_key_violation;
	END IF;

	IF NOT EXISTS(SELECT * FROM projet.super_heroes sh
		WHERE sh.sup_num=super_hero AND sh.sup_name = super_hero_name) THEN
	RAISE foreign_key_violation;
	END IF;

	IF NOT EXISTS(SELECT * FROM projet.battles bt
		WHERE bt.bat_date = date_rec AND bt.bat_posy = posy AND bt.bat_posx = posx AND bt.bat_num = battle) THEN
	RAISE foreign_key_violation;
	END IF;

	INSERT INTO projet.records VALUES
		(DEFAULT, agent, super_hero, date_rec, posx, posy, battle, status)
		RETURNING id_operation INTO id;
	RETURN id;
END;
$$ LANGUAGE plpgsql;

/*
* INSERT A SUPER HERO
*/

CREATE OR REPLACE FUNCTION projet.insertSuperHero(
	VARCHAR(100),
	VARCHAR(100),
	VARCHAR(100),
	VARCHAR(100),
	VARCHAR(100),
	INTEGER,
	BOOLEAN,
	VARCHAR(100),
	INTEGER
)RETURNS INTEGER AS $$
DECLARE
	super_last_name ALIAS FOR $1;
	super_first_name ALIAS FOR $2;
	super_name ALIAS FOR $3;
	super_type ALIAS FOR $4;
	super_origin ALIAS FOR $5;
	super_power ALIAS FOR $6;
	super_active ALIAS FOR $7;
	super_address ALIAS FOR $8;
	super_faction ALIAS FOR $9;
BEGIN

	INSERT INTO projet.super_heroes VALUES
	(DEFAULT,super_last_name,super_first_name,super_name,
		super_type,super_origin,super_power,super_active,
		super_address,super_faction)
	RETURNING sup_num AS super_number;
	RETURN super_number;
EXCEPTION
WHEN check_violation THEN RETURN -3;
END;
$$ LANGUAGE plpgsql;

/****************************************************************************/
/*********************************MODIFIE************************************/
/****************************************************************************/

/*
* DELETE AN AGENT
*/
CREATE OR REPLACE FUNCTION projet.deleteAgent(INTEGER, VARCHAR(100), VARCHAR(100)) RETURNS INTEGER AS $$
DECLARE
	agent ALIAS FOR $1;
	agent_lname ALIAS FOR $2;
	agent_fname ALIAS FOR $3;
	id INTEGER:=0;
BEGIN
	IF NOT EXISTS(SELECT * FROM projet.agents ag
		WHERE ag.age_num=agent AND ag.age_fname = agent_fname AND ag.age_lname = agent_lname) THEN
	RAISE foreign_key_violation;
	END IF;

	IF EXISTS(SELECT * FROM projet.agents ag
		WHERE ag.age_num=agent AND ag.age_fname = agent_fname AND ag.age_lname = agent_lname AND ag.age_active = false) THEN
	RAISE EXCEPTION 'This agent is already inactive';
	END IF;

	UPDATE projet.agents ag
	SET ag.age_active = false
	WHERE ag.age_num = agent AND ag.age_lname = agent_lname AND ag.age_fname = agent_fname
		RETURNING id_operation INTO id;
	RETURN id;
END;
$$ LANGUAGE plpgsql;

/*
* DELETE A SUPER HERO
*/
CREATE OR REPLACE FUNCTION projet.deleteSuperHero(INTEGER, VARCHAR(100), VARCHAR(100)) RETURNS INTEGER AS $$
DECLARE
	super_hero ALIAS FOR $1;
	super_hero_name ALIAS FOR $2;
	id INTEGER:=0;
BEGIN
	IF NOT EXISTS(SELECT * FROM projet.super_heroes sh
		WHERE sh.sup_num = super_hero AND sh.sup_name = super_hero_name) THEN
	RAISE foreign_key_violation;
	END IF;

	IF EXISTS(SELECT * FROM projet.super_heroes sh
		WHERE sh.sup_num = super_hero AND sh.sup_name = super_hero_name AND sh.sup_active = false) THEN
	RAISE EXCEPTION 'This super hero is already inactive';
	END IF;

	UPDATE projet.super_heroes sh
	SET sh.sup_active = false
	WHERE sh.sup_num = super_hero AND sp.sup_name = super_hero_name
		RETURNING id_operation INTO id;
	RETURN id;
END;
$$ LANGUAGE plpgsql;
