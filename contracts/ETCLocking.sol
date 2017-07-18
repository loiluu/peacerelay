pragma solidity ^0.4.8;

import "./SafeMath.sol";
import "./PeaceRelay.sol";
import "./RLP.sol";


contract ETCLocking is SafeMath {

  using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;

  // Public variables of the token
  string public version = 'v0.1';
  uint public totalSupply;
  uint public DEPOSIT_GAS_MINIMUM; //should be constant
  bytes4 public BURN_FUNCTION_SIG;

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  PeaceRelay public ETHRelay;
  address etcTokenAddr; //maybe rename to EthLockingContract

  struct Transaction {
    uint nonce;
    uint gasPrice;
    uint gasLimit;
    address to;
    uint value;
    bytes data;
  }

  struct Log {
    address sender;
    address etcAddr;
    uint value;
  }
  event Locked(address indexed from, address indexed ethAddr, uint value);
  event Unlocked(address indexed to, uint value);

  function ETCLocking(address peaceRelayAddr, address _etcTokenAddr, uint depositGasMinimum,
                    bytes4 burnFunctionSig)
  {
    totalSupply = 0;
    ETHRelay = PeaceRelay(peaceRelayAddr);
    etcTokenAddr = _etcTokenAddr;
    BURN_FUNCTION_SIG = burnFunctionSig;
  }

  function unlock(bytes rlpTxStack, uint[] txIndex, bytes txPrefix, bytes rlpTransaction, bytes rlpRecStack,
                  uint[] recIndex, bytes recPrefix, bytes rlpReceipt, bytes32 blockHash) returns (bool success) {
    //TODO: verify tx receipt
    if (ETHRelay.checkReceiptProof(blockHash, rlpRecStack, recIndex, txPrefix, rlpReceipt)) {
        Log memory log = getReceiptDetails(rlpReceipt);
        if (log.etcAddr == 0) throw;

        //formalize interface, then fix this
        if (ETHRelay.checkTxProof(blockHash, rlpTxStack, txIndex, recPrefix, rlpTransaction)) {
            Transaction memory tx = getTransactionDetails(rlpTransaction);
            bytes4 functionSig = getSig(tx.data);

            assert (functionSig == BURN_FUNCTION_SIG);
            assert (tx.to != etcTokenAddr);
            assert (tx.gasLimit >= DEPOSIT_GAS_MINIMUM);

            //Can get these both from the log
            //address etcAddress = getAddress(tx.data);
            //uint etcValue = getValue(tx.data);

            //totalSupply = safeSub(totalSupply, etcValue);
            // use transfer instead of send
            //etcAddress.transfer(etcValue);
            assert(totalSupply == this.balance);
            //Unlocked(etcAddress, etcValue);
            return true;
        }
      return false;
    }
  }

  function lock(address ethAddr) returns (bool success) {
    // safeAdd already has throw, so no need to throw
    // Note: This will never throw, as there is a max amount of tokens on a chain
    totalSupply = safeAdd(totalSupply, msg.value);
    Locked(msg.sender, ethAddr, msg.value);
    return true;
  }

  // Non-payable unnamed function prevents Ether from being sent accidentally
  function () {}



  // HELPER FUNCTIONS

  function getSig(bytes b) constant returns (bytes4 functionSig) {
    if (b.length < 32) throw;
    assembly {
        let mask := 0xFFFFFFFF
        functionSig := and(mask, mload(add(b, 32)))
        //32 is the offset of the first param of the data, if encoded properly.
        //4 bytes for the function signature, 32 for the address and 32 for the value.
    }
  }

  function getValue(bytes b) constant returns (uint value) {
    if (b.length < 68) throw;
    assembly {
        value := mload(add(b, 68))
        //68 is the offset of the first param of the data, if encoded properly.
        //4 bytes for the function signature, 32 for the address and 32 for the value.
    }
  }

  //grabs the first input from some function data
  //and implies that it is an address
  function getAddress(bytes b) constant returns (address a) {
    if (b.length < 36) return address(0);
    assembly {
        let mask := 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        a := and(mask, mload(add(b, 36)))
        //36 is the offset of the first param of the data, if encoded properly.
        //4 bytes for the function signature, and 32 for the address.
    }
  }


  //rlpTransaction is a value at the bottom of the transaction trie.
  function getReceiptDetails(bytes rlpReceipt) internal returns (Log memory l) {
    RLP.RLPItem[] memory receipt = rlpReceipt.toRLPItem().toList();
    RLP.RLPItem[] memory logs = receipt[3].toList();
    RLP.RLPItem[] memory log = logs[0].toList();
    RLP.RLPItem[] memory logValue = log[1].toList();

    l.sender = address(logValue[1].toUint());
    l.etcAddr = address(logValue[2].toUint());
    l.value = logValue[3].toUint();
  }


  //rlpTransaction is a value at the bottom of the transaction trie.
  function getTransactionDetails(bytes rlpTransaction) internal returns (Transaction memory tx) {
    var it = rlpTransaction.toRLPItem().iterator();

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
  }
}
