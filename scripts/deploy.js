async function main() {


    const LoanContract = await ethers.getContractFactory("LoanRequest");
    const loanContract = await LoanContract.deploy();
    
    console.log("contract deployed to:", loanContract.target);
  }
  
  main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
  