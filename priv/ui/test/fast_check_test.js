const fc = require('fast-check');

// Code under test
const contains = (text, pattern) => text.indexOf(pattern) >= 0;

// Properties
describe('properties', () => {
  // string text always contains itself
  it('should always contain itself', () => {
    fc.assert(fc.property(fc.string(), text => contains(text, text)));
  });
  // string a + b + c always contains b, whatever the values of a, b and c
  it('should always contain its substrings', () => {
    fc.assert(fc.property(fc.string(), fc.string(), fc.string(), (a,b,c) => {
      // Alternatively: no return statement and direct usage of expect or assert
      return contains(a+b+c, b);
    }));
  });
});
