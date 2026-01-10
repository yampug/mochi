class Calculator {
  constructor() {
    this.result = 0;
  }

  add(n) {
    this.result += n;
    return this;
  }

  multiply(n) {
    this.result *= n;
    return this;
  }

  getResult() {
    return this.result;
  }
}

const calc = new Calculator();
calc.add(5).multiply(3).add(2).getResult();
