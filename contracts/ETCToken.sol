pragma solidity ^0.4.8;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./ERC20.sol";
import "./PeaceRelay.sol";
import "./RLP.sol";


contract ETCToken is ERC20, SafeMath, Ownable {

  using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;

  // Public variables of the token
  string public name;
  string public symbol;
  uint8 public decimals;    //How many decimals to show.
  string public version = 'v0.1';
  uint public totalSupply;
  uint public DEPOSIT_GAS_MINIMUM; //should be constant
  bytes4 public LOCK_FUNCTION_SIG;

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  PeaceRelay public ETCRelay;
  address ethRelayAddr; //maybe rename to EthLockingContract

  struct Transaction {
    uint nonce;
    uint gasPrice;
    uint gasLimit;
    address to;
    uint value;
    bytes data;
  }

  event Burn(address indexed from, address indexed etcAddr, uint value);
  event Mint(address indexed to, uint value);


  function ETCToken(address peaceRelayAddr, address _ethRelayAddr, uint depositGasMinimum,
                    bytes4 lockFunctionSig)
  {
    totalSupply = 0;
    name = 'ETCToken';        // Set the name for display purposes
    symbol = 'ETC';                       // Set the symbol for display purposes
    decimals = 9;                        // Amount of decimals for display purposes
    ETCRelay = PeaceRelay(peaceRelayAddr);
    ethRelayAddr = _ethRelayAddr;
    DEPOSIT_GAS_MINIMUM = depositGasMinimum;
    LOCK_FUNCTION_SIG = lockFunctionSig;
  }


  function mint(bytes rlpProof, bytes rlpPath, bytes rlpTransaction, bytes32 blockHash) returns (bool success) {
    if (ETCRelay.verifyTransaction(rlpProof, rlpPath, rlpTransaction, blockHash)) {
    	Transaction memory tx = getTransactionDetails(rlpTransaction);
      bytes4 functionSig = getSig(tx.data);

      if (functionSig != LOCK_FUNCTION_SIG) throw;
      if (tx.to != ethRelayAddr) throw;
      if (tx.gasLimit < DEPOSIT_GAS_MINIMUM) throw;

      address newAddress = getAddress(tx.data);

    	totalSupply = safeAdd(totalSupply, tx.value);
    	balances[newAddress] = safeAdd(balances[newAddress], tx.value);
    	Mint(newAddress, tx.value);
    	return true;
    }
    return false;
  }

  function burn(uint256 _value, address etcAddr) returns (bool success) {
  	// safeSub already has throw, so no need to throw
  	balances[msg.sender] = safeSub(balances[msg.sender], _value) ;
  	totalSupply = safeSub(totalSupply, _value);
  	Burn(msg.sender, etcAddr, _value);
  	return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
  	// safeSub already has throw, so no need to throw
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

	// Non-payable unnamed function prevents Ether from being sent accidentally
	function () {}



  // HELPER FUNCTIONS


  function getSig(bytes b) constant returns (bytes4 functionSig) {
    if (b.length < 4) throw;
    //could use assembly, but this is a very short loop :)
    for (uint i = 0; i < 4; i++) {
      //not working for some reason
      //functionSig[i] = b[i];
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
        //4 bytes for the function signature, and 32 for the addess.
    }
  }

  //rlpTransaction is a value at the bottom of the transaction trie.
  function getTransactionDetails(bytes rlpTransaction) constant internal returns (Transaction memory tx) {
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
