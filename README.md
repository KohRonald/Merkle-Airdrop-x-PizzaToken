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

## EIPS
### EIP-4844 (Shard Blob Transactions [Proto-Danksharding])
- "Blobs" are temporary data storage mechanism 
- They allow for storing of data on-chain for a short period of time
- Remove the need to store transaction data permanently on ETH L1, with calldata, which were expensive
- A new BLOBHASH opcode and a precompile was created to calculate and verify the blobs
- Cannot access the data itself, only able to access the hash of the data with the new BLOBHASH opcode
- Blobs were added because rollups wanted a cheaper way to validate transactions

- The problem it solves: 
  - L2s rollups processes, bundles and compress transactions into a batch, and submit that batch to L1 for verification
  - L2s are used to do this as it is cheaper in terms of gas fees
  - However, when L2 submit these batches to L1, L1 has to verify that the batch of transactions is good
  - The L1 requires the compressed batch of txn to verify that the txn is good, after which that batch is rendered useless
  - So, this compressed batch of txn is stored forever as a calldata storage
  - Additionally, more gas costs is required for storage, so as it grows bigger, it gets even more expensive
  - Hence, Blobs are used to solve the need for permanently storing compressed txn batches


