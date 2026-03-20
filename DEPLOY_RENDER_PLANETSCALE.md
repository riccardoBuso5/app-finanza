# Deploy Backend su Render (fix errore ENOENT package.json)

Errore visto nel log:

```text
npm ERR! enoent Could not read package.json: /opt/render/project/src/package.json
```

Causa: Render sta eseguendo build dalla root del repository, ma il backend Node e in `backend/`.

## Soluzione applicata nel repository

E stato aggiunto `render.yaml` in root con:

- `rootDir: backend`
- `buildCommand: npm install`
- `startCommand: npm start`
- `healthCheckPath: /api/health`

## Se il servizio Render esiste gia

Controlla in Settings del servizio:

1. Root Directory: `backend`
2. Build Command: `npm install`
3. Start Command: `npm start`

Poi fai un nuovo deploy.

## Variabili ambiente richieste

Nel servizio Render imposta:

```env
DATABASE_HOST=dbspese-dbspese.g.aivencloud.com
DATABASE_PORT=28020
DATABASE_USER=avnadmin
DATABASE_PASSWORD=***
DATABASE_NAME=defaultdb
DATABASE_SSL=true
DATABASE_SSL_REJECT_UNAUTHORIZED=true
NODE_ENV=production
```

`PORT` non va impostata manualmente su Render: viene fornita dalla piattaforma e il server la legge con `process.env.PORT`.
