require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

const app = express();

// Configurazione API:
// - CORS per consentire chiamate dal frontend
// - JSON parser per leggere il body delle richieste
// Middleware
app.use(cors());
app.use(express.json());

// Pool di connessioni al database
const pool = mysql.createPool({
  host: process.env.DATABASE_HOST,
  port: process.env.DATABASE_PORT,
  user: process.env.DATABASE_USER,
  password: process.env.DATABASE_PASSWORD,
  database: process.env.DATABASE_NAME,
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

// Nota: ogni endpoint apre una connessione dal pool e la rilascia sempre nel finally.
// In questo modo si evitano connessioni "bloccate" quando ci sono errori.
// Endpoint di registrazione
app.post('/api/register', async (req, res) => {
  try {
    const { userId, email, password } = req.body;

    if (!userId || !email || !password) {
      return res.status(400).json({ message: 'Compila tutti i campi' });
    }

    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.execute(
        'SELECT mail FROM user WHERE mail = ?',
        [email]
      );
      if (rows.length > 0) {
        return res.status(400).json({ message: 'Email gia registrata' });
      }

      const [userIdRows] = await conn.execute(
        'SELECT userId FROM user WHERE userId = ?',
        [userId]
      );
      if (userIdRows.length > 0) {
        return res.status(400).json({ message: 'Nome utente gia in uso' });
      }

      const hashedPassword = await bcrypt.hash(password, 10);

      // Salva password hashata (mai in chiaro) per motivi di sicurezza.
      await conn.execute(
        'INSERT INTO user (userId, mail, password) VALUES (?, ?, ?)',
        [userId, email, hashedPassword]
      );

      return res.status(201).json({
        message: 'Utente registrato con successo',
        user: { userId, email },
      });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore registrazione:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

// Endpoint di login
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'Inserisci email e password' });
    }

    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.execute(
        'SELECT * FROM user WHERE mail = ?',
        [email]
      );
      if (rows.length === 0) {
        return res.status(400).json({ message: 'Email o password non validi' });
      }

      const user = rows[0];

      // Confronta la password inserita con l'hash salvato nel DB.
      const passwordMatch = await bcrypt.compare(password, user.password);
      if (!passwordMatch) {
        return res.status(400).json({ message: 'Email o password non validi' });
      }

      return res.json({
        message: 'Login riuscito',
        user: {
          nome: user.userId,
          email: user.mail,
        },
      });
      console.log('Utente loggato:', user.userId, '(', user.mail, ')');
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore login:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

// Endpoint creazione categoria (catalogo)
app.post('/api/categorie', async (req, res) => {
  try {
    const { nome } = req.body;

    if (!nome) {
      return res.status(400).json({ message: 'Inserisci il nome della categoria' });
    }

    const conn = await pool.getConnection();
    try {
      const [result] = await conn.execute(
        'INSERT INTO categorie (nome) VALUES (?)',
        [nome.trim()]
      );

      return res.status(201).json({
        message: 'Categoria salvata con successo',
        id: result.insertId,
      });
    } finally {
      conn.release();
    }
  } catch (error) {
    if (error && error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ message: 'Categoria gia esistente' });
    }
     console.error('Errore creazione categoria:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

// Endpoint lettura categorie per combobox
app.get('/api/categorie', async (_req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.execute(
        'SELECT idcategoria, nome FROM categorie ORDER BY nome ASC'
      );
      return res.json({ categorie: rows });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore lettura categorie:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

// Endpoint creazione spesa
app.post('/api/spese', async (req, res) => {
  try {
    const { nome, giorno, prezzo, idcategoria, categoria } = req.body;

    if (!nome || !giorno || prezzo === undefined || prezzo === null || (!idcategoria && !categoria)) {
      return res.status(400).json({ message: 'Compila tutti i campi della spesa' });
    }

    const prezzoInt = Number(prezzo);
    if (!Number.isInteger(prezzoInt) || prezzoInt < 0) {
      return res.status(400).json({ message: 'Il prezzo deve essere un intero positivo' });
    }

    const giornoDate = new Date(giorno);
    if (Number.isNaN(giornoDate.getTime())) {
      return res.status(400).json({ message: 'Data non valida' });
    }

    const conn = await pool.getConnection();
    try {
      // Transazione: o salviamo tutta la spesa, o annulliamo tutto in caso di errore.
      await conn.beginTransaction();

      let categoriaId = Number(idcategoria);
      if (!Number.isInteger(categoriaId) || categoriaId <= 0) {
        // Fallback: se il frontend invia il nome categoria, recuperiamo il relativo id.
        const [categoriaRows] = await conn.execute(
          'SELECT idcategoria FROM categorie WHERE nome = ? LIMIT 1',
          [categoria]
        );
        if (categoriaRows.length === 0) {
          await conn.rollback();
          return res.status(400).json({ message: 'Categoria non trovata. Inseriscila prima nella pagina categorie.' });
        }
        categoriaId = Number(categoriaRows[0].idcategoria);
      }

      const [result] = await conn.execute(
        'INSERT INTO spese (nome, giorno, prezzo, idcategoria) VALUES (?, ?, ?, ?)',
        [nome, giorno, prezzoInt, categoriaId]
      );

      const spesaId = result.insertId;

      await conn.commit();
      return res.status(201).json({
        message: 'Spesa salvata con successo',
        idspese: spesaId,
      });
    } catch (error) {
      await conn.rollback();
      throw error;
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore creazione spesa:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

// Endpoint ultime spese per Home
app.get('/api/spese', async (req, res) => {
  try {
    const requestedLimit = Number(req.query.limit);
    // Limite protetto per evitare richieste troppo pesanti.
    const limit = Number.isInteger(requestedLimit) && requestedLimit > 0
      ? Math.min(requestedLimit, 100)
      : 10;

    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query(
        `SELECT s.idspese, s.nome, s.giorno, s.prezzo, s.idcategoria, c.nome AS categoria_nome
         FROM spese s
         LEFT JOIN categorie c ON c.idcategoria = s.idcategoria
         ORDER BY s.giorno DESC, s.idspese DESC
         LIMIT ${limit}`
      );

      return res.json({ spese: rows });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore lettura spese:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

// Health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'OK', message: 'Server e online' });
});

// Avvia il server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server in ascolto su http://localhost:${PORT}`);
});

// Chiude il pool alla terminazione
process.on('SIGINT', async () => {
  await pool.end();
  console.log('\nConnessione al database chiusa');
  process.exit(0);
});
