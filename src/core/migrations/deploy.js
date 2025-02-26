const Voting = artifacts.require("Vote");

module.exports = function(deployer) {
  const proposalNames = ["Proposal 1", "Proposal 2", "Proposal 3"].map(name => web3.utils.asciiToHex(name));
  deployer.deploy(Voting, proposalNames);
};