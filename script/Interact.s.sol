// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";

/**
 * This contract takes the Signature of a signed message from address (A) to allow address (B) to call airdrop claim on their behalf.
 * Airdrop claim address validation handled by MerkleAirdrop contract.
 * If address (B) trys to claim for address (C) and address (C) is not eligible for aidrop, then no claim will occur.
 */
contract ClaimAirdrop is Script {
    error __ClaimAirdropScript_InvalidSignatureLength();

    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 CLAIMING_AMOUNT = 25 * 1e18;

    //This proofs were generated and written in output.json that is under the user's address
    //The Proof are for the second address, which is the claiming address
    bytes32 PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] proof = [PROOF_ONE, PROOF_TWO];
    bytes private SIGNATURE =
        hex"fbd2270e6f23fb5fe9248480c0f4be8a4e9bd77c3ad0b1333cc60b5debc511602a2a06c24085d8d7c038bad84edc53664c8ce0346caeaa3570afec0e61144dc11c";

    /**
     * @param airdrop The address of the aidrop contract
     * @dev The v,r,s values are retrived through getting the message digest(data to sign), then signing the digest with the user(account receiving the airdrop) to get the signature.
     *
     * This is done via cast:
     *  1. cast call <contract address> <function signature> <function variables> --rpc-url http://localhost:8545
     *      a. cast call 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "getMessageHash(address,uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 25000000000000000000 --rpc-url http://localhost:8545
     *
     *  2. cast wallet sign --no-hash <message digest> --private-key <private-key>
     *      a. cast wallet sign --no-hash 0x184e30c4b19f5e304a89352421dc50346dad61c461e79155b910e73fd856dc72 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
     *  - command --no-hash is used to prevent 2nd hashing since it is already in bytes
     *  - On actual testnet/mainnet, use keystore account via --account to prevent typing of private key
     *
     *  3. Store the Signature as a variable (dont take the 0x (first 2 values of the signature)):
     *      a. use hex""
     *
     *  4. Call splitSignature() to split the Signature into its v,r,s component
     */
    function claimAirdrop(address airdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(airdrop).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, proof, v, r, s);
        vm.stopBroadcast();
    }

    /**
     * @notice Splits signature of a signed message to get its v,r,s component. Even though we call it v,r,s the signature holds the values as r,s,v.
     * @param sig The Signature of the signed message
     * @return v The v value of the Signature
     * @return r The r value of the Signature
     * @return s The svalue of the Signature
     * @dev uint8 == byte 1
     */
    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        //validate that the signaure is of correct length
        if (sig.length != 65) {
            revert __ClaimAirdropScript_InvalidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 32)) //from memory, loading first 32 bytes
            s := mload(add(sig, 64)) //from memory, loading second 32 bytes
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /**
     * @dev Call the function as the non-claiming address, to claim on behalf of the claimer. Claimer will receive the airdrop, non-claiming address will pay the gas fee. Test is done on CLI:
     *  - forge script script/Interact.s.sol:ClaimAirdrop --rpc-url http://localhost:8545 --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d --broadcast
     * @dev To verify the airdrop recived by claimer:
     *  1. cast call <token contract> "balanceOf(address)" <receiving account public address>
     *      a. cast call 0x5FbDB2315678afecb367f032d93F642f64180aa3 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
     *
     *  2. cast the return bytes to dec
     *      a. cast --to-dec 0x0000000000000000000000000000000000000000000000015af1d78b58c40000
     */
    function run() external {
        address monstRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(monstRecentlyDeployed);
    }
}
