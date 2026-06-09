const fc = require('fast-check');
const { GameCollection } = require('./games.js');

describe('GameCollection Fuzzing', () => {
  test('createGame should not throw or crash when receiving random inputs', () => {
    fc.assert(
      fc.property(
        fc.anything(), // Gera qualquer tipo de dado (nulo, undefined, arrays, booleanos, objetos exóticos)
        (randomInput) => {
          const collection = new GameCollection();
          // Independente da entrada, o método não deve causar Unhandled Exceptions
          const result = collection.createGame(randomInput);
          expect(typeof result).toBe('boolean');
        }
      )
    );
  });

  test('getGame should not throw when queried with random inputs', () => {
    fc.assert(
      fc.property(
        fc.anything(),
        (randomInput) => {
          const collection = new GameCollection();
          const result = collection.getGame(randomInput);
          expect(result === undefined || typeof result === 'object').toBe(true);
        }
      )
    );
  });
  
  test('removeGame should not throw when removing random inputs', () => {
    fc.assert(
      fc.property(
        fc.anything(),
        (randomInput) => {
          const collection = new GameCollection();
          const result = collection.removeGame(randomInput);
          expect(typeof result).toBe('boolean');
        }
      )
    );
  });
});
