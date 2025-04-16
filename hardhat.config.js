require("@nomicfoundation/hardhat-toolbox");
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",
  settings: {
    viaIR: true,       // Enable IR pipeline
    optimizer: { 
      enabled: true,
      runs: 200,
      details: {
        yul: true,
        yulDetails: {
          stackAllocation: true, 
          optimizerSteps: "u"// Critical fix
        }    // Required for viaIR
      }
    }
  },
  defaultNetwork :'hardhat',
  networks:{
    localhost : {
       url : 'http://127.0.0.1:8545',
       chainId : 31337
    }
  }
};
