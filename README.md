# Peace Relay
before getting to know Peace Relay, you should first learn about how [BTC Relay](https://github.com/ethereum/btcrelay) works
## What is Peace Relay
Peace Relay is a system of smart contracts that aim to allow for cross-EVM-chain communication using relay contracts. 

These contracts will be able to verifiy merkle-patricia proofs about state, transactions, or receipts within specific blocks. 

This, along with the wonderful Ethash verification work done by SmartPool, allows for trustless cross chain transfers of all tokens on any EVM chain. 

## How does it work
* Some important notes: 
    * In order to do cross-chain verification, we need valid block header informations stored in `PeaceRelay` contract so then other proofs like transaction proof or account state proof can be verified based on merkle roots in block header. Right now in the early stage of Peace Relay **we assume the block header submitted is the correct header from counter chain**. In the future, **these headers will be verified based on PoW within and chain re-organization will be taken care of.**
    * In the demo, when user in one chain(say ETH) wants to transfer his funds to other chain(say ETC), he will lock his **ethers** in ETH and gets some **tokens** on ETC in return. Then he can use these tokens for his business on ETC chain. If someone wish to **trade ethers between chains**, they can use Peace Relay the way others use BTC Relay - by verifying a transaction and it's value.

* How it works step by step:
    * Here we assume a scenario where a user wish to lock his ethers in ETH and gets some tokens in ETC in return. There are `PeaceRelay` contracts deployed on both ETH and ETC, `ETCLocking` contract deployed on ETH and `ETCToken` contract deployed on ETC. `PeaceRelay` contract stores block headers. `ETCLocking` contract locks/unlocks the ethers in ETH. `ETCToken` contract mints/burns tokens in ETC.
    1. deploy `PeaceRelay` contract on both ETH and ETC and submits headers into the contract
        * block header of ETH is submitted into `PeaceRelay` contract on ETC and vice versa
    2. deploy `ETCLocking` on ETH and `ETCToken` on ETC
    3. send transaction to execute `ETCLocking.lock` function along with amount of ethers to lock
    4. generate the proof of the transaction in step 4 off-chain
    5. send transaction to execute `ETCToken.mint` function provided with proof from step 5
        * then user can spend those tokens at will until someday they wish to convert them back to ethers in ETH
    6. to convert tokens to ethers, send transaction to execute `ETCToken.burn` to burn the tokens
    7. generate the proof of the transaction in step 6 off-chain
        * proof in this step contains transaction and corresponding transaction receipt
    8. send transaction to execute `ETCLocking.unlock` function provided with proof from step 7 to unlcok ethers
## Possible application