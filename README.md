# Merkle Tree ERC20 Airdrop – Documentation

This repository demonstrates a **pull-based ERC20 airdrop** using **Merkle trees** for gas efficiency and trust-minimized distribution.

The system consists of:

- Two Solidity smart contracts
- One JavaScript script to generate the Merkle tree, root, and proofs

---

## Architecture Overview

```
Off-chain (Node.js)
└── merkle.js
    ├── Builds Merkle Tree
    ├── Generates Merkle Root
    └── Generates proofs per user

On-chain (Solidity)
├── ERC20_Merkel.sol     → ERC20 token
└── Merkel_Proof.sol    → Airdrop claim contract
```

Users **claim their tokens themselves**, paying their own gas, by submitting a Merkle proof.

---

## 1. `merkle.js` – Merkle Tree Generator

### Purpose

This script creates:

- Merkle tree leaves
- Merkle root (stored on-chain)
- Merkle proofs (sent to users)

### Leaf Definition (Critical)

Each leaf is generated exactly as Solidity expects:

```
keccak256(abi.encodePacked(account, amount))
```

In ethers.js:

```js
ethers.solidityPackedKeccak256(["address", "uint256"], [account, amount]);
```

⚠️ **Any mismatch between JS and Solidity encoding will break verification.**

### What the Script Outputs

- Merkle Root → to be deployed into the airdrop contract
- Proof array per user → sent off-chain (email, backend, UI, etc.)

### Sorted Pairs

The tree is created with:

```js
{
  sortPairs: true;
}
```

This ensures deterministic proofs and matches OpenZeppelin’s recommended approach.

---

## 2. `Merkel_Proof.sol` – Merkle Airdrop Contract

### Purpose

Allows eligible users to **claim ERC20 tokens** by submitting:

- Their address

  > **Note:** To be fetched automatically when the user connects his wallet.

- Their allocated amount

  > **Note:** The allocated amount is not entered by the user.
  > It is fetched off-chain based on the connected wallet address.

- A valid Merkle proof
  > **Note:** same as the allocated amount.

### Key State Variables

```solidity
IERC20 public token;
bytes32 public merkleRoot;
mapping(bytes32 => bool) public claimed;
```

- `token` → ERC20 being distributed
- `merkleRoot` → root generated off-chain
- `claimed` → prevents double claims

---

### Claim Flow

1. User calls `claim(amount, proof)`
2. Contract:

   - Recreates the leaf
   - Verifies proof against `merkleRoot`
   - Checks the claim wasn’t already used
   - Transfers tokens

### Double-Claim Protection

Each leaf hash can be claimed **only once**:

```solidity
require(!claimed[leaf], "Already claimed");
claimed[leaf] = true;
```

---

### Why Token Address Is Set Later

The token address is set using:

```solidity
function SetTokenAddress(IERC20 _token) external onlyOwner
```

This allows:

- Deploying the airdrop contract **before** the token
- Reusing the contract with different tokens (if intended)

---

### Root Updates

The owner can update the Merkle root to support:

- New airdrop rounds
- Corrected allowlists

⚠️ Old proofs become invalid when the root changes.

---

## 3. `ERC20_Merkel.sol` – ERC20 Token Contract

### Purpose

Defines the ERC20 token that will be distributed via the Merkle airdrop.

Typical usage:

- Mint full supply to deployer or treasury
- Transfer required amount to the airdrop contract
- Users claim tokens from the airdrop contract

---

## Full Claim Lifecycle

1. Build allowlist off-chain
2. Generate Merkle root + proofs (`merkle.js`)
3. Deploy ERC20 token
4. Deploy `Merkel_Proof.sol`
5. Set token address
6. Set Merkle root
7. Fund airdrop contract with tokens
8. Users claim tokens with their proof

---

## Why Use Merkle Airdrops?

### Advantages

- Extremely gas efficient
- No on-chain storage of allowlists
- Scales to tens of thousands of users
- Users pay their own gas

### Trade-offs

- Proof distribution must be handled off-chain
- Root updates invalidate old proofs
- Requires careful encoding consistency

---

## Security Notes

- Encoding **must match exactly** between JS and Solidity
- Always use `abi.encodePacked` consistently
- Never reuse proofs across different roots
- Consider pausing claims if root updates are frequent

---

## Summary

This setup represents a **production-grade Merkle airdrop pattern**:

- Standard OpenZeppelin primitives
- Gas-efficient distribution
- Clear separation of off-chain and on-chain responsibilities

---

### Related Source Files

- `merkle.js`
- `Merkel_Proof.sol`
- `ERC20_Merkel.sol`

---
