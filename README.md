# Merkle Airdrop x Pizza Token

- Allow list of addresses to claim pizza tokens
- Utilise Merkle proofs for token claims 

## Contracts
1. PizzaToken.sol
   - The ERC20 token for airdrop

2. MerkleAirdop.sol
   - Checks if address is eligible for claim
   - Utilises Merkle proofs


## Merkle Proof
- Hashing the data (address + amount) to get the leaf node, and calculating with intermediate hashes to get the Merkle Root
- Data is hashed twice to calculate the leaf node, this is done to avoid hashing collision, preventing Second Pre-Image Attack
- Compare the calculated Merkle Root against the expected Merkle Root, if matches, address is eligible for airdrop

## Merkle Tree Generation
Generating proofs utilising murky library by dmfxyz (https://github.com/dmfxyz/murky)

1. GenerateInput.s.sol
- Generating Merkle Tree which takes in variables and concatenate them together, writing to input.json file by allowing permissions in foundry.toml for writing to file: 
```
fs_permissions = [{ access = "read-write", path = "./" }]
```

1. MakeMerkle.s.sol
- Modified from Murky Github Repo
- Essentially hashes and calculate the proof at every tree node level, utilising the address + amount as input values
