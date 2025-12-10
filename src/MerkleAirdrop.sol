// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {PizzaToken} from "src/PizzaToken.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20; //allows for calling of functions defined in SafeERC20 for IERC20

    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AddressAlreadyClaimedAirdrop();
    error MerkleAirdrop__InvalidSignature();

    bytes32 private immutable i_merkleRoot;
    IERC20 private immutable i_airdopToken;
    mapping(address claimer => bool claimed) private s_hasClaimed;

    //This is the hashed version of the AirdropClaim struct define below
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address account, uint256 amount)");

    struct AirdropClaim {
        address account;
        uint256 amount;
    }

    event Claim(address account, uint256 amount);

    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = merkleRoot;
        i_airdopToken = airdropToken;
    }

    /**
     *
     * @param account Account receiving the claimed airdrop tokens
     * @param amount Amount of tokens to be airdropped
     * @param merkleProof Array used to calculate if account claiming airdop is eligible
     * @param v The v value for signature checking
     * @param r The r value for signature checking
     * @param s The s value for signature checking
     * @dev Values in array in Merkle Proof are the required intermediate hashes to be use to calculate the merkle root. The calculated root is then compared to the expected root defined in the constructor. If they tally, then the address is proven to be elgible for the airdrop.
     * @dev bytes32[] requires calldata to specify where to save the value to
     * @dev Follows CEI pattern
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        //==CHECK==
        if (s_hasClaimed[account]) {
            revert MerkleAirdrop__AddressAlreadyClaimedAirdrop();
        }

        //Check if signature is valid
        if (!_isValidSignature(account, getMessage(account, amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
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

    /**
     * @notice Gets hash EIP712 message value of the Airdrop struct, otherwise known as the digest
     * @param account Address to claim airdrop
     * @param amount Amount of tokens to claim from airdrop
     */
    function getMessage(address account, uint256 amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            //Hashing the encoded struct hash and the struct values
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount})))
        );
    }

    /**
     * @notice Calculate the signer from the message digest, and v,r,s values. Then compares signer address with actual address. If address matches then we can verify that the signature is valid.
     * @param account The address to claim airdrop
     * @param digest The EIP712 value of the message struct and message
     * @param v The v value for signature checking
     * @param r The r value for signature checking
     * @param s The s value for signature checking
     */
    function _isValidSignature(address account, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner == account;
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirdropToken() external view returns (IERC20) {
        return i_airdopToken;
    }
}
