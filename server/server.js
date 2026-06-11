var express = require('express'),
    app = express(),
    server = require('http').createServer(app),
    socketIo = require('socket.io')(server),
    GameCollection = require('./games.js').GameCollection,
    games = new GameCollection(),
    { Client } = require('pg');

const dbClient = new Client({
  connectionString: process.env.DATABASE_URL || 'postgres://postgres:postgres@localhost:5432/mkjs_db'
});

dbClient.connect()
  .then(() => {
    console.log('Connected to PostgreSQL');
    return dbClient.query(`
      CREATE TABLE IF NOT EXISTS games_history (
        id SERIAL PRIMARY KEY,
        game_name VARCHAR(255) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
  })
  .then(() => console.log('games_history table ready'))
  .catch(err => console.error('PostgreSQL connection error:', err));

app.use(express.static(__dirname + '/../game'));

server.listen(55555);

var Responses = {
    SUCCESS: 0,
    GAME_EXISTS: 1,
    GAME_NOT_EXISTS: 2,
    GAME_FULL: 3
  },
  Requests = {
    CREATE_GAME: 'create-game',
    JOIN_GAME: 'join-game'
  };

socketIo.sockets.on('connection', function (socket) {
  socket.on(Requests.CREATE_GAME, function (gameName) {
    if (games.createGame(gameName)) {
      games.getGame(gameName).addPlayer(socket);
      
      // Segurança: Usando queries parametrizadas para evitar SQL Injection
      dbClient.query(
        'INSERT INTO games_history(game_name) VALUES($1)',
        [gameName]
      ).catch(err => console.error('Error inserting game history:', err));

      socket.emit('response', Responses.SUCCESS);
    } else {
      socket.emit('response', Responses.GAME_EXISTS);
    }
  });
  socket.on(Requests.JOIN_GAME, function (gameName) {
    var game = games.getGame(gameName);
    if (!game) {
      socket.emit('response', Responses.GAME_NOT_EXISTS);
    } else {
      if (game.addPlayer(socket)) {
        socket.emit('response', Responses.SUCCESS);
      } else {
        socket.emit('response', Responses.GAME_FULL);
      }
    }
  });
});
