DROP DATABASE IF EXISTS movietheater;
CREATE DATABASE movietheater;

USE movietheater;

DELIMITER //
CREATE PROCEDURE new_staff (
IN n_firstname VARCHAR(50), 
IN n_lastname VARCHAR(50),
IN n_email VARCHAR(256),
IN n_pass BINARY(64),
IN n_theater INT(11),
IN n_birthdate DATE
) 
BEGIN
	DECLARE last_id INT(11);
	INSERT INTO movietheater.anonymous ( is_student ) VALUES ( 0 );
    SET last_id = LAST_INSERT_ID();
	REPLACE INTO movietheater.users (user_id, firstname, lastname, email, pass, birthdate) VALUES (
		last_id, n_firstname, n_lastname, n_email, n_pass, n_birthdate);
    INSERT INTO movietheater.staff (staff_id, works_at) VALUES (
		last_id, n_theater
		);
	INSERT INTO movietheater.user_roles (r_user_id, r_role_id) VALUES (
		last_id, 3
        );
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE new_customer (
IN n_firstname VARCHAR(50), 
IN n_lastname VARCHAR(50),
IN n_email VARCHAR(256),
IN n_pass BINARY(64),
IN n_birthdate DATE,
IN n_is_student TINYINT
)
BEGIN
	DECLARE last_id INT(11);
	INSERT INTO movietheater.anonymous ( is_student ) VALUES ( n_is_student );
    SET last_id = LAST_INSERT_ID();

	INSERT INTO movietheater.users (user_id, firstname, lastname, email, pass, birthdate) VALUES (
		last_id, n_firstname, n_lastname, n_email, n_pass, n_birthdate);
    
    INSERT INTO movietheater.customers (customer_id) VALUES (
		last_id);
	
	INSERT INTO movietheater.user_roles (r_user_id, r_role_id) VALUES (
		last_id, 4
        );
END //

DELIMITER ;

DELIMITER // 

CREATE PROCEDURE fire_staff(
	IN n_staff_id INT(11)
)
BEGIN
	IF 
		NOT n_staff_id IN (SELECT manager_staff_id FROM movietheater.manager) AND 
        NOT n_staff_id IN (SELECT admin_id FROM movietheater.administrator) AND 
        n_staff_id IN (SELECT staff_id FROM movietheater.staff) THEN
			DELETE FROM movietheater.user_roles WHERE r_user_id = n_staff_id;
			DELETE FROM movietheater.staff WHERE staff_id = n_staff_id;
			DELETE FROM movietheater.users WHERE user_id = n_staff_id;
	END iF;
END //

DELIMITER ;

DELIMITER // 

CREATE PROCEDURE delete_customer(
	IN n_customer_id INT(11)
)
BEGIN
	IF n_customer_id IN (SELECT customer_id FROM movietheater.customers) THEN
		DELETE FROM movietheater.users WHERE user_id = n_customer_id;
	END iF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE new_manager(
IN n_staff_id INT(11)
)
BEGIN
	REPLACE INTO movietheater.manager(manager_staff_id, manager_theater_id) VALUES ( n_staff_id, (SELECT works_at FROM movietheater.staff WHERE staff_id = n_staff_id));
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE new_admin (
IN n_administrator_id INT(11)
)
BEGIN
	IF NOT n_adminsistor_id IN (SELECT admin_id FROM movietheater.administrator) THEN
		INSERT INTO movietheater.administrator(admin_id) VALUES (n_adminstrator_id);
	END IF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE delete_admin (
IN n_administrator_id INT(11)
)
BEGIN
	IF n_adminsistor_id IN (SELECT admin_id FROM movietheater.administrator) THEN
		DELETE FROM movietheater.administrator WHERE admin_id = n_adminstrator_id;
	END IF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE register_movie_to_projection (
IN n_movie_id INT(11),
IN n_projection_id INT(11)
)
BEGIN
	REPLACE INTO movietheater.showing(s_movie_id, s_projection_id) VALUES (n_movie_id, n_projection_id);
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE add_to_cart (
IN n_customer_id INT(11),
IN n_projection_id INT(11)
)
BEGIN
	DECLARE n_movie_id INT(11);
    DECLARE n_place_left INT(11);
    SET n_movie_id = (SELECT s_movie_id FROM movietheater.showing WHERE s_projection_id = n_projection_id);
    SET n_place_left = (SELECT place_left FROM movietheater.room INNER JOIN (SELECT p_room_id FROM movietheater.projection WHERE projection_id = n_projection_id) AS r ON room_id = p_room_id);
    
    IF n_place_left > 0 THEN
		IF (SELECT YEAR(CURDATE()) - YEAR((SELECT birthdate FROM movietheater.users WHERE user_id = n_customer_id)) AS age ) <= 14 THEN
			INSERT INTO movietheater.carts(c_customer_id, c_product_id, quantity, c_projection_id) VALUES (n_customer_id, 3, 1, n_projection_id);
		ELSEIF (SELECT is_student FROM movietheater.anonymous WHERE anonymous_id = n_customer_id) = 1 THEN
			INSERT INTO movietheater.carts(c_customer_id, c_product_id, quantity, c_projection_id) VALUES (n_customer_id, 2, 1, n_projection_id);
		ELSE 
			INSERT INTO movietheater.carts(c_customer_id, c_product_id, quantity, c_projection_id) VALUES (n_customer_id, 1, 1, n_projection_id);
		END IF;
        UPDATE movietheater.room SET place_left = place_left-1 WHERE room_id = (SELECT p_room_id FROM movietheater.projection WHERE projection_id = n_projection_id);
	ELSE 
		SELECT "No more place available" AS "Error";
	END IF;
END //

DELIMITER ;

DELIMITER //

CREATE PROCEDURE add_to_cart_anonymous (
IN n_projection_id INT(11),
IN n_under_14 TINYINT,
IN n_is_student TINYINT
)
BEGIN
	DECLARE n_movie_id INT(11);
	DECLARE last_id INT(11);
    DECLARE n_place_left INT(11);
    
    SET n_movie_id = (SELECT s_movie_id FROM movietheater.showing WHERE s_projection_id = n_projection_id);
    SET n_place_left = (SELECT place_left FROM movietheater.room INNER JOIN (SELECT p_room_id FROM movietheater.projection WHERE projection_id = n_projection_id) AS r ON room_id = p_room_id);
    
	INSERT INTO movietheater.anonymous ( is_student ) VALUES ( n_is_student );
    SET last_id = LAST_INSERT_ID();
	IF n_place_left > 0 THEN
		IF n_under_14 = 1 THEN
			INSERT INTO movietheater.carts(c_customer_id, c_product_id, quantity, c_projection_id) VALUES (last_id, 3, 1, n_projection_id);
		ELSEIF (SELECT is_student FROM movietheater.anonymous WHERE anonymous_id = last_id) = 1 THEN
			INSERT INTO movietheater.carts(c_customer_id, c_product_id, quantity, c_projection_id) VALUES (last_id, 2, 1, n_projection_id);
		ELSE 
			INSERT INTO movietheater.carts(c_customer_id, c_product_id, quantity, c_projection_id) VALUES (last_id, 1, 1, n_projection_id);
		END IF;
		UPDATE movietheater.room SET place_left = place_left-1 WHERE room_id = (SELECT p_room_id FROM movietheater.projection WHERE projection_id = n_projection_id);
	ELSE
		SELECT "No more place available" AS "Error";
	END IF;
END //

DELIMITER ;


CREATE TABLE movietheater.anonymous (
	anonymous_id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
	is_student TINYINT DEFAULT 0
    );

-- Table des utilisateurs qu'ils soient clients pour les achats (customers) en ligne ou les employés (staff, manager, admin)
CREATE TABLE movietheater.users ( 
	user_id INT(11) NOT NULL PRIMARY KEY, 
    firstname VARCHAR(50) NOT NULL, 
    lastname VARCHAR(50) NOT NULL, 
    email VARCHAR(256) NOT NULL UNIQUE,
    pass BINARY(64) NOT NULL,
    birthdate DATE NOT NULL,
    FOREIGN KEY (user_id) REFERENCES movietheater.anonymous(anonymous_id)
    );
   
-- Tables des cinémas (theater), des salles (romm), des films disponibles (film) et des programmes de diffusion (schedules)
CREATE TABLE movietheater.theater ( 
	theater_id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    theater_name VARCHAR(100) NOT NULL DEFAULT ""
    ); 
    
CREATE TABLE movietheater.room ( 
	room_id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    room_name VARCHAR(100) NOT NULL, 
    theater INT(11) NOT NULL,
    number_of_places INT(11) NOT NULL,
    place_left INT(11) NULL,
    FOREIGN KEY (theater) REFERENCES movietheater.theater(theater_id)
    );
    
CREATE TABLE movietheater.movie ( 
	movie_id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    movie_name VARCHAR(50) NOT NULL,
    duration TIME NOT NULL
    );
    
CREATE TABLE movietheater.projection (
	projection_id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY,
    projection_time TIME NOT NULL,
    p_room_id INT(11) NOT NULL,
    FOREIGN KEY (p_room_id) REFERENCES movietheater.room(room_id)
	);
    
CREATE TABLE movietheater.showing (
	s_movie_id INT(11) NOT NULL,
    s_projection_id INT(11) NOT NULL UNIQUE,
    FOREIGN KEY (s_movie_id)  REFERENCES movietheater.movie(movie_id),
    FOREIGN KEY (s_projection_id) REFERENCES movietheater.projection(projection_id)
	);
    
CREATE TABLE movietheater.staff ( 
	staff_id INT(11) NOT NULL PRIMARY KEY, 
    works_at INT(11) NOT NULL, 
    FOREIGN KEY (staff_id) REFERENCES movietheater.users(user_id), 
    FOREIGN KEY (works_at) REFERENCES movietheater.theater(theater_id) 
    );
    
CREATE TABLE movietheater.manager (
	manager_theater_id INT(11) NOT NULL UNIQUE,
    manager_staff_id INT(11) NOT NULL PRIMARY KEY,
    FOREIGN KEY (manager_theater_id) REFERENCES movietheater.theater(theater_id),
    FOREIGN KEY (manager_staff_id) REFERENCES movietheater.staff(staff_id)
);

CREATE TABLE movietheater.administrator ( 
	admin_id INT(11) NOT NULL PRIMARY KEY, 
    FOREIGN KEY (admin_id) REFERENCES movietheater.staff(staff_id) 
    );

CREATE TABLE movietheater.customers ( 
	customer_id INT(11) NOT NULL PRIMARY KEY, 
    FOREIGN KEY (customer_id) REFERENCES movietheater.users(user_id)
    );


-- Table des roles d'utilisateurs
CREATE TABLE movietheater.roles ( 
	role_id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    role_name VARCHAR(50) NOT NULL UNIQUE 
    );

CREATE TABLE movietheater.user_roles (     
	r_user_id INT(11) NOT NULL,
    r_role_id INT(11) DEFAULT 4,
    PRIMARY KEY (r_user_id, r_role_id),
    FOREIGN KEY (r_user_id) REFERENCES movietheater.users(user_id),
    FOREIGN KEY (r_role_id) REFERENCES movietheater.roles(role_id) 
    );

-- Table des produits correspondant aux différents tarifs
CREATE TABLE movietheater.products ( 
	product_id INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY, 
    price DECIMAL(10, 2) NOT NULL, 
    label VARCHAR(50) NOT NULL
    );
    
CREATE TABLE movietheater.carts ( 
    c_customer_id INT(11) NOT NULL,
    c_product_id INT(11) NOT NULL,
    c_projection_id INT(11) NOT NULL,
    quantity INT(11) NOT NULL,
    PRIMARY KEY (c_customer_id, c_product_id),
    FOREIGN KEY (c_customer_id) REFERENCES movietheater.anonymous(anonymous_id),
    FOREIGN KEY (c_product_id) REFERENCES movietheater.products(product_id),
    FOREIGN KEY (c_projection_id) REFERENCES movietheater.projection(projection_id)
    );
    
INSERT INTO movietheater.products (price, label)
	VALUES
    (9.20, 'Plein Tarif'),
    (7.60, 'Etudiant'),
    (5.90, 'Moins de 14 ans')
    ;
    
INSERT INTO movietheater.roles (role_name)
	VALUES
    ('ROLE_ADMIN'),
    ('ROLE_MANAGER'),
    ('ROLE_STAFF'),
    ('ROLE_CUSTOMER')
    ;

INSERT INTO movietheater.theater (theater_name) 
	VALUES 
    ('Filmothèque des Cinéphiles'),
    ('Grand Diplo'),
    ('Auditorium du Musée de l\'Opéra')
    ;

INSERT INTO movietheater.room (room_name, theater, number_of_places, place_left)
	VALUES
    ('Salle 1', 1, '150', '150'),
    ('Salle 2', 1, '112', '112'),
    ('Salle 3', 1, '92', '92'),
    ('Salle 4', 1, '120', '120'),
    ('Salle 5', 1, '230', '230'),
    ('Salle 6', 1, '108', '108'),
    ('Salle VIP', 1, '50', '50'),
    ('Salle 101', 2, '500', '500'),
    ('Salle 102', 2, '250', '250'),
    ('Salle 103', 2, '213', '213'),
    ('Salle 201', 2, '555', '555'),
    ('Salle 202', 2, '312', '312'),
    ('Salle 301', 2, '260', '260'),
    ('Salle 302', 2, '302', '302'),
    ('Salle 303', 2, '190', '190'),
    ('Salle 304', 2, '293', '293'),
    ('Salle 401', 2, '423', '423'),
    ('Salle Charles Burles', 3, '305', '305'),
    ('Salle Mady Mesplé', 3, '268', '268'),
    ('Salle René Bianco', 3, '461', '461'),
    ('Salle Christiane Eda-Pierre', 3, '346', '346'),
    ('Salle Hélène Bouvier', 3, '480', '480'),
    ('Salle Michel Sénéchal', 3, '369', '369')
    ;

INSERT INTO movietheater.projection ( projection_time, p_room_id )
	VALUES
    ('10:30:00', 1), ('14:00:00', 1), ('19:00:00', 1),
    ('11:00:00', 2), ('15:00:00', 2), ('20:00:00', 2),
    ('12:00:00', 3), ('17:00:00', 3), ('21:00:00', 3),
    ('11:30:00', 4), ('16:00:00', 4), ('20:30:00', 4),
    ('10:30:00', 5), ('14:00:00', 5), ('17:30:00', 5), ('21:00:00', 5),
    ('10:30:00', 6), ('15:00:00', 6), ('20:00:00', 6),
    ('14:30:00', 7), ('18:00:00', 7), 
    ('10:30:00', 8), ('14:00:00', 8), ('17:30:00', 8), ('21:00:00', 8),
    ('10:30:00', 9), ('14:30:00', 9), ('19:00:00', 9),
    ('11:00:00', 10), ('15:00:00', 10), ('20:00:00', 10),
    ('10:30:00', 11), ('14:00:00', 11), ('17:30:00', 11), ('21:00:00', 11),
    ('11:30:00', 12), ('15:30:00', 12), ('20:30:00', 12),
    ('11:00:00', 13), ('14:30:00', 13), ('19:00:00', 13),
    ('11:30:00', 14), ('16:00:00', 14), ('20:00:00', 14),
    ('13:00:00', 15), ('17:00:00', 15), ('21:00:00', 15),
    ('10:30:00', 16), ('14:00:00', 16), ('18:00:00', 16),
    ('10:30:00', 17), ('14:00:00', 17), ('17:30:00', 17), ('21:00:00', 17),
    ('13:30:00', 18), ('17:00:00', 18), ('21:00:00', 18),
    ('14:00:00', 19), ('17:00:00', 19),
    ('13:00:00', 20), ('16:30:00', 20), ('20:30:00', 20),
    ('10:30:00', 21), ('14:00:00', 21), ('18:00:00', 21),
    ('12:30:00', 22), ('16:00:00', 22), ('20:00:00', 22),
    ('12:00:00', 23), ('15:30:00', 23), ('19:30:00', 23)
    ;

INSERT INTO movietheater.movie (movie_name, duration)
	VALUES
    ('La Marraine', '02:36:00'),
    ('The White Knight', '02:48:00'),
    ('Fictioctopus', '02:55:00'),
    ('Resolution', '02:22:00'),
    ('Extrastellar', '02:41:00'),
    ('La Ligne Rouge', '03:13:00'),
    ('Retour vers le passé', '02:08:00'),
    ('WALL-A', '01:45:00'),
    ('Le Retour du Samouraï', '02:15:00'),
    ('Kill Phil', '02:49:00'),
    ('Le Géant d\'acier', '01:36:00'),
    ('Asmérism: Mission César', '02:05:00')
    ;

CALL movietheater.register_movie_to_projection(1, 1);
CALL movietheater.register_movie_to_projection(3, 2);
CALL movietheater.register_movie_to_projection(8, 3);
CALL movietheater.register_movie_to_projection(6, 4);
CALL movietheater.register_movie_to_projection(5, 5);
CALL movietheater.register_movie_to_projection(8, 6);
CALL movietheater.register_movie_to_projection(6, 7);
CALL movietheater.register_movie_to_projection(1, 8);
CALL movietheater.register_movie_to_projection(6, 9);
CALL movietheater.register_movie_to_projection(11, 10);
CALL movietheater.register_movie_to_projection(3, 11);
CALL movietheater.register_movie_to_projection(1, 12);
CALL movietheater.register_movie_to_projection(2, 13);
CALL movietheater.register_movie_to_projection(2, 14);
CALL movietheater.register_movie_to_projection(2, 15);
CALL movietheater.register_movie_to_projection(2, 16);
CALL movietheater.register_movie_to_projection(11, 17);
CALL movietheater.register_movie_to_projection(4, 18);
CALL movietheater.register_movie_to_projection(4, 19);
CALL movietheater.register_movie_to_projection(2, 21);
CALL movietheater.register_movie_to_projection(2, 22);
CALL movietheater.register_movie_to_projection(2, 24);
CALL movietheater.register_movie_to_projection(2, 25);
CALL movietheater.register_movie_to_projection(1, 26);
CALL movietheater.register_movie_to_projection(5, 27);
CALL movietheater.register_movie_to_projection(12, 29);
CALL movietheater.register_movie_to_projection(1, 30);
CALL movietheater.register_movie_to_projection(2, 32);
CALL movietheater.register_movie_to_projection(2, 33);
CALL movietheater.register_movie_to_projection(3, 37);
CALL movietheater.register_movie_to_projection(7, 38);
CALL movietheater.register_movie_to_projection(6, 39);
CALL movietheater.register_movie_to_projection(5, 40);
CALL movietheater.register_movie_to_projection(8, 46);
CALL movietheater.register_movie_to_projection(8, 47);
CALL movietheater.register_movie_to_projection(4, 50);
CALL movietheater.register_movie_to_projection(10, 52);
CALL movietheater.register_movie_to_projection(10, 54);
CALL movietheater.register_movie_to_projection(10, 55);
CALL movietheater.register_movie_to_projection(1, 57);
CALL movietheater.register_movie_to_projection(6, 58);
CALL movietheater.register_movie_to_projection(5, 59);
CALL movietheater.register_movie_to_projection(9, 60);
CALL movietheater.register_movie_to_projection(2, 61);
CALL movietheater.register_movie_to_projection(6, 63);
CALL movietheater.register_movie_to_projection(4, 65);
CALL movietheater.register_movie_to_projection(2, 67);
CALL movietheater.register_movie_to_projection(3, 71);

CALL movietheater.new_staff('Jean', 'Sarrazin', 'JeanSarrazin@teleworm.us', SHA1('obahPohk4'), 1, '1986-11-27');
CALL movietheater.new_staff('Aya', 'Lamy', 'AyaLamy@armyspy.com ', SHA1('Xohz5Izahs7'), 1, '1996-03-03');
CALL movietheater.new_staff('Vallis', 'Lamour', 'VallisLamour@armyspy.com', SHA1('ieThoh4hi'), 1, '1962-05-16');
CALL movietheater.new_staff('Azura', 'Paquet', 'AzuraPaquet@teleworm.us', SHA1('Akohgh6ro'), 1, '1999-07-08');
CALL movietheater.new_staff('Lowell', 'Faubert', 'LowellFaubert@rhyta.com', SHA1('Uusaemi0oom'), 1, '1974-07-22');

CALL movietheater.new_staff('Liane', 'Ruel', 'LianeRuel@jourrapide.com', SHA1('beiPeif5b'), 2, '1963-09-26');
CALL movietheater.new_staff('Véronique', 'Vallée', 'VéroniqueVallée@teleworm.us', SHA1('ooja9axaeLa'), 2, '1983-07-31');
CALL movietheater.new_staff('Charles', 'Beaudoin', 'CharlesBeaudoin@dayrep.com', SHA1('ieW2pei9xe'), 2, '1981-06-17');
CALL movietheater.new_staff('Amitée', 'Lepage', 'AmiteeLepage@armyspy.com', SHA1('wa9OT7oode9e'), 2, '1968-10-18');
CALL movietheater.new_staff('Audrey', 'Bellefeuille', 'AudreyBellefeuille@armyspy.com ', SHA1('qui8ohSh'), 2, '1990-01-18');
CALL movietheater.new_staff('Ogier', 'Potvin', 'OgierPotvin@armyspy.com', SHA1('it4ail7Shoh'), 2, '1967-08-22');
CALL movietheater.new_staff('Laurette', 'Labonté', 'LauretteLabonté@armyspy.com', SHA1('Jee2Ya2aeD'), 2, '1963-05-19');
CALL movietheater.new_staff('Noémie', 'Archambault', 'NoemiArchambault@jourrapide.com ', SHA1('eewoX5ce'), 2, '1989-06-13');
CALL movietheater.new_staff('Gauthier', 'Labrosse', 'GauthierLabrosse@teleworm.us', SHA1('shiak8Bai'), 2, '1972-03-16');
CALL movietheater.new_staff('Aceline', 'Archambault', 'AcelineArchambault@armyspy.com', SHA1('rohyeed0UGh'), 2, '1957-11-15');
CALL movietheater.new_staff('Eugenia', 'Fecteau', 'EugeniaFecteau@armyspy.com', SHA1('see6aeXai'), 2, '1984-01-16');

CALL movietheater.new_staff('Harriette', 'Laforest', 'HarrietteLaforest@rhyta.com', SHA1('maePoh8oe4oh'), 3, '1984-09-08');
CALL movietheater.new_staff('Henry', 'Desaulniers', 'HenryDesaulniers@dayrep.com', SHA1('Vahkulah6ge'), 3, '1986-05-22');
CALL movietheater.new_staff('Albertine', 'Richer', 'AlbertineRicher@rhyta.com', SHA1('eiM0uex4ibe'), 3, '1967-10-21');
CALL movietheater.new_staff('Alexandre', 'Desjardins', 'AlexandreDesjardins@rhyta.com', SHA1('Oiz7oP0eng'), 3, '1966-02-21');
CALL movietheater.new_staff('Gérard', 'Lafrenière', 'GerardLafreniere@armyspy.com', SHA1('uyai8Deejae'), 3, '1998-04-11');
CALL movietheater.new_staff('Patrice', 'Laisné', 'PatriceLaisne@teleworm.us', SHA1('cohWeiph0ph'), 3, '1969-09-09');
CALL movietheater.new_staff('Eloise', 'Camus', 'EloiseCamus@armyspy.com', SHA1('ceeF8Sai'), 3, '1975-06-05');
CALL movietheater.new_staff('Pénélope', 'Neufville', 'PenelopeNeufville@rhyta.com', SHA1('eiz4uJieY'), 3, '1992-07-12');
CALL movietheater.new_staff('Élise', 'Desrosiers', 'EliseDesrosiers@jourrapide.com', SHA1('ienaif0NaeG'), 3, '1967-01-15');

CALL movietheater.new_manager(1);
CALL movietheater.new_manager(6);
CALL movietheater.new_manager(17);

CALL movietheater.new_customer('Monique', 'Lussier', 'MoniqueLussier@teleworm.us', SHA1('aeN7ooXee'), '1965-09-27', 0);
CALL movietheater.new_customer('Aurélie', 'Édouard', 'AurelieEdouard@jourrapide.com', SHA1('heig0Doo8a'), '1998-07-07', 0);
CALL movietheater.new_customer('Élise', 'Ruais', 'EliseRuais@jourrapide.com', SHA1('Ieyah5ood'), '2001-08-28', 1);
CALL movietheater.new_customer('Véronique', 'Benoit', 'VeroniqueBenoit@dayrep.com', SHA1('UGoh5Dai3Ah'), '1963-07-08', 0);
CALL movietheater.new_customer('Ophelia', 'Mailloux', 'OpheliaMailloux@rhyta.com', SHA1('Uu4EePh1'), '2005-04-25', 1);
CALL movietheater.new_customer('Yvon', 'Jalbert', 'YvonJalbert@dayrep.com', SHA1('Af1IhieFu3'), '2010-04-06', 0);

-- Take customer id, projection id to assign a cart to a customer
CALL movietheater.add_to_cart(26, 13); -- Cliente Monique Lussier pour la projection id 13 (Salle 5 à 10h30 Filmothèque des Cinéphiles) diffusant le film id 2 (The White Knight)
CALL movietheater.add_to_cart(27, 40); -- Cliente Aurélie Edouard pour la projection id 40 (Salle 301 à 14h30 Grand Diplo) diffusant le film id 5 (Extrastellar)
CALL movietheater.add_to_cart(28, 38); -- Cliente Elise Ruais pour la projection id 38 (Salle 202 à 20h30 Grand Diplo) diffusant le film id 7 (Retour vers le plassé)

-- Take projection id, under 14 yo (0 or 1) and is student (0 or 1) to create an anonymous customer and assign it a cart
CALL movietheater.add_to_cart_anonymous(21, 1, 0);


-- Get registered users name with theater name room hour price for their carts
SELECT theater_name AS "Cinéma", room_name AS "Salle", projection_time AS "Heure", label AS "Formule", price AS "prix", fullname AS "Nom" FROM movietheater.projection
	INNER JOIN (SELECT c_projection_id  FROM movietheater.carts) 
    AS a ON projection_id = c_projection_id
    INNER JOIN (SELECT label, price, proj_id FROM movietheater.products 
		INNER JOIN (SELECT c_product_id, c_projection_id AS proj_id FROM movietheater.carts) 
		AS b ON product_id = c_product_id) 
	AS c ON projection_id = proj_id
    INNER JOIN (SELECT CONCAT(firstname, " ", lastname) AS fullname, proj_id2 FROM movietheater.users 
		INNER JOIN (SELECT c_customer_id, c_projection_id AS proj_id2 FROM movietheater.carts) 
		AS d ON user_id = c_customer_id)
	AS e ON projection_id = proj_id2
    INNER JOIN (SELECT room_id, room_name, theater_name FROM movietheater.room 
		INNER JOIN (SELECT theater_name, theater_id FROM movietheater.theater) 
        AS g ON theater_id = theater) 
	AS f ON p_room_id = room_id;
    
-- Get anonymous customers id with theater name room hour price for their carts
SELECT theater_name AS "Cinéma", room_name AS "Salle", projection_time AS "Heure", label AS "Formule", price AS "prix", anonymous_id AS "ID" FROM movietheater.projection
	INNER JOIN (SELECT c_projection_id  FROM movietheater.carts) 
    AS a ON projection_id = c_projection_id
    INNER JOIN (SELECT label, price, proj_id FROM movietheater.products 
		INNER JOIN (SELECT c_product_id, c_projection_id AS proj_id FROM movietheater.carts) 
		AS b ON product_id = c_product_id) 
	AS c ON projection_id = proj_id
	INNER JOIN (SELECT anonymous_id, proj_id3 FROM movietheater.anonymous 
		INNER JOIN (SELECT c_customer_id, c_projection_id AS proj_id3 FROM movietheater.carts) 
		AS d ON anonymous_id = c_customer_id) 
	AS e ON projection_id = proj_id3
	INNER JOIN (SELECT room_id, room_name, theater_name FROM movietheater.room 
		INNER JOIN (SELECT theater_name, theater_id FROM movietheater.theater) 
        AS g ON theater_id = theater) 
	AS f ON p_room_id = room_id
    LEFT JOIN movietheater.users ON anonymous_id = user_id WHERE user_id IS NULL;
    



-- Display the sum of all cart from different customer
SELECT SUM(price) AS "Total" FROM
(SELECT price FROM movietheater.products INNER JOIN (
SELECT c_product_id FROM movietheater.carts WHERE c_customer_id IN (26, 28, 32)) AS c ON product_id = c_product_id) AS p;
		
-- Get managers for each Theaters
SELECT user_id AS "ID", firstname AS "Prénom", lastname AS "Nom", theater_name AS "Manager de" FROM movietheater.users 
INNER JOIN (
	SELECT staff_id, theater_name FROM movietheater.theater 
	INNER JOIN (
		SELECT manager_staff_id AS staff_id, manager_theater_id FROM movietheater.manager) 
	AS m ON theater_id = m.manager_theater_id)
AS t ON user_id = t.staff_id;

-- Get Room by theaters with a minimum and/or maximum number of places
SELECT room_id AS "ID", room_name AS "Nom de la Salle", number_of_places AS "Places", place_left AS "Places restantes", theater_name AS "Cinéma" FROM movietheater.room
INNER JOIN (
	SELECT theater_id, theater_name FROM movietheater.theater
    ) AS t ON theater = t.theater_id
WHERE number_of_places BETWEEN 0 AND 600;

-- Get All Room name, Movie name and projection time registered
SELECT movie_name "Nom du film", room_name AS "Salle", s_projection_id AS "Id Projection", projection_time AS "Heure de projection", theater_name AS "Cinéma" FROM movietheater.theater 
	INNER JOIN (
	SELECT s_projection_id, movie_name, room_name, projection_time, theater, s_movie_id FROM movietheater.room
		INNER JOIN (
		SELECT s_projection_id, p_room_id AS s_room_id, movie_name, projection_time, s_movie_id FROM movietheater.movie
		INNER JOIN (
			SELECT s_projection_id, projection_time, p_room_id, s_movie_id FROM movietheater.projection
			INNER JOIN (
				SELECT s_projection_id , s_movie_id FROM movietheater.showing
				) AS proj ON projection_id = s_projection_id
			) AS mov ON movie_id = s_movie_id
		) AS room ON room_id = s_room_id
	) AS cinema ON theater_id = theater
WHERE s_movie_id = 1;