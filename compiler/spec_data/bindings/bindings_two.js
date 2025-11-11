let bindElements0 = this.shadow.querySelectorAll('[123]');
if (bindElements0) {
  for (let i = 0; i < bindElements0.length; i++) {
    const observer = new MutationObserver((mutationsList, observer) => {
      for (const mutation of mutationsList) {
        if (mutation.type === 'attributes') {
          let newValue = mutation.target.getAttribute(mutation.attributeName);
          this.attributeChangedCallback('abc', null, newValue);
        }
      }
    });
    observer.observe(bindElements0[i], {
      attributes: true,
      childList: false,
      subtree: false,
      characterData: false,
      attributeOldValue: false
    });
  }
}
let bindElements1 = this.shadow.querySelectorAll('[5678]');
if (bindElements1) {
  for (let i = 0; i < bindElements1.length; i++) {
    const observer = new MutationObserver((mutationsList, observer) => {
      for (const mutation of mutationsList) {
        if (mutation.type === 'attributes') {
          let newValue = mutation.target.getAttribute(mutation.attributeName);
          this.attributeChangedCallback('def', null, newValue);
        }
      }
    });
    observer.observe(bindElements1[i], {
      attributes: true,
      childList: false,
      subtree: false,
      characterData: false,
      attributeOldValue: false
    });
  }
}
