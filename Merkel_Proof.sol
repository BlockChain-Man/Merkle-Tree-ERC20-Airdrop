// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MerkleAirdrop is Ownable {
    IERC20 public token;
    bytes32 public merkleRoot;

    // double-claim protection: leaf => claimed?
    mapping(bytes32 => bool) public claimed;

    event Claimed(address indexed account, uint256 amount);

    constructor(bytes32 _merkleRoot) Ownable(msg.sender) {
        merkleRoot = _merkleRoot;
    }

    /// to keep this code usable for already deployed contracts, I preferred to create SetTokenAddress() to provide the address of the token instead of assigning the token address using a constructor.

    function SetTokenAddress(IERC20 _token) external onlyOwner {
        token = _token;
    }

    /// the below function allows the user to set an entirely new merkel root assuming a change needs to be made to current root OR a new root needs to be used.
    /// in either cases we must save / re-save the prooves associated with each address (and the amount) off-chain

    function setMerkleRoot(bytes32 newRoot) external onlyOwner {
        merkleRoot = newRoot;
    }

    // Leaf format: keccak256(abi.encodePacked(account, amount))
    function _leaf(
        address account,
        uint256 amount
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount));
    }

    function claim(uint256 amount, bytes32[] calldata proof) external {
        bytes32 leaf = _leaf(msg.sender, amount);

        require(!claimed[leaf], "Already claimed");
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Not eligible");

        claimed[leaf] = true;

        require(token.transfer(msg.sender, amount), "Token transfer failed");
        emit Claimed(msg.sender, amount);
    }
}
