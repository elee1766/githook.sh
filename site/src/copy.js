document.querySelectorAll('.copy-btn').forEach(btn => {
  btn.onclick = () => {
    const pre = btn.closest('pre');
    const text = pre.textContent.slice(0, -1); // trim button area
    navigator.clipboard.writeText(text);
    btn.classList.add('copied');
    setTimeout(() => btn.classList.remove('copied'), 1500);
  };
});

document.querySelectorAll('code').forEach(code => {
  code.ondblclick = () => {
    const sel = window.getSelection();
    const range = document.createRange();
    range.selectNodeContents(code);
    sel.removeAllRanges();
    sel.addRange(range);
  };
});
