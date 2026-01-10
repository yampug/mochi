const numbers = [1, 2, 3, 4, 5];

const sum = numbers.reduce((acc, n) => acc + n, 0);
const doubled = numbers.map(n => n * 2);
const evens = numbers.filter(n => n % 2 === 0);

const result = {
  sum: sum,
  doubled: doubled,
  evens: evens,
  length: numbers.length
};

result;
