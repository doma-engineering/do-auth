import * as sodium0 from "libsodium-wrappers";

export type CanonicalisedValue =
  number |
  bigint |
  string |
  Array<Array<string | CanonicalisedValue>> |
  Array<any>;

export type CanonicalisableValue =
  string |
  number |
  bigint |
  Record<string, any> |
  CanonicalisableValue[]

export function canonicalise(x: CanonicalisableValue | undefined): CanonicalisedValue | undefined {
  // console.log("Canonicalising ", x)
  if (typeof (x) === "string" || typeof (x) === "number" || typeof (x) === "bigint") {
    // console.log("It's just a value", x)
    return x;
  }
  if (x instanceof Array) {
    return x.map(x => canonicalise(x));
  }
  if (x instanceof Object) {
    var ks = Object.keys(x);
    const x1: Record<string, any> = { ...x };
    ks.sort();
    var y: Array<Array<string | CanonicalisedValue>> = new Array();
    for (let i = 0; i < ks.length; i++) {
      // console.log("Got object, working on adding **", ks[i], "**, the", i, "th element of", ks)
      const canonical = canonicalise(x1[ks[i]]);
      if (canonical) {
        y.push([
          ks[i],
          canonical
        ]);
      } else {
        return undefined;
      }
      // console.log("Accumulator so far:", [...y])
    }
    return y;
  }
  return undefined;
}