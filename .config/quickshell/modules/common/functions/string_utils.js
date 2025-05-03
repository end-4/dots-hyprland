function format(str, ...args) {
  return str.replace(/{(\d+)}/g, (match, index) => 
    typeof args[index] !== 'undefined' ? args[index] : match
  );
}
