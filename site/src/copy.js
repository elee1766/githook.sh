document.querySelectorAll('.copy-btn').forEach(btn => {
  btn.onclick = () => {
    const pre = btn.closest('pre');
    const text = pre.textContent.slice(0, -1); // trim button area
    navigator.clipboard.writeText(text);
    btn.classList.remove('copied');
    void btn.offsetWidth; // force reflow to restart animation
    btn.classList.add('copied');
  };
});

document.querySelectorAll('.cmd').forEach(el => {
  el.ondblclick = () => {
    const sel = window.getSelection();
    const range = document.createRange();
    range.selectNodeContents(el);
    sel.removeAllRanges();
    sel.addRange(range);
  };
});
