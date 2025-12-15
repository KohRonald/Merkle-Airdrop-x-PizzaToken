// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console2} from "forge-std/Test.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {PizzaToken} from "src/PizzaToken.sol";
import {DeployMerkleAirdrop} from "script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "foundry-devops/src/ZkSyncChainChecker.sol";

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    PizzaToken public pizzaToken;
    MerkleAirdrop public merkleAirdrop;

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;

    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18; //Amount to claim
    uint256 public AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;

    //This proofs were generated and written in output.json that is under the user's address
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];

    address public gasPayer;
    address user;
    uint256 userPrivateKey;

    /**
     * @notice We only run the deployer script on non-ZkSync chains. This is because the deployer script does not work when deploying on ZkSync Chains.
     */
    function setUp() public {
        if (!isZkSyncChain()) {
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (merkleAirdrop, pizzaToken) = deployer.run();
        } else {
            pizzaToken = new PizzaToken();
            merkleAirdrop = new MerkleAirdrop(ROOT, pizzaToken);
            pizzaToken.mint(pizzaToken.owner(), AMOUNT_TO_SEND); //Mint the inital token
            pizzaToken.transfer(address(merkleAirdrop), AMOUNT_TO_SEND); //Send tokens to airdrop contract as claims are withdrawn there
        }
        (user, userPrivateKey) = makeAddrAndKey("user"); //makeAddrAndKey will generate the address of the user and their private key
        gasPayer = makeAddr("gasPayer");
    }

    function testUsersCanClaim() public {
        console2.log("User address: ", user); //Log to check that the address generated is the same as the one we used to generate the proofs in the Merkle Tree

        uint256 startingBalance = pizzaToken.balanceOf(user);
        console2.log("startingBalance: ", startingBalance);

        bytes32 digest = merkleAirdrop.getMessageHash(user, AMOUNT_TO_CLAIM);

        //sign message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPrivateKey, digest); //returns v,r,s vaules of the signed message

        //gasPayer call claims on behalf of user using signed message
        //gasPayer essentially pays the gas, but user will receive the tokens
        vm.prank(gasPayer);
        merkleAirdrop.claim(user, AMOUNT_TO_CLAIM, PROOF, v, r, s);

        uint256 endingBalance = pizzaToken.balanceOf(user);
        console2.log("endingBalance: ", endingBalance);

        assertEq(endingBalance - startingBalance, AMOUNT_TO_CLAIM);
    }
}
