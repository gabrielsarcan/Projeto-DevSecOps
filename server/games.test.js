const { GameCollection } = require('./games.js');

describe('GameCollection', () => {
  let collection;

  beforeEach(() => {
    collection = new GameCollection();
  });

  test('should create a new game successfully', () => {
    const success = collection.createGame('game1');
    expect(success).toBe(true);
    expect(collection.getGame('game1')).toBeDefined();
  });

  test('should NOT allow creating a game with an ID that already exists', () => {
    collection.createGame('game1');
    // Esta chamada deveria retornar falso, pois o jogo já existe.
    // O bug atual do `games.js` fará retornar verdadeiro, falhando o teste.
    const success = collection.createGame('game1');
    expect(success).toBe(false);
  });

  test('should remove a game successfully', () => {
    collection.createGame('game1');
    const removed = collection.removeGame('game1');
    expect(removed).toBe(true);
    expect(collection.getGame('game1')).toBeUndefined();
  });

  test('should return false when removing a non-existent game', () => {
    const removed = collection.removeGame('non-existent');
    expect(removed).toBe(false);
  });
});
