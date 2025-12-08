// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PizzaToken} from "src/PizzaToken.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    using SafeERC20 for IERC20; //allows for calling of functions defined in SafeERC20 for IERC20

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AddressAlreadyClaimedAirdrop();

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdopToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    event Claim(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        i_merkleRoot = merkleRoot;
        i_airdopToken = airdropToken;
    }

    /**
     *
     * @param account Account receiving the claimed airdrop tokens
     * @param amount Amount of tokens to be airdropped
     * @param merkleProof Array used to calculate if account claiming airdop is eligible
     * @dev Values in array in Merkle Proof are the required intermediate hashes to be use to calculate the merkle root. The calculated root is then compared to the expected root defined in the constructor. If they tally, then the address is proven to be elgible for the airdrop.
     * @dev bytes32[] requires calldata to specify where to save the value to
     * @dev Follows CEI pattern
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        //==CHECK==
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AddressAlreadyClaimedAirdrop();
        }

        //Calculate using the account and the amount, the hash -> leaf node
        //1. Combined and hash the account + amount
        //2. Hash twice (2x keccak256) and use byes.concat
        //2a. The reason is to avoid hashing collision, preventing Second Pre-Image Attack
        //* This is done when Merkle proofs and Merkle trees are used
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        //utilise openzeppelin's MerkleProof function
        if (!MerkleProof.verify(merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        emit Claim(account, amount);

        //==EFFECTS==
        s_hasClaimed[account] = true;

        //==INTERACTIONS==
        //safeTransfer is used for the safety and compatibility of ERC20 token transactions
        //eg. the receiving address might not be able to receive the token, safeTransfer will revert on such cases
        i_airdopToken.safeTransfer(account, amount);
    }
}
