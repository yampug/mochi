let bindElements = this.shadow.querySelectorAll('[123]');
if (bindElements) {
  for (let i = 0; i < bindElements.length; i++) {
    const observer = new MutationObserver((mutationsList, observer) => {
      for (const mutation of mutationsList) {
        if (mutation.type === 'attributes') {
          let newValue = mutation.target.getAttribute(mutation.attributeName);
          this.attributeChangedCallback('abc', null, newValue);
        }
      }
    });
    observer.observe(bindElements[i], {
      attributes: true,
      childList: false,
      subtree: false,
      characterData: false,
      attributeOldValue: false
    });
  }
}
let bindElements = this.shadow.querySelectorAll('[5678]');
if (bindElements) {
  for (let i = 0; i < bindElements.length; i++) {
    const observer = new MutationObserver((mutationsList, observer) => {
      for (const mutation of mutationsList) {
        if (mutation.type === 'attributes') {
          let newValue = mutation.target.getAttribute(mutation.attributeName);
          this.attributeChangedCallback('def', null, newValue);
        }
      }
    });
    observer.observe(bindElements[i], {
      attributes: true,
      childList: false,
      subtree: false,
      characterData: false,
      attributeOldValue: false
    });
  }
}
