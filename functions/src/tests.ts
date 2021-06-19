const d = require("date-fns/differenceInYears");
const differenceInYears = d.differenceInYears;

const start = new Date(2000, 0);
const end = new Date(2001, 0);
console.log(differenceInYears(end, start));
