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
    bytes32   stateRoot;    // 3
    bytes32   txRoot;       // 4
    bytes32   receiptRoot;  // 5
    //Maybe store total difficulty up to this point here.
  }

  struct Transaction {
    //data
  }

  //For now, just assume all blocks are good + valid.
  //In the future, will use SmartPool's verification.
  function submitBlock(bytes32 blockHash, bytes rlpHeader) {
    BlockHeader memory header = parseBlockHeader(rlpHeader);
    blocks[blockHash] = header;
    //TO DO: pass in cmix, check PoW
  }

  //This function probably does not work as-is
  function checkStateProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes rlpState) constant returns (bool) {
   bytes32 stateRoot = blocks[blockHash].stateRoot;
   if (checkProof(stateRoot, rlpStack, indexes, rlpState)) {
     return true;
   } else {
     return false;
   }
  }

  function checkTxProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes rlpTransaction) constant returns (bool) {
    bytes32 txRoot = blocks[blockHash].txRoot;
    if (checkProof(txRoot, rlpStack, indexes, rlpTransaction)) {
      return true;
    } else {
      return false;
    }
  }

  function checkReceiptProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes rlpReceipt) constant returns (bool) {
   bytes32 receiptRoot = blocks[blockHash].receiptRoot;
   if (checkProof(receiptRoot, rlpStack, indexes, rlpReceipt)) {
     return true;
   } else {
     return false;
   }
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
        header.stateRoot = bytes32(it.next().toUint());
      } else if (idx == 4) {
        header.txRoot = bytes32(it.next().toUint());
      } else if (idx == 5) {
        header.receiptRoot = bytes32(it.next().toUint());
      } else {
        it.next();
      }
      idx++;
     }
     return header;
  }

  function checkProof(bytes32 rootHash, bytes rlpStack, uint[] indexes, bytes rlpValue) constant returns (bool) {
   RLP.RLPItem[] memory stack = rlpStack.toRLPItem().toList();
   bytes32 hashOfNode = rootHash;
   bytes memory currNode;
   RLP.RLPItem[] memory currNodeList;

   for (uint i = 0; i < stack.length; i++) {
     if (i == stack.length - 1) {
       currNode = stack[i].toBytes();
       if (hashOfNode != sha3(currNode)) {return false;}
       currNodeList = stack[i].toList();
       RLP.RLPItem memory value = currNodeList[currNodeList.length - 1];
       if (sha3(rlpValue) == sha3(value.toBytes())) {
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

  function getStateRoot(bytes32 blockHash) constant returns (bytes32) {
    return blocks[blockHash].stateRoot;
  }

  function getTxRoot(bytes32 blockHash) constant returns (bytes32) {
    return blocks[blockHash].txRoot;
  }

  function getReceiptRoot(bytes32 blockHash) constant returns (bytes32) {
    return blocks[blockHash].receiptRoot;
  }
}
