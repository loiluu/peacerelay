var PeaceRelay = artifacts.require("./PeaceRelayCmix.sol");
var Ethash = artifacts.require("./Ethash.sol");

var sample = require('../cmix_header_input/sample.json')
var header = '0x' + sample.sample_list[0].header
var blockhash = '0x' + sample.sample_list[0].block_hash
var cmix = sample.sample_list[0].cmix

// console.log(header)
// console.log(cmix)

function parseBlock(peaceRelay) {
  return new Promise((resolve, reject) => {
    return peaceRelay.submitBlock(header, blockhash, cmix, {gas: 500000}).then(tx => {
      resolve()
    })
  })
}

contract('PeaceRelay', function(accounts) {
  var peaceRelay

  it("Should allow blocks to be submitted and parsed", function () {
    return Ethash.new().then(instance => {
      return PeaceRelay.new(instance.address)
    }).then(instance => {
      peaceRelay = instance
      return parseBlock(peaceRelay)
    })
  })
})