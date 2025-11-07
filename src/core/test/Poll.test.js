const Poll = artifacts.require('Poll')
const PollFactory = artifacts.require('PollFactory')
const truffleAssert = require('truffle-assertions')
const { MerkleTree } = require('merkletreejs')
const keccak256 = require('keccak256')

contract('Poll', (accounts) => {
  const [admin, voter1, voter2, voter3] = accounts

  it('open voting happy path', async () => {
    const factory = await PollFactory.new({ from: admin })
    const tx = await factory.createPoll(admin, 'T', 'D', ['A', 'B'], 0, 0, false, false, '0x0000000000000000000000000000000000000000', '0x'+'0'.repeat(64), { from: admin })
    const pollAddr = tx.logs.find(l => l.event === 'PollCreated').args.poll
    const poll = await Poll.at(pollAddr)
    await poll.activate({ from: admin })
    await poll.vote(1, { from: voter1 })
    const tallies = await poll.getTallies()
    assert.equal(tallies[0].toString(), '0')
    assert.equal(tallies[1].toString(), '1')
  })

  it('commit reveal voting', async () => {
    const factory = await PollFactory.new({ from: admin })
    const tx = await factory.createPoll(admin, 'T', 'D', ['A', 'B'], 0, 0, false, true, '0x0000000000000000000000000000000000000000', '0x'+'0'.repeat(64), { from: admin })
    const pollAddr = tx.logs.find(l => l.event === 'PollCreated').args.poll
    const poll = await Poll.at(pollAddr)
    await poll.activate({ from: admin })
    const salt = web3.utils.randomHex(32)
    const commitment = web3.utils.soliditySha3({t:'address', v: voter1}, {t:'uint256', v: 1}, {t:'bytes32', v: salt})
    await poll.commit(commitment, [], { from: voter1 })
    await poll.end({ from: admin })
    await poll.reveal(1, salt, { from: voter1 })
    const tallies = await poll.getTallies()
    assert.equal(tallies[1].toString(), '1')
  })

  it('merkle allowlist verify', async () => {
    const leaves = [voter1, voter2].map(a => Buffer.from(web3.utils.soliditySha3({t:'address', v: a}).slice(2), 'hex'))
    const tree = new MerkleTree(leaves, keccak256, { sortPairs: true })
    const root = '0x' + tree.getRoot().toString('hex')

    const factory = await PollFactory.new({ from: admin })
    const tx = await factory.createPoll(admin, 'T', 'D', ['A', 'B'], 0, 0, true, true, '0x0000000000000000000000000000000000000000', root, { from: admin })
    const pollAddr = tx.logs.find(l => l.event === 'PollCreated').args.poll
    const poll = await Poll.at(pollAddr)
    await poll.activate({ from: admin })
    const leaf = Buffer.from(web3.utils.soliditySha3({t:'address', v: voter1}).slice(2), 'hex')
    const proof = tree.getHexProof(leaf)
    const salt = web3.utils.randomHex(32)
    const commitment = web3.utils.soliditySha3({t:'address', v: voter1}, {t:'uint256', v: 0}, {t:'bytes32', v: salt})
    await poll.commit(commitment, proof, { from: voter1 })
    await poll.end({ from: admin })
    await poll.reveal(0, salt, { from: voter1 })
    const tallies = await poll.getTallies()
    assert.equal(tallies[0].toString(), '1')
  })
})
