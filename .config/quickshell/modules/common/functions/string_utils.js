function format(str, ...args) {
  return str.replace(/{(\d+)}/g, (match, index) => 
    typeof args[index] !== 'undefined' ? args[index] : match
  );
}

function getDomain(url) {
  const match = url.match(/^(?:https?:\/\/)?(?:www\.)?([^\/]+)/);
  return match ? match[1] : null;
}

function shellSingleQuoteEscape(str) {
  // First escape backslashes, then escape single quotes
  return String(str)
    .replace(/\\/g, '\\\\')
    .replace(/'/g, "'\\''");
}
