pragma solidity ^0.4.11;

import "./RLP.sol";

contract PeaceRelay {
   using RLP for RLP.RLPItem;
   using RLP for RLP.Iterator;
   using RLP for bytes;

   mapping (bytes32 => BlockHeader) blocks;
   mapping (bytes32 => Transaction) transactions;

   struct BlockHeader {
      uint      prevBlockHash;// 0
      bytes32   txRoot;       // 4
   }

   struct Transaction {
      //data
   }

   //For now, just assume all blocks are good + valid.
   //In the future, will use SmartPool's verification.
   function submitBlock(bytes rlpHeader, bytes32 blockHash) {
      BlockHeader memory header = parseBlockHeader(rlpHeader);

      blocks[blockHash] = header;
   }

   function verifyTransaction(bytes rlpProof, bytes rlpPath, bytes rlpTransaction, bytes32 blockHash) {
      BlockHeader memory header = blocks[blockHash];

      if (!checkProof(rlpProof, rlpPath, rlpTransaction)) {
         throw;
      }

      bytes32 txHash = sha3(rlpTransaction);
      transactions[txHash] = parseTransaction(rlpTransaction);
   }

   // HELPER FUNCTIONS

   function parseBlockHeader(bytes rlpHeader) constant internal returns(BlockHeader) {
      BlockHeader memory header;
      var it = rlpHeader.toRLPItem().iterator();

      uint idx;
      while(it.hasNext() && idx < 5) {
         if (idx == 0) {
            header.prevBlockHash = it.next().toUint();
         } else if (idx == 4) {
            header.txRoot = bytes32(it.next().toUint());
         }
         idx++;
      }
      return header;
   }

   function checkProof(bytes rlpProof, bytes rlpPath, bytes rlpTransaction) returns (bool) {
      return true;
   }

   function parseTransaction(bytes rlpTransaction) constant internal returns(Transaction) {
      Transaction memory transaction;
      var it = rlpTransaction.toRLPItem().iterator();

      uint idx;
      while(it.hasNext() && idx < 5) {
         /*

         HAVE TO FIGURE OUT INDEXS OF STUFF IN TRANSACTION

         if (idx == 0) {
            header.prevBlockHash = it.next().toUint();
         } else if (idx == 4) {
            header.txRoot = bytes32(it.next().toUint());
         }
         idx++;
         */
      }
   return transaction;
   }
}
