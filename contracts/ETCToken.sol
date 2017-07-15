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

    /* Public variables of the token */
  string public name;       
  string public symbol;
  uint8 public decimals;    //How many decimals to show.
  string public version = 'v0.1'; 
  uint256 public totalSupply;

  mapping(address => uint) balances;
  mapping (address => mapping (address => uint)) allowed;
  PeaceRelay public ETCRelay;
  address ethRelayAddr;

  event Burn(address indexed from, address indexed etcAddr, uint value);
  event Mint(address indexed to, uint value);

  /*
   *  The RLC Token created with the time at which the crowdsale end
   */

  function ETCToken(address peaceRelayAddr, address _ethRelayAddr) {
    totalSupply = 0;
    name = 'ETCToken';        // Set the name for display purposes     
    symbol = 'ETC';                       // Set the symbol for display purposes  
    decimals = 9;                        // Amount of decimals for display purposes
    ETCRelay = PeaceRelay(peaceRelayAddr);
    ethRelayAddr = _ethRelayAddr;
  }

  //REQUIRED: rlpTransaction must be generated from the said js code (ask Nate)
  function getTransactionDetails(bytes rlpTransaction) returns (uint value, address ethAddr){  	  	
  	var it = rlpTransaction.toRLPItem().iterator();

	uint idx;
	while(it.hasNext() && idx < 9) {         	 
		if (idx == 0) {
		   uint nonce = it.next().toUint(); // nonce
		}
		else if (idx == 1) {
			uint gasPrice = it.next().toUint(); // gas price
		} else if (idx == 2) {
			// gasProvided
		} else if (idx == 3){
			address relayAddr = it.next().toAddress();
		} else if (idx == 4){
			value = it.next().toUint(); // amount of etc send	 	
		} else if (idx == 5){
			ethAddr = it.next().toAddress(); // get the beneficial eth addr in the data field
		}
		idx++;         
	}
	if (relayAddr != ethRelayAddr){
		value = 0;
	}
  }

  function mint(bytes rlpProof, bytes rlpPath, bytes rlpTransaction, bytes32 blockHash) returns (bool success){
	if (ETCRelay.verifyTransaction(rlpProof, rlpPath, rlpTransaction, blockHash))
	{
		var (_value, ethAddr) = getTransactionDetails(rlpTransaction);
		totalSupply = safeAdd(totalSupply, _value);
		balances[ethAddr] = safeAdd(balances[ethAddr], _value);
		Mint(ethAddr, _value);
		return true;
	}
	return false;
	
  }

  function burn(uint256 _value, address etcAddr) returns (bool success){
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
  
	/* This unnamed function is called whenever someone tries to send ether to it */
	function () {
	    throw;     // Prevents accidental sending of ether
	}
}
