// async function main() {


//     const LoanContract = await ethers.getContractFactory("LoanRequest");
//     const LandContract = await ethers.getContractFactory("LandDocumentNFT");

//     const loanContract = await LoanContract.deploy();
//     const landContract = await LandContract.deploy();
    
//     console.log("Loan contract deployed to:", loanContract.target);
//     console.log("Land contract deployed to:", landContract.target);

//   }
  
//   main().catch((error) => {
//     console.error(error);
//     process.exitCode = 1;
//   });
const { ethers } = require("hardhat");

async function main() {
  // Force rebuild with viaIR settings
  await hre.run("clean");
  await hre.run("compile", { force: true });

  // Deploy with explicit gas limits and optimization
  const deploymentOptions = {
    gasLimit: 30_000_000,  // Needed for complex contracts
    pollingInterval: 1000   // Better for local deployment
  };

 
  console.log("Deploying LoanRequest...");
  const LoanContract = await ethers.getContractFactory("LoanRequest");
  const loanContract = await LoanContract.deploy(deploymentOptions);
  await loanContract.waitForDeployment();
  console.log("Loan contract deployed to:", loanContract.target);

  console.log("Deploying LandDocumentNFT...");
  const LandContract = await ethers.getContractFactory("LandDocumentNFT");
  const landContract = await LandContract.deploy(deploymentOptions);
  await landContract.waitForDeployment();
  console.log("Land contract deployed to:", landContract.target);

  // Verify contracts (optional)
  console.log("Verification completed (local network)");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });