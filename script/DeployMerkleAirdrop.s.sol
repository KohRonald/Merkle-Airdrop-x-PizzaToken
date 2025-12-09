// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "src/MerkleAirdrop.sol";
import {PizzaToken} from "src/PizzaToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public s_merkleRoot = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public s_amountToTransfer = 4 * 25 * 1e18; //Our test contains 4 users that are claiming 25 tokens each

    function run() external returns (MerkleAirdrop, PizzaToken) {
        return deployMerkleAirdrop();
    }

    /**
     * @notice Deploy contracts, mints Airdrop Tokens on pizza token contract, transfers minted token to Merkle Airdrop contract
     */
    function deployMerkleAirdrop() public returns (MerkleAirdrop, PizzaToken) {
        vm.startBroadcast();
        PizzaToken pizzaToken = new PizzaToken();
        MerkleAirdrop merkleAirdrop = new MerkleAirdrop(s_merkleRoot, IERC20(address(pizzaToken)));
        pizzaToken.mint(pizzaToken.owner(), s_amountToTransfer);
        pizzaToken.transfer(address(merkleAirdrop), s_amountToTransfer);
        vm.stopBroadcast();

        return (merkleAirdrop, pizzaToken);
    }
}
