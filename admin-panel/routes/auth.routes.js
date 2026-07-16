const express = require('express');
const router = express.Router();

router.get('/login', (req, res) => {
  res.render('login', { layout: false, error: null });
});

router.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (username === process.env.ADMIN_USERNAME && password === process.env.ADMIN_PASSWORD) {
    req.session.isAdmin = true;
    req.session.username = username;
    return res.redirect('/');
  }
  res.render('login', { layout: false, error: 'Invalid credentials' });
});

router.post('/logout', (req, res) => {
  req.session.destroy(() => res.redirect('/login'));
});

module.exports = router;
