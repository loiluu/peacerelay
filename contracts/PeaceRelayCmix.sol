pragma solidity ^0.4.11;

import "./RLP.sol";
import "./Ethash.sol";

contract PeaceRelay {
  using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;

  mapping (bytes32 => BlockHeader) blocks;
  mapping (bytes32 => Transaction) transactions;

  Ethash public ethash;

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

  function PeaceRelay(address _ethash) {
    ethash = Ethash(_ethash);
  }

  //For now, just assume all blocks are good + valid.
  //In the future, will use SmartPool's verification.
  function submitBlock(bytes rlpHeader, bytes32 blockHash, uint[8] cmix) {
        BlockHeader memory header;
        bytes8 nonceLe;
        uint targetDifficulty;
        (header, nonceLe, targetDifficulty) = parseBlockHeader(rlpHeader);

        uint[16] memory s;
        uint ethashResult;
        s = ethash.computeS(uint(sha3(rlpHeader)), uint(nonceLe));
        ethashResult = ethash.computeSha3(s, cmix);
        // if (ethashResult > ((2 ** 256 - 1) / targetDifficulty)) throw;
        if (ethashResult > ((2 ** 256 - 1) / 1)) throw;

        blocks[blockHash] = header;
    }

  //This function probably does not work as-is
  function checkStateProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes statePrefix, bytes rlpState) constant returns (bool) {
   bytes32 stateRoot = blocks[blockHash].stateRoot;
   if (checkProof(stateRoot, rlpStack, indexes, statePrefix, rlpState)) {
     return true;
   } else {
     return false;
   }
  }

  function checkTxProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes transactionPrefix, bytes rlpTransaction) constant returns (bool) {
    bytes32 txRoot = blocks[blockHash].txRoot;
    if (checkProof(txRoot, rlpStack, indexes, transactionPrefix, rlpTransaction)) {
      return true;
    } else {
      return false;
    }
  }

  function checkReceiptProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes receiptPrefix, bytes rlpReceipt) constant returns (bool) {
   bytes32 receiptRoot = blocks[blockHash].receiptRoot;
   if (checkProof(receiptRoot, rlpStack, indexes, receiptPrefix, rlpReceipt)) {
     return true;
   } else {
     return false;
   }
  }

  function parseBlockHeader(bytes rlpHeader) constant internal returns(BlockHeader, bytes8, uint) {
        BlockHeader memory header;
        var it = rlpHeader.toRLPItem().iterator();

        bytes8 nonce;
        uint idx;
        uint difficulty;
        while (it.hasNext()) {
            if (idx == 0) {
                header.prevBlockHash = it.next().toUint();
            } else if (idx == 3) {
                header.stateRoot = bytes32(it.next().toUint());
            } else if (idx == 4) {
                header.txRoot = bytes32(it.next().toUint());
            } else if (idx == 5) {
                header.receiptRoot = bytes32(it.next().toUint());
            } else if (idx == 7) {
                difficulty = it.next().toUint();
            } else if (idx == 14) {
                nonce = bytes8(uint64(it.next().toUint()));
            }
            else {
                it.next();
            }
            idx++;
        }
        return (header, nonce, difficulty);
    }

  function checkProof(bytes32 rootHash, bytes rlpStack, uint[] indexes, bytes valuePrefix, bytes rlpValue) constant returns (bool) {
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
       if (sha3(valuePrefix, rlpValue) == sha3(value.toBytes())) {
         return true;
       } else {
         return false;
       }
     }
     currNode = stack[i].toBytes();
     if (hashOfNode != sha3(currNode)) {return false;}
     currNodeList = stack[i].toList();
     hashOfNode = currNodeList[indexes[i]].toBytes32();
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

  function test(bytes rlpValue) constant returns (bytes) {
    return rlpValue.toRLPItem().toBytes();
  }

  //rlpTransaction is a value at the bottom of the transaction trie. This, however,
  //has the first few bytes chopped off.
  function getTransactionDetails(bytes rlpTransaction) constant returns (uint) {
  	RLP.RLPItem[] memory list = rlpTransaction.toRLPItem().toList();
    return list[2].toUint();
    /*
    uint idx = 0;
  	while(it.hasNext()) {
  		if (idx == 0) {
  		  tx.nonce = it.next().toUint();
  		} else if (idx == 1) {
  			tx.gasPrice = it.next().toUint();
  		} else if (idx == 2) {
        tx.gasLimit = it.next().toUint();
  		} else if (idx == 3) {
  			tx.to = it.next().toAddress();
  		} else if (idx == 4) {
  			tx.value = it.next().toUint(); // amount of etc sent
  		} else if (idx == 5) {
        	tx.data = it.next().toBytes();
      	}
  		idx++;
  	}
    return tx;
    */

  }

}
