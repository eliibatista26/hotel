Create database hotel;
use hotel;

# In this table contains all information about the client who is going to stay at the hotel
create table Guest(
IDGuest int not null primary key auto_increment,
Identification varchar(20) unique not null, 
name varchar(50) not null, 
surname varchar(50) not null, 
email varchar(64) not null unique, 
country varchar(50) not null,
numberphone varchar(64) not null, 
birthdayDate date not null,
IDPersonType int,
foreign Key(IDPersonType) references PersonType (IDPersonType)
);
insert into Guest(Identification,name,surname,email,country,numberphone,birthdayDate) values('4678939i','ee','ee','he@he.com','spain','+3456787998','2009-05-09');
insert into Guest values (null,'4672639y','h','h','h@h.com','spain','+3456787998','2009-05-09',1);
#In this table contains the information about the type of room we are going 
# to assign to the client. For example, if it's double room, if it's triple room,
# individual room. 

create table RoomType(
IDType int not null primary key auto_increment, 
typeRoom varchar(50) not null, 
Description text not null , 
picture varchar(50) not null
);
# In this table constains all the information about the room. 
# And his foregin key, the other table like that of client (You need to link all the information in the client table with the room.),
# available (You need to know if the room is a readiness or busy), 
#type(You need know what is the kind of room you are going to assigned.)

create table Room(
nRoom int primary key not null auto_increment, 
nPerson int not null, 
stay int not null, 
available boolean default true, 
IDType int, 
foreign key (IDType) references RoomType (IDType)
); 

 
 #This table is to know the name of the 
create table Service(
IDService int auto_increment primary key,
name varchar(50) not null); 

Create table ServiceRoom(
IDServiceRoom int primary key auto_increment,
IDServices int, 
nRooms int,
foreign key (IDServices) references service(IDService),
foreign key (nRooms) references room(nRoom)
);

CREATE TABLE IF NOT EXISTS Cards (
  card_id INT PRIMARY KEY AUTO_INCREMENT,
  card_number VARCHAR(100) NOT NULL UNIQUE,
  card_holder VARCHAR(100) NOT NULL,
  expiration_date DATE NOT NULL,
  cvv INT NOT NULL
) ENGINE = INNODB;

create table Cards_Client (
IDCardsClient int not null primary key auto_increment, 
IDGuest int, 
IDCard int, 
foreign key (IDCard) references cards(card_id),
foreign key (IDGuest) references Guest(IDGuest)
);

CREATE TABLE IF NOT EXISTS Addresses (
  address_id INT PRIMARY KEY AUTO_INCREMENT,
  postal_code VARCHAR(10) NOT NULL,
  city VARCHAR(100) NOT NULL,
  street VARCHAR(100) NOT NULL,
  number INT NOT NULL,
  floor INT,
  letter VARCHAR(5)
) ENGINE = INNODB;

Create table Address_Client(
IDAddress_client INT PRIMARY KEY AUTO_INCREMENT,
IDGuest int, 
IDAddress int, 
foreign key (IDGuest) references Guest(IDGuest),
foreign key (IDAddress) references addresses(address_id)
); 

CREATE TABLE IF NOT EXISTS Reservation (
	IDReserva INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    IdGuest int not null,
	checkIn date not null,
    checkOut date not null,
	details text,
    price double, -- el total de toda la reserva
    foreign key (IDGuest) references Guest(IDGuest)
);

Create table ReservationLine(
IDReservationLine int not null primary key auto_increment,
IDReservation int,
nRoom int,
price double,  -- lo que cuesta una linea de reserva,
foreign key (IDReservation) references reservation(IDReserva), 
foreign key (nRoom) references room(nRoom)
); 

-- funcion o procedimiento que rellene el tipo de la tabla huesped 

CREATE table PersonType(
IDPersonType int primary key auto_increment, 
nameType varchar(50) not null unique,
minAge int, 
maxAge int 
);

-- Lo relleno yo como administradora 
-- Calculo en la 
create table Rate (
IDRate int primary key auto_increment, 
IDPersonType int,
IDRoomType int,
price decimal(10,2) not null,
foreign key (IDPersonType) references PersonType (IDPersonType),
foreign key (IDRoomType) references RoomType (IDType)
); 

insert into Reservation values(null, '2023-03-26', '2023-03-31', "fdgfg",90.89);


DELIMITER $$
CREATE TRIGGER UpdateAvailability AFTER INSERT ON ReservationLine
FOR EACH ROW
BEGIN
  UPDATE Room
  SET Available = false
  WHERE nRoom = (SELECT nRoom FROM ReservationLine WHERE  IDReservationLine = NEW.IDReservationLine);

  SET @CheckOutDate = (SELECT CheckOut FROM Reservation WHERE IDReserva = NEW.IDReservation);
  
  IF @CheckOutDate = CURRENT_DATE() THEN
    UPDATE Room
    SET Available = true
    WHERE IDRoom = (SELECT nRoom FROM ReservationLine WHERE  IDReservationLine = NEW.IDReservationLine);
  END IF;
END;
$$
DELIMITER ;


DELIMITER $$
CREATE TRIGGER Sojourn AFTER INSERT ON ReservationLine
FOR EACH ROW
BEGIN
    DECLARE num_noches INT;
    SELECT DATEDIFF((SELECT checkOut FROM Reservation WHERE IDReserva = NEW.IDReservation), (SELECT checkIn FROM Reservation WHERE IDReserva = NEW.IDReservation)) INTO num_noches;
    UPDATE Room SET stay = num_noches WHERE nRoom = NEW.nRoom;
END $$
DELIMITER ;
drop trigger update_guest;


DELIMITER $$
CREATE TRIGGER update_guest BEFORE INSERT ON guest
FOR EACH ROW
BEGIN
    DECLARE personType VARCHAR(50);
    DECLARE age INT;
    SET age = YEAR(CURDATE()) - YEAR(NEW.birthdayDate) - (DATE_FORMAT(CURDATE(), '%m%d') < DATE_FORMAT(NEW.birthdayDate, '%m%d'));
    
     SELECT IDPersonType INTO personType
    FROM PersonType
    WHERE minAge <= age AND maxAge >= age;
   
    SET NEW.IDPersonType = personType;
END;
$$
DELIMITER ;
drop procedure ReservationPrice;

DELIMITER //
CREATE PROCEDURE ReservationPrice(
    IN checkIn DATE,
    IN checkOut DATE,
    OUT price DECIMAL(10,2)
)
BEGIN
    DECLARE rate DECIMAL(10,2);
    DECLARE days INT;

    -- Buscar tarifa para el rango de fechas seleccionado
    SELECT price INTO rate
    FROM rate
    WHERE checkIn <= checkIn
        AND checkOut >= checkOut;

    -- Calcular días entre las fechas seleccionadas
    SET days = DATEDIFF(checkIn, checkOut) + 1;

    -- Calcular precio multiplicando la tarifa por el número de días
    SET price = rate * days;
END;
//
DELIMITER ;



/*DELIMITER //
CREATE TRIGGER ReservationPrice
BEFORE INSERT ON Reservation 
FOR EACH ROW
BEGIN
    DECLARE rate DECIMAL(10,2);
    DECLARE days INT;
	DECLARE roomType INT;
    DECLARE personType INT;
    
	SET roomType = (SELECT IDType FROM Room WHERE nRoom = NEW.nRoom);
	SET personType = NEW.IDPersonType;

    SELECT price INTO rate
    FROM rate
    WHERE IDTypeRoom = roomType
        AND IDPersonType = personType;

    SET days = DATEDIFF(NEW.checkOut, NEW.checkIn) + 1;

    SET NEW.price = rate * days;
END;
//
DELIMITER ; */



/*
DELIMITER //

CREATE TRIGGER tr_buscar_habitaciones_libres
BEFORE INSERT ON reserva -- Trigger se activa antes de insertar en la tabla "reserva"
FOR EACH ROW
BEGIN
    DECLARE habitaciones_disponibles INT;

    -- Lógica para buscar habitaciones libres
    SELECT COUNT(*) INTO habitaciones_disponibles
    FROM habitacion
    WHERE id_habitacion = NEW.id_habitacion
        AND NEW.fecha_inicio <= fecha_fin
        AND NEW.fecha_fin >= fecha_inicio;

    IF habitaciones_disponibles > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No hay habitaciones disponibles para las fechas especificadas';
    END IF;
END;
//

DELIMITER ;

*/


/*DELIMITER $$
CREATE TRIGGER ValidarEmail
before insert on Cliente 
for each row 
begin 
-- Utilizo una expresion regular para validar el email.
if not new.email regexp('^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
	then signal sqlstate '45000' SET message_text = 'Email invalido';
end if; 
end;
$$ 
delimiter; */

/*DELIMITER $$
CREATE FUNCTION validar_contrasena(contrasena VARCHAR(255))
RETURNS BOOLEAN
BEGIN
  DECLARE valido BOOLEAN DEFAULT TRUE;
  
  IF CHAR_LENGTH(contrasena) < 8 THEN
    SET valido = FALSE;
  END IF;
  
  IF NOT (contrasena REGEXP '[[:digit:]]') THEN
    SET valido = FALSE;
  END IF;
  
  IF NOT (contrasena REGEXP '[[:upper:]]') THEN
    SET valido = FALSE;
  END IF;
  
  IF NOT (contrasena REGEXP '[[:lower:]]') THEN
    SET valido = FALSE;
  END IF;
  
  RETURN valido;
END $$
DELIMITER ;*/

/*DELIMITER $$
CREATE TRIGGER validar_contrasena_trigger BEFORE INSERT ON usuarios
FOR EACH ROW
BEGIN
  IF NOT validar_contrasena(NEW.contrasena) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'La contraseña debe tener al menos 8 caracteres, al menos un dígito, una letra mayúscula y una letra minúscula';
  END IF;
END $$
DELIMITER ;*/



/*DELIMITER //
CREATE TRIGGER findFreeRoom
AFTER UPDATE ON Room FOR EACH ROW
BEGIN
  IF NEW.available = TRUE THEN
   UPDATE Room SET busy = TRUE WHERE nRoom = NEW.nRoom;
END IF;
END;//

DELIMITER ;*/





Insert into RoomType values(null,'Habitación Individual','Habitación con cama individual y un baño privado.
Incluye TV y minibar','individual.jpg');

Insert into RoomType values(null,'Habitación Doble','Habitación con cama doble o dos camas individuales y un 
baño privado.Habitación diseñada para dos personas. Incluye servicios de TV y minibar.','doble.jpeg');

Insert into RoomType values(null,'Habitación Triple','Habitación diseñada para tres personas. Incluye tres camas
individuales o una cama doble y una cama individual con baño privado. Incluye servicios de TV y minibar.','triple.jpg');
 
Insert into RoomType values(null,'Habitación Familiar','Habitación diseñada para familiar, incluye una cama doble
y dos camas individuales o una cama doble y literas. Puedes añadir cunas etc. Incluye servicios de TV y minibar .','familiar.jpeg');

Insert into RoomType values(null,'Habitación Con Balcon','Habitación con un balcón privado con vistas paronamicas a la ciudad
Incluye una cama doble o dos camas individuales con baño privado. Incluye servicios de TV y minibar.','ConBalcon.jpeg');

Insert into RoomType values(null,'Suite Presidencial','Habitación de lujo que ofrece una amplia sala de estar, un dormitorio 
principal con cama king-size, baño privado con bañera de hidromasaje o jacuzzi. Incuye terraza privada con vistas panoramicas, 
minibar, TV pantalla plana , equipo de sonido y servicio de mayordomo.','Presidencial.jpeg');

Insert into RoomType values(null,'Suite De Lujo','Habitación de lujo con vistas hacia la ciudad, amplia sala de estar, un dormitorio
principal con cama king-size con un baño privado con bañera de hidromasaje o jacuzzi. Incluye TV de pantalla plana, equipo de sonido
y servicio de mayordomo.','DeLujo.jpeg');

Insert into RoomType values(null,'Suite Penthouse','Suite de lujo ubicada en la planta superior del edificio del hotel, con vistas paronamicas
en la ciudad, ampliar sala de estar, un dormitorio principal con cama king-size con un baño privado con bañera de hidromasaje o con jacuzzi.
Incluye minibar, TV, equipo de sonido. Y servicio de mayordomo.','Penthouse.jpeg');

Insert into RoomType values(null,'Habitacion Prueba','Suite de lujo ubicada en la planta superior del edificio del hotel, con vistas paronamicas
en la ciudad, ampliar sala de estar, un dormitorio principal con cama king-size con un baño privado con bañera de hidromasaje o con jacuzzi.
Incluye minibar, TV, equipo de sonido. Y servicio de mayordomo.','Penthouse.jpeg');

insert into Rate values(null,1,1,15);
insert into Rate values(null,2,1,30);
insert into Rate values(null,3,1,40);
insert into Rate values(null,4,1,50);
insert into Rate values(null,5,1,35);
insert into Rate values(null,1,2,30);
insert into Rate values(null,2,2,60);
insert into Rate values(null,3,2,80);
insert into Rate values(null,4,2,110);
insert into Rate values(null,5,2,70);

