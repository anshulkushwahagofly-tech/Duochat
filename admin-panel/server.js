require('dotenv').config();
const express = require('express');
const session = require('express-session');
const MongoStore = require('connect-mongo');
const mongoose = require('mongoose');
const expressLayouts = require('express-ejs-layouts');
const path = require('path');

const dashboardRoutes = require('./routes/dashboard.routes');
const authRoutes = require('./routes/auth.routes');
const { requireLogin } = require('./middleware/requireLogin');

const app = express();
const PORT = process.env.PORT || 4000;

mongoose.connect(process.env.MONGO_URI).then(() => console.log('[Admin] MongoDB connected'));

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));
app.use(expressLayouts);
app.set('layout', 'layout');
app.use(express.static(path.join(__dirname, 'public')));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());

app.use(
  session({
    secret: process.env.SESSION_SECRET,
    resave: false,
    saveUninitialized: false,
    store: MongoStore.create({ mongoUrl: process.env.MONGO_URI }),
    cookie: { maxAge: 1000 * 60 * 60 * 8 }, // 8h
  })
);

app.use('/', authRoutes);
app.use('/', requireLogin, dashboardRoutes);

app.listen(PORT, () => console.log(`🛠  DuoChat admin panel running on http://localhost:${PORT}`));
