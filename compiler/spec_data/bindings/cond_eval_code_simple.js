{
  let _anchor = this._ifAnchors[0];
  if (_anchor) {
    let _show = this.evaluateCondition(0);
    if (_show && !this._ifRendered[0]) {
      let _clone = this._ifTemplates[0].content.cloneNode(true);
      this._ifRendered[0] = Array.from(_clone.childNodes);
      _anchor.parentNode.insertBefore(_clone, _anchor.nextSibling);
    } else if (!_show && this._ifRendered[0]) {
      this._ifRendered[0].forEach(n => n.parentNode && n.parentNode.removeChild(n));
      this._ifRendered[0] = null;
    }
  }
}
