let conditionalElements = this.shadow.querySelectorAll('mochi-if');
for (let condEl of conditionalElements) {
    let condId = parseInt(condEl.getAttribute('data-cond-id'));
    let result = this.evaluateCondition(condId);
    condEl.style.display = result ? '' : 'none';
}
