const express = require('express');
const path = require('path');
const compression = require('compression');
const app = express();
const PORT = process.env.PORT || 3000;
const isDev = process.env.NODE_ENV !== 'production';

app.use(compression());

if (isDev) {
    app.use((req, res, next) => {
        res.set('Cache-Control', 'no-cache, no-store, must-revalidate');
        res.set('Pragma', 'no-cache');
        res.set('Expires', '0');
        next();
    });
}

app.use(express.static(path.join(__dirname, 'public'), {
    maxAge: isDev ? 0 : '1y',
    etag: !isDev
}));

app.get('/download', (req, res) => {
    const dmgPath = path.join(__dirname, '..', 'build', 'Gouttelette-1.0.0.dmg');
    res.download(dmgPath);
});

app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
    console.log(`Gouttelette site running on http://localhost:${PORT}`);
});
