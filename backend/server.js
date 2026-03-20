require('dotenv').config();
const express = require('express');
const cors = require('cors');
const mysql = require('mysql2/promise');
const bcrypt = require('bcryptjs');

const app = express();

const dbSslEnabled = String(process.env.DATABASE_SSL || '').toLowerCase() === 'true';
const dbSslRejectUnauthorized = String(process.env.DATABASE_SSL_REJECT_UNAUTHORIZED || 'true').toLowerCase() === 'true';
const dbSslCaBase64 = process.env.DATABASE_SSL_CA_BASE64;
const dbSslCaPem = process.env.DATABASE_SSL_CA;

function buildDbSslConfig() {
  if (!dbSslEnabled) return undefined;

  const sslConfig = {
    rejectUnauthorized: dbSslRejectUnauthorized,
  };

  if (dbSslCaBase64) {
    try {
      const raw = String(dbSslCaBase64).trim();

      if (raw.includes('BEGIN CERTIFICATE')) {
        // Supporta anche un PEM completo passato dentro DATABASE_SSL_CA_BASE64.
        sslConfig.ca = raw.includes('\\n') ? raw.replace(/\\n/g, '\n') : raw;
      } else {
        const decodedUtf8 = Buffer.from(raw, 'base64').toString('utf8');
        if (decodedUtf8.includes('BEGIN CERTIFICATE')) {
          // Caso: PEM codificato in base64.
          sslConfig.ca = decodedUtf8;
        } else {
          // Caso: body base64 "nudo" (MIIE...) senza header/footer PEM.
          const normalizedBody = raw.replace(/\s+/g, '');
          const wrapped = normalizedBody.match(/.{1,64}/g) || [normalizedBody];
          sslConfig.ca = [
            '-----BEGIN CERTIFICATE-----',
            ...wrapped,
            '-----END CERTIFICATE-----',
            '',
          ].join('\n');
        }
      }
    } catch (error) {
      console.error('DATABASE_SSL_CA_BASE64 non valido, impossibile decodificare il certificato CA:', error.message);
    }
  } else if (dbSslCaPem) {
    // Supporta certificato passato come singola riga con \n escapati.
    sslConfig.ca = dbSslCaPem.includes('\\n') ? dbSslCaPem.replace(/\\n/g, '\n') : dbSslCaPem;
  }

  return sslConfig;
}

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
  ssl: buildDbSslConfig(),
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0,
});

function extractUserId(req) {
  const headerValue = req.headers['x-user-id'];
  const raw = headerValue ?? req.body?.userId ?? req.query?.userId;
  const userId = typeof raw === 'string' ? raw.trim() : '';
  return userId;
}

function requireUserId(req, res) {
  const userId = extractUserId(req);
  if (!userId) {
    res.status(400).json({ message: 'Utente non identificato (userId mancante)' });
    return null;
  }
  return userId;
}

async function bootstrapSchema() {
  const conn = await pool.getConnection();
  try {
    await conn.execute('ALTER TABLE categorie ADD COLUMN IF NOT EXISTS userId VARCHAR(100) NULL');
    await conn.execute('ALTER TABLE spese ADD COLUMN IF NOT EXISTS userId VARCHAR(100) NULL');
    await conn.execute('ALTER TABLE entrate ADD COLUMN IF NOT EXISTS userId VARCHAR(100) NULL');

    await conn.execute('CREATE INDEX IF NOT EXISTS idx_categorie_userId ON categorie (userId)');
    await conn.execute('CREATE INDEX IF NOT EXISTS idx_spese_userId ON spese (userId)');
    await conn.execute('CREATE INDEX IF NOT EXISTS idx_entrate_userId ON entrate (userId)');
  } finally {
    conn.release();
  }
}

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
          userId: user.userId,
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
    const userId = requireUserId(req, res);
    if (!userId) return;

    if (!nome) {
      return res.status(400).json({ message: 'Inserisci il nome della categoria' });
    }

    const conn = await pool.getConnection();
    try {
      const [existingRows] = await conn.execute(
        'SELECT idcategoria FROM categorie WHERE userId = ? AND nome = ? LIMIT 1',
        [userId, nome.trim()]
      );
      if (existingRows.length > 0) {
        return res.status(400).json({ message: 'Categoria gia esistente' });
      }

      const [result] = await conn.execute(
        'INSERT INTO categorie (nome, userId) VALUES (?, ?)',
        [nome.trim(), userId]
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
app.get('/api/categorie', async (req, res) => {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;

    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.execute(
        'SELECT idcategoria, nome FROM categorie WHERE userId = ? ORDER BY nome ASC',
        [userId]
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

app.put('/api/categorie/:idcategoria', async (req, res) => {
  try {
    const idcategoria = Number(req.params.idcategoria);
    const { nome } = req.body;
    const userId = requireUserId(req, res);
    if (!userId) return;

    if (!Number.isInteger(idcategoria) || idcategoria <= 0) {
      return res.status(400).json({ message: 'ID categoria non valido' });
    }

    if (!nome || String(nome).trim().isEmpty) {
      return res.status(400).json({ message: 'Inserisci il nome della categoria' });
    }

    const conn = await pool.getConnection();
    try {
      const [result] = await conn.execute(
        'UPDATE categorie SET nome = ? WHERE idcategoria = ? AND userId = ? LIMIT 1',
        [String(nome).trim(), idcategoria, userId]
      );

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Categoria non trovata' });
      }

      return res.json({ message: 'Categoria aggiornata con successo' });
    } finally {
      conn.release();
    }
  } catch (error) {
    if (error && error.code === 'ER_DUP_ENTRY') {
      return res.status(400).json({ message: 'Categoria gia esistente' });
    }
    console.error('Errore aggiornamento categoria:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

app.delete('/api/categorie/:idcategoria', async (req, res) => {
  try {
    const idcategoria = Number(req.params.idcategoria);
    const userId = requireUserId(req, res);
    if (!userId) return;

    if (!Number.isInteger(idcategoria) || idcategoria <= 0) {
      return res.status(400).json({ message: 'ID categoria non valido' });
    }

    const conn = await pool.getConnection();
    try {
      const [result] = await conn.execute(
        'DELETE FROM categorie WHERE idcategoria = ? AND userId = ? LIMIT 1',
        [idcategoria, userId]
      );

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Categoria non trovata' });
      }

      return res.json({ message: 'Categoria eliminata con successo' });
    } finally {
      conn.release();
    }
  } catch (error) {
    if (error && (error.code === 'ER_ROW_IS_REFERENCED_2' || error.code === 'ER_ROW_IS_REFERENCED')) {
      return res.status(409).json({ message: 'Categoria usata in una o piu spese, impossibile eliminarla' });
    }
    console.error('Errore cancellazione categoria:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

// Endpoint creazione spesa
app.post('/api/spese', async (req, res) => {
  try {
    const { nome, giorno, prezzo, idcategoria, categoria } = req.body;
    const userId = requireUserId(req, res);
    if (!userId) return;

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
          'SELECT idcategoria FROM categorie WHERE nome = ? AND userId = ? LIMIT 1',
          [categoria, userId]
        );
        if (categoriaRows.length === 0) {
          await conn.rollback();
          return res.status(400).json({ message: 'Categoria non trovata. Inseriscila prima nella pagina categorie.' });
        }
        categoriaId = Number(categoriaRows[0].idcategoria);
      }

      const [result] = await conn.execute(
        'INSERT INTO spese (nome, giorno, prezzo, idcategoria, userId) VALUES (?, ?, ?, ?, ?)',
        [nome, giorno, prezzoInt, categoriaId, userId]
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

app.put('/api/spese/:idspese', async (req, res) => {
  try {
    const idspese = Number(req.params.idspese);
    const { nome, giorno, prezzo, idcategoria } = req.body;
    const userId = requireUserId(req, res);
    if (!userId) return;

    if (!Number.isInteger(idspese) || idspese <= 0) {
      return res.status(400).json({ message: 'ID spesa non valido' });
    }

    if (!nome || !giorno || prezzo === undefined || prezzo === null || !idcategoria) {
      return res.status(400).json({ message: 'Compila tutti i campi della spesa' });
    }

    const prezzoInt = Number(prezzo);
    if (!Number.isInteger(prezzoInt) || prezzoInt < 0) {
      return res.status(400).json({ message: 'Il prezzo deve essere un intero positivo' });
    }

    const giornoRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!giornoRegex.test(String(giorno))) {
      return res.status(400).json({ message: 'Data non valida' });
    }

    const categoriaId = Number(idcategoria);
    if (!Number.isInteger(categoriaId) || categoriaId <= 0) {
      return res.status(400).json({ message: 'Categoria non valida' });
    }

    const conn = await pool.getConnection();
    try {
      const [result] = await conn.execute(
        'UPDATE spese SET nome = ?, giorno = STR_TO_DATE(?, \'%Y-%m-%d\'), prezzo = ?, idcategoria = ? WHERE idspese = ? AND userId = ? LIMIT 1',
        [nome.trim(), String(giorno), prezzoInt, categoriaId, idspese, userId]
      );

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Spesa non trovata' });
      }

      return res.json({ message: 'Spesa aggiornata con successo' });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore aggiornamento spesa:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

// Endpoint creazione entrata
app.post('/api/entrate', async (req, res) => {
  try {
    const { nome, prezzo, data, giorno } = req.body;
    const userId = requireUserId(req, res);
    if (!userId) return;

    const dataValue = data ?? giorno;
    const now = new Date();
    const today = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    const normalizedDate = (typeof dataValue === 'string' && dataValue.trim().length > 0)
      ? dataValue.trim()
      : today;

    if (!nome || prezzo === undefined || prezzo === null) {
      return res.status(400).json({ message: 'Compila tutti i campi dell\'entrata' });
    }

    const prezzoInt = Number(prezzo);
    if (!Number.isInteger(prezzoInt) || prezzoInt < 0) {
      return res.status(400).json({ message: 'Il prezzo deve essere un intero positivo' });
    }

    const dateOnlyRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateOnlyRegex.test(normalizedDate)) {
      return res.status(400).json({ message: 'Data non valida' });
    }

    const conn = await pool.getConnection();
    try {
      
      const [result] = await conn.execute(
        'INSERT INTO entrate (nome, prezzo, data, userId) VALUES (?, ?, STR_TO_DATE(?, \'%Y-%m-%d\'), ?)',
        [nome.trim(), prezzoInt, normalizedDate, userId]
      );

      return res.status(201).json({
        message: 'Entrata salvata con successo',
        identrate: result.insertId,
        entrata: {
          identrate: result.insertId,
          nome: nome.trim(),
          prezzo: prezzoInt,
          data: normalizedDate,
        },
      });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore creazione entrata:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

app.put('/api/entrate/:identrate', async (req, res) => {
  try {
    const identrate = Number(req.params.identrate);
    const { nome, prezzo, data, giorno } = req.body;
    const userId = requireUserId(req, res);
    if (!userId) return;

    const dataValue = data ?? giorno;

    if (!Number.isInteger(identrate) || identrate <= 0) {
      return res.status(400).json({ message: 'ID entrata non valido' });
    }

    if (!nome || prezzo === undefined || prezzo === null || !dataValue) {
      return res.status(400).json({ message: 'Compila tutti i campi dell\'entrata' });
    }

    const prezzoInt = Number(prezzo);
    if (!Number.isInteger(prezzoInt) || prezzoInt < 0) {
      return res.status(400).json({ message: 'Il prezzo deve essere un intero positivo' });
    }

    const normalizedDate = String(dataValue).trim();
    const dateOnlyRegex = /^\d{4}-\d{2}-\d{2}$/;
    if (!dateOnlyRegex.test(normalizedDate)) {
      return res.status(400).json({ message: 'Data non valida' });
    }

    const conn = await pool.getConnection();
    try {
      const [result] = await conn.execute(
        'UPDATE entrate SET nome = ?, prezzo = ?, data = STR_TO_DATE(?, \'%Y-%m-%d\') WHERE identrate = ? AND userId = ? LIMIT 1',
        [nome.trim(), prezzoInt, normalizedDate, identrate, userId]
      );

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Entrata non trovata' });
      }

      return res.json({ message: 'Entrata aggiornata con successo' });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore aggiornamento entrata:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

// Endpoint ultime spese per Home
app.get('/api/spese', async (req, res) => {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;

    const requestedLimit = Number(req.query.limit);
    // Limite protetto per evitare richieste troppo pesanti.
    const limit = Number.isInteger(requestedLimit) && requestedLimit > 0
      ? Math.min(requestedLimit, 100)
      : 10;

    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query(
        `SELECT s.idspese, s.nome, DATE_FORMAT(s.giorno, '%Y-%m-%d') AS giorno, s.prezzo, s.idcategoria, c.nome AS categoria_nome
         FROM spese s
         LEFT JOIN categorie c ON c.idcategoria = s.idcategoria
         WHERE s.userId = ?
         ORDER BY s.giorno DESC, s.idspese DESC
         LIMIT ${limit}`,
        [userId]
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

app.get('/api/entrate', async (req, res) => {
  try {
    const userId = requireUserId(req, res);
    if (!userId) return;

    const requestedLimit = Number(req.query.limit);
    // Limite protetto per evitare richieste troppo pesanti.
    const limit = Number.isInteger(requestedLimit) && requestedLimit > 0
      ? Math.min(requestedLimit, 100)
      : 10;

    const conn = await pool.getConnection();
    try {
      const [rows] = await conn.query(
        `SELECT e.identrate, e.nome, e.prezzo, DATE_FORMAT(e.data, '%Y-%m-%d') AS data
         FROM entrate e
         WHERE e.userId = ?
         ORDER BY e.data DESC, e.identrate DESC
         LIMIT ${limit}`,
        [userId]
      );

      return res.json({
        message: 'Entrate caricate con successo',
        total: rows.length,
        entrate: rows,
      });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore lettura entrate:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

app.delete('/api/spese/:idspese', async (req, res) => {
  try {
    const idspese = Number(req.params.idspese);
    const userId = requireUserId(req, res);
    if (!userId) return;

    if (!Number.isInteger(idspese) || idspese <= 0) {
      return res.status(400).json({ message: 'ID spesa non valido' });
    }

    const conn = await pool.getConnection();
    try {
      const [result] = await conn.execute(
        'DELETE FROM spese WHERE idspese = ? AND userId = ? LIMIT 1',
        [idspese, userId]
      );

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Spesa non trovata' });
      }

      return res.json({ message: 'Spesa eliminata con successo' });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore cancellazione spesa:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

app.delete('/api/entrate/:identrate', async (req, res) => {
  try {
    const identrate = Number(req.params.identrate);
    const userId = requireUserId(req, res);
    if (!userId) return;

    if (!Number.isInteger(identrate) || identrate <= 0) {
      return res.status(400).json({ message: 'ID entrata non valido' });
    }

    const conn = await pool.getConnection();
    try {
      const [result] = await conn.execute(
        'DELETE FROM entrate WHERE identrate = ? AND userId = ? LIMIT 1',
        [identrate, userId]
      );

      if (result.affectedRows === 0) {
        return res.status(404).json({ message: 'Entrata non trovata' });
      }

      return res.json({ message: 'Entrata eliminata con successo' });
    } finally {
      conn.release();
    }
  } catch (error) {
    console.error('Errore cancellazione entrata:', error);
    return res.status(500).json({ message: 'Errore server: ' + error.message });
  }
});

// Health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'OK', message: 'Server e online' });
});

// Health check database: utile in produzione per distinguere errori app da errori DB/TLS.
app.get('/api/health/db', async (_req, res) => {
  try {
    const conn = await pool.getConnection();
    try {
      await conn.query('SELECT 1 AS ok');
      return res.json({ status: 'OK', message: 'Database raggiungibile' });
    } finally {
      conn.release();
    }
  } catch (error) {
    return res.status(500).json({
      status: 'ERROR',
      message: 'Database non raggiungibile',
      error: error.message,
      code: error.code || null,
    });
  }
});

// Avvia il server
const PORT = process.env.PORT || 3000;
async function startServer() {
  try {
    await bootstrapSchema();
    app.listen(PORT, () => {
      console.log(`Server in ascolto su http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Errore bootstrap schema:', error);
    process.exit(1);
  }
}

startServer();

// Chiude il pool alla terminazione
process.on('SIGINT', async () => {
  await pool.end();
  console.log('\nConnessione al database chiusa');
  process.exit(0);
});
