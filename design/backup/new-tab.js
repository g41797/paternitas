// The Zig API docs open in a new tab. A nav entry takes no target, so this
// sets one on every link to apidocs/. It runs on each page change: instant
// loading swaps pages without a load.
function apidocsInNewTab() {
  document.querySelectorAll('a[href*="apidocs/"]').forEach(function (a) {
    a.target = "_blank";
    a.rel = "noopener";
  });
}

if (typeof document$ !== "undefined") {
  document$.subscribe(apidocsInNewTab);
} else {
  document.addEventListener("DOMContentLoaded", apidocsInNewTab);
}
