-- MySQL dump 10.13  Distrib 8.0.36, for Win64 (x86_64)
--
-- Host: 127.0.0.1    Database: dbspese
-- ------------------------------------------------------
-- Server version	8.4.7

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `spese`
--

DROP TABLE IF EXISTS `spese`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `spese` (
  `idspese` int NOT NULL AUTO_INCREMENT,
  `nome` varchar(45) NOT NULL,
  `giorno` date NOT NULL,
  `prezzo` int NOT NULL,
  `idcategoria` int NOT NULL,
  PRIMARY KEY (`idspese`),
  KEY `fk_spese_categorie_idx` (`idcategoria`),
  CONSTRAINT `fk_spese_categorie` FOREIGN KEY (`idcategoria`) REFERENCES `categorie` (`idcategoria`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=89 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `spese`
--

LOCK TABLES `spese` WRITE;
/*!40000 ALTER TABLE `spese` DISABLE KEYS */;
INSERT INTO `spese` VALUES (6,'iliad','2025-10-02',10,3),(7,'now','2025-10-03',5,8),(8,'vodafone','2025-10-06',7,3),(9,'palestra','2025-10-08',30,10),(10,'acqua','2025-10-09',17,1),(11,'corrente','2025-10-22',17,1),(12,'uscita','2025-10-28',10,6),(13,'spesa','2025-10-28',34,7),(14,'tasse ottobre','2025-10-15',580,11),(15,'vestiti','2025-10-16',80,12),(16,'37','2025-10-09',37,7),(17,'uscita','2025-10-03',7,6),(18,'barcolana','2025-10-22',70,6),(19,'spesa','2025-10-13',40,7),(20,'uscita','2025-10-04',21,6),(21,'sushi','2025-10-31',38,6),(22,'breadboard','2025-10-22',10,13),(23,'tnt','2025-10-31',30,6),(24,'iliad','2025-11-01',10,3),(25,'now','2025-11-02',5,8),(26,'vodafone','2025-11-03',7,3),(27,'acqua','2025-11-06',47,1),(28,'birretta','2025-11-04',17,6),(29,'spesa','2025-11-04',32,7),(30,'spesa','2025-11-13',45,7),(31,'birretta','2025-11-12',6,6),(32,'pancetta + birra','2025-11-12',10,6),(33,'ram pc','2025-11-19',33,13),(34,'spesa','2025-11-14',38,7),(35,'birretta','2025-11-17',20,6),(36,'sushi','2025-11-19',33,6),(37,'spesa','2025-11-19',23,7),(38,'pigiama','2025-12-24',30,13),(39,'attacchi gopro','2025-11-20',10,13),(40,'roomba','2025-11-19',6,13),(41,'viti giradischi','2025-11-20',10,13),(42,'birretta','2025-11-29',20,6),(43,'aberitivo','2025-11-30',10,6),(44,'benzina','2025-11-30',15,9),(45,'iliad','2025-12-01',10,3),(46,'now','2025-12-03',5,8),(47,'assicurazione','2025-12-03',25,9),(48,'vodafone','2025-12-04',7,3),(49,'palestra','2025-12-10',30,10),(50,'casette','2025-12-06',40,6),(51,'spesa','2025-12-01',40,7),(52,'spesa','2025-12-09',40,7),(53,'regalo sara','2025-12-10',30,13),(54,'regalo mamma e papa','2025-12-17',30,13),(55,'birra','2025-12-10',6,6),(56,'treno','2025-12-11',23,11),(57,'verona','2025-12-16',13,6),(58,'copri divano','2025-12-16',5,13),(59,'birretta','2025-12-22',20,6),(60,'gioco','2025-12-22',30,13),(61,'rinnovo contratto','2025-12-22',60,11),(62,'spese varie','2025-12-31',120,14),(63,'spesa','2026-01-01',48,7),(64,'farmacia','2026-01-01',30,16),(65,'bollo','2026-01-02',30,9),(66,'spesa','2026-01-07',20,7),(67,'filtro passa basso','2026-01-08',8,13),(68,'spesa','2026-01-21',21,7),(69,'drink','2026-01-20',14,6),(70,'orologio lorenzo','2026-01-28',120,12),(71,'bilancia','2026-01-14',20,10),(72,'tasse feb','2026-01-02',670,11),(73,'benzina','2026-02-03',20,9),(74,'alcol + mandarini','2026-02-10',50,13),(75,'spesa','2026-02-11',31,7),(76,'spesa','2026-02-18',32,7),(77,'birretta','2026-02-17',17,6),(78,'spesa','2026-02-17',46,7),(79,'birretta','2026-02-16',15,6),(80,'spesa','2026-02-23',25,7),(81,'bobine','2026-02-24',43,11),(82,'birretta','2026-02-18',14,6),(83,'montagna','2026-02-21',20,10),(84,'palestra','2026-03-01',115,10),(85,'spesa','2026-03-03',33,7),(86,'birretta','2026-03-06',22,6),(87,'telefono','2026-03-09',171,3);
/*!40000 ALTER TABLE `spese` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-03-20  0:15:52
