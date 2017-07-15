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

   function verifyTransaction(bytes rlpProof, bytes rlpPath, bytes rlpTransaction, bytes32 blockHash) returns (bool){
      BlockHeader memory header = blocks[blockHash];

      //if (!checkProof(rlpProof, rlpPath, rlpTransaction)) {
      //   throw;
      //}

      bytes32 txHash = sha3(rlpTransaction);
      transactions[txHash] = parseTransaction(rlpTransaction);
      return true;
   }

   // HELPER FUNCTIONS

   function parseBlockHeader(bytes rlpHeader) constant internal returns (BlockHeader) {
      BlockHeader memory header;
      var it = rlpHeader.toRLPItem().iterator();

      uint idx;
      while(it.hasNext()) {
         if (idx == 0) {
            header.prevBlockHash = it.next().toUint();
         } else if (idx == 3) {
            header.txRoot = bytes32(it.next().toUint());
         }
         it.next();
         idx++;
      }
      return header;
   }

   function getStackLength(bytes rlpProof) constant returns (uint) {
     RLP.RLPItem[] memory stack = rlpProof.toRLPItem().toList();
     return stack.length;
   }

  function checkProof(bytes32 txRoot, bytes rlpProof, uint[] indexes, bytes rlpTransaction) constant returns (bool) {
    RLP.RLPItem[] memory stack = rlpProof.toRLPItem().toList();
    bytes32 hashOfNode = txRoot;
    bytes memory currNode;
    RLP.RLPItem[] memory currNodeList;

    for (uint i = 0; i < stack.length; i++) {
      if (i == stack.length - 1) {
        currNode = stack[i].toBytes();
        if (hashOfNode != sha3(currNode)) {return false;}
        currNodeList = stack[i].toList();
        RLP.RLPItem memory value = currNodeList[currNodeList.length - 1];
        if (sha3(rlpTransaction) == sha3(value.toBytes())) {
          return true;
        } else {
          return false;
        }
      }
      currNode = stack[i].toBytes();
      if (hashOfNode != sha3(currNode)) {return false;}
      currNodeList = stack[i].toList();
      hashOfNode = currNodeList[indexes[i]].toBytes32();
      if (i == 1) return true;
    }
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

	 function getTxRoot(bytes32 blockHash) constant returns (bytes32) {
		 return blocks[blockHash].txRoot;
	 }
}
