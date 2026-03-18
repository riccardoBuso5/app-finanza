# App Finanza

Applicazione per la gestione delle spese personali, pensata per tenere traccia in modo semplice di uscite e categorie.

Il progetto e diviso in due parti:
- un'app Flutter (interfaccia utente)
- un backend Node.js/Express (API + persistenza su MySQL)

## A cosa serve

App Finanza nasce per risolvere un problema pratico: annotare velocemente le spese quotidiane e avere una vista ordinata delle ultime uscite.

In particolare permette di:
- creare un account ed effettuare login
- definire categorie personalizzate (es. Spesa, Trasporti, Tempo libero)
- registrare una spesa con nome, data, prezzo e categoria
- visualizzare le ultime spese salvate

Obiettivo: avere un diario economico minimale, chiaro e facilmente estendibile.

## Funzionalita principali

- Registrazione utente con controllo email e username univoci
- Login con verifica password hashata
- Gestione catalogo categorie
- Inserimento spese con validazioni lato backend
- Lettura lista spese ordinate per data decrescente
- Endpoint health check per verificare che il server sia operativo

## Architettura

### Frontend (Flutter)

Il frontend si occupa di:
- autenticazione utente
- form di inserimento categorie e spese
- visualizzazione dati nella home
- gestione tema (chiaro/scuro)

La comunicazione avviene via HTTP JSON tramite il servizio in [flutter_application_1/lib/db_service.dart](flutter_application_1/lib/db_service.dart).

### Backend (Node.js + Express)

Il backend espone API REST e gestisce:
- validazione input
- accesso al database MySQL
- hashing password con `bcryptjs`
- transazioni nelle operazioni critiche (es. inserimento spesa)

Entry point: [backend/server.js](backend/server.js).

### Database (MySQL)

Schema logico minimo:
- `user`: credenziali utente
- `categorie`: elenco categorie personalizzate
- `spese`: movimenti di spesa associati a una categoria

## Stack tecnologico

- Flutter / Dart (SDK `^3.11.1`)
- Node.js + Express
- MySQL
- `mysql2/promise`, `bcryptjs`, `dotenv`, `cors`

## Struttura progetto

```text
app-finanza/
  backend/
    package.json
    server.js
    .env.example
  flutter_application_1/
    lib/
    pubspec.yaml
```

## Flusso utente (end-to-end)

1. L'utente crea account dalla schermata di registrazione.
2. Effettua login con `userId` e password.
3. Inserisce una o piu categorie personali.
4. Registra le spese selezionando categoria e data.
5. Nella home vede le ultime spese salvate.

## Setup rapido

### Prerequisiti

- Flutter SDK installato
- Node.js 18+
- MySQL 8+ (o compatibile)

### 1) Backend

```bash
cd backend
npm install
```

Crea `.env` copiando [backend/.env.example](backend/.env.example):

```env
DATABASE_HOST=localhost
DATABASE_PORT=3306
DATABASE_USER=root
DATABASE_PASSWORD=password
DATABASE_NAME=finanzadb
PORT=3002
```

Nota: in [flutter_application_1/lib/db_service.dart](flutter_application_1/lib/db_service.dart) l'API base e `http://localhost:3002/api`, quindi `PORT` deve essere `3002` (oppure aggiorna il base URL lato Flutter).

### 2) Database

Esegui questo script SQL:

```sql
CREATE DATABASE IF NOT EXISTS finanzadb;
USE finanzadb;

CREATE TABLE IF NOT EXISTS user (
  userId VARCHAR(100) PRIMARY KEY,
  mail VARCHAR(255) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS categorie (
  idcategoria INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS spese (
  idspese INT AUTO_INCREMENT PRIMARY KEY,
  nome VARCHAR(255) NOT NULL,
  giorno DATE NOT NULL,
  prezzo INT NOT NULL,
  idcategoria INT NOT NULL,
  CONSTRAINT fk_spese_categoria
    FOREIGN KEY (idcategoria) REFERENCES categorie(idcategoria)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);
```

### 3) Avvio servizi

Avvia backend:

```bash
cd backend
npm run dev
```

Avvia frontend:

```bash
cd flutter_application_1
flutter pub get
flutter run -d chrome
```

## API disponibili

- `POST /api/register`
- `POST /api/login`
- `POST /api/categorie`
- `GET /api/categorie`
- `POST /api/spese`
- `GET /api/spese?limit=10`
- `GET /api/health`

## Sicurezza e validazioni

- Password mai salvate in chiaro: vengono hashate con `bcryptjs`.
- Controlli backend su campi obbligatori e formato dati (es. data e prezzo).
- Pool di connessioni MySQL con rilascio sicuro delle connessioni.

## Troubleshooting

- `npm run dev` fallisce:
  verifica `npm install`, file `.env` e credenziali DB.
- Flutter non raggiunge il backend:
  verifica che porta backend e `_baseUrl` coincidano.
- Errori login/registrazione:
  controlla che le tabelle esistano e che il DB sia raggiungibile.
- CORS o rete su browser:
  assicurati che il backend sia avviato prima del frontend.

## Possibili evoluzioni

- filtro spese per periodo/categoria
- grafici mensili e report
- budget mensile con alert superamento
- gestione multiutente completa con token/JWT
