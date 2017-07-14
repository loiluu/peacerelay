pragma solidity ^0.4.11;

import "./RLP.sol";

contract PeaceRelay {
	using RLP for RLP.RLPItem;
  using RLP for RLP.Iterator;
  using RLP for bytes;

	mapping (bytes32 => BlockHeader) blocks;

	struct BlockHeader {
      uint      prevBlockHash;// 0
			bytes32		txRoot;				// 4
  }

	//For now, just assume all blocks are good + valid.
	//In the future, will use SmartPool's verification.
	function submitBlock(bytes rlpHeader, bytes32 blockHash) {
  	BlockHeader memory header = parseBlockHeader(rlpHeader);

		blocks[blockHash] = header;
	}


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
}
