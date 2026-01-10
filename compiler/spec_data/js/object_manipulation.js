const person = {
  name: "Alice",
  age: 30,
  city: "San Francisco"
};

const keys = Object.keys(person);
const values = Object.values(person);
const entries = Object.entries(person);

const updated = { ...person, age: 31, country: "USA" };

JSON.stringify(updated);
