// Copy buttons: any element with class "copy" copies the text of the element named in data-for.
document.querySelectorAll('.copy').forEach(function (btn) {
  var src = document.getElementById(btn.getAttribute('data-for'));
  if (!src) return;
  var icon = btn.innerHTML;
  var check = '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M5 12l5 5L20 7"/></svg>';
  function fallback(text) {
    var ta = document.createElement('textarea');
    ta.value = text; ta.setAttribute('readonly', ''); ta.style.position = 'absolute'; ta.style.left = '-9999px';
    document.body.appendChild(ta); ta.select();
    try { document.execCommand('copy'); } catch (e) {}
    document.body.removeChild(ta);
  }
  btn.addEventListener('click', function () {
    var text = src.textContent.trim();
    var p = (navigator.clipboard && window.isSecureContext) ? navigator.clipboard.writeText(text) : Promise.reject();
    p.catch(function () { fallback(text); }).finally(function () {
      btn.classList.add('done'); btn.innerHTML = check; btn.title = 'Copied';
      setTimeout(function () { btn.classList.remove('done'); btn.innerHTML = icon; btn.title = 'Copy'; }, 1600);
    });
  });
});
