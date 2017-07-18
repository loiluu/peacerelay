var PeaceRelay = artifacts.require("./PeaceRelay.sol");

function parseBlock(peaceRelay, txData) {
  return new Promise((resolve, reject) => {
    return peaceRelay.submitBlock(header, blockhash, cmix).then(tx => {
      resolve()
    })
  })
}

var sample = require('../cmix_header_input/sample.json')
var header = '0x' + sample.sample_list[0].header
var blockhash = '0x' + sample.sample_list[0].block_hash
var cmix = sample.sample_list[0].cmix