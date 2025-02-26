const Vote = artifacts.require("Vote");

module.exports = function(deployer, network, accounts) {
  const proposalNames = ["Proposal 1", "Proposal 2", "Proposal 3"].map(name => web3.utils.asciiToHex(name));
  const initialAuthorities = accounts.slice(0, 3);
  deployer.deploy(Vote, proposalNames, initialAuthorities);
};