const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const { ethers } = require("ethers");

// Example allowlist: address + amount
const claims = [
  { account: "0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", amount: "10000000000000000000" }, // 1 token (18 decimals)
  { account: "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2", amount: "5000000000000000000" },
  { account: "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", amount: "1000000000000000000" }
];

// IMPORTANT: leaf must match Solidity exactly:
// keccak256(abi.encodePacked(account, amount))
// In ethers.js:
function leaf(account, amount) {
  return ethers.solidityPackedKeccak256(["address", "uint256"], [account, amount]);
}

const leaves = claims.map(x => Buffer.from(leaf(x.account, x.amount).slice(2), "hex"));

// For allowlists, using sorted pairs is common
const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

const root = "0x" + tree.getRoot().toString("hex");
console.log("Merkle Root:", root);

for (const c of claims) {
  const l = leaf(c.account, c.amount);
  const proof = tree.getHexProof(Buffer.from(l.slice(2), "hex"));
  console.log("\nAccount:", c.account);
  console.log("Amount:", c.amount);
  console.log("Proof:", proof);
}
