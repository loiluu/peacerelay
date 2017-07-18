pragma solidity ^0.4.11;

import "./RLP.sol";
import "./Ethash.sol";

contract PeaceRelay {
    using RLP for RLP.RLPItem;
    using RLP for RLP.Iterator;
    using RLP for bytes;

    mapping(bytes32 => BlockHeader) blocks;
    mapping(bytes32 => Transaction) transactions;
    
    Ethash ethash;
    
    struct BlockHeader {
        uint prevBlockHash; // 0
        bytes32 stateRoot; // 3
        bytes32 txRoot; // 4
        bytes32 receiptRoot; // 5
    }

    struct Transaction {
        //data
    }

    function PeaceRelay(address _ethash) {
        ethash = Ethash(_ethash); //ethash contract
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
        if (ethashResult > ((2 ** 256 - 1) / targetDifficulty)) throw;

        blocks[blockHash] = header;
    }

    // function computeS(bytes rlpHeader, bytes8 nonce, uint[8] cmix) constant returns(uint) {
    //     uint[16] memory s;
    //     // uint ethashResult;
    //     s = ethash.computeS(uint(sha3(rlpHeader)), uint(nonce));
    //     return ethash.computeSha3(s, cmix);
    // }

    // function prs(bytes rlpHeader) constant returns(bytes8, uint) {
    //     BlockHeader memory header;
    //     bytes8 nonce;
    //     uint targetDifficulty;
    //     (header, nonce, targetDifficulty) = parseBlockHeader(rlpHeader);
    //     return (nonce, targetDifficulty);
    // }

    //This function probably does not work as-is
    function checkStateProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes rlpState) constant returns(bool) {
        bytes32 stateRoot = blocks[blockHash].stateRoot;
        if (checkProof(stateRoot, rlpStack, indexes, rlpState)) {
            return true;
        } else {
            return false;
        }
    }

    function checkTxProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes rlpTransaction) returns(bool) {
        bytes32 txRoot = blocks[blockHash].txRoot;
        if (checkProof(txRoot, rlpStack, indexes, rlpTransaction)) {
            return true;
        } else {
            return false;
        }
    }

    function checkReceiptProof(bytes32 blockHash, bytes rlpStack, uint[] indexes, bytes rlpReceipt) constant returns(bool) {
        bytes32 receiptRoot = blocks[blockHash].receiptRoot;
        if (checkProof(receiptRoot, rlpStack, indexes, rlpReceipt)) {
            return true;
        } else {
            return false;
        }
    }

    // HELPER FUNCTIONS

    function parseBlockHeader(bytes rlpHeader) constant internal returns(BlockHeader, bytes8, uint) {
        BlockHeader memory header;
        var it = rlpHeader.toRLPItem().iterator();

        bytes8 nonceLe;
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
            } else if (idx == 14) { // need to find out which one is nonce
                // extract nonce from header
                nonceLe = bytes8(uint64(it.next().toUint()));
            }
            else {
                it.next();
            }
            idx++;
        }
        return (header, nonceLe, difficulty);
    }

    function getStackLength(bytes rlpProof) constant returns(uint) {
        RLP.RLPItem[] memory stack = rlpProof.toRLPItem().toList();
        return stack.length;
    }

    function checkProof(bytes32 rootHash, bytes rlpStack, uint[] indexes, bytes rlpValue) constant returns(bool) {
        RLP.RLPItem[] memory stack = rlpStack.toRLPItem().toList();
        bytes32 hashOfNode = rootHash;
        bytes memory currNode;
        RLP.RLPItem[] memory currNodeList;

        for (uint i = 0; i < stack.length; i++) {
            if (i == stack.length - 1) {
                currNode = stack[i].toBytes();
                if (hashOfNode != sha3(currNode)) {
                    return false;
                }
                currNodeList = stack[i].toList();
                RLP.RLPItem memory value = currNodeList[currNodeList.length - 1];
                if (sha3(rlpValue) == sha3(value.toBytes())) {
                    return true;
                } else {
                    return false;
                }
            }
            currNode = stack[i].toBytes();
            if (hashOfNode != sha3(currNode)) {
                return false;
            }
            currNodeList = stack[i].toList();
            hashOfNode = currNodeList[indexes[i]].toBytes32();
            if (i == 1) return true;
        }
    }

    function parseTransaction(bytes rlpTransaction) constant internal returns(Transaction) {
        Transaction memory transaction;
        var it = rlpTransaction.toRLPItem().iterator();

        uint idx;
        while (it.hasNext() && idx < 5) {
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

    function getStateRoot(bytes32 blockHash) constant returns(bytes32) {
        return blocks[blockHash].stateRoot;
    }

    function getTxRoot(bytes32 blockHash) constant returns(bytes32) {
        return blocks[blockHash].txRoot;
    }

    function getReceiptRoot(bytes32 blockHash) constant returns(bytes32) {
        return blocks[blockHash].receiptRoot;
    }
}