var PeaceRelay = artifacts.require("./PeaceRelay.sol");
EthProof  = require('../merkle-patricia-proof/lib/ethProof.js')
EthVerify = require('../merkle-patricia-proof/lib/ethVerify.js')
ethProof = new EthProof(new Web3.providers.HttpProvider("https://mainnet.infura.io"))

contract('PeaceRelay', function(accounts) {
  var peaceRelay

  describe("parsing block headers", (done) => {
    it("with block 1", function () {
      var p
      var test = false
      ethProof.getTxProof('0xb53f752216120e8cbe18783f41c6d960254ad59fac16229d4eaec5f7591319de').then(res => {
        p = res
        test = true
        console.log("RUNNING")
        return PeaceRelay.new()
      }).then(instance => {
        peaceRelay = instance
        return peaceRelay.submitBlock(p.blockhash, p.header)
      }).then(() => {
        return peaceRelay.getStateRoot(p.blockhash)
      }).then(root => {
        assert.equal(root, p.stateRoot, "roots should match")
        return peaceRelay.getTxRoot(p.blockhash)
      }).then(root => {
        assert.equal(root, p.txRoot, "roots should match")
        return peaceRelay.getReceiptRoot(p.blockhash)
      }).then(root => {
        assert.equal(root, p.receiptRoot, "roots should match")
        done()
      })
    })

    it("with block 2", function () {
      var p
      ethProof.getTxProof('0xc55e2b90168af6972193c1f86fa4d7d7b31a29c156665d15b9cd48618b5177ef', function(error,result) {
        p = result
        return PeaceRelay.new().then(instance => {
          peaceRelay = instance
          return peaceRelay.submitBlock(p.blockhash, p.header)
        }).then(() => {
          return peaceRelay.getStateRoot(p.blockhash)
        }).then(root => {
          assert.equal(root, p.stateRoot, "roots should match")
          return peaceRelay.getTxRoot(p.blockhash)
        }).then(root => {
          assert.equal(root, p.txRoot, "roots should match")
          return peaceRelay.getReceiptRoot(p.blockhash)
        }).then(root => {
          assert.equal(root, p.receiptRoot, "roots should match")
        })
      })
    })

    it("with block 3", function () {
      var p
      ethProof.getTxProof('0x299a93acf5b100336455ef6ecda39e22329fb750e6264c8ee44f579947349de9', function(error,result) {
        p = result
        return PeaceRelay.new().then(instance => {
          peaceRelay = instance
          return peaceRelay.submitBlock(p.blockhash, p.header)
        }).then(() => {
          return peaceRelay.getStateRoot(p.blockhash)
        }).then(root => {
          assert.equal(root, p.stateRoot, "roots should match")
          return peaceRelay.getTxRoot(p.blockhash)
        }).then(root => {
          assert.equal(root, p.txRoot, "roots should match")
          return peaceRelay.getReceiptRoot(p.blockhash)
        }).then(root => {
          assert.equal(root, p.receiptRoot, "roots should match")
        })
      })
    })

  })

  describe("transaction verification", function () {
    before(function () {
      return PeaceRelay.new().then(instance => {
        peaceRelay = instance
      })
    })


    it("should work with transaction 1", function () {
      var p
      ethProof.getTxProof('0xb53f752216120e8cbe18783f41c6d960254ad59fac16229d4eaec5f7591319de', function(error,result) {
        p = result
        return peaceRelay.submitBlock(p.blockhash, p.header).then(() => {
          return peaceRelay.checkTxProof(p.blockhash, p.stack, p.path, p.value)
        }).then(res => {
          assert.isTrue(res,"proof should pass")
        })
      })
    })

    it("should work with transaction 2", function () {
      var p
      ethProof.getTxProof('0xc55e2b90168af6972193c1f86fa4d7d7b31a29c156665d15b9cd48618b5177ef', function(error,result) {
        p = result
        return peaceRelay.submitBlock(p.blockhash, p.header).then(() => {
          return peaceRelay.checkTxProof(p.blockhash, p.stack, p.path, p.value)
        }).then(res => {
          assert.isTrue(res,"proof should pass")
        })
      })
    })


    it("should work with transaction 3", function () {
      var p
      ethProof.getTxProof('0x299a93acf5b100336455ef6ecda39e22329fb750e6264c8ee44f579947349de9', function(error,result) {
        p = result
        return peaceRelay.submitBlock(p.blockhash, p.header).then(() => {
          return peaceRelay.checkTxProof(p.blockhash, p.stack, p.path, p.value)
        }).then(res => {
          assert.isTrue(res,"proof should pass")
        })
      })
    })

    it("should work with transaction 4", function () {
      var p
      ethProof.getTxProof('0x4e4b9cd37d9b5bb38941983a34d1539e4930572bdaf41d1aa54ddc738630b1bb', function(error,result) {
        p = result
        console.log(p)
        return peaceRelay.submitBlock(p.blockhash, p.header).then(() => {
          return peaceRelay.checkTxProof(p.blockhash, p.stack, p.path, p.value)
        }).then(res => {
          assert.isTrue(res,"proof should pass")
        })
      })
    })

    it("should work with transaction 5", function () {
      var p
      console.log(p)
      ethProof.getTxProof('0x74bdf5450025b8806d55cfbb9b393dce630232f5bf87832ae6b675db9d286ac3', function(error,result) {
        p = result
        return peaceRelay.submitBlock(p.blockhash, p.header).then(() => {
          return peaceRelay.checkTxProof(p.blockhash, p.stack, p.path, p.value)
        }).then(res => {
          assert.isTrue(res,"proof should pass")
        })
      })
    })

    it("Should not allow verification with a mistake is stack", function () {
      var p
      ethProof.getTxProof('0x74bdf5450025b8806d55cfbb9b393dce630232f5bf87832ae6b675db9d286ac3', function(error,result) {
        p = result
        return peaceRelay.submitBlock(p.blockhash, p.header).then(() => {
          return peaceRelay.checkTxProof(p.blockhash, p.stack.slice(0, -1), p.path, p.value)
        }).then(res => {
          assert.isFalse(res,"proof should pass")
        })
      })
    })

    it("Should not allow verification with a fake transaction", function () {
      var p
      ethProof.getTxProof('0x74bdf5450025b8806d55cfbb9b393dce630232f5bf87832ae6b675db9d286ac3', function(error,result) {
        p = result
        return peaceRelay.submitBlock(p.blockhash, p.header).then(() => {
          return peaceRelay.checkTxProof(p.blockhash, p.stack, p.path, p.value.slice(0, -1))
        }).then(res => {
          assert.isFalse(res,"proof should pass")
        })
      })
    })
  })
})
